import 'package:get/get.dart';
import 'notification_settings_controller.dart';

/// 通知设置页面绑定
class NotificationSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationSettingsController>(
      () => NotificationSettingsController(),
    );
  }
}
