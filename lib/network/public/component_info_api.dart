import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/api_request.dart';
import 'package:kissu_app/network/enum/cache_control.dart';

class ComponentInfoModel {
  final int isVip;
  final int isBind;
  final String userHeadPortrait;
  final String halfHeadPortrait;
  final String distance;
  final String userPower;
  final String halfPower;
  final int isSetLoverTime;
  final int loveDays;
  final String loveTime;

  const ComponentInfoModel({
    required this.isVip,
    required this.isBind,
    required this.userHeadPortrait,
    required this.halfHeadPortrait,
    required this.distance,
    required this.userPower,
    required this.halfPower,
    required this.isSetLoverTime,
    required this.loveDays,
    required this.loveTime,
  });

  factory ComponentInfoModel.fromJson(Map<String, dynamic> json) {
    return ComponentInfoModel(
      isVip: (json['is_vip'] as num?)?.toInt() ?? 0,
      isBind: (json['is_bind'] as num?)?.toInt() ?? 0,
      userHeadPortrait: json['user_head_portrait'] as String? ?? '',
      halfHeadPortrait: json['half_head_portrait'] as String? ?? '',
      distance: json['distance'] as String? ?? '',
      userPower: json['user_power'] as String? ?? '',
      halfPower: json['half_power'] as String? ?? '',
      isSetLoverTime: (json['is_set_lover_time'] as num?)?.toInt() ?? 0,
      loveDays: (json['love_days'] as num?)?.toInt() ?? 0,
      loveTime: json['love_time'] as String? ?? '',
    );
  }
}

class ComponentInfoApi {
  Future<HttpResultN<ComponentInfoModel>> getComponentInfo() async {
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.getComponentInfo,
      paramEncrypt: false,
      networkDebounce: false,
      cacheControl: CacheControl.noCache,
    );
    if (result.isSuccess) {
      return result.convert(
        data: ComponentInfoModel.fromJson(result.getDataJson()),
      );
    }
    return result.convert();
  }
}
