import 'package:get/get.dart';
import 'check_in_188_card_log_controller.dart';

/// 补签卡日志页面绑定
class CheckIn188CardLogBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CheckIn188CardLogController>(
      () => CheckIn188CardLogController(),
    );
  }
}
