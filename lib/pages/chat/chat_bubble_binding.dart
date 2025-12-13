import 'package:get/get.dart';
import 'package:kissu_app/pages/chat/chat_bubble_controller.dart';

class ChatBubbleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatBubbleController>(() => ChatBubbleController());
  }
}

