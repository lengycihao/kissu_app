/// 应用第三方SDK及服务常量配置
/// 所有第三方 API Key、AppID、密钥等集中管理
class AppConstants {
  AppConstants._();

  // ==================== 应用基础信息 ====================
  static const String packageName = 'com.yuluo.kissu';

  // ==================== 友盟 ====================
  static const String umengAppKey = '6879fba679267e0210b67bde';
  static const String umengChannel = 'umengshare';

  // ==================== 微信 ====================
  static const String weChatAppId = 'wxca15128b8c388c13';
  static const String weChatUniversalLink = 'https://ulink.ikissu.cn/';
  static const String weChatFileProvider = '$packageName.fileprovider';

  // ==================== QQ ====================
  static const String qqAppKey = '102797447';
  static const String qqAppSecret = 'c5KJ2VipiMRMCpJf';

  // ==================== 腾讯IM ====================
  static const int tencentIMSdkAppID = 1600095370;
  static const String tencentIMPushAppKey =
      '4M2JkNNiZkZslXJyw0YsmudcMw42THgiRtSud5H5iTRsT3GuHEXhQnzlQaYkjPrp';

  // ==================== 高德地图 ====================
  static const String amapApiKey = '7623ef33c6617f0c00aceca537b97516';

  // ==================== API 签名 ====================
  static const String apiSignatureSecretKey = 'TYXHTRrGeP8xy095q0iY';

  // ==================== 分享默认链接 ====================
  static const String defaultSharePage =
      'https://www.ikissu.cn/share/matchingcode.html';
  static const String defaultSharePageDev =
      'http://devweb.ikissu.cn/share/couplesdeFecating.html';

  // ==================== 第三方信息共享页 ====================
  static const String thirdPartySharingUrl =
      'https://www.ikissu.cn/agreement/thirdPartyShare.html';
}
