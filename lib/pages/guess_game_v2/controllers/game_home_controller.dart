import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/user_manager.dart';
import '../models/game_models.dart';
import '../services/game_api_service.dart';

/// 你说我猜V2 首页控制器
/// 管理历史记录列表、得分、排名等
class GameHomeController extends GetxController {
  final _apiService = GameApiService();

  // 历史记录（分 Tab 存储）
  final myRecords = <GameRecord>[].obs;
  final taRecords = <GameRecord>[].obs;
  final isLoading = false.obs;

  // 分页
  int _currentPageMy = 1;
  int _currentPageTa = 1;
  final hasMoreMy = true.obs;
  final hasMoreTa = true.obs;
  final isLoadingMore = false.obs;

  // 得分/排名（接口获取）
  final totalScore = 0.obs;
  final ranking = '10000+'.obs;

  // 候选题目池（来自接口 answer_data，供选题页使用）
  final answerData = <CandidateTopic>[].obs;

  // Tab切换：0=我发起的, 1=Ta发起的
  final selectedTab = 0.obs;

  final PageController pageController = PageController();

  String get myUserId => UserManager.currentUser?.uniqueId ?? '';

  @override
  void onInit() {
    super.onInit();
    _loadMyRecords();
    _loadTaRecords();
  }

  /// 切换 Tab
  void switchTab(int index) {
    selectedTab.value = index;
  }

  List<GameRecord> get myInitiatedRecords => myRecords;
  List<GameRecord> get taInitiatedRecords => taRecords;

  /// 获取当前Tab下的记录
  List<GameRecord> get filteredRecords =>
      selectedTab.value == 0 ? myRecords : taRecords;

  /// 加载"我发起的"记录（is_oneself=1）
  Future<void> _loadMyRecords({bool isRefresh = true}) async {
    if (isRefresh) {
      _currentPageMy = 1;
      isLoading.value = true;
    }
    try {
      final result = await _apiService.getRecordList(
        isOneself: 1,
        page: _currentPageMy,
      );
      if (result != null) {
        if (isRefresh) {
          myRecords.value = result.records;
        } else {
          myRecords.addAll(result.records);
        }
        hasMoreMy.value = result.hasMore;
        // 排名和得分仅从我发起的接口中取
        ranking.value = result.ranking;
        totalScore.value = result.starNums;
        logger.debug('[游戏首页] 排名=${result.ranking}, 星星=${result.starNums}, 记录数=${result.records.length}', tag: 'GameHome');
        // 候选题目池
        if (result.answerData.isNotEmpty) {
          answerData.value = result.answerData;
        }
      }
    } catch (e) {
      // ignore
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载"Ta发起的"记录（is_oneself=0）
  Future<void> _loadTaRecords({bool isRefresh = true}) async {
    if (isRefresh) {
      _currentPageTa = 1;
    }
    try {
      final result = await _apiService.getRecordList(
        isOneself: 0,
        page: _currentPageTa,
      );
      if (result != null) {
        if (isRefresh) {
          taRecords.value = result.records;
        } else {
          taRecords.addAll(result.records);
        }
        hasMoreTa.value = result.hasMore;
      }
    } catch (e) {
      // ignore
    }
  }

  /// 下拉刷新
  Future<void> refreshData() async {
    await Future.wait([
      _loadMyRecords(isRefresh: true),
      _loadTaRecords(isRefresh: true),
    ]);
  }

  /// 上拉加载更多（当前Tab）
  Future<void> loadMore() async {
    if (isLoadingMore.value) return;
    isLoadingMore.value = true;
    try {
      if (selectedTab.value == 0 && hasMoreMy.value) {
        _currentPageMy++;
        await _loadMyRecords(isRefresh: false);
      } else if (selectedTab.value == 1 && hasMoreTa.value) {
        _currentPageTa++;
        await _loadTaRecords(isRefresh: false);
      }
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// 添加一条记录（发起游戏后本地插入，等刷新）
  void addRecord(GameRecord record) {
    if (record.isMeInitiator) {
      myRecords.insert(0, record);
    } else {
      taRecords.insert(0, record);
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
