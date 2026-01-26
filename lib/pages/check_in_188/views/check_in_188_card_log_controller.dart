import 'package:get/get.dart';

/// 补签卡日志页面控制器
class CheckIn188CardLogController extends GetxController {
  /// 当前选中的Tab索引 (0: 获得记录, 1: 补卡记录)
  final RxInt currentTabIndex = 0.obs;
  
  /// 导航栏透明度
  final RxDouble navBarOpacity = 0.0.obs;
  
  /// 获得记录列表
  final RxList<CardObtainRecord> obtainRecords = <CardObtainRecord>[].obs;
  
  /// 补卡记录列表
  final RxList<CardUseRecord> useRecords = <CardUseRecord>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    _initMockData();
  }
  
  /// 初始化模拟数据
  void _initMockData() {
    // 模拟获得记录
    obtainRecords.value = [
      CardObtainRecord(
        title: '邀请好友获得补签卡',
        count: 1,
        time: '2025-08-14 15:44:37',
        description: '活动1：邀请灯友通过你的专属链接完成下载注册并绑定情侣关系，且连续登录App满3天，即可获得1张补签卡。',
      ),
      CardObtainRecord(
        title: '邀请好友获得补签卡',
        count: 1,
        time: '2025-08-14 15:44:37',
        description: '活动1：邀请灯友通过你的专属链接完成下载注册并绑定情侣关系，且连续登录App满3天，即可获得1张补签卡。',
      ),
      CardObtainRecord(
        title: '购买补签卡',
        count: 3,
        time: '2025-08-14 15:44:37',
        description: '可乐购买了 3张补签卡 花费为:73.00',
      ),
    ];
    
    // 模拟补卡记录
    useRecords.value = [
      CardUseRecord(
        date: '7/12',
        count: 10,
        userName: '可乐',
        time: '2025-08-14 15:44:37',
      ),
      CardUseRecord(
        date: '7/12',
        count: 10,
        userName: '可乐',
        time: '2025-08-14 15:44:37',
      ),
    ];
  }
  
  /// 切换Tab
  void switchTab(int index) {
    currentTabIndex.value = index;
  }
  
  /// 更新导航栏透明度
  void updateNavBarOpacity(double offset) {
    // 根据滚动偏移量计算透明度，0-100px范围内从0到1
    final opacity = (offset / 100).clamp(0.0, 1.0);
    navBarOpacity.value = opacity;
  }
  
  /// 返回上一页
  void goBack() {
    Get.back();
  }
}

/// 补签卡获得记录
class CardObtainRecord {
  final String title; // 标题
  final int count; // 数量
  final String time; // 时间
  final String description; // 描述
  
  CardObtainRecord({
    required this.title,
    required this.count,
    required this.time,
    required this.description,
  });
}

/// 补签卡使用记录
class CardUseRecord {
  final String date; // 补签日期
  final int count; // 数量
  final String userName; // 使用者名称
  final String time; // 时间
  
  CardUseRecord({
    required this.date,
    required this.count,
    required this.userName,
    required this.time,
  });
}
