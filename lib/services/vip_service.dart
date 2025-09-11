import 'package:kissu_app/models/vip_package_model.dart';
import 'package:kissu_app/models/payment_model.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/api_request.dart';

class VipService {
  /// 获取VIP套餐列表
  Future<HttpResultN<List<VipPackageModel>>> getVipPackageList() async {
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.vipPackageList,
      paramEncrypt: false,
    );
 
    if (result.isSuccess) {
      final List<VipPackageModel> list = (result.listJson as List)
          .map((e) => VipPackageModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return result.convert(data: list);
    } else {
      return result.convert();
    }
    // if (result.isSuccess) {
    //   final dynamic data = result.getDataJson();
    //   List<dynamic> dataList;
      
    //   // 处理不同的响应格式
    //   if (data is List<dynamic>) {
    //     // 如果直接是数组
    //     dataList = data;
    //   } else if (data is Map<String, dynamic>) {
    //     // 如果是对象，尝试找到包含列表的字段
    //     if (data.containsKey('list')) {
    //       dataList = data['list'] as List<dynamic>;
    //     } else if (data.containsKey('data')) {
    //       dataList = data['data'] as List<dynamic>;
    //     } else if (data.containsKey('packages')) {
    //       dataList = data['packages'] as List<dynamic>;
    //     } else {
    //       // 如果找不到列表字段，可能整个data就是一个单独的套餐
    //       dataList = [data];
    //     }
    //   } else {
    //     throw Exception('Unexpected data format: ${data.runtimeType}');
    //   }
      
    //   final List<VipPackageModel> vipPackages = dataList
    //       .map((json) => VipPackageModel.fromJson(json as Map<String, dynamic>))
    //       .toList();
    //   return result.convert(data: vipPackages);
    // } else {
    //   return result.convert();
    // }
  }

  /// 微信支付
  Future<HttpResultN<WxPayModel>> wxPay({required int vipPackageId}) async {
    final params = {
      'vip_package_id': vipPackageId,
    };
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.wxPay,
      jsonParam: params,
      paramEncrypt: false,
    );

    if (result.isSuccess) {
      return result.convert(data: WxPayModel.fromJson(result.getDataJson()));
    } else {
      return result.convert();
    }
  }

  /// 支付宝支付
  Future<HttpResultN<AliPayModel>> aliPay({required int vipPackageId}) async {
    final params = {
      'vip_package_id': vipPackageId,
    };
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.aliPay,
      jsonParam: params,
      paramEncrypt: false,
    );

    if (result.isSuccess) {
      return result.convert(data: AliPayModel.fromJson(result.getDataJson()));
    } else {
      return result.convert();
    }
  }
}
