class AppConfigN {
  /// 服务环境
  /// 测试环境:true
  /// 生产环境: 
  static const serverEnvironmentTest = false;

  /// 🔥 打包渠道（打包时在这里统一修改）
  /// kissu_xiaomi  kissu_huawei  kissu_rongyao
  /// kissu_vivo  kissu_oppo  kissu_meizu
  /// kissu_yyb  kissu_wdj  kissu_douyin   kissu_default
  static const String appChannel = 'kissu_huawei';
  


  // 生产环境加密，测试环境不加密
  static bool get apiEncrypt => !serverEnvironmentTest;


  // /// 配置
  static late final String baseApiUrl;
  static bool _isConfigured = false; // 🔥 配置标志防止重复初始化

  static Future configuration({String urlType = 'test'}) async {
    // 🔥 已经配置过直接返回
    if (_isConfigured) {
      return;
    }
    
    // ossBucketName = "yvoice-app";
    // baseWebUrl = 'https://protocol.syyimeng.com';
    // appChannel = const int.fromEnvironment('app_channel', defaultValue: 0);
    // abiFilters = const String.fromEnvironment('abiFilters', defaultValue: '');
    // PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // appVersion = packageInfo.version;

    // 根据环境 API 地址
    if (serverEnvironmentTest) {
      // 测试环境
      baseApiUrl = "http://dev-love-api.ikissu.cn";
    } else {
      // 生产环境（使用 HTTPS）
      baseApiUrl = "https://service-api.ikissu.cn";
    }
    
    _isConfigured = true; // 标记为已配置
  }

}