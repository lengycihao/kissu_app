import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/pages/mine/app_usage/models/app_usage_record.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';

/// 应用使用记录上报API
class AppUsageApi {
  /// 上报应用使用记录
  /// [records] 应用使用记录列表
  /// 返回上报结果
  static Future<HttpResultN<dynamic>> reportAppUsage(List<AppUsageRecord> records) async {
    try {
      final reportDate = DateTime.now().toString().split(' ')[0];
      final batchReport = AppUsageBatchReport(
        reportDate: reportDate,
        records: records,
      );
      
      logger.info('准备上报应用使用记录: ${records.length}个应用', tag: 'AppUsageApi');
      
      final result = await HttpManagerN.instance.executePost(
        '/app-usage/report',
        jsonParam: batchReport.toJson(),
        isShowLoadingDialog: true,
      );
      
      if (result.isSuccess) {
        logger.info('应用使用记录上报成功', tag: 'AppUsageApi');
      } else {
        logger.error('应用使用记录上报失败: ${result.msg}', tag: 'AppUsageApi');
      }
      
      return result;
    } catch (e) {
      logger.error('上报应用使用记录异常: $e', tag: 'AppUsageApi', error: e);
      return HttpResultN<dynamic>(
        isSuccess: false,
        code: -1,
        msg: '上报失败: $e',
      );
    }
  }
  
  /// 上报单个应用的使用记录
  /// [record] 单个应用使用记录
  static Future<HttpResultN<dynamic>> reportSingleAppUsage(AppUsageRecord record) async {
    return reportAppUsage([record]);
  }
  
  /// 获取应用使用记录历史
  /// [startDate] 开始日期 yyyy-MM-dd
  /// [endDate] 结束日期 yyyy-MM-dd
  static Future<HttpResultN<List<AppUsageRecord>>> getUsageHistory({
    required String startDate,
    required String endDate,
  }) async {
    try {
      logger.info('获取使用记录历史: $startDate ~ $endDate', tag: 'AppUsageApi');
      
      final result = await HttpManagerN.instance.executeGet(
        '/app-usage/history',
        queryParam: {
          'startDate': startDate,
          'endDate': endDate,
        },
      );
      
      if (result.isSuccess) {
        final data = result.getDataJson();
        final records = (data['records'] as List<dynamic>)
            .map((e) => AppUsageRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        
        logger.info('获取使用记录成功: ${records.length}条', tag: 'AppUsageApi');
        
        return HttpResultN<List<AppUsageRecord>>(
          isSuccess: true,
          code: result.code,
          msg: result.msg,
          data: records,
        );
      } else {
        logger.error('获取使用记录失败: ${result.msg}', tag: 'AppUsageApi');
        return HttpResultN<List<AppUsageRecord>>(
          isSuccess: false,
          code: result.code,
          msg: result.msg,
        );
      }
    } catch (e) {
      logger.error('获取使用记录异常: $e', tag: 'AppUsageApi', error: e);
      return HttpResultN<List<AppUsageRecord>>(
        isSuccess: false,
        code: -1,
        msg: '获取失败: $e',
      );
    }
  }
}

