class AppConfigN {
  /// 服务环境
  /// 测试环境:true
  /// 生产环境:false
  static const serverEnvironmentTest = false;


  // 生产环境加密，测试环境不加密
  static bool get apiEncrypt => !serverEnvironmentTest;


  // /// 域名
  static late final String baseApiUrl;
  static bool _isConfigured = false; // 🔒 添加配置标志，防止重复初始化

  static Future configuration({String urlType = 'test'}) async {
    // 🔒 如果已经配置过，直接返回
    if (_isConfigured) {
      return;
    }
    
    // ossBucketName = "yvoice-app";
    // baseWebUrl = 'https://protocol.syyimeng.com';
    // appChannel = const int.fromEnvironment('app_channel', defaultValue: 0);
    // abiFilters = const String.fromEnvironment('abiFilters', defaultValue: '');
    // PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // appVersion = packageInfo.version;

    // 根据环境配置 API 地址
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
