import 'package:get/get.dart';
import 'package:kissu_app/network/public/usage_record_api.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'device_usage_page.dart';

/// 用机记录控制器
class DeviceUsageController extends GetxController {
  // 手机使用数据
  var screenUsageHours = 0.obs; // 屏幕使用时长（小时）
  var screenUsageMinutes = 0.obs; // 屏幕使用时长（分钟）
  var unlockCount = 0.obs; // 解锁次数
  var recentUsageMinutes = 0.obs; // 最近使用时长（分钟）

  // App使用数据
  var mostUsedApp = "".obs; // 打开次数最多的App
  var mostUsedAppCount = 0.obs; // 打开次数
  var mostUsedAppHours = 0.obs; // 最长使用App时长（小时）
  var mostUsedAppMinutes = 0.obs; // 最长使用App时长（分钟）
  var recentApp = "".obs; // 最近使用的App
  var recentAppTime = "".obs; // 最近使用时间

  // 敏感操作记录
  var sensitiveRecords = <SensitiveRecord>[].obs;

  // 数据加载状态
  var isLoading = false.obs;
  
  // 调试模式：显示空数据状态
  var isDebugEmptyMode = false.obs;

  final _usageRecordApi = UsageRecordApi();

  @override
  void onInit() {
    super.onInit();
    _loadMockData(); // 使用模拟数据
  }
  
  /// 切换调试模式
  void toggleDebugMode() {
    isDebugEmptyMode.value = !isDebugEmptyMode.value;
    
    if (isDebugEmptyMode.value) {
      // 进入空数据模式
      // 手机使用数据显示0值
      screenUsageHours.value = 0;
      screenUsageMinutes.value = 0;
      unlockCount.value = 0;
      recentUsageMinutes.value = 0;
      
      // App使用数据清空（显示空状态）
      mostUsedApp.value = "";
      mostUsedAppCount.value = 0;
      mostUsedAppHours.value = 0;
      mostUsedAppMinutes.value = 0;
      recentApp.value = "";
      recentAppTime.value = "";
      
      // 敏感操作记录清空
      sensitiveRecords.value = [];
    } else {
      // 恢复模拟数据
      _loadMockData();
    }
  }
  
  /// 加载模拟数据
  void _loadMockData() {
    // 手机使用数据
    screenUsageHours.value = 13;
    screenUsageMinutes.value = 12;
    unlockCount.value = 15;
    recentUsageMinutes.value = 3;
    
    // App使用数据
    mostUsedApp.value = "微信";
    mostUsedAppCount.value = 161;
    mostUsedAppHours.value = 3;
    mostUsedAppMinutes.value = 25;
    recentApp.value = "微博";
    recentAppTime.value = "11:19";
    
    // 敏感操作记录
    sensitiveRecords.value = [
      SensitiveRecord(
        iconPath: "assets/4.0/kissu4_new_use_wifi.webp",
        content: "对方更换了网络",
        time: "23:30",
        subtitle: "yuluo-5G",
      ),
      SensitiveRecord(
        iconPath: "assets/4.0/kissu4_new_use_4g.webp",
        content: "对方切换成了移动网络",
        time: "23:30",
        subtitle: "",
      ),
      SensitiveRecord(
        iconPath: "assets/4.0/kissu4_new_use_lock.webp",
        content: "对方解锁了手机",
        time: "23:30",
        subtitle: "",
      ),
    ];
  }

  /// 加载数据
  Future<void> _loadData() async {
    try {
      isLoading.value = true;

      // 检查是否已绑定
      final userInfo = UserManager.getUserBasicInfo();
      if (!userInfo['isBound']) {
        logDebug('用户未绑定，不加载数据', tag: 'DeviceUsage');
        return;
      }

      // 获取用机记录数据
      final result = await _usageRecordApi.getSensitiveRecord();
      
      if (result.isSuccess && result.data != null) {
        final data = result.data!;
        
        // 处理屏幕使用时长数据
        final screenTimeData = data.mobileScreenUsageDurationRecord;
        if (screenTimeData.number > 0 && screenTimeData.mobileScreenUsageDurationList.isNotEmpty) {
          // 计算总使用时长（分钟）
          int totalMinutes = 0;
          for (var group in screenTimeData.mobileScreenUsageDurationList) {
            totalMinutes += group.groupDurationMinutes;
          }
          
          // 转换为小时和分钟
          screenUsageHours.value = totalMinutes ~/ 60;
          screenUsageMinutes.value = totalMinutes % 60;
          
          // 获取最近使用时长（最后一条记录）
          if (screenTimeData.mobileScreenUsageDurationList.isNotEmpty) {
            final lastGroup = screenTimeData.mobileScreenUsageDurationList.last;
            recentUsageMinutes.value = lastGroup.groupDurationMinutes;
          }
        }

        // 处理解锁次数数据
        final unlockData = data.unlockMobileRecord;
        unlockCount.value = unlockData.number;

        // 处理敏感操作记录（最多3条）
        final sensitiveData = data.sensitiveRecord;
        final records = <SensitiveRecord>[];
        
        for (var i = 0; i < sensitiveData.data.length && i < 3; i++) {
          final record = sensitiveData.data[i];
          String iconPath;
          String content;
          
          // 根据事件类型选择图标
          switch (record.eventType) {
            case 9: // WiFi相关
              iconPath = "assets/4.0/kissu4_new_use_wifi.webp";
              content = record.content;
              break;
            case 10: // 4G相关
              iconPath = "assets/4.0/kissu4_new_use_4g.webp";
              content = record.content;
              break;
            case 16: // 锁屏相关
            case 17:
              iconPath = "assets/4.0/kissu4_new_use_lock.webp";
              content = record.content;
              break;
            default:
              iconPath = "assets/4.0/kissu4_new_use_lock.webp";
              content = record.content;
          }
          
          records.add(SensitiveRecord(
            iconPath: iconPath,
            content: content,
            time: record.createTime,
            subtitle: "",
          ));
        }
        
        sensitiveRecords.value = records;

        // TODO: 处理App使用数据（需要额外的API）
        // 目前使用模拟数据
        mostUsedApp.value = "微信";
        mostUsedAppCount.value = 161;
        recentApp.value = "微博";
        recentAppTime.value = "11:19";

        logInfo('用机记录数据加载成功', tag: 'DeviceUsage');
      } else {
        logWarning('用机记录数据加载失败: ${result.msg}', tag: 'DeviceUsage');
      }
    } catch (e, stackTrace) {
      logError('加载用机记录数据异常: $e', tag: 'DeviceUsage', error: e, stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新数据（供外部调用）
  Future<void> refreshData() async {
    await _loadData();
  }
}

