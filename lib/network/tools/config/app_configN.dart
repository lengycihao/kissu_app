
class AppConfigN {
  /// 服务环境
  /// 测试环境:true
  /// 生产环境:false
  static const serverEnvironmentTest = true;

  /// api 加密开关
  /// 仅测试渠道可关闭api加密
  // static const _apiEncrypt = true;
  // static bool get apiEncrypt => appChannel != 0 || _apiEncrypt;

  // 生产环境加密，测试环境不加密
  static bool get apiEncrypt => !serverEnvironmentTest;

  /// 渠道
  /// 0 内部测试
  /// 1 苹果
  /// 2 小米
  /// 3 华为
  /// 4 VIVO
  /// 5 OPPO
  /// 6 荣耀
  /// 7 应用宝
  /// 8 官网
  // static late final int appChannel;

  // /// CPU架构
  // static late final String abiFilters;

  // /// 版本号
  // static late final String appVersion;

  // /// 域名
  static late final String baseApiUrl;
  // static late final String baseWsUrl;
  // static late final String baseWebUrl;
  // static late final String baseH5Url;

  // // zego参数
  // static late final int zegoAppId;
  // static late final String zegoAppSign;

  // // oss
  // static late final String ossBucketName;

  // // api encrypt key pair
  // static const apiAesKey1 = 'M9rA0ehv1A';
  // static const apiAesKey2 = 'JgczDtgkvoA';

  // // app build time
  // static const appBuildTime = '';
  // static const appleStoreId = '6742088748';

  static Future configuration({String urlType = 'test'}) async {
    // ossBucketName = "yvoice-app";
    // baseWebUrl = 'https://protocol.syyimeng.com';
    // appChannel = const int.fromEnvironment('app_channel', defaultValue: 0);
    // abiFilters = const String.fromEnvironment('abiFilters', defaultValue: '');
    // PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // appVersion = packageInfo.version;

    baseApiUrl = "http://129.204.154.113";
  }

  ///
  /// h5 url

  // // 用户服务协议
  // static String userServiceDescription =
  //     "$baseWebUrl/userServiceDescription.html";

  // // 隐私政策
  // static String privacyPolicy = "$baseWebUrl/privacyPolicy.html";

  // // 云顶币充值协议
  // static String coinRechargeAgreement =
  //     "$baseWebUrl/coinRechargeAgreement.html";

  // // 个人信息收集类型
  // static String personalInformationCollection =
  //     "$baseWebUrl/personalInformationCollection.html";

  // // 应用权限说明
  // static String applicationPermissionsDescription =
  //     "$baseWebUrl/applicationPermissionsDescription.html";

  // // 信息发布规范
  // static String informationReleaseStandards =
  //     "$baseWebUrl/informationReleaseStandards.html";

  // // 隐私保护指引
  // static String privacyProtectionGuidelines =
  //     "$baseWebUrl/privacyProtectionGuidelines.html";

  // // 未成年人隐私保护协议
  // static String teenagersPrivacyAgreement =
  //     "$baseWebUrl/teenagersPrivacyAgreement.html";

  // //用户注销协议
  // static String accountCancellation = '$baseWebUrl/accountCancellation.html';

  // //人脸验证服务协议
  // static String faceRecognition = '$baseWebUrl/faceRecognition.html';
}
