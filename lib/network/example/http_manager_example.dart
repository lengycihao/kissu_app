import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/public/service_locator.dart';

/// HTTP 管理器初始化示例
/// 展示如何正确配置业务请求头
class HttpManagerExample {
  
  /// 初始化网络管理器
  static Future<void> initializeHttpManager() async {
    // 从 GetIt 获取已注册并初始化好的 AuthService 实例
    final authService = getIt<AuthService>();
    
    // 初始化 HTTP 管理器，启用业务请求头
    HttpManagerN.instance.init(
      'http://dev-love-api.ikissu.cn', // 替换为实际的 API 基础 URL
      authService: authService, // 传入 AuthService 实例
      enableBusinessHeaders: true, // 启用业务请求头
      enableCache: true,
      enableDebounce: true,
      enableEncryption: false, // 根据需要开启加密
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    );
  }
  
  /// 示例：发送带有自动业务请求头的 GET 请求
  static Future<void> exampleGetRequest() async {
    final result = await HttpManagerN.instance.executeGet(
      '/api/user/profile',
      queryParam: {'id': '123'},
    );
    
    if (result.isSuccess) {
      print('请求成功: ${result.dataJson}');
    } else {
      print('请求失败: ${result.msg}');
    }
  }
  
  /// 示例：发送带有自动业务请求头的 POST 请求
  static Future<void> examplePostRequest() async {
    final result = await HttpManagerN.instance.executePost(
      '/api/user/update',
      jsonParam: {
        'name': '张三',
        'age': 25,
      },
    );
    
    if (result.isSuccess) {
      print('更新成功: ${result.dataJson}');
    } else {
      print('更新失败: ${result.msg}');
    }
  }
}

/// 使用示例
/// 
/// 在 main.dart 中调用：
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // 初始化网络管理器
///   await HttpManagerExample.initializeHttpManager();
///   
///   runApp(MyApp());
/// }
/// ```
/// 
/// 在任何需要发送请求的地方调用：
/// ```dart
/// // 自动添加了以下请求头：
/// // - token: 用户登录后的 token（如果已登录）
/// // - sign: 请求签名
/// // - version: 应用版本号
/// // - channel: 渠道（android/ios）
/// // - pkg: 包名
/// // - network-name: 网络名称
/// // - deviceid: 设备ID
/// // - mobile-model: 手机型号
/// // - power: 电量信息
/// // - brand: 品牌信息
/// 
/// await HttpManagerExample.exampleGetRequest();
/// await HttpManagerExample.examplePostRequest();
/// ```
