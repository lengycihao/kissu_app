import 'package:intl/intl.dart';
import 'package:kissu_app/models/usage_record_api_model.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/api_request.dart';

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

      print('📊 用机记录API调用开始');
      print('📝 API端点: ${ApiRequest.getSensitiveRecord}');
      print('📦 请求参数: $params');

      final result = await HttpManagerN.instance.executeGet(
        ApiRequest.getSensitiveRecord,
        queryParam: params,
      );

      print('📡 API响应状态: ${result.isSuccess}');
      print('📡 API响应码: ${result.code}');
      print('📡 API响应消息: ${result.msg}');

      if (result.isSuccess) {
        print('✅ 用机记录获取成功');
        final jsonData = result.getDataJson();
        print('📦 返回数据: $jsonData');
        
        return result.convert(
          data: UsageRecordApiResponse.fromJson(jsonData),
        );
      } else {
        print('❌ 用机记录获取失败: ${result.msg}');
        return result.convert();
      }
    } catch (e, stackTrace) {
      print('💥 用机记录API异常: $e');
      print('📋 堆栈跟踪: $stackTrace');
      return HttpResultN<UsageRecordApiResponse>(
        isSuccess: false,
        code: -1,
        msg: '用机记录获取异常: $e',
      );
    }
  }
}

