import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/chat/chat_controller.dart';
import 'package:kissu_app/pages/chat/widgets/chat_message_item.dart';
import 'package:kissu_app/pages/chat/widgets/image_preview_page.dart';

/// 聊天消息列表区域，只负责列表渲染
class ChatMessageListView extends StatelessWidget {
  const ChatMessageListView({
    super.key,
    required this.controller,
  });

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 🔥 修复：添加behavior确保点击空白处也能触发onTap，收起键盘
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.hideAllPanels(),
      child: Obx(() {
        final messages = controller.messages;
        
        // 使用reverse:true，新消息自动出现在底部，加载历史不跳动
        // 数据按时间正序存储，渲染时反向取
        // 使用Align让消息少时从顶部开始显示
        return Align(
          alignment: Alignment.topCenter,
          child: ListView.builder(
            controller: controller.scrollController,
            reverse: true,
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: messages.length,
            itemBuilder: (context, index) {
            // reverse:true时，index=0是列表底部（最新消息）
            // 数据按时间正序存储，所以要反向取
            final reverseIndex = messages.length - 1 - index;
            final message = messages[reverseIndex];

            // 通用时间显示规则由 ChatController 统一管理
            bool showTimestamp = controller.shouldShowTimestampForIndex(reverseIndex);

            // 对于 systemEvent 类型，再加一条去重规则：
            // 如果前一条也是 systemEvent 且时间相同（精确到分钟），则不重复显示
            if (message.type == MessageType.systemEvent && reverseIndex > 0) {
              final prevMessage = messages[reverseIndex - 1];
              if (prevMessage.type == MessageType.systemEvent) {
                final currentTimeFloorToMinute = DateTime(
                  message.time.year,
                  message.time.month,
                  message.time.day,
                  message.time.hour,
                  message.time.minute,
                );
                final prevTimeFloorToMinute = DateTime(
                  prevMessage.time.year,
                  prevMessage.time.month,
                  prevMessage.time.day,
                  prevMessage.time.hour,
                  prevMessage.time.minute,
                );
                if (currentTimeFloorToMinute == prevTimeFloorToMinute) {
                  showTimestamp = false;
                }
              }
            }

            return ChatMessageItem(
              message: message,
              onLongPress: null,
              showTimestamp: showTimestamp,
              onImageTap: (msg) {
                _openImageGallery(context, controller, msg);
              },
            );
          },
          ),
        );
      }),
    );
  }

}

// 打开图片预览画廊（支持左右滑动查看当前会话中的所有图片消息）
void _openImageGallery(
  BuildContext context,
  ChatController controller,
  ChatMessage targetMessage,
) {
  // 收集当前会话中所有的图片消息（按照时间顺序）
  final imageMessages = controller.messages
      .where((m) => m.type == MessageType.image && m.imageUrl != null)
      .toList();

  if (imageMessages.isEmpty) return;

  // 找到当前点击图片在图片消息列表中的索引
  final initialIndex =
      imageMessages.indexWhere((m) => m.id == targetMessage.id);
  if (initialIndex < 0) return;

  final imageUrls = imageMessages.map((m) => m.imageUrl!).toList();

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ImagePreviewPage(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
      ),
      fullscreenDialog: true,
    ),
  );
}


