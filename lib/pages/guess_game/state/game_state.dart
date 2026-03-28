import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/chat/chat_controller.dart';
import 'package:kissu_app/pages/chat/models/chat_message.dart';
import 'package:kissu_app/utils/user_manager.dart';
import '../models/game_models.dart';
import '../services/game_im_service.dart';

/// 你说我猜 游戏状态管理（ChangeNotifier，不用GetX）
/// 使用真实 IM 群聊进行消息收发
class GameState extends ChangeNotifier {
  // ===== IM 服务 =====
  final GameIMService _imService = GameIMService();
  GameIMService get imService => _imService;

  /// 对方退出回调（页面可监听此回调自动导航返回）
  VoidCallback? onPartnerExited;

  /// 加入房间失败回调（群已解散/不存在）
  void Function(String reason)? onJoinFailed;

  // ===== 房间状态 =====
  GameRoom? _room;
  GameRoom? get room => _room;

  GamePhase _phase = GamePhase.lobby;
  GamePhase get phase => _phase;

  // ===== 角色 & 流程状态 =====
  bool _isHost = true;
  bool get isHost => _isHost;

  GameRole? _myRole;
  GameRole? get myRole => _myRole;

  bool _inviteSent = false;
  bool get inviteSent => _inviteSent;

  bool _partnerJoined = false;
  bool get partnerJoined => _partnerJoined;

  bool _gameStarted = false;
  bool get gameStarted => _gameStarted;

  // ===== 题目 =====
  List<GameQuestion> _questions = [];
  List<GameQuestion> get questions => _questions;

  int _currentQuestionIndex = 0;
  int get currentQuestionIndex => _currentQuestionIndex;

  GameQuestion? get currentQuestion =>
      _questions.isNotEmpty && _currentQuestionIndex < _questions.length
          ? _questions[_currentQuestionIndex]
          : null;

  // ===== 倒计时 =====
  int _countdownValue = 3;
  int get countdownValue => _countdownValue;

  int _questionTimer = 120;
  int get questionTimer => _questionTimer;

  Timer? _countdownTimer;
  Timer? _questionTimerRef;

  // ===== 聊天 =====
  final List<GameChatMessage> _messages = [];
  List<GameChatMessage> get messages => List.unmodifiable(_messages);

  // ===== 特权 & 提示 =====
  int _privilegeCount = 1;
  int get privilegeCount => _privilegeCount;

  int _hintRequestCount = 0;
  int get hintRequestCount => _hintRequestCount;

  bool _hintRequestedThisQuestion = false;
  bool get hintRequestedThisQuestion => _hintRequestedThisQuestion;

  String? _currentHint;
  String? get currentHint => _currentHint;

  bool _waitingForHintSelection = false;
  bool get waitingForHintSelection => _waitingForHintSelection;

  bool _waitingForCustomAnswer = false;
  bool get waitingForCustomAnswer => _waitingForCustomAnswer;

  // ===== 得分 =====
  int _correctCount = 0;
  int get correctCount => _correctCount;

  int _totalScore = 0;
  int get totalScore => _totalScore;

  // ===== 题库 =====
  static final List<Map<String, String>> _questionBank = [
    {'answer': '西瓜', 'category': '水果'},
    {'answer': '熊猫', 'category': '动物'},
    {'answer': '钢琴', 'category': '乐器'},
    {'answer': '长城', 'category': '建筑'},
    {'answer': '月亮', 'category': '天文'},
    {'answer': '筷子', 'category': '生活用品'},
    {'answer': '蝴蝶', 'category': '昆虫'},
    {'answer': '篮球', 'category': '运动'},
    {'answer': '冰淇淋', 'category': '食物'},
    {'answer': '彩虹', 'category': '自然'},
    {'answer': '口红', 'category': '化妆品'},
    {'answer': '拥抱', 'category': '动作'},
    {'answer': '初恋', 'category': '情感'},
    {'answer': '日出', 'category': '自然'},
    {'answer': '棉花糖', 'category': '食物'},
    {'answer': '摩天轮', 'category': '游乐设施'},
    {'answer': '验牌', 'category': '棋牌'},
    {'answer': '跳绳', 'category': '运动'},
    {'answer': '星星', 'category': '天文'},
    {'answer': '巧克力', 'category': '食物'},
  ];

  // ===== 初始化 =====

  /// 创建房间（房主端，仅设置大厅状态，不立即创建群）
  void createRoom() {
    _isHost = true;
    _resetGameData();
    _inviteSent = false;
    _partnerJoined = false;
    _gameStarted = false;

    _room = GameRoom(
      roomId: 'room_${DateTime.now().millisecondsSinceEpoch}',
      groupId: '',
      host: GamePlayer(
        userId: _imService.myIMUserID,
        nickname: _imService.myNickname,
        avatarUrl: _imService.myAvatar,
      ),
      totalScore: 0,
      ranking: 0,
      weeklyCleared: 0,
    );
    _phase = GamePhase.lobby;
    notifyListeners();
  }

  /// 发送邀请（房主点击邀请按钮）
  /// 创建IM群聊 + 发送C2C邀请消息到聊天页面
  Future<bool> sendInvite() async {
    if (_inviteSent) return false;

    final groupID = await _imService.createGameGroup();
    if (groupID == null) {
      _addSystemMessage('❌ 创建游戏房间失败，请检查网络');
      notifyListeners();
      return false;
    }

    // 注册消息回调
    _imService.onGameMessage = _onGameMessageReceived;

    // 更新房间groupId
    _room = _room?.copyWith(groupId: groupID);

    // 发送C2C邀请消息到对方聊天页面
    final sent = await _imService.sendInviteMessage();
    if (sent) {
      _inviteSent = true;

      // 手动注入邀请消息到ChatController，使其立即在聊天页面显示
      _injectInviteMessageToChat(groupID);

      notifyListeners();
      return true;
    }
    return false;
  }

  /// 被邀请方加入房间（从聊天页面点击邀请卡片进入）
  Future<void> joinRoom(String groupId) async {
    _isHost = false;
    _resetGameData();
    _inviteSent = false;
    _partnerJoined = true;
    _gameStarted = false;

    final joined = await _imService.joinGameGroup(groupId);
    if (!joined) {
      // 群不存在或加入失败
      onJoinFailed?.call('邀请已过期，房间已关闭');
      return;
    }
    _imService.onGameMessage = _onGameMessageReceived;

    _room = GameRoom(
      roomId: 'room_${DateTime.now().millisecondsSinceEpoch}',
      groupId: groupId,
      host: GamePlayer(
        userId: _imService.partnerIMUserID,
        nickname: _imService.partnerNickname,
        avatarUrl: _imService.partnerAvatar,
      ),
      guest: GamePlayer(
        userId: _imService.myIMUserID,
        nickname: _imService.myNickname,
        avatarUrl: _imService.myAvatar,
      ),
      isGuestReady: true,
      totalScore: 0,
      ranking: 0,
      weeklyCleared: 0,
    );
    _phase = GamePhase.lobby;

    // 通知房主对方已加入
    await _imService.sendGameMessage(type: 'game_partner_joined');

    notifyListeners();
  }

  /// 房主端：对方已加入房间
  void onPartnerJoined() {
    _partnerJoined = true;
    _room = _room?.copyWith(
      guest: GamePlayer(
        userId: _imService.partnerIMUserID,
        nickname: _imService.partnerNickname,
        avatarUrl: _imService.partnerAvatar,
      ),
      isGuestReady: true,
    );
    notifyListeners();
  }

  /// 开始游戏（进入角色选择）
  void startGame() {
    if (_room == null || !_partnerJoined) return;
    _gameStarted = true;
    _phase = GamePhase.roleSelection;
    notifyListeners();
  }

  /// 选择角色并通知对方
  Future<void> selectRole(GameRole role) async {
    _myRole = role;
    final partnerRole = role == GameRole.describer
        ? GameRole.guesser
        : GameRole.describer;

    _room = _room?.copyWith(
      host: _room!.host.copyWith(role: _isHost ? role : partnerRole),
      guest: _room!.guest?.copyWith(role: _isHost ? partnerRole : role),
    );

    // 生成题目
    _generateQuestions();
    _currentQuestionIndex = 0;
    _correctCount = 0;
    _totalScore = 0;
    _privilegeCount = 1;
    _hintRequestCount = 0;
    _messages.clear();

    // 通过IM发送游戏开始信号（含题目数据）
    await _imService.sendGameStart(
      questions: _questions.map((q) => {
        'index': q.index,
        'answer': q.answer,
        'category': q.category ?? '',
        'isCustom': q.isCustom,
      }).toList(),
    );

    // 通知对方自己选择的角色
    await _imService.sendRoleSelect(role == GameRole.describer ? 'describer' : 'guesser');

    // 进入倒计时
    _startCountdown();
    notifyListeners();
  }

  /// 生成本轮5道题（前4题随机，第5题为自定义）
  void _generateQuestions() {
    final random = Random();
    final shuffled = List<Map<String, String>>.from(_questionBank)..shuffle(random);
    _questions = List.generate(5, (i) {
      if (i == 4) {
        return GameQuestion(
          index: i,
          answer: '',
          category: '自定义',
          isCustom: true,
        );
      }
      final q = shuffled[i % shuffled.length];
      return GameQuestion(
        index: i,
        answer: q['answer']!,
        category: q['category'],
        isCustom: false,
      );
    });
  }

  /// 出题者设置第5题的自定义答案
  Future<void> setCustomAnswer(String answer) async {
    if (answer.trim().isEmpty) return;
    final idx = _questions.indexWhere((q) => q.isCustom && q.answer.isEmpty);
    if (idx < 0) return;
    _questions[idx] = _questions[idx].copyWith(answer: answer.trim());
    _waitingForCustomAnswer = false;

    // 通知对方自定义答案
    await _imService.sendCustomAnswer(answer.trim());

    _startPlaying();
    notifyListeners();
  }

  /// 出题者随机生成第5题答案
  Future<void> randomizeCustomAnswer() async {
    final random = Random();
    final q = _questionBank[random.nextInt(_questionBank.length)];
    await setCustomAnswer(q['answer']!);
  }

  // ===== 倒计时逻辑 =====

  void _startCountdown() {
    _phase = GamePhase.countdown;
    _countdownValue = 3;
    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownValue--;
      if (_countdownValue <= 0) {
        timer.cancel();
        _startPlaying();
      }
      notifyListeners();
    });
  }

  void _startPlaying() {
    // 第5题（自定义）：出题者需要先设置答案
    if (currentQuestion != null && currentQuestion!.isCustom && currentQuestion!.answer.isEmpty) {
      if (_myRole == GameRole.describer) {
        _waitingForCustomAnswer = true;
        _phase = GamePhase.playing;
        notifyListeners();
        return;
      }
    }

    _phase = GamePhase.playing;
    _questionTimer = 120;
    _hintRequestedThisQuestion = false;
    _waitingForHintSelection = false;
    _currentHint = null;
    notifyListeners();

    _addSystemMessage('第 ${_currentQuestionIndex + 1} 题开始！');

    _questionTimerRef?.cancel();
    _questionTimerRef = Timer.periodic(const Duration(seconds: 1), (timer) {
      _questionTimer--;
      if (_questionTimer <= 0) {
        timer.cancel();
        _onQuestionTimeout();
      }
      notifyListeners();
    });
  }

  // ===== 游戏操作（真实IM发送） =====

  /// 出题者发送描述
  Future<void> sendDescription(String description) async {
    if (description.trim().isEmpty) return;

    // 检查描述中是否包含答案
    if (currentQuestion != null) {
      for (final char in currentQuestion!.answerChars) {
        if (description.contains(char)) {
          _addSystemMessage('⚠️ 描述中不能包含答案的任一字！');
          notifyListeners();
          return;
        }
      }
    }

    // 先添加本地消息
    _messages.add(GameChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _imService.myIMUserID,
      senderName: _imService.myNickname,
      senderAvatar: _imService.myAvatar,
      content: description,
      time: DateTime.now(),
      isSelf: true,
      type: GameChatMessageType.text,
    ));
    notifyListeners();

    // 通过IM发送
    await _imService.sendGameTextMessage(description);
  }

  /// 猜题者提交答案
  Future<void> submitAnswer(String answer) async {
    if (answer.trim().isEmpty || currentQuestion == null) return;

    // 添加本地答案消息
    _messages.add(GameChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _imService.myIMUserID,
      senderName: _imService.myNickname,
      senderAvatar: _imService.myAvatar,
      content: answer,
      time: DateTime.now(),
      isSelf: true,
      type: GameChatMessageType.answer,
    ));

    // 通过IM发送答案
    await _imService.sendAnswerMessage(answer);

    // 检查答案（猜题者不知道答案，由出题者端判断）
    // 这里暂时本地判断（后续可改为出题者端判断）
    final isCorrect = answer.trim() == currentQuestion!.answer;
    if (isCorrect) {
      _questions[_currentQuestionIndex] = currentQuestion!.copyWith(
        status: QuestionStatus.correct,
      );
      _correctCount++;
      _totalScore += 10;
      _addSystemMessage('🎉 回答正确！答案是「${currentQuestion!.answer}」');
      _questionTimerRef?.cancel();

      Future.delayed(const Duration(seconds: 2), () {
        _nextQuestion();
      });
    }
    notifyListeners();
  }

  /// 使用特权：+30秒
  Future<void> usePrivilegeAddTime() async {
    if (_privilegeCount <= 0) return;
    _privilegeCount--;
    _questionTimer += 30;
    _addSystemMessage('⏰ 使用特权：+30秒');
    notifyListeners();

    await _imService.sendPrivilegeUse('add_time');
  }

  /// 使用特权：跳过这道题
  Future<void> usePrivilegeSkip() async {
    if (_privilegeCount <= 0) return;
    _privilegeCount--;
    _questions[_currentQuestionIndex] = currentQuestion!.copyWith(
      status: QuestionStatus.skipped,
    );
    _addSystemMessage('使用特权：跳过本题');
    _questionTimerRef?.cancel();
    notifyListeners();

    await _imService.sendPrivilegeUse('skip');

    Future.delayed(const Duration(seconds: 1), () {
      _nextQuestion();
    });
  }

  /// 请求提示（猜题者发起，通过IM发送）
  Future<void> requestHint() async {
    if (_hintRequestedThisQuestion) return;
    _hintRequestedThisQuestion = true;
    _hintRequestCount++;

    // 添加本地消息
    _messages.add(GameChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _imService.myIMUserID,
      senderName: _imService.myNickname,
      senderAvatar: _imService.myAvatar,
      content: '请求提示',
      time: DateTime.now(),
      isSelf: true,
      type: GameChatMessageType.hintRequest,
    ));
    notifyListeners();

    // 通过IM发送提示请求
    await _imService.sendHintRequest();
  }

  /// 出题者选择提示字发送给猜题者（通过IM发送）
  Future<void> sendHintChar(int charIndex) async {
    if (currentQuestion == null) return;
    if (charIndex < 0 || charIndex >= currentQuestion!.answerChars.length) return;

    final hintChar = currentQuestion!.answerChars[charIndex];
    _currentHint = hintChar;
    _waitingForHintSelection = false;

    // 添加本地消息
    _messages.add(GameChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _imService.myIMUserID,
      senderName: _imService.myNickname,
      senderAvatar: _imService.myAvatar,
      content: '提示：$hintChar',
      time: DateTime.now(),
      isSelf: true,
      type: GameChatMessageType.hintResponse,
    ));
    notifyListeners();

    // 通过IM发送
    await _imService.sendHintResponse(hintChar);
  }

  // ===== 接收对方消息（IM回调） =====

  void _onGameMessageReceived(Map<String, dynamic> data, String senderID) {
    final type = data['type'] as String? ?? '';
    final senderName = data['senderName'] as String? ?? '对方';
    final senderAvatar = data['senderAvatar'] as String? ?? '';

    switch (type) {
      case 'game_text':
        final content = data['content'] as String? ?? '';
        _messages.add(GameChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          senderId: senderID,
          senderName: senderName,
          senderAvatar: senderAvatar,
          content: content,
          time: DateTime.now(),
          isSelf: false,
          type: GameChatMessageType.text,
        ));
        notifyListeners();
        break;

      case 'game_answer':
        final content = data['content'] as String? ?? '';
        _messages.add(GameChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          senderId: senderID,
          senderName: senderName,
          senderAvatar: senderAvatar,
          content: content,
          time: DateTime.now(),
          isSelf: false,
          type: GameChatMessageType.answer,
        ));
        // 出题者端判断答案是否正确
        if (_myRole == GameRole.describer && currentQuestion != null) {
          final isCorrect = content.trim() == currentQuestion!.answer;
          if (isCorrect) {
            _questions[_currentQuestionIndex] = currentQuestion!.copyWith(
              status: QuestionStatus.correct,
            );
            _correctCount++;
            _totalScore += 10;
            _addSystemMessage('🎉 回答正确！答案是「${currentQuestion!.answer}」');
            _questionTimerRef?.cancel();
            Future.delayed(const Duration(seconds: 2), () {
              _nextQuestion();
            });
          }
        }
        notifyListeners();
        break;

      case 'game_hint_request':
        _hintRequestedThisQuestion = true;
        // 出题者端：显示提示请求 + 答案拆字选择器
        if (_myRole == GameRole.describer) {
          _waitingForHintSelection = true;
        }
        _messages.add(GameChatMessage(
          id: 'msg_hint_req_${DateTime.now().millisecondsSinceEpoch}',
          senderId: senderID,
          senderName: senderName,
          senderAvatar: senderAvatar,
          content: '请求提示',
          time: DateTime.now(),
          isSelf: false,
          type: GameChatMessageType.hintRequest,
        ));
        notifyListeners();
        break;

      case 'game_hint_response':
        final hintChar = data['hintChar'] as String? ?? '';
        _currentHint = hintChar;
        _messages.add(GameChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          senderId: senderID,
          senderName: senderName,
          senderAvatar: senderAvatar,
          content: '提示：$hintChar',
          time: DateTime.now(),
          isSelf: false,
          type: GameChatMessageType.hintResponse,
        ));
        notifyListeners();
        break;

      case 'game_privilege':
        final privType = data['privilegeType'] as String? ?? '';
        if (privType == 'add_time') {
          _questionTimer += 30;
          _addSystemMessage('⏰ 对方使用特权：+30秒');
        } else if (privType == 'skip') {
          if (currentQuestion != null) {
            _questions[_currentQuestionIndex] = currentQuestion!.copyWith(
              status: QuestionStatus.skipped,
            );
          }
          _addSystemMessage('对方使用特权：跳过本题');
          _questionTimerRef?.cancel();
          Future.delayed(const Duration(seconds: 1), () {
            _nextQuestion();
          });
        }
        notifyListeners();
        break;

      case 'game_custom_answer':
        final answer = data['answer'] as String? ?? '';
        if (answer.isNotEmpty) {
          final idx = _questions.indexWhere((q) => q.isCustom && q.answer.isEmpty);
          if (idx >= 0) {
            _questions[idx] = _questions[idx].copyWith(answer: answer);
          }
          // 猜题者端也开始倒计时
          if (_myRole == GameRole.guesser) {
            _waitingForCustomAnswer = false;
            _startPlaying();
          }
        }
        notifyListeners();
        break;

      case 'game_partner_joined':
        // 房主端：对方已加入房间
        if (_isHost) {
          onPartnerJoined();
        }
        break;

      case 'game_start':
        // 被邀请方收到游戏开始信号：同步题目并进入游戏
        if (!_isHost) {
          _gameStarted = true;
          final questionsData = data['questions'] as List<dynamic>?;
          if (questionsData != null) {
            _questions.clear();
            for (final q in questionsData) {
              final map = q as Map<String, dynamic>;
              _questions.add(GameQuestion(
                index: (map['index'] as int?) ?? 0,
                answer: (map['answer'] as String?) ?? '',
                category: map['category'] as String?,
                isCustom: (map['isCustom'] as bool?) ?? false,
              ));
            }
          }
          _currentQuestionIndex = 0;
          _correctCount = 0;
          _totalScore = 0;
          _privilegeCount = 1;
          _hintRequestCount = 0;
          _messages.clear();
        }
        notifyListeners();
        break;

      case 'game_role_select':
        // 被邀请方收到对方角色选择：设置自己的角色并开始倒计时
        if (!_isHost) {
          final roleStr = data['role'] as String?;
          // 对方选的角色，自己反过来
          if (roleStr == 'describer') {
            _myRole = GameRole.guesser;
          } else {
            _myRole = GameRole.describer;
          }
          _room = _room?.copyWith(
            host: _room!.host.copyWith(
              role: roleStr == 'describer' ? GameRole.describer : GameRole.guesser,
            ),
            guest: _room!.guest?.copyWith(role: _myRole),
          );
          // 进入倒计时
          _startCountdown();
        }
        notifyListeners();
        break;

      case 'game_exit':
        // 对方退出了房间，重置状态
        _handlePartnerExit();
        break;

      case 'game_end':
        _endGame();
        break;
    }
  }

  // ===== 内部逻辑 =====

  void _onQuestionTimeout() {
    if (currentQuestion == null) return;
    _questions[_currentQuestionIndex] = currentQuestion!.copyWith(
      status: QuestionStatus.timeout,
    );
    _addSystemMessage('⏱️ 时间到！答案是「${currentQuestion!.answer}」');
    notifyListeners();

    Future.delayed(const Duration(seconds: 2), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex >= 4) {
      _endGame();
      return;
    }
    _currentQuestionIndex++;
    if (currentQuestion != null && currentQuestion!.isCustom && currentQuestion!.answer.isEmpty) {
      _startPlaying();
    } else {
      _startCountdown();
    }
  }

  void _endGame() {
    _questionTimerRef?.cancel();
    _countdownTimer?.cancel();
    _phase = GamePhase.gameResult;
    _imService.sendGameEnd();
    notifyListeners();
  }

  void _addSystemMessage(String content) {
    _messages.add(GameChatMessage(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'system',
      senderName: '系统',
      content: content,
      time: DateTime.now(),
      isSelf: false,
      type: GameChatMessageType.system,
    ));
  }

  /// 手动注入邀请消息到ChatController，使发送后立即在聊天页面显示
  void _injectInviteMessageToChat(String groupID) {
    try {
      if (Get.isRegistered<ChatController>()) {
        final chatCtrl = Get.find<ChatController>();
        final chatMsg = ChatMessage(
          id: 'say_guess_${DateTime.now().millisecondsSinceEpoch}',
          content: '已向对方发起你说我猜挑战，等待对方加入~',
          type: MessageType.sayGuess,
          isSent: true,
          time: DateTime.now(),
          avatarUrl: UserManager.userAvatar,
          groupId: groupID,
        );
        chatCtrl.messages.add(chatMsg);
        chatCtrl.messages.refresh();
      }
    } catch (_) {
      // ChatController可能未注册，忽略
    }
  }

  void _resetGameData() {
    _questions.clear();
    _currentQuestionIndex = 0;
    _correctCount = 0;
    _totalScore = 0;
    _privilegeCount = 1;
    _hintRequestCount = 0;
    _hintRequestedThisQuestion = false;
    _currentHint = null;
    _messages.clear();
    _countdownValue = 3;
    _questionTimer = 120;
    _waitingForHintSelection = false;
    _waitingForCustomAnswer = false;
    _myRole = null;
  }

  /// 重新开始（回到大厅）
  void restartGame() {
    _resetGameData();
    _gameStarted = false;
    _phase = GamePhase.lobby;
    notifyListeners();
  }

  /// 对方退出处理
  void _handlePartnerExit() {
    _countdownTimer?.cancel();
    _questionTimerRef?.cancel();
    _resetGameData();
    _inviteSent = false;
    _partnerJoined = false;
    _gameStarted = false;
    _room = null;
    _phase = GamePhase.lobby;

    // 清理群聊（不再发送消息，直接解散/退出）
    if (_imService.groupID != null) {
      if (_isHost) {
        _imService.dismissGameGroup();
      } else {
        _imService.quitGameGroup();
      }
    }

    notifyListeners();
    // 通知页面对方已退出
    onPartnerExited?.call();
  }

  /// 退出游戏（主动退出）
  Future<void> exitGame() async {
    _countdownTimer?.cancel();
    _questionTimerRef?.cancel();

    // 有群聊时，先通知对方自己要退出，再解散/退出
    if (_imService.groupID != null) {
      await _imService.sendExitMessage();
      // 等待短暂时间确保消息发送成功
      await Future.delayed(const Duration(milliseconds: 300));
      if (_isHost) {
        await _imService.dismissGameGroup();
      } else {
        await _imService.quitGameGroup();
      }
    }

    _resetGameData();
    _inviteSent = false;
    _partnerJoined = false;
    _gameStarted = false;
    _room = null;
    _phase = GamePhase.lobby;
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _questionTimerRef?.cancel();
    _imService.dispose();
    super.dispose();
  }
}
