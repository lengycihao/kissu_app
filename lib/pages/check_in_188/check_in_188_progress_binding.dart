import 'package:get/get.dart';
import 'check_in_188_progress_controller.dart';

/// 188打卡进行中页面绑定
class CheckIn188ProgressBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CheckIn188ProgressController>(() => CheckIn188ProgressController());
  }
}
