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
      return result.convert(data: LocationResponseModel.fromJson(result.getDataJson()));
    } else {
      return result.convert();
    }
  }
}
