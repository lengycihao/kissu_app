import 'package:intl/intl.dart';
import 'package:kissu_app/models/usage_record_api_model.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/api_request.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/pages/mine/device_usage/models/screen_unlock_stat_model.dart';
import 'package:kissu_app/pages/mine/device_usage/models/phone_record_stat_model.dart';

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

      // logDebug('📊 用机记录API调用开始', tag: 'UsageRecordApi');
      // logDebug('📝 API端点: ${ApiRequest.getSensitiveRecord}', tag: 'UsageRecordApi');
      // logDebug('📦 请求参数: $params', tag: 'UsageRecordApi');

      final result = await HttpManagerN.instance.executeGet(
        ApiRequest.getSensitiveRecord,
        queryParam: params,
      );

      // logDebug('📡 API响应状态: ${result.isSuccess}', tag: 'UsageRecordApi');
      // logDebug('📡 API响应码: ${result.code}', tag: 'UsageRecordApi');
      // logDebug('📡 API响应消息: ${result.msg}', tag: 'UsageRecordApi');

      if (result.isSuccess) {
        // logInfo('✅ 用机记录获取成功', tag: 'UsageRecordApi');
        final jsonData = result.getDataJson();
        // logDebug('📦 返回数据: $jsonData', tag: 'UsageRecordApi');
        
        return result.convert(
          data: UsageRecordApiResponse.fromJson(jsonData),
        );
      } else {
        logWarning('❌ 用机记录获取失败: ${result.msg}', tag: 'UsageRecordApi');
        return result.convert();
      }
    } catch (e, stackTrace) {
      logError('💥 用机记录API异常: $e', tag: 'UsageRecordApi', error: e, stackTrace: stackTrace);
      // logError('📋 堆栈跟踪: $stackTrace', tag: 'UsageRecordApi');
      return HttpResultN<UsageRecordApiResponse>(
        isSuccess: false,
        code: -1,
        msg: '用机记录获取异常: $e',
      );
    }
  }

  /// 获取敏感记录（分页版本）
  /// 参数：
  /// - page: 页码，从1开始
  /// - pageSize: 每页数量，默认10
  /// - sensitiveClassify: 筛选类型（不传/为空查询全部，支持多选逗号分隔，如"1,2"，1=kissu，2=手机状态，3=app使用统计，4=位置轨迹）
  /// - date: 日期，格式：2025-11-28
  Future<HttpResultN<SensitiveRecordPageResponse>> getSensitiveRecordPage({
    required int page,
    int pageSize = 10,
    String? sensitiveClassify,
    String? date,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'page': page,
        'page_size': pageSize,
      };
      
      if (sensitiveClassify != null && sensitiveClassify.isNotEmpty) {
        params['sensitive_classify'] = sensitiveClassify;
      }
      
      if (date != null && date.isNotEmpty) {
        params['date'] = date;
      }

      // logDebug('📊 敏感记录分页API调用开始', tag: 'UsageRecordApi');
      // logDebug('📝 API端点: ${ApiRequest.getSensitiveRecord}', tag: 'UsageRecordApi');
      // logDebug('📦 请求参数: $params', tag: 'UsageRecordApi');

      final result = await HttpManagerN.instance.executeGet(
        ApiRequest.getSensitiveRecord,
        queryParam: params,
      );

      // logDebug('📡 API响应状态: ${result.isSuccess}', tag: 'UsageRecordApi');
      // logDebug('📡 API响应码: ${result.code}', tag: 'UsageRecordApi');
      // logDebug('📡 API响应消息: ${result.msg}', tag: 'UsageRecordApi');

      if (result.isSuccess) {
        // logInfo('✅ 敏感记录分页获取成功', tag: 'UsageRecordApi');
        final jsonData = result.getDataJson();
        // logDebug('📦 返回数据: $jsonData', tag: 'UsageRecordApi');
        
        return result.convert(
          data: SensitiveRecordPageResponse.fromJson(jsonData),
        );
      } else {
        logWarning('❌ 敏感记录分页获取失败: ${result.msg}', tag: 'UsageRecordApi');
        return result.convert();
      }
    } catch (e, stackTrace) {
      logError('💥 敏感记录分页API异常: $e', tag: 'UsageRecordApi', error: e, stackTrace: stackTrace);
      // logError('📋 堆栈跟踪: $stackTrace', tag: 'UsageRecordApi');
      return HttpResultN<SensitiveRecordPageResponse>(
        isSuccess: false,
        code: -1,
        msg: '敏感记录分页获取异常: $e',
      );
    }
  }

  /// 获取用机记录统计数据（废弃）
  /// 参数：date - 日期，格式：2025-11-12
  @Deprecated('使用 getPhoneRecordStat 替代')
  Future<HttpResultN<MobileUsageRecordStaResponse>> getMobileUsageRecordSta({
    String? date,
  }) async {
    try {
      // 格式化日期参数
      final Map<String, dynamic> params = {};
      if (date != null) {
        params['date'] = date;
      }

      // logDebug('📊 用机记录统计API调用开始', tag: 'UsageRecordApi');
      // logDebug('📝 API端点: ${ApiRequest.getMobileUsageRecordSta}', tag: 'UsageRecordApi');
      // logDebug('📦 请求参数: $params', tag: 'UsageRecordApi');

      final result = await HttpManagerN.instance.executeGet(
        ApiRequest.getMobileUsageRecordSta,
        queryParam: params,
      );

      // logDebug('📡 API响应状态: ${result.isSuccess}', tag: 'UsageRecordApi');
      // logDebug('📡 API响应码: ${result.code}', tag: 'UsageRecordApi');
      // logDebug('📡 API响应消息: ${result.msg}', tag: 'UsageRecordApi');

      if (result.isSuccess) {
        // logInfo('✅ 用机记录统计获取成功', tag: 'UsageRecordApi');
        final jsonData = result.getDataJson();
        // logDebug('📦 返回数据: $jsonData', tag: 'UsageRecordApi');
        
        return result.convert(
          data: MobileUsageRecordStaResponse.fromJson(jsonData),
        );
      } else {
        logWarning('❌ 用机记录统计获取失败: ${result.msg}', tag: 'UsageRecordApi');
        return result.convert();
      }
    } catch (e, stackTrace) {
      logError('💥 用机记录统计API异常: $e', tag: 'UsageRecordApi', error: e, stackTrace: stackTrace);
      // logError('📋 堆栈跟踪: $stackTrace', tag: 'UsageRecordApi');
      return HttpResultN<MobileUsageRecordStaResponse>(
        isSuccess: false,
        code: -1,
        msg: '用机记录统计获取异常: $e',
      );
    }
  }

  /// 获取屏幕使用和解锁统计数据（废弃）
  /// 参数：date - 日期，格式：2025-11-28，不传默认返回当天
  @Deprecated('使用 getPhoneRecordStat 替代')
  Future<HttpResultN<ScreenUnlockStatModel>> getScreenUnlockStat({
    String? date,
  }) async {
    try {
      // 格式化日期参数
      final Map<String, dynamic> params = {};
      if (date != null && date.isNotEmpty) {
        params['date'] = date;
      }

      // logDebug('📊 屏幕解锁统计API调用开始', tag: 'UsageRecordApi');
      // logDebug('📝 API端点: ${ApiRequest.getScreenUnlockStat}', tag: 'UsageRecordApi');
      // logDebug('📦 请求参数: $params', tag: 'UsageRecordApi');

      final result = await HttpManagerN.instance.executeGet(
        ApiRequest.getScreenUnlockStat,
        queryParam: params,
      );

      // logDebug('📡 API响应状态: ${result.isSuccess}', tag: 'UsageRecordApi');
      // logDebug('📡 API响应码: ${result.code}', tag: 'UsageRecordApi');
      // logDebug('📡 API响应消息: ${result.msg}', tag: 'UsageRecordApi');

      if (result.isSuccess) {
        // logInfo('✅ 屏幕解锁统计获取成功', tag: 'UsageRecordApi');
        final jsonData = result.getDataJson();
        // logDebug('📦 返回数据: $jsonData', tag: 'UsageRecordApi');
        
        return result.convert(
          data: ScreenUnlockStatModel.fromJson(jsonData),
        );
      } else {
        logWarning('❌ 屏幕解锁统计获取失败: ${result.msg}', tag: 'UsageRecordApi');
        return result.convert();
      }
    } catch (e, stackTrace) {
      logError('💥 屏幕解锁统计API异常: $e', tag: 'UsageRecordApi', error: e, stackTrace: stackTrace);
      // logError('📋 堆栈跟踪: $stackTrace', tag: 'UsageRecordApi');
      return HttpResultN<ScreenUnlockStatModel>(
        isSuccess: false,
        code: -1,
        msg: '屏幕解锁统计获取异常: $e',
      );
    }
  }

  /// 获取用机记录统计数据（新接口）
  /// 参数：date - 日期，格式：2025-11-28，不传默认返回当天
  Future<HttpResultN<PhoneRecordStatModel>> getPhoneRecordStat({
    String? date,
  }) async {
    try {
      // 格式化日期参数
      final Map<String, dynamic> params = {};
      if (date != null && date.isNotEmpty) {
        params['date'] = date;
      }

      // logDebug('📊 用机记录统计API调用开始', tag: 'UsageRecordApi');
      // logDebug('📝 API端点: ${ApiRequest.getPhoneRecordStat}', tag: 'UsageRecordApi');
      // logDebug('📦 请求参数: $params', tag: 'UsageRecordApi');

      final result = await HttpManagerN.instance.executeGet(
        ApiRequest.getPhoneRecordStat,
        queryParam: params,
      );

      // logDebug('📡 API响应状态: ${result.isSuccess}', tag: 'UsageRecordApi');
      // logDebug('📡 API响应码: ${result.code}', tag: 'UsageRecordApi');
      // logDebug('📡 API响应消息: ${result.msg}', tag: 'UsageRecordApi');

      if (result.isSuccess) {
        // logInfo('✅ 用机记录统计获取成功', tag: 'UsageRecordApi');
        final jsonData = result.getDataJson();
        // logDebug('📦 返回数据: $jsonData', tag: 'UsageRecordApi');
        
        return result.convert(
          data: PhoneRecordStatModel.fromJson(jsonData),
        );
      } else {
        logWarning('❌ 用机记录统计获取失败: ${result.msg}', tag: 'UsageRecordApi');
        return result.convert();
      }
    } catch (e, stackTrace) {
      logError('💥 用机记录统计API异常: $e', tag: 'UsageRecordApi', error: e, stackTrace: stackTrace);
      // logError('📋 堆栈跟踪: $stackTrace', tag: 'UsageRecordApi');
      return HttpResultN<PhoneRecordStatModel>(
        isSuccess: false,
        code: -1,
        msg: '用机记录统计获取异常: $e',
      );
    }
  }
}

