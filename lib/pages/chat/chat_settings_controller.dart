import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/pages/chat/chat_controller.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/tencent_im_service.dart';
import 'package:kissu_app/utils/oktoast_util.dart';

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

  // 保存昵称（备注），并同步到腾讯 IM 资料
  Future<void> saveNickname() async {
    final newName = nicknameController.text.trim();
    if (newName.isNotEmpty && newName != currentNickname.value) {
      final partnerId = chatController.partnerImId;
      if (partnerId == null || partnerId.isEmpty) {
        logDebug('更新腾讯 IM 备注失败: 无法获取聊天对象ID');
        return;
      }

      try {
        final im = TencentIMService.instance;
        if (im.isInitialized && im.isLoggedIn) {
          // 设置好友备注，而不是自己的昵称
          final success = await im.setFriendRemark(partnerId, newName);
          if (success) {
            currentNickname.value = newName;
            // 同步更新聊天页面的昵称显示
            chatController.chatName.value = newName;
            logDebug('更新腾讯 IM 备注成功: $newName');
          } else {
            logDebug('更新腾讯 IM 备注失败: SDK 返回失败');
          }
        }
      } catch (e) {
        logError('更新腾讯 IM 备注失败: $e');
      }
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

  // 设置自动报备消息 - 跳转到IM通知设置页面
  void setSensitiveInfo() {
    Get.toNamed(KissuRoutePath.imNotificationSettings);
  }

    // 设置聊天主题 - 跳转到主题选择页面
    void setChatTheme() {
      Get.toNamed(KissuRoutePath.chatTheme);
    }

    // 举报对方 - 跳转到举报页面
    void reportPartner() {
      OKToastUtil.showSuccess('举报成功');
    }
}

