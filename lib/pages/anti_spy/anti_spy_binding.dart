import 'package:get/get.dart';
import 'anti_spy_controller.dart';

class AntiSpyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AntiSpyController>(() => AntiSpyController());
  }
}
