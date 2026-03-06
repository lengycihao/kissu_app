import 'package:get/get.dart';
import 'lock_screen_controller.dart';

class LockScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LockScreenController>(() => LockScreenController());
  }
}
