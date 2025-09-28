import 'package:get/get.dart';
import 'share_controller.dart';

class ShareBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShareController>(() => ShareController());
  }
}
