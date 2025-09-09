import 'package:kissu_app/model/login_model/login_model.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/api_request.dart';

class AuthApi {
  Future<HttpResultN<LoginModel>> _login({
    String? phone,
    String? captcha,
    String? friendCode,
  }) async {
    final params = {
      if (phone != null) "phone": phone,
      if (captcha != null) "captcha": captcha,
      "friend_code": friendCode,
    };
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.authLoginByCode,
      jsonParam: params,
      paramEncrypt: false,
    );

    if (result.isSuccess) {
      return result.convert(data: LoginModel.fromJson(result.getDataJson()));
    } else {
      return result.convert();
    }

    // return HttpResultN(
    //   isSuccess: result.isSuccess,
    //   code: result.code,
    //   msg: result.msg,
    // );
  }

  ///获取验证码
  Future<HttpResultN> getPhoneCode({
    required String phone,
    required String type,
  }) async {
    final params = {
      "phone": phone,
      "type": type, // login登录验证码 change_phone更换手机号 logout注销账号
    };
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.phoneCode,
      queryParam: params,
      paramEncrypt: false,
    );
    return result;
  }

  /// code 登录
  Future<HttpResultN<LoginModel>> loginWithCode({
    required String phone,
    required String captcha,
    String? friendCode,
  }) async {
    return await _login(phone: phone, captcha: captcha, friendCode: friendCode);
  }

  /// 退出登录
  Future<HttpResultN> logout() async {
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.logout,
      jsonParam: {},
      paramEncrypt: false,
    );
    return result;
  }

  /// 注销账号
  Future<HttpResultN> cancelAccount({required String captcha}) async {
    final params = {"captcha": captcha};
    final result = await HttpManagerN.instance.executePost(
      "/logout", // 注销API路径
      jsonParam: params,
      paramEncrypt: false,
    );
    return result;
  }

  /// 更换手机号
  Future<HttpResultN> changePhone({
    required String phone,
    required String captcha,
  }) async {
    final params = {"phone": phone, "captcha": captcha};
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.changePhone,
      jsonParam: params,
      paramEncrypt: false,
    );
    return result;
  }

  /// 更新用户信息
  Future<HttpResultN> updateUserInfo({
    String? nickname,
    String? headPortrait,
    int? gender,
    String? birthday,
    String? loveTime,
  }) async {
    final params = <String, dynamic>{};
    if (nickname != null) params['nickname'] = nickname;
    if (headPortrait != null) params['head_portrait'] = headPortrait;
    if (gender != null) params['gender'] = gender;
    if (birthday != null) params['birthday'] = birthday;
    if (loveTime != null) params['love_time'] = loveTime;

    final result = await HttpManagerN.instance.executePost(
      ApiRequest.updateUserInfo,
      jsonParam: params,
      paramEncrypt: false,
    );
    return result;
  }

  /// 获取用户信息
  Future<HttpResultN<LoginModel>> getUserInfo() async {
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.getUserInfo,
      paramEncrypt: false,
    );

    if (result.isSuccess) {
      return result.convert(data: LoginModel.fromJson(result.getDataJson()));
    } else {
      return result.convert();
    }
  }

  /// 绑定另一半
  Future<HttpResultN> bindPartner({required String friendCode}) async {
    final params = {"friend_code": friendCode};
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.bindPartner,
      jsonParam: params,
      paramEncrypt: false,
    );
    return result;
  }

  /// 解除关系
  Future<HttpResultN> unbindPartner() async {
    final result = await HttpManagerN.instance.executePost(
      "/unbind",
      jsonParam: {},
      paramEncrypt: false,
    );
    return result;
  }
}
