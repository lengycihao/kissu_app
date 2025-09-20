import 'package:get_it/get_it.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
import 'package:kissu_app/services/sensitive_data_service.dart';
import 'package:kissu_app/services/home_scroll_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ✅ 注册 AuthService 单例run
  final authService = AuthService();
  getIt.registerSingleton<AuthService>(authService);

  // 初始化 AuthService
  await authService.init();

  // ✅ 注册 SensitiveDataService 单例
  final sensitiveDataService = SensitiveDataService();
  getIt.registerSingleton<SensitiveDataService>(sensitiveDataService);

  // ✅ 注册 HomeScrollService 单例
  final homeScrollService = HomeScrollService();
  getIt.registerSingleton<HomeScrollService>(homeScrollService);

  logger.info('Service locator setup completed', tag: 'ServiceLocator');
}

/// Clean up all registered services
Future<void> cleanupServiceLocator() async {
  logger.info('Cleaning up service locator', tag: 'ServiceLocator');

  // Reset GetIt instance
  await getIt.reset();

  logger.info('Service locator cleanup completed', tag: 'ServiceLocator');
}

/// Convenience methods for common service access
extension ServiceLocatorExtensions on GetIt {
  // Business services
  AuthService get authService => get<AuthService>();
  SensitiveDataService get sensitiveDataService => get<SensitiveDataService>();
  HomeScrollService get homeScrollService => get<HomeScrollService>();
}
