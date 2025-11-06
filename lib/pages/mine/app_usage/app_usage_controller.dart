import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
import 'package:kissu_app/pages/mine/app_usage/models/app_usage_record.dart';
import 'package:kissu_app/pages/mine/app_usage/api/app_usage_api.dart';

/// App使用时长控制器
class AppUsageController extends GetxController {
  static const platform = MethodChannel('app_usage_channel');
  
  // 已安装应用列表
  var apps = <AppInfo>[].obs;
  
  // 筛选的应用包名列表（用于采集数据的应用）
  var selectedApps = <String>{}.obs;
  
  // 加载状态
  var isLoading = true.obs;
  
  // 上报状态
  var isReporting = false.obs;
  
  // 搜索关键词
  var searchKeyword = ''.obs;
  
  // 权限状态
  var hasUsagePermission = false.obs;
  
  // 选中的日期
  var selectedDate = DateTime.now().obs;
  
  // 是否显示日期选择器
  var showDatePicker = false.obs;
  
  // 使用记录数据
  var usageRecords = <AppUsageRecord>[].obs;
  
  // 是否显示次数（true）还是分钟数（false）
  var showUsageCount = true.obs;
  
  // 是否显示时间轴视图（false: 统计视图, true: 时间轴视图）
  var showTimeline = false.obs;
  
  // 时间轴视图中选中的App
  var selectedAppForTimeline = ''.obs;
  
  // 是否显示全部最近使用的App
  var showAllRecentApps = false.obs;
  
  // 最近使用的App列表
  List<AppUsageRecord> get recentlyUsedApps {
    final sorted = usageRecords.toList()
      ..sort((a, b) {
        if (showUsageCount.value) {
          return b.sessionCount.compareTo(a.sessionCount);
        } else {
          return b.totalDuration.compareTo(a.totalDuration);
        }
      });
    return sorted;
  }
  
  // 最大使用次数
  int get maxSessionCount {
    if (usageRecords.isEmpty) return 0;
    return usageRecords.map((e) => e.sessionCount).reduce((a, b) => a > b ? a : b);
  }
  
  // 最大使用时长（分钟）
  int get maxDuration {
    if (usageRecords.isEmpty) return 0;
    return usageRecords.map((e) => (e.totalDuration / 60000).round()).reduce((a, b) => a > b ? a : b);
  }
  
  // 过滤后的应用列表
  List<AppInfo> get filteredApps {
    if (searchKeyword.value.isEmpty) {
      return apps;
    }
    return apps.where((app) {
      return app.appName.toLowerCase().contains(searchKeyword.value.toLowerCase()) ||
             app.packageName.toLowerCase().contains(searchKeyword.value.toLowerCase());
    }).toList();
  }
  
  @override
  void onInit() {
    super.onInit();
    _loadData();
    _checkPermission();
    _loadUsageData();
  }
  
  /// 检查权限
  Future<void> _checkPermission() async {
    hasUsagePermission.value = await _hasUsagePermission();
  }
  
  /// 加载使用数据
  Future<void> _loadUsageData() async {
    try {
      // TODO: 这里应该从API或本地缓存加载真实数据
      // 暂时使用模拟数据来展示UI效果
      usageRecords.value = _generateMockData();
      
      // 正式版本应该检查权限
      // if (!await _hasUsagePermission()) {
      //   return;
      // }
    } catch (e) {
      logger.error('加载使用数据失败: $e', tag: 'AppUsage', error: e);
    }
  }
  
  /// 生成模拟数据（用于UI展示）
  List<AppUsageRecord> _generateMockData() {
    final now = DateTime.now();
    final targetDate = selectedDate.value;
    final dayDiff = now.difference(targetDate).inDays;
    
    // 倒数第二天（今天往前数第二天）：显示空数据
    if (dayDiff == 1) {
      return [];
    }
    
    // 倒数第三天：只显示3个App（少于5个）
    if (dayDiff == 2) {
      return _generateMockDataForApps(3, targetDate);
    }
    
    // 其他日期：显示7个App
    return _generateMockDataForApps(7, targetDate);
  }
  
  /// 为指定数量的App生成模拟数据
  List<AppUsageRecord> _generateMockDataForApps(int appCount, DateTime date) {
    final mockApps = [
      {'name': '微信', 'package': 'com.tencent.mm'},
      {'name': '王者荣耀', 'package': 'com.tencent.tmgp.sgame'},
      {'name': '抖音', 'package': 'com.ss.android.ugc.aweme'},
      {'name': 'Bilibili', 'package': 'tv.danmaku.bili'},
      {'name': '支付宝', 'package': 'com.eg.android.AlipayGphone'},
      {'name': '淘宝', 'package': 'com.taobao.taobao'},
      {'name': 'QQ', 'package': 'com.tencent.mobileqq'},
    ];
    
    final records = <AppUsageRecord>[];
    final selectedApps = mockApps.take(appCount).toList();
    final isToday = _isSameDay(date, DateTime.now());
    
    // 确定最大小时：今天显示到当前小时，历史日期显示完整24小时
    final maxHour = isToday ? DateTime.now().hour : 23;
    
    for (int i = 0; i < selectedApps.length; i++) {
      final app = selectedApps[i];
      final sessions = <AppUsageSession>[];
      final hourlyMap = <int, List<AppUsageSession>>{};
      
      // 根据日期和App生成不同的使用时间段
      final baseHour = 7 + (date.day % 3);  // 7-9点开始
      // 历史日期生成更多会话记录
      final sessionCount = isToday ? (5 + (i * 2)) : (8 + (i * 3) + (date.day % 5));
      
      for (int j = 0; j < sessionCount; j++) {
        // 更分散的时间分布
        int hour;
        if (isToday) {
          // 今天：从早上到现在
          hour = (baseHour + (j * 2)) % (maxHour + 1);
        } else {
          // 历史日期：分布在全天
          hour = (baseHour + (j * 2) + (date.day % 2)) % 24;
        }
        
        final minute = (j * 13 + date.day * 7 + i * 5) % 60;
        final openTime = DateTime(date.year, date.month, date.day, hour, minute);
        final duration = ((10 + (j * 5) + date.day * 2 + i * 3) % 50 + 5) * 60 * 1000; // 5-55分钟
        final closeTime = openTime.add(Duration(milliseconds: duration));
        
        final session = AppUsageSession(
          openTime: openTime.millisecondsSinceEpoch,
          closeTime: closeTime.millisecondsSinceEpoch,
        );
        sessions.add(session);
        
        if (!hourlyMap.containsKey(hour)) {
          hourlyMap[hour] = [];
        }
        hourlyMap[hour]!.add(session);
      }
      
      // 构建每小时记录
      final hourlyRecords = <HourlyUsageRecord>[];
      hourlyMap.forEach((hour, sessions) {
        final totalDuration = sessions.fold<int>(0, (sum, s) => sum + s.duration);
        hourlyRecords.add(HourlyUsageRecord(
          hour: hour,
          totalDuration: totalDuration,
          sessionCount: sessions.length,
          sessions: sessions,
        ));
      });
      
      hourlyRecords.sort((a, b) => a.hour.compareTo(b.hour));
      
      records.add(AppUsageRecord(
        appName: app['name']!,
        packageName: app['package']!,
        date: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        hourlyRecords: hourlyRecords,
        totalSessions: sessionCount,
      ));
    }
    
    return records;
  }
  
  /// 判断是否是同一天
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
  
  /// 切换日期选择器显示/隐藏
  void toggleDatePicker() {
    showDatePicker.value = !showDatePicker.value;
  }
  
  /// 选择日期
  void selectDate(DateTime date) {
    selectedDate.value = date;
    showDatePicker.value = false;
    _loadUsageData();  // 重新加载数据
  }
  
  /// 切换显示/隐藏全部最近使用的App
  void toggleShowAllRecentApps() {
    showAllRecentApps.value = !showAllRecentApps.value;
  }
  
  /// 选择时间轴视图中的App
  void selectAppForTimeline(String packageName) {
    if (selectedAppForTimeline.value == packageName) {
      selectedAppForTimeline.value = '';
    } else {
      selectedAppForTimeline.value = packageName;
    }
  }
  
  /// 加载数据
  Future<void> _loadData() async {
    isLoading.value = true;
    try {
      await _loadSelectedApps();
      await _loadInstalledApps();
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 加载已筛选的应用包名
  Future<void> _loadSelectedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('selected_apps_for_usage') ?? [];
      selectedApps.clear();
      selectedApps.addAll(list);
      logger.info('已加载筛选应用列表: ${selectedApps.length}个', tag: 'AppUsage');
    } catch (e) {
      logger.error('加载筛选应用列表失败: $e', tag: 'AppUsage', error: e);
    }
  }
  
  /// 加载已安装应用列表
  Future<void> _loadInstalledApps() async {
    try {
      logger.info('开始获取已安装应用列表（后台线程）', tag: 'AppUsage');
      
      // 🔧 添加超时保护（30秒超时）
      final List<dynamic> result = await platform
          .invokeMethod('getInstalledApps')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              logger.error('获取应用列表超时', tag: 'AppUsage');
              throw TimeoutException('获取应用列表超时，请重试');
            },
          );
      
      apps.value = result.map((e) {
        final map = Map<String, dynamic>.from(e);
        return AppInfo(
          appName: map['appName'] as String,
          packageName: map['packageName'] as String,
          icon: map['icon'] as Uint8List,
        );
      }).toList();
      
      logger.info('✅ 已获取 ${apps.length} 个用户应用', tag: 'AppUsage');
    } on TimeoutException catch (e) {
      logger.error('获取应用列表超时: $e', tag: 'AppUsage', error: e);
      Get.snackbar('提示', '获取应用列表超时，请稍后重试');
    } on PlatformException catch (e) {
      logger.error('获取应用列表失败: ${e.message}', tag: 'AppUsage', error: e);
      Get.snackbar('错误', '获取应用列表失败: ${e.message}');
    } catch (e) {
      logger.error('获取应用列表异常: $e', tag: 'AppUsage', error: e);
      Get.snackbar('错误', '获取应用列表失败');
    }
  }
  
  /// 切换筛选状态
  Future<void> toggleSelection(String packageName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (selectedApps.contains(packageName)) {
        selectedApps.remove(packageName);
        logger.info('取消筛选应用: $packageName', tag: 'AppUsage');
      } else {
        selectedApps.add(packageName);
        logger.info('筛选应用: $packageName', tag: 'AppUsage');
      }
      
      await prefs.setStringList('selected_apps_for_usage', selectedApps.toList());
    } catch (e) {
      logger.error('保存筛选状态失败: $e', tag: 'AppUsage', error: e);
      Get.snackbar('错误', '保存失败');
    }
  }
  
  /// 显示应用使用时长
  Future<void> showUsageTime(String packageName, String appName) async {
    try {
      logger.info('获取应用使用时长: $packageName', tag: 'AppUsage');
      final int millis = await platform.invokeMethod('getAppUsageTime', {'packageName': packageName});
      final duration = Duration(milliseconds: millis);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      
      Get.dialog(
        _buildUsageDialog(appName, hours, minutes),
        barrierDismissible: true,
      );
    } on PlatformException catch (e) {
      if (e.code == 'NO_PERMISSION') {
        _showPermissionDialog();
      } else {
        logger.error('获取使用时长失败: ${e.message}', tag: 'AppUsage', error: e);
        Get.snackbar('错误', '获取使用时长失败: ${e.message}');
      }
    } catch (e) {
      logger.error('获取使用时长异常: $e', tag: 'AppUsage', error: e);
      Get.snackbar('错误', '获取使用时长失败');
    }
  }
  
  /// 采集并上报使用数据
  Future<void> collectAndReportUsageData() async {
    if (selectedApps.isEmpty) {
      Get.snackbar('提示', '请先筛选需要采集的应用');
      return;
    }
    
    if (!await _hasUsagePermission()) {
      _showPermissionDialog();
      return;
    }
    
    isReporting.value = true;
    try {
      logger.info('开始采集 ${selectedApps.length} 个应用的使用数据', tag: 'AppUsage');
      
      // 批量获取详细使用数据
      final List<dynamic> result = await platform.invokeMethod(
        'getBatchDetailedUsageData',
        {'packageNames': selectedApps.toList()},
      );
      
      // 转换为AppUsageRecord列表
      final records = <AppUsageRecord>[];
      for (final data in result) {
        final map = _convertMap(data);
        
        // 只上报有使用记录的应用
        final hourlyRecords = (map['hourlyRecords'] as List<dynamic>)
            .map((e) => HourlyUsageRecord.fromJson(_convertMap(e)))
            .toList();
        
        if (hourlyRecords.isNotEmpty) {
          records.add(AppUsageRecord(
            appName: map['appName'] as String,
            packageName: map['packageName'] as String,
            iconBase64: map['iconBase64'] as String?,
            date: map['date'] as String,
            hourlyRecords: hourlyRecords,
          ));
        }
      }
      
      if (records.isEmpty) {
        logger.info('没有需要上报的使用记录', tag: 'AppUsage');
        Get.snackbar('提示', '暂无使用记录需要上报');
        return;
      }
      
      logger.info('准备上报 ${records.length} 个应用的使用记录', tag: 'AppUsage');
      
      // 上报数据
      final apiResult = await AppUsageApi.reportAppUsage(records);
      
      if (apiResult.isSuccess) {
        Get.snackbar(
          '成功',
          '已成功上报 ${records.length} 个应用的使用记录',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
        logger.info('使用记录上报成功: ${records.length}个应用', tag: 'AppUsage');
      } else {
        Get.snackbar('失败', apiResult.msg ?? '上报失败');
        logger.error('使用记录上报失败: ${apiResult.msg}', tag: 'AppUsage');
      }
    } on PlatformException catch (e) {
      logger.error('采集使用数据失败: ${e.message}', tag: 'AppUsage', error: e);
      Get.snackbar('错误', '采集使用数据失败: ${e.message}');
    } catch (e) {
      logger.error('采集并上报使用数据异常: $e', tag: 'AppUsage', error: e);
      Get.snackbar('错误', '操作失败: $e');
    } finally {
      isReporting.value = false;
    }
  }
  
  /// 获取单个应用的详细使用数据（用于查看）
  Future<AppUsageRecord?> getDetailedUsageData(String packageName) async {
    try {
      if (!await _hasUsagePermission()) {
        _showPermissionDialog();
        return null;
      }
      
      final Map<dynamic, dynamic> result = await platform.invokeMethod(
        'getDetailedUsageData',
        {'packageName': packageName},
      );
      
      final map = _convertMap(result);
      final hourlyRecords = (map['hourlyRecords'] as List<dynamic>)
          .map((e) => HourlyUsageRecord.fromJson(_convertMap(e)))
          .toList();
      
      return AppUsageRecord(
        appName: map['appName'] as String,
        packageName: map['packageName'] as String,
        iconBase64: map['iconBase64'] as String?,
        date: map['date'] as String,
        hourlyRecords: hourlyRecords,
      );
    } on PlatformException catch (e) {
      logger.error('获取详细使用数据失败: ${e.message}', tag: 'AppUsage', error: e);
      Get.snackbar('错误', '获取使用数据失败: ${e.message}');
      return null;
    } catch (e) {
      logger.error('获取详细使用数据异常: $e', tag: 'AppUsage', error: e);
      Get.snackbar('错误', '获取使用数据失败');
      return null;
    }
  }
  
  /// 递归转换Map类型（处理嵌套的Map和List）
  Map<String, dynamic> _convertMap(dynamic data) {
    if (data is Map) {
      return data.map((key, value) {
        if (value is Map) {
          return MapEntry(key.toString(), _convertMap(value));
        } else if (value is List) {
          return MapEntry(key.toString(), value.map((e) {
            if (e is Map) {
              return _convertMap(e);
            }
            return e;
          }).toList());
        }
        return MapEntry(key.toString(), value);
      });
    }
    return {};
  }
  
  /// 检查是否有使用权限
  Future<bool> _hasUsagePermission() async {
    try {
      // 尝试获取一个简单的使用数据来检测权限
      await platform.invokeMethod('getAppUsageTime', {'packageName': 'com.android.settings'});
      return true;
    } on PlatformException catch (e) {
      if (e.code == 'NO_PERMISSION') {
        return false;
      }
      return true; // 其他错误认为有权限
    } catch (e) {
      return true;
    }
  }
  
  /// 显示权限对话框
  void _showPermissionDialog() {
    Get.dialog(
      _buildPermissionDialog(),
      barrierDismissible: false,
    );
  }
  
  /// 打开使用情况访问设置
  Future<void> openUsageSettings() async {
    try {
      await platform.invokeMethod('openUsageSettings');
    } catch (e) {
      logger.error('打开使用情况设置失败: $e', tag: 'AppUsage', error: e);
    }
  }
  
  /// 构建使用时长对话框
  Widget _buildUsageDialog(String appName, int hours, int minutes) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(
        '$appName 使用时长',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '过去24小时使用时长',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$hours 小时 $minutes 分钟',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF839E),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text(
            '确定',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFFF839E),
            ),
          ),
        ),
      ],
    );
  }
  
  /// 构建权限对话框
  Widget _buildPermissionDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: const Text(
        '需要授权',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: const Text(
        '查看应用使用时长需要开启"使用情况访问"权限\n\n请在设置页面找到 Kissu 并开启权限',
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text(
            '取消',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF999999),
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            openUsageSettings();
          },
          child: const Text(
            '去授权',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFFF839E),
            ),
          ),
        ),
      ],
    );
  }
  
  /// 刷新数据
  Future<void> onRefresh() async {
    await _loadData();
  }
}

/// 应用信息模型
class AppInfo {
  final String appName;
  final String packageName;
  final Uint8List icon;
  
  AppInfo({
    required this.appName,
    required this.packageName,
    required this.icon,
  });
}
