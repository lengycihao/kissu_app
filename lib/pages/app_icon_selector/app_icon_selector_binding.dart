import 'package:get/get.dart';
import 'app_icon_selector_controller.dart';

class AppIconSelectorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppIconSelectorController>(() => AppIconSelectorController());
  }
}
