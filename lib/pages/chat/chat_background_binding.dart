import 'package:get/get.dart';
import 'package:kissu_app/pages/chat/chat_background_controller.dart';

class ChatBackgroundBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatBackgroundController>(() => ChatBackgroundController());
  }
}

