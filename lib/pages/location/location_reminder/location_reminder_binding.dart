import 'package:get/get.dart';
import 'package:kissu_app/pages/location/location_reminder/location_reminder_controller.dart';

/// 位置提醒页面的依赖注入绑定
/// 
/// 性能优化：
/// - 使用 lazyPut 延迟创建 Controller
/// - fenix: false 确保页面关闭后完全销毁，避免内存泄漏
class LocationReminderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocationReminderController>(
      () => LocationReminderController(),
      fenix: false, // 页面关闭后不复活，完全销毁
    );
  }
}

