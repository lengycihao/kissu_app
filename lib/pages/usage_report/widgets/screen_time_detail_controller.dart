 import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:kissu_app/services/screen_usage_service.dart';
import 'package:kissu_app/models/screen_time_model.dart';
import 'package:kissu_app/models/usage_record_api_model.dart';

/// 屏幕使用时长详情页面控制器
class ScreenTimeDetailController extends GetxController {
  final ScreenUsageService _screenUsageService = ScreenUsageService();
  
  // 数据加载状态
  final isLoading = true.obs;
  final hasError = false.obs;
  
  // 屏幕使用数据
  final totalMinutes = 0.obs;
  final screenTimeData = Rx<ScreenTimeDetailModel?>(null);
  final screenUsageGroups = <ScreenUsageGroup>[].obs;
  
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
      screenUsageGroups.value = []; // 暂时使用空数据，将在_generateChartDataFromAPI中处理
      
      debugPrint('📊 获取到 ${appUsageStats.length} 个应用使用数据');
      
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
      
      // 生成柱状图数据（使用API数据）
      final hourlyData = _generateChartDataFromAPI();
      
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
  
  
  /// 从API数据生成柱状图数据
  List<ChartDataPoint> _generateChartDataFromAPI() {
    // 生成12个2小时时间段的数据点
    final List<ChartDataPoint> chartData = [];
    
    // 如果有API数据，使用真实数据
    if (screenUsageGroups.isNotEmpty) {
      // 取前12个分组数据，如果不足12个则用模拟数据补充
      for (int i = 0; i < 12; i++) {
        if (i < screenUsageGroups.length) {
          final group = screenUsageGroups[i];
          
          // 生成detail信息，格式为 "hour点：duration"
          String detailInfo = '';
          if (group.detail.isNotEmpty) {
            final details = group.detail.map((d) => '${d.hour}点：${d.duration}').join('\n');
            detailInfo = details;
          } else {
            detailInfo = '${group.groupLabel}：${group.groupDuration}';
          }
          
          chartData.add(ChartDataPoint(
            label: group.groupLabel, // 保存group_label用于x轴位置
            value: group.groupDurationMinutes.toDouble(), // 使用group_duration
            detail: detailInfo, // 用于tooltip显示
          ));
        } else {
          // 补充模拟数据
          final startHour = i * 2;
          double value = 5.0;
          if (startHour >= 8 && startHour <= 22) {
            value = (20 + (i % 7) * 5).toDouble();
          } else if (startHour >= 6 && startHour <= 7) {
            value = 15.0;
          }
          chartData.add(ChartDataPoint(
            label: '$startHour-${startHour + 1}',
            value: value,
            detail: '${startHour}点：${value.toInt()}min',
          ));
        }
      }
    } else {
      // 没有API数据时，生成12个2小时时间段的模拟数据
      for (int i = 0; i < 12; i++) {
        final startHour = i * 2;
        final endHour = startHour + 1;
        final periodLabel = '$startHour-$endHour';
        
        // 模拟数据：白天时段使用时长较高
        double value = 5.0;
        if (startHour >= 8 && startHour <= 22) {
          value = (20 + (i % 7) * 5).toDouble();
        } else if (startHour >= 6 && startHour <= 7) {
          value = 15.0;
        }
        
        chartData.add(ChartDataPoint(
          label: periodLabel,
          value: value,
          detail: '${startHour}点：${value.toInt()}min',
        ));
      }
    }
    
    return chartData;
  }
  
  /// 找出使用时长最长的时段
  List<ChartDataPoint> _findLongestPeriod(List<ChartDataPoint> hourlyData) {
    // 找出连续2-3个时间段使用时长最长的时段
    double maxSum = 0;
    int maxStartIndex = 4; // 默认从8-9点开始（第4个时间段）
    
    for (int i = 0; i <= hourlyData.length - 3; i++) {
      double sum = 0;
      for (int j = i; j < i + 3; j++) {
        sum += hourlyData[j].value;
      }
      if (sum > maxSum) {
        maxSum = sum;
        maxStartIndex = i;
      }
    }
    
    return hourlyData.sublist(maxStartIndex, maxStartIndex + 3);
  }
  
  /// 找出23点后异常时段数据
  List<ChartDataPoint> _findAbnormalPeriod(List<ChartDataPoint> hourlyData) {
    // 22-23点、0-1点、2-3点（对应索引11, 0, 1）
    return [
      hourlyData[11], // 22-23点
      hourlyData[0],  // 0-1点
      hourlyData[1],  // 2-3点
    ];
  }
  
  /// 获取模拟数据（作为备用）
  ScreenTimeDetailModel _getMockData() {
    final hourlyData = List.generate(12, (index) {
      final startHour = index * 2;
      final endHour = startHour + 1;
      final periodLabel = '$startHour-$endHour';
      
      // 模拟数据：白天时段使用时长较高
      double value = 5.0;
      if (startHour >= 8 && startHour <= 22) {
        value = (20 + (index % 7) * 5).toDouble();
      } else if (startHour >= 6 && startHour <= 7) {
        value = 15.0;
      }
      
      return ChartDataPoint(
        label: periodLabel,
        value: value,
      );
    });
    
    final longestPeriodData = [
      ChartDataPoint(label: '8-9', value: 45),
      ChartDataPoint(label: '10-11', value: 60),
      ChartDataPoint(label: '12-13', value: 55),
    ];
    
    final abnormalPeriodData = [
      ChartDataPoint(label: '22-23', value: 30),
      ChartDataPoint(label: '0-1', value: 45),
      ChartDataPoint(label: '2-3', value: 60),
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

