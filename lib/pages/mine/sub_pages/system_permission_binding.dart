import 'package:get/get.dart';
import 'system_permission_controller.dart';

/// 系统权限页面绑定
class SystemPermissionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SystemPermissionController>(() => SystemPermissionController());
  }
}
