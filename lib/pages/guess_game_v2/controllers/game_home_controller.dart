import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/user_manager.dart';
import '../models/game_models.dart';

/// 你说我猜V2 首页控制器
/// 管理历史记录列表、得分、排名等
class GameHomeController extends GetxController {
  // 历史记录
  final records = <GameRecord>[].obs;
  final isLoading = false.obs;

  // 得分/排名（后续接口获取）
  final totalScore = 12.obs;
  final ranking = '10000+'.obs;

  // Tab切换：0=我发起的, 1=Ta发起的
  final selectedTab = 0.obs;

  final PageController pageController = PageController();

  String get myUserId =>
      UserManager.currentUser?.uniqueId ?? '';

  @override
  void onInit() {
    super.onInit();
    _loadRecords();
  }

  /// 切换 Tab
  void switchTab(int index) {
    selectedTab.value = index;
  }

  List<GameRecord> get myInitiatedRecords =>
      records.where((r) => r.isMeInitiator).toList();

  List<GameRecord> get taInitiatedRecords =>
      records.where((r) => !r.isMeInitiator).toList();

  /// 获取当前Tab下的记录
  List<GameRecord> get filteredRecords {
    if (selectedTab.value == 0) {
      return records.where((r) => r.isMeInitiator).toList();
    } else {
      return records.where((r) => !r.isMeInitiator).toList();
    }
  }

  /// 加载历史记录（TODO：后期接口）
  Future<void> _loadRecords() async {
    isLoading.value = true;
    try {
      // TODO: 调用接口获取历史记录
      // 暂时用空列表
      records.clear();
    } catch (e) {
      // ignore
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新数据
  Future<void> refreshData() async {
    await _loadRecords();
  }

  /// 添加一条记录（创建游戏后调用）
  void addRecord(GameRecord record) {
    records.insert(0, record);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
