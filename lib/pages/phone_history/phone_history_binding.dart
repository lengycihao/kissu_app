import 'package:get/get.dart';
import 'phone_history_controller.dart';

class PhoneHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PhoneHistoryController>(() => PhoneHistoryController());
  }
}
