import 'package:intl/intl.dart';
import 'package:kissu_app/models/usage_record_api_model.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/api_request.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

/// 用机记录API
class UsageRecordApi {
  /// 获取敏感记录
  /// 参数：date - 日期，格式：2025-09-26，不传默认当天
  Future<HttpResultN<UsageRecordApiResponse>> getSensitiveRecord({
    DateTime? date,
  }) async {
    try {
      // 格式化日期参数
      final Map<String, dynamic> params = {};
      if (date != null) {
        params['date'] = DateFormat('yyyy-MM-dd').format(date);
      }

      logDebug('📊 用机记录API调用开始', tag: 'UsageRecordApi');
      logDebug('📝 API端点: ${ApiRequest.getSensitiveRecord}', tag: 'UsageRecordApi');
      logDebug('📦 请求参数: $params', tag: 'UsageRecordApi');

      final result = await HttpManagerN.instance.executeGet(
        ApiRequest.getSensitiveRecord,
        queryParam: params,
      );

      logDebug('📡 API响应状态: ${result.isSuccess}', tag: 'UsageRecordApi');
      logDebug('📡 API响应码: ${result.code}', tag: 'UsageRecordApi');
      logDebug('📡 API响应消息: ${result.msg}', tag: 'UsageRecordApi');

      if (result.isSuccess) {
        logInfo('✅ 用机记录获取成功', tag: 'UsageRecordApi');
        final jsonData = result.getDataJson();
        logDebug('📦 返回数据: $jsonData', tag: 'UsageRecordApi');
        
        return result.convert(
          data: UsageRecordApiResponse.fromJson(jsonData),
        );
      } else {
        logWarning('❌ 用机记录获取失败: ${result.msg}', tag: 'UsageRecordApi');
        return result.convert();
      }
    } catch (e, stackTrace) {
      logError('💥 用机记录API异常: $e', tag: 'UsageRecordApi', error: e, stackTrace: stackTrace);
      logError('📋 堆栈跟踪: $stackTrace', tag: 'UsageRecordApi');
      return HttpResultN<UsageRecordApiResponse>(
        isSuccess: false,
        code: -1,
        msg: '用机记录获取异常: $e',
      );
    }
  }

  /// 获取用机记录统计数据
  /// 参数：date - 日期，格式：2025-11-12
  Future<HttpResultN<MobileUsageRecordStaResponse>> getMobileUsageRecordSta({
    String? date,
  }) async {
    try {
      // 格式化日期参数
      final Map<String, dynamic> params = {};
      if (date != null) {
        params['date'] = date;
      }

      logDebug('📊 用机记录统计API调用开始', tag: 'UsageRecordApi');
      logDebug('📝 API端点: ${ApiRequest.getMobileUsageRecordSta}', tag: 'UsageRecordApi');
      logDebug('📦 请求参数: $params', tag: 'UsageRecordApi');

      final result = await HttpManagerN.instance.executeGet(
        ApiRequest.getMobileUsageRecordSta,
        queryParam: params,
      );

      logDebug('📡 API响应状态: ${result.isSuccess}', tag: 'UsageRecordApi');
      logDebug('📡 API响应码: ${result.code}', tag: 'UsageRecordApi');
      logDebug('📡 API响应消息: ${result.msg}', tag: 'UsageRecordApi');

      if (result.isSuccess) {
        logInfo('✅ 用机记录统计获取成功', tag: 'UsageRecordApi');
        final jsonData = result.getDataJson();
        logDebug('📦 返回数据: $jsonData', tag: 'UsageRecordApi');
        
        return result.convert(
          data: MobileUsageRecordStaResponse.fromJson(jsonData),
        );
      } else {
        logWarning('❌ 用机记录统计获取失败: ${result.msg}', tag: 'UsageRecordApi');
        return result.convert();
      }
    } catch (e, stackTrace) {
      logError('💥 用机记录统计API异常: $e', tag: 'UsageRecordApi', error: e, stackTrace: stackTrace);
      logError('📋 堆栈跟踪: $stackTrace', tag: 'UsageRecordApi');
      return HttpResultN<MobileUsageRecordStaResponse>(
        isSuccess: false,
        code: -1,
        msg: '用机记录统计获取异常: $e',
      );
    }
  }
}

