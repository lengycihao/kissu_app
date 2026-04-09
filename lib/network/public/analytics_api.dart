import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/public/api_request.dart';

/// 埋点上传 API
class AnalyticsApi {
  /// 上传埋点数据
  /// 
  /// [pointData] 埋点数据列表
  /// 返回上传结果
  Future<HttpResultN> uploadPoint({
    required List<Map<String, dynamic>> pointData,
  }) async {
    try {
      final params = {
        'point_data': pointData,
      };

      final result = await HttpManagerN.instance.executePost(
        ApiRequest.uploadPoint,
        jsonParam: params,
        paramEncrypt: false,
      );

      return result;
    } catch (e) {
      return HttpResultN(
        isSuccess: false,
        code: -1,
        msg: '埋点上传失败: $e',
      );
    }
  }
}
