import 'package:get/get.dart';
import 'app_usage_detail_controller.dart';

/// App使用记录详情页面绑定
class AppUsageDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppUsageDetailController>(() => AppUsageDetailController());
  }
}

