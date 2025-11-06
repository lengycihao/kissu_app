import 'package:get/get.dart';
import 'device_usage_controller.dart';

/// 用机记录页面绑定
class DeviceUsageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeviceUsageController>(() => DeviceUsageController());
  }
}

