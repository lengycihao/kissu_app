import 'dart:convert';
import 'package:kissu_app/model/location_model/location_report_model.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/api_request.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

class LocationReportApi {
  /// 上报位置信息
  /// 参数：locations - 位置信息列表
  Future<HttpResultN<LocationReportResponse>> reportLocation(
    List<LocationReportModel> locations,
  ) async {
    try {
      // 过滤无效的位置数据（使用宽松验证，与Android原生策略保持一致）
      final validLocations = locations
          .where((loc) => loc.isBasicValid) // 🔧 改为使用宽松验证
          .toList();

      if (validLocations.isEmpty) {
        logWarning('⚠️ 没有有效的位置数据可上报', tag: 'LocationReportApi');
        return HttpResultN<LocationReportResponse>(
          isSuccess: false,
          code: -2,
          msg: '没有有效的位置数据可上报',
        );
      }

      // 将位置模型列表转换为JSON字符串（正确处理）
      final locationsJsonList = validLocations.map((e) => e.toJson()).toList();
      final locationsString = jsonEncode(locationsJsonList);

      // // 添加调试信息
      // logDebug('🚀 位置上报API调用开始', tag: 'LocationReportApi');
      // logDebug('📝 API端点: ${ApiRequest.reportLocation}', tag: 'LocationReportApi');
      // logDebug('📦 请求数据: $locationsString', tag: 'LocationReportApi');
      // logDebug('📊 有效位置数据数量: ${validLocations.length}', tag: 'LocationReportApi');

      // 发送位置上报请求
      final result = await HttpManagerN.instance.executePost(
        ApiRequest.reportLocation,
        jsonParam: {
          'locations': locationsString,
        },
      );

      // logDebug('📡 API响应状态: ${result.isSuccess}', tag: 'LocationReportApi');
      // logDebug('📡 API响应码: ${result.code}', tag: 'LocationReportApi');
      // logDebug('📡 API响应消息: ${result.msg}', tag: 'LocationReportApi');
      // logDebug('📡 原始响应dataJson: ${result.dataJson}', tag: 'LocationReportApi');
      // logDebug('📡 原始响应listJson: ${result.listJson}', tag: 'LocationReportApi');
      // logDebug('📡 完整响应对象: ${result.toString()}', tag: 'LocationReportApi');

      if (result.isSuccess) {
        logInfo('✅ 位置上报成功', tag: 'LocationReportApi');
        return result.convert(
          data: LocationReportResponse.fromJson(result.getDataJson()),
        );
      } else {
        logWarning('❌ 位置上报失败: ${result.msg}', tag: 'LocationReportApi');
        return result.convert();
      }
    } catch (e, stackTrace) {
      logError('💥 位置上报API异常: $e', tag: 'LocationReportApi', error: e, stackTrace: stackTrace);
      logError('📋 堆栈跟踪: $stackTrace', tag: 'LocationReportApi');
      return HttpResultN<LocationReportResponse>(
        isSuccess: false,
        code: -1,
        msg: '位置上报异常: $e',
      );
    }
  }
}
