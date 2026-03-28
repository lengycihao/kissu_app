import 'dart:math';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import '../models/game_models.dart';
import '../services/game_im_service.dart';
import 'game_home_controller.dart';

/// 选题页面控制器
class TopicSelectionController extends GetxController {
  final GameIMServiceV2 imService = GameIMServiceV2();

  // 候选题目池（后期从接口获取）
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

  /// 题库（后期走接口，现在本地）
  static final List<Map<String, String>> _questionBank = [
    {'answer': '西瓜', 'description': '一种绿皮红瓤的水果'},
    {'answer': '熊猫', 'description': '中国的国宝动物'},
    {'answer': '钢琴', 'description': '黑白键的乐器'},
    {'answer': '长城', 'description': '中国古代的防御建筑'},
    {'answer': '月亮', 'description': '夜晚天空最亮的天体'},
    {'answer': '筷子', 'description': '中国人吃饭用的餐具'},
    {'answer': '蝴蝶', 'description': '会飞的美丽昆虫'},
    {'answer': '篮球', 'description': '一项投篮运动'},
    {'answer': '冰淇淋', 'description': '夏天最爱的冷饮甜品'},
    {'answer': '彩虹', 'description': '雨后天空的七色弧'},
    {'answer': '口红', 'description': '女生常用的化妆品'},
    {'answer': '拥抱', 'description': '一种表达爱意的动作'},
    {'answer': '初恋', 'description': '人生第一次恋爱'},
    {'answer': '日出', 'description': '太阳从地平线升起'},
    {'answer': '棉花糖', 'description': '蓬松甜蜜的小零食'},
    {'answer': '摩天轮', 'description': '游乐场的大转盘'},
    {'answer': '水晶球', 'description': '透明的球形装饰品'},
    {'answer': '路飞', 'description': '海贼王的主角'},
    {'answer': '雾淞', 'description': '冬天树枝上的冰晶'},
    {'answer': '薰衣草', 'description': '紫色的芳香植物'},
    {'answer': '线条小狗', 'description': '一种简笔画风格的卡通狗'},
    {'answer': '绿洲', 'description': '沙漠中的水源地'},
    {'answer': '奶茶鼠', 'description': '一种可爱的奶茶色仓鼠'},
  ];

  @override
  void onInit() {
    super.onInit();
    _loadCandidates();
  }

  void _loadCandidates() {
    isLoading.value = true;
    // 打乱顺序
    final shuffled = List<Map<String, String>>.from(_questionBank)..shuffle(Random());
    candidates.value = shuffled
        .map((q) => CandidateTopic(
              answer: q['answer']!,
              description: q['description'] ?? '',
            ))
        .toList();
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

  /// 下一步：创建群聊 + 发送邀请 + 进入游戏页面
  Future<void> onNextStep() async {
    if (!canProceed) {
      OKToastUtil.showError('请选择${maxSelectCount}个题目');
      return;
    }

    isSending.value = true;
    try {
      // 1. 创建群聊
      final groupId = await imService.createGameGroup();
      if (groupId == null) {
        OKToastUtil.showError('创建游戏房间失败，请检查网络');
        return;
      }

      // 2. 发送邀请消息到聊天页面
      final sent = await imService.sendInviteMessage();
      if (!sent) {
        OKToastUtil.showError('发送邀请失败');
        return;
      }

      // 3. 注入邀请消息到聊天页面
      _injectInviteToChat(groupId);

      // 4. 添加记录到首页
      _addGameRecord(groupId);

      // 5. 标记游戏已启动（必须在 Get.offNamed 之前设置，防止 onClose 误删群）
      _gameStarted = true;

      // 6. 构建题目列表
      final topics = selectedTopics.map((t) => GameTopic(
            answer: t.answer,
            description: t.description,
            isCustom: customTopics.contains(t),
          )).toList();

      // 7. 跳转到游戏页面（替换当前页面）
      // 注意：不再在这里发送 senderJoined，由 GamePlayController._setupIM 负责
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

  void _injectInviteToChat(String groupId) {
    try {
      // 参考老版本的注入逻辑
      if (Get.isRegistered<dynamic>(tag: 'ChatController')) {
        // 如果 ChatController 已注册，注入消息
      }
    } catch (_) {}
  }

  void _addGameRecord(String groupId) {
    try {
      if (Get.isRegistered<GameHomeController>()) {
        final homeCtrl = Get.find<GameHomeController>();
        homeCtrl.addRecord(GameRecord(
          id: groupId,
          groupId: groupId,
          initiator: imService.myNickname,
          initiatorId: imService.myIMUserID,
          createTime: DateTime.now(),
          status: GameRecordStatus.ongoing,
          isMeInitiator: true,
        ));
      }
    } catch (_) {}
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
