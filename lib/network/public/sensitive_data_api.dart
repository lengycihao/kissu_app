import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/api_request.dart';

/// 敏感数据上报API
class SensitiveDataApi {
  /// 上报敏感数据
  /// 
  /// [eventType] 事件类型：
  /// - 2: 打开APP
  /// - 4: 打开定位
  /// - 5: 关闭定位
  /// - 6: 更换网络
  /// - 7: 开始充电
  /// - 8: 结束充电
  /// 
  /// [ext] 扩展参数：
  /// - eventType为7或8时：{"power": 手机电量}
  /// - eventType为6时：{"network_name": 网络名称}
  Future<HttpResultN> reportSensitiveData({
    required int eventType,
    Map<String, dynamic>? ext,
  }) async {
    final params = <String, dynamic>{
      'event_type': eventType,
    };
    
    // 添加扩展参数
    if (ext != null && ext.isNotEmpty) {
      params['ext'] = ext;
    }
    
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.sensitiveDataReport,
      jsonParam: params,
      paramEncrypt: false,
    );
    
    return result;
  }
  
  /// 上报APP打开事件
  Future<HttpResultN> reportAppOpen() async {
    return await reportSensitiveData(eventType: 2);
  }
  
  /// 上报定位打开事件
  Future<HttpResultN> reportLocationOpen() async {
    return await reportSensitiveData(eventType: 4);
  }
  
  /// 上报定位关闭事件
  Future<HttpResultN> reportLocationClose() async {
    return await reportSensitiveData(eventType: 5);
  }
  
  /// 上报网络更换事件
  Future<HttpResultN> reportNetworkChange({required String networkName}) async {
    return await reportSensitiveData(
      eventType: 6,
      ext: {'network_name': networkName},
    );
  }
  
  /// 上报开始充电事件
  Future<HttpResultN> reportChargingStart({required int power}) async {
    return await reportSensitiveData(
      eventType: 7,
      ext: {'power': power},
    );
  }
  
  /// 上报结束充电事件
  Future<HttpResultN> reportChargingEnd({required int power}) async {
    return await reportSensitiveData(
      eventType: 8,
      ext: {'power': power},
    );
  }
}
