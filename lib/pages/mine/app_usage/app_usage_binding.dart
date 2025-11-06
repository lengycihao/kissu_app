import 'package:get/get.dart';
import 'app_usage_controller.dart';

/// App使用时长绑定
class AppUsageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppUsageController>(() => AppUsageController());
  }
}






