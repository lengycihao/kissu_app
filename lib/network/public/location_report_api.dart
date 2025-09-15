import 'dart:convert';
import 'package:kissu_app/model/location_model/location_report_model.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/api_request.dart';

class LocationReportApi {
  /// 上报位置信息
  /// 参数：locations - 位置信息列表
  Future<HttpResultN<LocationReportResponse>> reportLocation(
    List<LocationReportModel> locations,
  ) async {
    try {
      // 将位置数组转换为JSON字符串
      final locationsJson = locations.map((location) => location.toJson()).toList();
      final locationsString = jsonEncode(locationsJson);
      
      // 添加调试信息
      print('🚀 位置上报API调用开始');
      print('📝 API端点: ${ApiRequest.reportLocation}');
      print('📦 请求数据: $locationsString');
      print('📊 位置数据数量: ${locations.length}');
      
      final result = await HttpManagerN.instance.executePost(
        ApiRequest.reportLocation,
        jsonParam: {'locations': locationsString},
      );

      print('📡 API响应状态: ${result.isSuccess}');
      print('📡 API响应码: ${result.code}');
      print('📡 API响应消息: ${result.msg}');
      
      if (result.isSuccess) {
        print('✅ 位置上报成功');
        return result.convert(
          data: LocationReportResponse.fromJson(result.getDataJson()),
        );
      } else {
        print('❌ 位置上报失败: ${result.msg}');
        return result.convert();
      }
    } catch (e, stackTrace) {
      print('💥 位置上报API异常: $e');
      print('📋 堆栈跟踪: $stackTrace');
      return HttpResultN<LocationReportResponse>(
        isSuccess: false,
        code: -1,
        msg: '位置上报异常: $e',
      );
    }
  }
}
