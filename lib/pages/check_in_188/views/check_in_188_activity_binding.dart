 import 'package:kissu_app/pages/check_in_188/views/check_in_188_activity_controller.dart';
import 'package:get/get.dart';

class CheckIn188ActivityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CheckIn188ActivityController>(
      () => CheckIn188ActivityController(),
    );
  }
}
