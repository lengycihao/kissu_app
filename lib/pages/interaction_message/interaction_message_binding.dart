import 'package:get/get.dart';
import 'interaction_message_controller.dart';

class InteractionMessageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InteractionMessageController>(() => InteractionMessageController());
  }
}

