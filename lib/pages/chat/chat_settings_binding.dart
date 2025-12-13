import 'package:get/get.dart';
import 'package:kissu_app/pages/chat/chat_settings_controller.dart';

class ChatSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatSettingsController>(() => ChatSettingsController());
  }
}

