import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/chat/chat_controller.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';

class ChatSettingsController extends GetxController {
  // 获取聊天控制器实例
  late ChatController chatController;

  // 当前昵称
  final RxString currentNickname = '你是毛毛'.obs;
  
  // 是否正在编辑昵称
  final RxBool isEditingNickname = false.obs;
  
  // 昵称编辑控制器
  final TextEditingController nicknameController = TextEditingController();
  final FocusNode nicknameFocusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    // 获取聊天控制器实例
    chatController = Get.find<ChatController>();
    // 初始化昵称
    currentNickname.value = chatController.chatName.value;
    nicknameController.text = currentNickname.value;
    
    // 监听焦点变化
    nicknameFocusNode.addListener(() {
      if (!nicknameFocusNode.hasFocus && isEditingNickname.value) {
        // 失去焦点时保存
        saveNickname();
      }
    });
  }

  @override
  void onClose() {
    nicknameController.dispose();
    nicknameFocusNode.dispose();
    super.onClose();
  }

  // 开始编辑昵称
  void startEditNickname() {
    isEditingNickname.value = true;
    nicknameController.text = currentNickname.value;
    // 延迟聚焦，确保TextField已经渲染
    Future.delayed(const Duration(milliseconds: 100), () {
      nicknameFocusNode.requestFocus();
      // 选中所有文本
      nicknameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: nicknameController.text.length,
      );
    });
  }

  // 保存昵称
  void saveNickname() {
    final newName = nicknameController.text.trim();
    if (newName.isNotEmpty && newName != currentNickname.value) {
      currentNickname.value = newName;
      // 同步更新聊天页面的昵称
      chatController.chatName.value = newName;
    }
    isEditingNickname.value = false;
  }

  // 修改昵称（点击时触发编辑）
  void editNickname() {
    if (!isEditingNickname.value) {
      startEditNickname();
    }
  }

  // 设置聊天背景 - 跳转到背景选择页面
  void setChatBackground() {
    Get.toNamed(KissuRoutePath.chatBackground);
  }

  // 设置聊天气泡 - 跳转到气泡选择页面
  void setChatBubbles() {
    Get.toNamed(KissuRoutePath.chatBubble);
  }

  // 设置敏感信息 - 跳转到推送设置页面，标题为"敏感信息"
  void setSensitiveInfo() {
    Get.toNamed(
      KissuRoutePath.notificationSettings,
      arguments: {'title': '敏感信息'},
    );
  }

  // 设置聊天主题 - 跳转到主题选择页面
  void setChatTheme() {
    Get.toNamed(KissuRoutePath.chatTheme);
  }
}

