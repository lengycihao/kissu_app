import 'package:get/get.dart';
import 'package:kissu_app/pages/chat/chat_theme_controller.dart';

class ChatThemeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatThemeController>(() => ChatThemeController());
  }
}

