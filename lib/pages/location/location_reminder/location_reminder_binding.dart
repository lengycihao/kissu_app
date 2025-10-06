import 'package:get/get.dart';
import 'package:kissu_app/pages/location/location_reminder/location_reminder_controller.dart';

/// 位置提醒Binding
class LocationReminderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocationReminderController>(() => LocationReminderController());
  }
}

