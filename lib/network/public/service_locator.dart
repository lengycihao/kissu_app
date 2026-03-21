import 'package:get_it/get_it.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
final GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ✅ 注册 AuthService 单例run
  final authService = AuthService();
  getIt.registerSingleton<AuthService>(authService);

  // 初始化 AuthService
  await authService.init();

  // 🔒 隐私合规：SensitiveDataService 移到 main.dart 统一管理，避免重复初始化
  // final sensitiveDataService = SensitiveDataService();
  // getIt.registerSingleton<SensitiveDataService>(sensitiveDataService);

  // HomeScrollService 已移至 GetX 管理，不再通过 service locator 注册

  // logger.info('Service locator setup completed', tag: 'ServiceLocator');
}

/// Clean up all registered services
Future<void> cleanupServiceLocator() async {
  // logger.info('Cleaning up service locator', tag: 'ServiceLocator');

  // Reset GetIt instance
  await getIt.reset();

  // logger.info('Service locator cleanup completed', tag: 'ServiceLocator');
}

/// Convenience methods for common service access
extension ServiceLocatorExtensions on GetIt {
  // Business services
  AuthService get authService => get<AuthService>();
  // SensitiveDataService 已移到 GetX 管理，不再通过 service locator 访问
  // SensitiveDataService get sensitiveDataService => get<SensitiveDataService>();
  // HomeScrollService 已移到 GetX 管理，不再通过 service locator 访问
  // HomeScrollService get homeScrollService => get<HomeScrollService>();
}
