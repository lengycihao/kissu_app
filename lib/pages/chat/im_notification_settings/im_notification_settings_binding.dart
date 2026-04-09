import 'package:get/get.dart';
import 'im_notification_settings_controller.dart';

/// IM通知设置页面绑定
class ImNotificationSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ImNotificationSettingsController>(
      () => ImNotificationSettingsController(),
    );
  }
}

