import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/chat/chat_controller.dart';
import 'package:kissu_app/pages/chat/widgets/chat_message_item.dart';
import 'package:kissu_app/pages/chat/widgets/chat_input_bar.dart';
import 'package:kissu_app/pages/chat/widgets/chat_emoji_panel.dart';
import 'package:kissu_app/pages/chat/widgets/chat_extension_panel.dart';
import 'package:kissu_app/pages/chat/widgets/chat_voice_recorder.dart';
import 'package:kissu_app/pages/chat/widgets/chat_more_menu.dart';

class ChatPage extends GetView<ChatController> {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFDF6F1),
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // 主体内容区域
          Column(
            children: [
              // 消息列表
              Expanded(
                child: _buildMessageList(),
              ),

              // 输入栏
              Obx(() => ChatInputBar(
                    onSendText: controller.sendTextMessage,
                    onVoicePressed: controller.startVoiceRecording,
                    onVoiceReleased: controller.stopVoiceRecording,
                    onVoiceCancelled: controller.cancelVoiceRecording,
                    onVoiceCancelStateChanged: controller.updateVoiceCancelState,
                    onEmojiTap: controller.toggleEmojiPanel,
                    onExtensionTap: controller.toggleExtensionPanel,
                    showEmojiPanel: controller.showEmojiPanel.value,
                    showExtensionPanel: controller.showExtensionPanel.value,
                    focusNode: controller.inputFocusNode,
                    isRecording: controller.isVoiceRecording.value,
                  )),

              // 表情面板
              Obx(() => controller.showEmojiPanel.value
                  ? ChatEmojiPanel(
                      onEmojiSelected: controller.sendEmoji,
                      onVipEmojiSelected: controller.sendVipEmoji,
                      isVip: controller.isVip.value,
                    )
                  : const SizedBox.shrink()),

              // 扩展功能面板
              Obx(() => controller.showExtensionPanel.value
                  ? ChatExtensionPanel(
                      onItemTap: controller.handleExtensionAction,
                    )
                  : const SizedBox.shrink()),
            ],
          ),

          // 语音录制浮层
          Obx(() => ChatVoiceRecorder(
                isRecording: controller.isVoiceRecording.value,
                isCanceling: controller.isVoiceCanceling.value,
              )),
        ],
      ),
    );
  }

  // 顶部导航栏
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Colors.black,
          size: 20,
        ),
        onPressed: () => Get.back(),
      ),
      title: Obx(() => Text(
            controller.chatName.value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          )),
      actions: [
        // 更多菜单按钮
        IconButton(
          icon: const Icon(
            Icons.more_horiz,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () => _showMoreMenu(context),
        ),
      ],
    );
  }

  // 消息列表
  Widget _buildMessageList() {
    return GestureDetector(
      onTap: () => controller.hideAllPanels(),
      child: Obx(() {
        if (controller.messages.isEmpty) {
          return const Center(
            child: Text(
              '暂无消息',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          );
        }

        return Container(
          decoration: controller.backgroundImage.value.isNotEmpty
              ? BoxDecoration(
                  image: DecorationImage(
                    image: _getBackgroundImageProvider(controller.backgroundImage.value),
                    fit: BoxFit.cover,
                  ),
                )
              : null,
          child: ListView.builder(
            controller: controller.scrollController,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: controller.messages.length,
            itemBuilder: (context, index) {
              final message = controller.messages[index];
              return ChatMessageItem(
                message: message,
                onLongPress: () => _showMessageActions(message),
              );
            },
          ),
        );
      }),
    );
  }

  // 获取背景图片提供器（支持资产图片和文件图片）
  ImageProvider _getBackgroundImageProvider(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  // 显示更多菜单
  void _showMoreMenu(BuildContext context) {
    // 获取按钮位置
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    // 获取按钮在屏幕上的位置
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonSize = button.size;
    
    // 计算菜单显示位置：在按钮右下方
    ChatMoreMenu.show(
      context,
      position: Offset(
        buttonPosition.dx + buttonSize.width, // 右对齐到按钮右边
        buttonPosition.dy + buttonSize.height + 4, // 按钮下方，留4像素间隙
      ),
      onItemTap: controller.handleMoreMenuAction,
    );
  }

  // 显示消息操作菜单
  void _showMessageActions(ChatMessage message) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('复制'),
                onTap: () {
                  Get.back();
                  // TODO: 复制消息内容
                },
              ),
              if (!message.isSent)
                ListTile(
                  leading: const Icon(Icons.reply),
                  title: const Text('回复'),
                  onTap: () {
                    Get.back();
                    // TODO: 回复消息
                  },
                ),
              if (message.isSent)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('删除', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Get.back();
                    controller.messages.remove(message);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
