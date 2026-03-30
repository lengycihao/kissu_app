import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import '../models/game_models.dart';
import '../services/game_im_service.dart';
import '../widgets/game_event_dialog.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';

/// 核心游戏逻辑控制器
/// 管理：题目进度、答题(4次机会)、聊天/答案模式切换、特权、提示、在线检测、数据同步
class GamePlayController extends GetxController {
  late final GameIMServiceV2 imService;

  // ===== 路由参数 =====
  late final String groupId;
  late final bool isInitiator; // 是否发起方（出题者）
  List<GameTopic> topics = [];

  // ===== 游戏状态 =====
  final currentIndex = 0.obs; // 当前题目索引 0-4
  final phase = GamePhase.playing.obs;
  final isGameOver = false.obs;

  // ===== 答题 =====
  final wrongAttempts = 0.obs; // 当前题错误次数
  final maxAttempts = 4; // 每题最多4次
  final correctCount = 0.obs; // 答对总数

  // ===== 进度条状态 =====
  final questionStatuses = <QuestionStatus>[].obs;

  // ===== 聊天消息 =====
  final messages = <GameChatMessage>[].obs;
  final scrollController = ScrollController();
  final inputController = TextEditingController();

  // ===== 特权 =====
  final privilegeCount = 1.obs; // 使用特权次数（每轮1次）
  final showPrivilegePopup = false.obs;

  // ===== 提示 =====
  final hintRequestCount = 0.obs; // 提示请求次数
  final hintRequestedThisQ = false.obs;
  final currentHint = Rxn<String>();
  final waitingForHintSelection = false.obs;

  // ===== 在线检测 =====
  final isPartnerOnline = false.obs;
  Timer? _onlineCheckTimer;

  // ===== 动画状态 =====
  final showResultAnimation = false.obs; // 答错/答对动画
  final resultAnimationType = 0.obs; // 0=错误, 1=正确

  // ===== 游戏事件弹窗 =====
  final currentEventDialog = Rxn<String>(); // 当前要显示的事件弹窗类型

  // ===== 答题弹窗状态 =====
  final isAnswerDialogOpen = false.obs; // 答题弹窗打开时禁止Scaffold随键盘resize

  // ===== 惩罚 =====
  final receivedPenaltyType = Rxn<String>(); // 回答者收到的惩罚类型
  final receivedPenaltyProof = Rxn<String>(); // 回答者收到的惩罚凭证（URL）

  // ===== 当前题目 =====
  GameTopic? get currentTopic =>
      currentIndex.value < topics.length ? topics[currentIndex.value] : null;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    groupId = args['groupId'] as String? ?? '';
    isInitiator = args['isInitiator'] as bool? ?? true;

    // 题目：发起方从选题页带过来，接收方后续从同步消息获取
    final topicArgs = args['topics'];
    if (topicArgs is List<GameTopic>) {
      topics = topicArgs;
    }

    // 初始化进度条
    questionStatuses.value = List.generate(5, (_) => QuestionStatus.pending);

    // 设置IM
    imService = GameIMServiceV2();
    _setupIM();

    // 统一在 controller 里监听弹窗事件，避免 build() 里多次注册 Worker
    ever(currentEventDialog, (String? eventType) {
      if (eventType == null || eventType.isEmpty) return;
      currentEventDialog.value = null; // 立即清空防止重入
      _handleEventDialog(eventType);
    });

    // 添加系统消息
    _addSystemMessage('游戏开始！共5题');
    if (!isInitiator) {
      _addSystemMessage(
        '请等待对方描述答案\n你则根据对方的描述在下方提交答案\n每轮可使用一次特权（增加答题次数或跳过这道题）\n每道题可使用一次提示请求',
      );
      _addSystemMessage('等待同步题目数据...');
    }
  }

  Future<void> _setupIM() async {
    if (groupId.isNotEmpty) {
      // 先注册回调，确保不漏消息
      imService.onGameMessage = _onGameMessage;
      imService.onPartnerOnlineChanged = (online) {
        isPartnerOnline.value = online;
      };

      if (isInitiator) {
        // 发起方：加入群监听
        await imService.joinGameGroup(groupId);
        await imService.sendSenderJoined();
        _addSystemMessage('你进入了房间');
        // 有题目时主动发送给对方（首次进入 / 重新进入且数据还在）
        if (topics.isNotEmpty) {
          _sendFullStateToPartner();
        } else {
          _addSystemMessage('等待对方同步游戏数据...');
        }
      } else {
        // 接收方：加入群
        final ok = await imService.joinGameGroup(groupId);
        if (!ok) {
          OKToastUtil.showError('加入游戏房间失败');
          Get.back();
          return;
        }
        await imService.sendReceiverJoined();
        _addSystemMessage('你进入了房间');
        // 接收方有题目时也主动同步（发起方可能重入房间）
        if (topics.isNotEmpty) {
          _sendFullStateToPartner();
        }
      }
    } else {
      imService.onGameMessage = _onGameMessage;
      imService.onPartnerOnlineChanged = (online) {
        isPartnerOnline.value = online;
      };
    }

    // 启动心跳
    imService.startHeartbeat();

    // 定时检查在线状态
    _onlineCheckTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => imService.checkPartnerOnline(),
    );
  }

  @override
  void onClose() {
    _onlineCheckTimer?.cancel();
    imService.stopHeartbeat();
    // 发送离开消息
    if (isInitiator) {
      imService.sendSenderAway();
    } else {
      imService.sendReceiverAway();
    }
    imService.dispose();
    scrollController.dispose();
    inputController.dispose();
    super.onClose();
  }

  // ==================== 答题逻辑 ====================

  /// 提交答案（答题者/接收方调用）
  Future<void> submitAnswer(String answer) async {
    if (answer.trim().isEmpty || isGameOver.value) return;

    if (currentTopic == null) {
      _addSystemMessage('题目数据尚未同步，请稍等...');
      return;
    }

    // 检查是否还有答题机会
    if (wrongAttempts.value >= maxAttempts) {
      _addSystemMessage('本题答题机会已用完');
      return;
    }

    // 添加本地答案消息
    _addMessage(answer, GameChatMessageType.answer, isSelf: true);

    // 通过IM发送
    await imService.sendGameAnswer(answer.trim());

    // 本地判断答案（双方都判断，确保即使消息延迟也有即时反馈）
    _checkAnswer(answer.trim(), isSelf: true);
  }

  void _checkAnswer(String answer, {required bool isSelf}) {
    final topic = currentTopic;
    if (topic == null || topics.isEmpty) return;
    if (currentIndex.value >= topics.length) return;

    final isCorrect = answer == topic.answer;
    if (isCorrect) {
      // 答对
      correctCount.value++;
      questionStatuses[currentIndex.value] = QuestionStatus.correct;
      topics[currentIndex.value].status = QuestionStatus.correct;
      _addSystemMessage('🎉 回答正确！答案是「${topic.answer}」');

      // 显示正确弹窗（最后一题不弹，因为马上会显示游戏结束弹窗）
      if (currentIndex.value < 4) {
        currentEventDialog.value = 'right';
      }

      // 只有本地答题才发送状态（避免重复）
      if (isSelf) {
        imService.sendAnswerState(1);
      }

      // 最后一题直接结算；其余题等2秒让弹窗展示完
      if (currentIndex.value >= 4) {
        _nextQuestion();
      } else {
        Future.delayed(const Duration(seconds: 2), () => _nextQuestion());
      }
    } else {
      // 答错
      wrongAttempts.value++;
      topics[currentIndex.value].wrongAttempts = wrongAttempts.value;
      final remaining = maxAttempts - wrongAttempts.value;

      if (wrongAttempts.value < maxAttempts) {
        // 前3次错误：系统提示
        _addSystemMessage('❌ 回答错误，还剩$remaining次机会');
      } else {
        // 第4次错误：题目失败
        questionStatuses[currentIndex.value] = QuestionStatus.wrong;
        topics[currentIndex.value].status = QuestionStatus.wrong;
        _addSystemMessage('💔 回答错误，答案是「${topic.answer}」');

        // 显示错误弹窗（最后一题不弹，因为马上会显示游戏结束弹窗）
        if (currentIndex.value < 4) {
          currentEventDialog.value = 'wrong';
        }

        // 只有本地答题才发送状态（避免重复）
        if (isSelf) {
          imService.sendAnswerState(0);
        }

        // 展示错误动画，3秒后下一题（最后一题直接结算）
        showResultAnimation.value = true;
        resultAnimationType.value = 0;
        if (currentIndex.value >= 4) {
          _nextQuestion();
        } else {
          Future.delayed(const Duration(seconds: 3), () {
            showResultAnimation.value = false;
            _nextQuestion();
          });
        }
      }
    }
  }

  /// 进入下一题
  void _nextQuestion() {
    if (currentIndex.value >= 4) {
      _endGame();
      return;
    }
    currentIndex.value++;
    wrongAttempts.value = 0;
    hintRequestedThisQ.value = false;
    currentHint.value = null;
    waitingForHintSelection.value = false;
    _addSystemMessage('第 ${currentIndex.value + 1} 题开始！');

    // 发送同步消息
    _sendSyncMessage();
  }

  /// 游戏结束
  void _endGame() {
    isGameOver.value = true;
    phase.value = GamePhase.result;

    final passed = correctCount.value >= 3;
    showResultAnimation.value = true;
    resultAnimationType.value = passed ? 1 : 0;

    // 显示结果弹窗
    currentEventDialog.value = passed ? 'success' : 'failed';

    // 发送游戏结果
    imService.sendGameResult(
      result: passed ? 1 : 0,
      correctCount: correctCount.value,
    );

    _addSystemMessage(
      passed
          ? '🎉 挑战成功！答对 ${correctCount.value}/5 题'
          : '😢 挑战失败！答对 ${correctCount.value}/5 题',
    );
  }

  // ==================== 聊天 ====================

  /// 发送聊天消息
  Future<void> sendChatText(String text) async {
    if (text.trim().isEmpty) return;

    // 检查聊天内容不能包含答案
    if (currentTopic != null && isInitiator) {
      for (final char in currentTopic!.answerChars) {
        if (text.contains(char)) {
          OKToastUtil.showError('描述中不能包含答案的任一字！');
          return;
        }
      }
    }

    _addMessage(text, GameChatMessageType.text, isSelf: true);
    await imService.sendGameText(text.trim());

    // 同时发送同步消息
    _sendSyncMessage();
  }

  // ==================== 特权 ====================

  /// 使用特权：答题次数+1
  Future<void> usePrivilegeExtraAttempt() async {
    if (privilegeCount.value <= 0) return;
    privilegeCount.value--;
    wrongAttempts.value = (wrongAttempts.value - 1).clamp(0, maxAttempts);
    _addSystemMessage('🌟 使用特权：答题次数+1');
    currentEventDialog.value = 'addTimesSelf';
    showPrivilegePopup.value = false;
    await imService.sendPrivilegeUse('extra_attempt');
  }

  /// 使用特权：跳过这道题
  Future<void> usePrivilegeSkip() async {
    if (privilegeCount.value <= 0) return;
    if (topics.isEmpty || currentIndex.value >= topics.length) {
      _addSystemMessage('题目数据尚未同步，无法使用特权');
      showPrivilegePopup.value = false;
      return;
    }
    privilegeCount.value--;
    questionStatuses[currentIndex.value] = QuestionStatus.skipped;
    topics[currentIndex.value].status = QuestionStatus.skipped;
    _addSystemMessage('🌟 使用特权：跳过本题');
    currentEventDialog.value = 'skipSelf';
    showPrivilegePopup.value = false;
    await imService.sendPrivilegeUse('skip');
    Future.delayed(const Duration(seconds: 1), () => _nextQuestion());
  }

  // ==================== 提示 ====================

  /// 请求提示
  Future<void> requestHint() async {
    if (hintRequestedThisQ.value) return;

    if (currentTopic == null || topics.isEmpty) {
      _addSystemMessage('题目数据尚未同步，无法请求提示');
      return;
    }

    hintRequestedThisQ.value = true;
    hintRequestCount.value++;

    if (isPartnerOnline.value) {
      // 对方在线：发送请求，等对方选择
      _addMessage('请求提示', GameChatMessageType.hintRequest, isSelf: true);
      await imService.sendHintRequest();
    } else {
      // 对方离线：本地随机选一个提示字
      final chars = currentTopic!.answerChars;
      if (chars.isNotEmpty) {
        final idx = Random().nextInt(chars.length);
        currentHint.value = chars[idx];
        _addSystemMessage('💡 系统提示：${chars[idx]}');
      }
    }
  }

  /// 出题者选择提示字（对方在线时）
  Future<void> sendHintChar(int charIndex) async {
    if (currentTopic == null) return;
    if (charIndex < 0 || charIndex >= currentTopic!.answerChars.length) return;
    final hint = currentTopic!.answerChars[charIndex];
    currentHint.value = hint;
    waitingForHintSelection.value = false;
    _addMessage('提示已回复，上方查看', GameChatMessageType.hintResponse, isSelf: true);
    await imService.sendHintResponse(hint);
  }

  // ==================== 数据同步（临时方案） ====================

  /// 发送完整状态给对方（题目 + 进度），任何有数据的一方都可以调用
  void _sendFullStateToPartner() {
    if (topics.isEmpty) return;
    _sendTopicsSync();
    _sendSyncMessage();
  }

  /// 发送题目数据（任一方有题目即可发送）
  void _sendTopicsSync() {
    if (topics.isEmpty) return;
    final topicsData = topics
        .map(
          (t) => <String, dynamic>{
            'answer': t.answer,
            'description': t.description,
            'isCustom': t.isCustom,
          },
        )
        .toList();
    imService.sendGameSync({'syncType': 'topics', 'topics': topicsData});
  }

  void _sendSyncMessage() {
    final topic = currentTopic;
    imService.sendGameSync({
      'syncType': 'state',
      'currentIndex': currentIndex.value,
      'correctCount': correctCount.value,
      'wrongAttempts': wrongAttempts.value,
      'statuses': questionStatuses.map((s) => s.index).toList(),
      'currentAnswer': topic?.answer ?? '',
      'currentDescription': topic?.description ?? '',
    });
  }

  void _handleSyncMessage(Map<String, dynamic> data) {
    final syncType = data['syncType'] as String? ?? 'state';

    if (syncType == 'topics') {
      // 处理题目数据同步（首次同步或重入同步都接受）
      final topicsData = data['topics'] as List<dynamic>?;
      if (topicsData != null) {
        final wasEmpty = topics.isEmpty;
        topics = topicsData
            .map(
              (t) => GameTopic(
                answer: (t as Map<String, dynamic>)['answer'] as String? ?? '',
                description: t['description'] as String? ?? '',
                isCustom: t['isCustom'] as bool? ?? false,
              ),
            )
            .toList();
        // 初始化/更新进度条
        if (questionStatuses.length != topics.length) {
          questionStatuses.value = List.generate(
            topics.length,
            (_) => QuestionStatus.pending,
          );
        }
        if (wasEmpty) {
          _addSystemMessage('已收到题目，游戏开始！');
        } else {
          _addSystemMessage('题目数据已同步');
        }
      }
      return;
    }

    // 处理状态同步
    final idx = data['currentIndex'] as int?;
    final correct = data['correctCount'] as int?;
    final wrong = data['wrongAttempts'] as int?;
    final statuses = data['statuses'] as List<dynamic>?;
    final currentAnswer = data['currentAnswer'] as String?;
    final currentDesc = data['currentDescription'] as String?;

    if (idx != null) currentIndex.value = idx;
    if (correct != null) correctCount.value = correct;
    if (wrong != null) wrongAttempts.value = wrong;
    if (statuses != null) {
      for (int i = 0; i < statuses.length && i < questionStatuses.length; i++) {
        questionStatuses[i] = QuestionStatus.values[statuses[i] as int];
      }
    }
    // 更新当前题目信息（接收方用）
    if (currentAnswer != null &&
        currentAnswer.isNotEmpty &&
        currentIndex.value < topics.length) {
      topics[currentIndex.value] = GameTopic(
        answer: currentAnswer,
        description: currentDesc ?? '',
      );
    }
  }

  // ==================== 事件弹窗处理 ====================

  void _handleEventDialog(String eventType) {
    GameEventType? type;
    switch (eventType) {
      case 'addTimes':     type = GameEventType.addTimes; break;
      case 'addTimesSelf': type = GameEventType.addTimesSelf; break;
      case 'skip':         type = GameEventType.skip; break;
      case 'skipSelf':     type = GameEventType.skipSelf; break;
      case 'wrong':        type = GameEventType.wrong; break;
      case 'right':        type = GameEventType.right; break;
      case 'success':      type = GameEventType.success; break;
      case 'failed':       type = GameEventType.failed; break;
    }
    if (type == null) return;

    if (eventType == 'success' || eventType == 'failed') {
      showGameEventDialogGet(type).then((_) => _navigateAfterGameEnd(eventType));
    } else {
      showGameEventDialogGet(type);
    }
  }

  void _navigateAfterGameEnd(String resultType) {
    if (resultType == 'success') {
      Get.toNamed(
        KissuRoutePath.guessGameV2Success,
        arguments: {'correctCount': correctCount.value, 'isInitiator': isInitiator},
      );
    } else {
      if (isPartnerOnline.value) {
        Get.toNamed(
          KissuRoutePath.guessGameV2Failed,
          arguments: {'isInitiator': isInitiator, 'isPartnerOnline': true},
        );
      } else {
        Get.until((route) => route.settings.name == KissuRoutePath.chat);
      }
    }
  }

  // ==================== IM消息处理 ====================

  void _onGameMessage(Map<String, dynamic> data, String senderID) {
    final type = data['type'] as String? ?? '';
    final senderName = data['senderName'] as String? ?? '对方';
    final senderAvatar = data['senderAvatar'] as String? ?? '';
    final content = data['content'] as String? ?? '';

    switch (type) {
      case 'game_text':
        _addMessage(
          content,
          GameChatMessageType.text,
          isSelf: false,
          name: senderName,
          avatar: senderAvatar,
          sid: senderID,
        );
        break;

      case 'game_answer':
        // 收到自己发出的消息，忽略（本地已通过 _checkAnswer(isSelf:true) 处理）
        if (senderID == imService.myIMUserID) break;

        _addMessage(
          content,
          GameChatMessageType.answer,
          isSelf: false,
          name: senderName,
          avatar: senderAvatar,
          sid: senderID,
        );
        // 对方发来的答案，判断结果
        _checkAnswer(content.trim(), isSelf: false);
        break;

      case 'game_answer_state':
        // 注意：双方都在 game_answer 中本地 _checkAnswer 了，
        // 这里只作为备用（当本地 _checkAnswer 因 topics 未同步而跳过时）
        final state = data['state'] as int? ?? 0;
        final alreadyHandled =
            currentIndex.value < questionStatuses.length &&
            questionStatuses[currentIndex.value] != QuestionStatus.pending;
        if (!alreadyHandled) {
          if (state == 1) {
            if (currentIndex.value < questionStatuses.length) {
              correctCount.value++;
              questionStatuses[currentIndex.value] = QuestionStatus.correct;
            }
            _addSystemMessage('🎉 回答正确！');
            // 显示正确弹窗（最后一题不弹）
            if (currentIndex.value < 4) {
              currentEventDialog.value = 'right';
            }
            Future.delayed(const Duration(seconds: 2), () => _nextQuestion());
          } else {
            if (currentIndex.value < questionStatuses.length) {
              questionStatuses[currentIndex.value] = QuestionStatus.wrong;
            }
            _addSystemMessage('💔 回答错误');
            // 显示错误弹窗（最后一题不弹）
            if (currentIndex.value < 4) {
              currentEventDialog.value = 'wrong';
            }
            showResultAnimation.value = true;
            resultAnimationType.value = 0;
            Future.delayed(const Duration(seconds: 3), () {
              showResultAnimation.value = false;
              _nextQuestion();
            });
          }
        }
        break;

      case 'game_hint_request':
        hintRequestedThisQ.value = true;
        if (isInitiator) {
          waitingForHintSelection.value = true;
          _addSystemMessage('💡 对方请求提示，请选择一个字作为提示');
        }
        _addMessage(
          '请求提示',
          GameChatMessageType.hintRequest,
          isSelf: false,
          name: senderName,
          avatar: senderAvatar,
          sid: senderID,
        );
        break;

      case 'game_hint_response':
        final hint = data['hintChar'] as String? ?? '';
        currentHint.value = hint;
        _addMessage(
          '提示已回复，上方查看',
          GameChatMessageType.hintResponse,
          isSelf: false,
          name: senderName,
          avatar: senderAvatar,
          sid: senderID,
        );
        break;

      case 'game_privilege':
        // 收到自己发出的消息，忽略（本地已弹窗）
        if (senderID == imService.myIMUserID) break;

        final privType = data['privilegeType'] as String? ?? '';
        if (privType == 'extra_attempt') {
          wrongAttempts.value = (wrongAttempts.value - 1).clamp(0, maxAttempts);
          _addSystemMessage('🌟 对方使用特权：答题次数+1');
          // 显示特权弹窗
          currentEventDialog.value = 'addTimes';
        } else if (privType == 'skip') {
          if (currentIndex.value < questionStatuses.length) {
            questionStatuses[currentIndex.value] = QuestionStatus.skipped;
          }
          _addSystemMessage('🌟 对方使用特权：跳过本题');
          // 显示特权弹窗
          currentEventDialog.value = 'skip';
          Future.delayed(const Duration(seconds: 1), () => _nextQuestion());
        }
        break;

      case 'game_failed_guesser':
        // 发起者选择了惩罚，回答者收到此消息
        final penaltyType = data['penaltyType'] as String? ?? '';
        receivedPenaltyType.value = penaltyType;
        break;

      case 'game_penalty_guesser':
        // 发起者完成了惩罚凭证，回答者收到此消息
        final pType = data['penaltyType'] as String? ?? '';
        final proofUrl = data['proofUrl'] as String? ?? '';
        receivedPenaltyType.value = pType;
        receivedPenaltyProof.value = proofUrl;
        break;

      case 'game_result':
        // 如果游戏已经结束，说明是收到自己发送的消息，忽略避免重复弹窗
        if (isGameOver.value) break;
        
        final result = data['result'] as int? ?? 0;
        isGameOver.value = true;
        phase.value = GamePhase.result;
        showResultAnimation.value = true;
        resultAnimationType.value = result;
        // 显示结果弹窗
        currentEventDialog.value = result == 1 ? 'success' : 'failed';
        _addSystemMessage(result == 1 ? '🎉 挑战成功！' : '😢 挑战失败！');
        break;

      case 'game_sender_joined':
        _addSystemMessage('对方进入了房间');
        isPartnerOnline.value = true;
        // 对方进入时，有数据的一方主动同步（支持重入场景）
        if (topics.isNotEmpty) {
          _sendFullStateToPartner();
        }
        break;

      case 'game_sender_away':
        _addSystemMessage('对方离开了房间');
        isPartnerOnline.value = false;
        break;

      case 'game_receiver_joined':
        _addSystemMessage('对方进入了房间');
        isPartnerOnline.value = true;
        // 对方进入时，有数据的一方主动同步（支持重入场景）
        if (topics.isNotEmpty) {
          _sendFullStateToPartner();
        }
        break;

      case 'game_receiver_away':
        _addSystemMessage('对方离开了房间');
        isPartnerOnline.value = false;
        break;

      case 'game_sync':
        _handleSyncMessage(data);
        break;
    }
  }

  // ==================== 工具方法 ====================

  void _addMessage(
    String content,
    GameChatMessageType type, {
    required bool isSelf,
    String? name,
    String? avatar,
    String? sid,
  }) {
    messages.add(
      GameChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_${messages.length}',
        senderId: sid ?? imService.myIMUserID,
        senderName: name ?? imService.myNickname,
        senderAvatar: avatar ?? imService.myAvatar,
        content: content,
        time: DateTime.now(),
        isSelf: isSelf,
        type: type,
      ),
    );
    _scrollToBottom();
  }

  void _addSystemMessage(String content) {
    messages.add(
      GameChatMessage(
        id: 'sys_${DateTime.now().millisecondsSinceEpoch}_${messages.length}',
        senderId: 'system',
        senderName: '系统',
        content: content,
        time: DateTime.now(),
        isSelf: false,
        type: GameChatMessageType.system,
      ),
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        // reverse:true时，pixels=0是底部（最新消息）
        scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
