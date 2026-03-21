import 'package:kissu_app/model/login_model/login_model.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/api_request.dart';
import 'package:kissu_app/network/interceptor/http_header_key.dart';
import 'package:kissu_app/model/unbind_reason_model.dart';

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

  /// 同步授权应用（首页进入时调用）
  Future<HttpResultN> syncAuthApp() async {
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.syncAuthApp,
      jsonParam: const {},
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
      final dataJson = result.getDataJson();
      // 检查数据是否有效（不为空且包含必要字段）
      if (dataJson.isNotEmpty &&
          dataJson.containsKey('id') &&
          dataJson['id'] != null) {
        return result.convert(data: LoginModel.fromJson(dataJson));
      } else {
        // 数据无效，返回失败结果
        return HttpResultN.failure(-1, '用户数据无效或为空');
      }
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

  /// 获取解绑原因列表
  /// 返回的数据结构是数组，不是包含 list 的对象
  Future<HttpResultN<UnbindReasonModel>> getUnbindReasons() async {
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.unbindReasonSelect,
      paramEncrypt: false,
    );

    if (result.isSuccess) {
      // 优先从 listJson 取数据（HttpManagerN 对纯数组响应会写到 listJson）
      List<dynamic> listJson = result.getListJson();

      // 如果 listJson 为空，再从 dataJson 中做兼容处理
      if (listJson.isEmpty) {
        final rawData = result.getDataDynamic();

        if (rawData is List) {
          // 如果返回的是数组（新格式）
          listJson = rawData;
        } else if (rawData is Map<String, dynamic>) {
          // 兼容旧格式：包含 list 字段的对象
          if (rawData.containsKey('list') && rawData['list'] != null) {
            listJson = rawData['list'] as List<dynamic>;
          } else {
            return HttpResultN<UnbindReasonModel>.failure(
              -1,
              '数据格式错误：未找到原因列表',
            );
          }
        } else {
          return HttpResultN<UnbindReasonModel>.failure(
            -1,
            '数据格式错误：未找到原因列表',
          );
        }
      }
      
      final reasons = listJson
          .map((e) => UnbindReasonModel.fromJson(e as Map<String, dynamic>))
          .toList();
      
      return HttpResultN<UnbindReasonModel>.success(
        dataList: reasons,
        code: result.code,
        msg: result.msg,
        listJson: listJson,
      );
    }

    return HttpResultN<UnbindReasonModel>.failure(
      result.code,
      result.msg ?? '获取解绑原因列表失败',
    );
  }

  /// 解除关系
  Future<HttpResultN> unbindPartner({
    required int reasonId,
    String? supplementReason,
  }) async {
    final params = <String, dynamic>{'reason_id': reasonId};
    if (supplementReason != null && supplementReason.isNotEmpty) {
      params['supplement_reason'] = supplementReason;
    }

    final result = await HttpManagerN.instance.executePost(
      ApiRequest.unbind,
      jsonParam: params,
      paramEncrypt: false,
    );
    return result;
  }

  /// App启动接口
  /// [androidId] Android ID（Settings.Secure.ANDROID_ID），用于巨量引擎归因
  Future<HttpResultN> appStart({String? androidId}) async {
    final Map<String, String> extraHeaders = {};
    if (androidId != null && androidId.isNotEmpty) {
      extraHeaders[HttpHeaderKey.androidId] = androidId;
    }
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.appStart,
      jsonParam: {},
      headers: extraHeaders.isNotEmpty ? extraHeaders : null,
      paramEncrypt: false,
    );
    return result;
  }
 
}
