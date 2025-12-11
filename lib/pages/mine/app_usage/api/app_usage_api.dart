import 'dart:convert';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/api_request.dart';
import 'package:kissu_app/pages/mine/app_usage/models/app_usage_record.dart';
import 'package:kissu_app/pages/mine/app_usage/models/app_usage_stat_data.dart';
import 'package:kissu_app/pages/mine/app_usage/models/app_open_record_detail_data.dart';
import 'package:kissu_app/pages/mine/app_usage/models/hourly_app_record_data.dart';
import 'package:kissu_app/pages/mine/app_usage/models/half_auth_app.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';

/// 应用使用记录上报API
class AppUsageApi {
  /// 上报应用使用记录
  /// [appUseRecordData] 应用使用记录数据列表（已转换格式）
  /// [date] 日期（yyyyMMdd格式，如20251130）
  /// 返回上报结果
  static Future<HttpResultN<dynamic>> reportAppUsage(
    List<Map<String, dynamic>> appUseRecordData,
    int date,
  ) async {
    try {
      // 构建请求数据（按照api.md格式）
      final requestData = {
        'app_use_record_data': appUseRecordData,
        'date': date,
      };
      
      logger.info('准备上报应用使用记录: ${appUseRecordData.length}个应用, 日期: $date', tag: 'AppUsageApi');
      logger.debug('上报数据: ${jsonEncode(requestData)}', tag: 'AppUsageApi');
      
      // 根据api.md说明，接口需要json格式，直接传递整个json对象
      // http_engine会自动将jsonParam转换为json字符串作为body
      final result = await HttpManagerN.instance.executePost(
        ApiRequest.reportAppUseRecord,
        jsonParam: requestData, // 直接传递json对象
        paramEncrypt: false,
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
  
  /// 上报单个应用的使用记录（已废弃，请使用新的上报格式）
  /// [record] 单个应用使用记录
  @Deprecated('请使用新的上报格式，需要先转换数据格式')
  static Future<HttpResultN<dynamic>> reportSingleAppUsage(AppUsageRecord record) async {
    // 此方法已废弃，因为新的上报接口需要不同的数据格式
    // 请使用 reportAppUsage 方法，并先转换数据格式
    throw UnimplementedError('请使用新的上报格式');
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
        ApiRequest.appUsageHistory,
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
  
  /// 获取App使用统计数据（用于"最近使用App"模块）
  /// [date] 日期 yyyy-MM-dd格式，如：2025-11-30
  /// 返回统计数据
  static Future<HttpResultN<AppUsageStatResponse>> getAppUsageStat({
    required String date,
  }) async {
    try {
      logger.info('获取App使用统计数据: $date', tag: 'AppUsageApi');
      
      final result = await HttpManagerN.instance.executeGet(
        ApiRequest.appUsageStat,
        queryParam: {
          'date': date,
        },
      );
      
      if (result.isSuccess) {
        final data = result.getDataJson();
        final statResponse = AppUsageStatResponse.fromJson(data);
        
        logger.info('获取App使用统计数据成功: ${statResponse.appUseStatData.length}个App', tag: 'AppUsageApi');
        
        return HttpResultN<AppUsageStatResponse>(
          isSuccess: true,
          code: result.code,
          msg: result.msg,
          data: statResponse,
        );
      } else {
        logger.error('获取App使用统计数据失败: ${result.msg}', tag: 'AppUsageApi');
        return HttpResultN<AppUsageStatResponse>(
          isSuccess: false,
          code: result.code,
          msg: result.msg,
        );
      }
    } catch (e) {
      logger.error('获取App使用统计数据异常: $e', tag: 'AppUsageApi', error: e);
      return HttpResultN<AppUsageStatResponse>(
        isSuccess: false,
        code: -1,
        msg: '获取失败: $e',
      );
    }
  }
  
  /// 获取App打开记录详情（用于"时间轴"视图）
  /// [date] 日期 yyyy-MM-dd格式，如：2025-11-30
  /// [appPkg] 应用包名，不传默认查询最近使用的一个APP
  /// 返回打开记录详情
  static Future<HttpResultN<AppOpenRecordDetailResponse>> getAppOpenRecordDetail({
    required String date,
    String? appPkg,
  }) async {
    try {
      logger.info('获取App打开记录详情: date=$date, appPkg=$appPkg', tag: 'AppUsageApi');
      
      final queryParam = <String, dynamic>{
        'date': date,
      };
      
      // 如果传入了appPkg，添加到查询参数
      if (appPkg != null && appPkg.isNotEmpty) {
        queryParam['app_pkg'] = appPkg;
      }
      
      final result = await HttpManagerN.instance.executeGet(
        ApiRequest.appOpenRecordDetail,
        queryParam: queryParam,
      );
      
      if (result.isSuccess) {
        final data = result.getDataJson();
        
        // 调试：打印原始数据
        logger.debug('API返回的原始数据: ${data.toString()}', tag: 'AppUsageApi');
        
        final detailResponse = AppOpenRecordDetailResponse.fromJson(data);
        
        logger.info(
          '获取App打开记录详情成功: ${detailResponse.latelyUseAppData.length}个App, ${detailResponse.appOpenRecordDetail.length}条记录',
          tag: 'AppUsageApi',
        );
        
        return HttpResultN<AppOpenRecordDetailResponse>(
          isSuccess: true,
          code: result.code,
          msg: result.msg,
          data: detailResponse,
        );
      } else {
        logger.error('获取App打开记录详情失败: ${result.msg}', tag: 'AppUsageApi');
        return HttpResultN<AppOpenRecordDetailResponse>(
          isSuccess: false,
          code: result.code,
          msg: result.msg,
        );
      }
    } catch (e) {
      logger.error('获取App打开记录详情异常: $e', tag: 'AppUsageApi', error: e);
      return HttpResultN<AppOpenRecordDetailResponse>(
        isSuccess: false,
        code: -1,
        msg: '获取失败: $e',
      );
    }
  }

  /// 获取Ta当前授权过的App列表
  static Future<HttpResultN<List<HalfAuthApp>>> getHalfAuthorizedApps() async {
    try {
      logger.info('获取Ta当前授权过的App列表', tag: 'AppUsageApi');

      final result = await HttpManagerN.instance.executeGet(
        ApiRequest.getHalfAuthApp,
      );

      if (result.isSuccess) {
        List<dynamic> appList = result.getListJson();

        if (appList.isEmpty) {
          final dynamicData = result.getDataDynamic();
          if (dynamicData is List) {
            appList = dynamicData;
          }
        }

        final apps = appList
            .map(
              (e) => HalfAuthApp.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();

        logger.info('获取Ta当前授权过的App成功: ${apps.length}个', tag: 'AppUsageApi');

        return HttpResultN<List<HalfAuthApp>>(
          isSuccess: true,
          code: result.code,
          msg: result.msg,
          data: apps,
        );
      } else {
        logger.error('获取Ta当前授权过的App失败: ${result.msg}', tag: 'AppUsageApi');
        return HttpResultN<List<HalfAuthApp>>(
          isSuccess: false,
          code: result.code,
          msg: result.msg,
        );
      }
    } catch (e) {
      logger.error('获取Ta当前授权过的App异常: $e', tag: 'AppUsageApi', error: e);
      return HttpResultN<List<HalfAuthApp>>(
        isSuccess: false,
        code: -1,
        msg: '获取失败: $e',
      );
    }
  }
  
  /// 获取App使用记录统计（用于"统计"视图）
  /// [date] 日期 yyyy-MM-dd格式，如：2025-11-30
  /// 返回每小时的使用记录统计
  static Future<HttpResultN<HourlyAppRecordResponse>> getAppRecordStat({
    required String date,
  }) async {
    try {
      logger.info('获取App使用记录统计: date=$date', tag: 'AppUsageApi');
      
      final result = await HttpManagerN.instance.executeGet(
        ApiRequest.appOpenRecordStat,
        queryParam: {
          'date': date,
        },
      );
      
      if (result.isSuccess) {
        // 根据api.md，返回的数据直接是一个数组
        // 使用getListJson()获取列表数据，如果为空则尝试getDataDynamic()
        List<dynamic> recordsList = result.getListJson();
        
        // 如果getListJson()返回空，尝试从getDataDynamic()获取
        if (recordsList.isEmpty) {
          final dynamicData = result.getDataDynamic();
          if (dynamicData is List) {
            recordsList = dynamicData;
          }
        }
        
        // 调试：打印原始数据
        logger.debug('API返回的原始数据: ${recordsList.toString()}', tag: 'AppUsageApi');
        logger.debug('API返回的数据类型: ${recordsList.runtimeType}', tag: 'AppUsageApi');
        logger.debug('API返回的数据长度: ${recordsList.length}', tag: 'AppUsageApi');
        
        // 解析数据
        final statResponse = HourlyAppRecordResponse.fromJson(recordsList);
        
        logger.info(
          '获取App使用记录统计成功: ${statResponse.hourlyRecords.length}个小时的记录',
          tag: 'AppUsageApi',
        );
        
        return HttpResultN<HourlyAppRecordResponse>(
          isSuccess: true,
          code: result.code,
          msg: result.msg,
          data: statResponse,
        );
      } else {
        logger.error('获取App使用记录统计失败: ${result.msg}', tag: 'AppUsageApi');
        return HttpResultN<HourlyAppRecordResponse>(
          isSuccess: false,
          code: result.code,
          msg: result.msg,
        );
      }
    } catch (e) {
      logger.error('获取App使用记录统计异常: $e', tag: 'AppUsageApi', error: e);
      return HttpResultN<HourlyAppRecordResponse>(
        isSuccess: false,
        code: -1,
        msg: '获取失败: $e',
      );
    }
  }
}

