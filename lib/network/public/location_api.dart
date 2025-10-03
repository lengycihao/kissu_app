import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/api_request.dart';
import 'package:kissu_app/network/enum/cache_control.dart';
import 'package:kissu_app/utils/debug_util.dart';

class LocationApi {
  /// 获取定位信息
  /// 返回用户和另一半的定位数据
  Future<HttpResultN<LocationResponseModel>> getLocation() async {
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.getLocation,
      paramEncrypt: false,
      networkDebounce: false, // 定位请求不去抖，避免二次启动首个请求被拦截
      // 显式只走网络不使用缓存，避免返回过期数据
      cacheControl: CacheControl.noCache,
    );

    if (result.isSuccess) {
      // 添加原始JSON调试信息
      final rawJson = result.getDataJson();
      DebugUtil.check('API原始JSON数据:');
      DebugUtil.check('  JSON keys: ${rawJson.keys.toList()}');
      
      // 检查stops字段
      if (rawJson['user_location_mobile_device'] != null) {
        final userData = rawJson['user_location_mobile_device'];
        DebugUtil.check('  user_location_mobile_device keys: ${userData.keys.toList()}');
        if (userData['stops'] != null) {
          DebugUtil.check('  user_location_mobile_device stops: ${userData['stops']}');
        } else {
          DebugUtil.check('  user_location_mobile_device stops: null');
        }
      }
      
      if (rawJson['half_location_mobile_device'] != null) {
        final halfData = rawJson['half_location_mobile_device'];
        DebugUtil.check('  half_location_mobile_device keys: ${halfData.keys.toList()}');
        if (halfData['stops'] != null) {
          DebugUtil.check('  half_location_mobile_device stops: ${halfData['stops']}');
        } else {
          DebugUtil.check('  half_location_mobile_device stops: null');
        }
      }
      
      return result.convert(data: LocationResponseModel.fromJson(rawJson));
    } else {
      return result.convert();
    }
  }
}
