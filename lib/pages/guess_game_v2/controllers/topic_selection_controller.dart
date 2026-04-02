import 'dart:math';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import '../models/game_models.dart';
import '../services/game_api_service.dart';
import '../services/game_im_service.dart';
import 'game_home_controller.dart';

/// 选题页面控制器
class TopicSelectionController extends GetxController {
  final GameIMServiceV2 imService = GameIMServiceV2();
  final GameApiService _apiService = GameApiService();

  // 候选题目池（从 GameHomeController.answerData 获取，来自接口）
  final candidates = <CandidateTopic>[].obs;

  // 已选题目（固定5个）
  final selectedTopics = <CandidateTopic>[].obs;

  // 自定义题目列表
  final customTopics = <CandidateTopic>[].obs;

  final isLoading = false.obs;
  final isSending = false.obs;
  bool _gameStarted = false; // 游戏已启动标记，防止onClose误删群

  static const int maxSelectCount = 5;

  int get selectedCount => selectedTopics.length;
  bool get canProceed => selectedCount == maxSelectCount;

  @override
  void onInit() {
    super.onInit();
    _loadCandidates();
  }

  void _loadCandidates() {
    isLoading.value = true;
    List<CandidateTopic> source = [];

    // 优先从 GameHomeController 获取接口返回的 answer_data
    if (Get.isRegistered<GameHomeController>()) {
      final homeCtrl = Get.find<GameHomeController>();
      if (homeCtrl.answerData.isNotEmpty) {
        source = List<CandidateTopic>.from(homeCtrl.answerData);
      }
    }

    if (source.isNotEmpty) {
      source.shuffle(Random());
      candidates.value = source
          .map((t) => CandidateTopic(answer: t.answer, description: t.description))
          .toList();
    }
    isLoading.value = false;
  }

  /// 切换选择状态
  void toggleSelect(int index) {
    final topic = candidates[index];
    if (topic.isSelected) {
      // 取消选择
      topic.isSelected = false;
      selectedTopics.removeWhere((t) => t.answer == topic.answer);
    } else {
      // 选择（不含自定义，先检查总数）
      if (selectedCount >= maxSelectCount) {
        OKToastUtil.showError('最多选择${maxSelectCount}个题目');
        return;
      }
      topic.isSelected = true;
      selectedTopics.add(topic);
    }
    candidates.refresh();
    selectedTopics.refresh();
  }

  /// 添加自定义题目
  void addCustomTopic(String answer, String description) {
    if (answer.trim().isEmpty) return;
    if (selectedCount >= maxSelectCount) {
      OKToastUtil.showError('最多选择${maxSelectCount}个题目');
      return;
    }

    // 检查描述中不能包含答案的任一字
    for (final char in answer.trim().split('')) {
      if (description.contains(char)) {
        OKToastUtil.showError('描述词不能包含答案任一个字');
        return;
      }
    }

    final topic = CandidateTopic(
      answer: answer.trim(),
      description: description.trim(),
      isSelected: true,
    );
    customTopics.add(topic);
    selectedTopics.add(topic);
  }

  /// 移除自定义题目
  void removeCustomTopic(int index) {
    if (index < 0 || index >= customTopics.length) return;
    final topic = customTopics[index];
    selectedTopics.removeWhere((t) => t.answer == topic.answer && t.description == topic.description);
    customTopics.removeAt(index);
  }

  /// 下一步：发起游戏（API） + 创建 TIM 群聊 + 发送邀请 + 进入游戏页面
  Future<void> onNextStep() async {
    if (!canProceed) {
      OKToastUtil.showError('请选择${maxSelectCount}个题目');
      return;
    }

    isSending.value = true;
    try {
      // 1. 调接口发起游戏，获取服务端生成的 group_id
      final groupId = await _apiService.launchGame(selectedTopics);
      if (groupId == null || groupId.isEmpty) {
        OKToastUtil.showError('创建游戏失败，请检查网络');
        return;
      }

      // 2. 设置群 ID（服务端已建群）并加入群聊监听
      imService.setGroupId(groupId);
      final joined = await imService.joinGameGroup(groupId);
      if (!joined) {
        OKToastUtil.showError('加入游戏房间失败，请检查网络');
        return;
      }

      // 3. 发送邀请消息到聊天页面
      final sent = await imService.sendInviteMessage();
      if (!sent) {
        OKToastUtil.showError('发送邀请失败');
        return;
      }

      // 4. 标记游戏已启动（必须在 Get.offNamed 之前设置，防止 onClose 误删群）
      _gameStarted = true;

      // 5. 构建题目列表
      final topics = selectedTopics.map((t) => GameTopic(
            answer: t.answer,
            description: t.description,
            isCustom: customTopics.contains(t),
          )).toList();

      // 8. 跳转到游戏页面（替换当前页面）
      Get.offNamed(KissuRoutePath.guessGameV2Play, arguments: {
        'groupId': groupId,
        'isInitiator': true,
        'topics': topics,
      });
    } catch (e) {
      OKToastUtil.showError('操作失败: $e');
    } finally {
      isSending.value = false;
    }
  }

  @override
  void onClose() {
    // 只有游戏未启动时才清理（用户中途退出选题页）
    if (imService.groupID != null && !_gameStarted) {
      imService.dismissGameGroup();
    }
    super.onClose();
  }
}
 