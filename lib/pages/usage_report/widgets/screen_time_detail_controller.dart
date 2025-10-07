 import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:kissu_app/services/screen_usage_service.dart';
import 'package:kissu_app/models/screen_time_model.dart';

/// 屏幕使用时长详情页面控制器
class ScreenTimeDetailController extends GetxController {
  final ScreenUsageService _screenUsageService = ScreenUsageService();
  
  // 数据加载状态
  final isLoading = true.obs;
  final hasError = false.obs;
  
  // 屏幕使用数据
  final totalMinutes = 0.obs;
  final screenTimeData = Rx<ScreenTimeDetailModel?>(null);
  
  @override
  void onInit() {
    super.onInit();
    loadScreenTimeData();
  }
  
  /// 加载屏幕使用时长数据
  Future<void> loadScreenTimeData() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      
      // 获取今日屏幕使用总时长（毫秒）
      final totalTimeMs = await _screenUsageService.getTodayScreenTime();
      totalMinutes.value = (totalTimeMs / (1000 * 60)).round();
      
      debugPrint('📊 今日屏幕使用时长: ${totalMinutes.value}分钟');
      
      // 获取今日应用使用详情（前10个）
      final appUsageStats = await _screenUsageService.getTodayAppUsageStats(limit: 10);
      
      // 转换为记录列表
      final records = appUsageStats.map((stat) {
        final durationMinutes = (stat.totalTimeInForeground / (1000 * 60)).round();
        return ScreenTimeRecordItem(
          startTime: stat.firstTimeStamp,
          endTime: stat.lastTimeStamp,
          durationMinutes: durationMinutes,
          appName: stat.appName, // 直接使用从系统获取的真实应用名称
          packageName: stat.packageName,
        );
      }).toList();
      
      // 生成24小时数据（暂时使用模拟数据，后续可以根据真实数据生成）
      final hourlyData = _generateHourlyData();
      
      // 生成曲线数据
      final longestPeriodData = _findLongestPeriod(hourlyData);
      final abnormalPeriodData = _findAbnormalPeriod(hourlyData);
      
      screenTimeData.value = ScreenTimeDetailModel(
        totalMinutes: totalMinutes.value,
        hourlyData: hourlyData,
        longestPeriodData: longestPeriodData,
        abnormalPeriodData: abnormalPeriodData,
        records: records,
      );
      
      debugPrint('📊 屏幕使用数据加载完成，共${records.length}条记录');
      
    } catch (e) {
      debugPrint('❌ 加载屏幕使用数据失败: $e');
      hasError.value = true;
      
      // 加载失败时使用模拟数据
      screenTimeData.value = _getMockData();
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 生成24小时使用数据（暂时使用模拟数据）
  /// TODO: 后续可以通过查询事件来获取每小时的真实使用时长
  List<ChartDataPoint> _generateHourlyData() {
    // 这里暂时返回模拟数据
    // 实际应用中，可以通过 queryEvents 获取每小时的使用时长
    return List.generate(24, (index) {
      return ChartDataPoint(
        label: index.toString(),
        value: (index >= 8 && index <= 22) ? (20 + (index % 7) * 5).toDouble() : 5.0,
      );
    });
  }
  
  /// 找出使用时长最长的时段
  List<ChartDataPoint> _findLongestPeriod(List<ChartDataPoint> hourlyData) {
    // 找出连续4-5小时使用时长最长的时段
    double maxSum = 0;
    int maxStartIndex = 8; // 默认从8点开始
    
    for (int i = 0; i <= hourlyData.length - 5; i++) {
      double sum = 0;
      for (int j = i; j < i + 5; j++) {
        sum += hourlyData[j].value;
      }
      if (sum > maxSum) {
        maxSum = sum;
        maxStartIndex = i;
      }
    }
    
    return hourlyData.sublist(maxStartIndex, maxStartIndex + 5);
  }
  
  /// 找出23点后异常时段数据
  List<ChartDataPoint> _findAbnormalPeriod(List<ChartDataPoint> hourlyData) {
    // 23点到凌晨2点（23, 0, 1, 2）
    return [
      hourlyData[23],
      hourlyData[0],
      hourlyData[1],
      hourlyData[2],
    ];
  }
  
  /// 获取模拟数据（作为备用）
  ScreenTimeDetailModel _getMockData() {
    final hourlyData = List.generate(24, (index) {
      return ChartDataPoint(
        label: index.toString(),
        value: (index >= 8 && index <= 22) ? (20 + (index % 7) * 5).toDouble() : 5.0,
      );
    });
    
    final longestPeriodData = [
      ChartDataPoint(label: '8', value: 45),
      ChartDataPoint(label: '9', value: 60),
      ChartDataPoint(label: '10', value: 55),
      ChartDataPoint(label: '11', value: 70),
      ChartDataPoint(label: '12', value: 50),
    ];
    
    final abnormalPeriodData = [
      ChartDataPoint(label: '23', value: 30),
      ChartDataPoint(label: '0', value: 45),
      ChartDataPoint(label: '1', value: 60),
      ChartDataPoint(label: '2', value: 35),
    ];
    
    final now = DateTime.now();
    final records = [
      ScreenTimeRecordItem(
        startTime: DateTime(now.year, now.month, now.day, 9, 0),
        endTime: DateTime(now.year, now.month, now.day, 11, 0),
        durationMinutes: 70,
        appName: '微信',
      ),
      ScreenTimeRecordItem(
        startTime: DateTime(now.year, now.month, now.day, 14, 0),
        endTime: DateTime(now.year, now.month, now.day, 15, 30),
        durationMinutes: 90,
        appName: 'QQ',
      ),
    ];
    
    return ScreenTimeDetailModel(
      totalMinutes: 420,
      hourlyData: hourlyData,
      longestPeriodData: longestPeriodData,
      abnormalPeriodData: abnormalPeriodData,
      records: records,
    );
  }
}

