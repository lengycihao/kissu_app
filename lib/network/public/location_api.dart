import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/api_request.dart';

class LocationApi {
  /// 获取定位信息
  /// 返回用户和另一半的定位数据
  Future<HttpResultN<LocationResponseModel>> getLocation() async {
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.getLocation,
      paramEncrypt: false,
    );

    if (result.isSuccess) {
      // 添加原始JSON调试信息
      final rawJson = result.getDataJson();
      print('🔍 API原始JSON数据:');
      print('  JSON keys: ${rawJson.keys.toList()}');
      
      // 检查stops字段
      if (rawJson['user_location_mobile_device'] != null) {
        final userData = rawJson['user_location_mobile_device'];
        print('  user_location_mobile_device keys: ${userData.keys.toList()}');
        if (userData['stops'] != null) {
          print('  user_location_mobile_device stops: ${userData['stops']}');
        } else {
          print('  user_location_mobile_device stops: null');
        }
      }
      
      if (rawJson['half_location_mobile_device'] != null) {
        final halfData = rawJson['half_location_mobile_device'];
        print('  half_location_mobile_device keys: ${halfData.keys.toList()}');
        if (halfData['stops'] != null) {
          print('  half_location_mobile_device stops: ${halfData['stops']}');
        } else {
          print('  half_location_mobile_device stops: null');
        }
      }
      
      return result.convert(data: LocationResponseModel.fromJson(rawJson));
    } else {
      return result.convert();
    }
  }
}
