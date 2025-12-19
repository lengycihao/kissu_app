import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/chat/chat_controller.dart';
import 'package:kissu_app/pages/chat/widgets/chat_message_item.dart';
import 'package:kissu_app/pages/chat/widgets/chat_message_action_bubble.dart';
import 'package:kissu_app/services/tencent_im_service.dart';

/// 聊天消息列表区域，只负责列表渲染和长按菜单交互
class ChatMessageListView extends StatelessWidget {
  const ChatMessageListView({
    super.key,
    required this.controller,
  });

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.hideAllPanels(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Obx(() {
            // 参考 iOS 实现：当内容不足一屏时，计算需要的 padding
            // reverse: true 时，bottom padding 在视觉上的顶部
            final EdgeInsets padding;
            
            // 估算内容高度（每条消息平均约 60-80px，加上 padding）
            final estimatedContentHeight = controller.messages.length * 70.0 + 24.0;
            final viewportHeight = constraints.maxHeight;
            
            // 如果估算的内容高度小于视口高度（不足一屏）
            if (estimatedContentHeight < viewportHeight && controller.messages.length < 20) {
              // 计算需要的 bottom padding（在 reverse 模式下，bottom 在顶部）
              // 参考 iOS: topInset = tableViewHeight - contentHeight
              // Flutter reverse: bottomPadding = viewportHeight - estimatedContentHeight
              final bottomPadding = viewportHeight - estimatedContentHeight;
              padding = EdgeInsets.only(
                top: 12,
                bottom: bottomPadding > 0 ? bottomPadding : 12,
              );
            } else {
              padding = const EdgeInsets.symmetric(vertical: 12);
            }
            
            return ListView.builder(
              controller: controller.scrollController,
              reverse: true,
              padding: padding,
              itemCount: controller.messages.length,
              itemBuilder: (context, index) {
                // reverse:true 时，index=0 对应时间上最新的一条，需要反向取数据
                final reverseIndex = controller.messages.length - 1 - index;
                final message = controller.messages[reverseIndex];

                // 通用时间显示规则由 ChatController 统一管理
                bool showTimestamp =
                    controller.shouldShowTimestampForIndex(reverseIndex);

                // 对于 systemEvent 类型，再加一条去重规则：
                // 如果前一条也是 systemEvent 且时间相同（精确到分钟），则不重复显示
                if (message.type == MessageType.systemEvent && reverseIndex > 0) {
                  final prevMessage = controller.messages[reverseIndex - 1];
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

                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPressStart: (details) => _showMessageActions(
                      context, message, details.globalPosition),
                  child: ChatMessageItem(
                    message: message,
                    onLongPress: null,
                    showTimestamp: showTimestamp,
                    onImageTap: (msg) {
                      _openImageGallery(context, controller, msg);
                    },
                  ),
                );
              },
            );
          });
        },
      ),
    );
  }

  // 显示消息操作菜单（贴着气泡上方的小菜单）
  void _showMessageActions(
      BuildContext context, ChatMessage message, Offset globalPosition) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final overlaySize = overlay.size;

    final isSelf = message.isSent;
    final canCopy = message.type == MessageType.text;

    final menu = Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 半透明遮罩，点击关闭
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Get.back(),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.shrink(),
            ),
          ),
          // 顶部菜单气泡
          Positioned(
            left: isSelf ? null : 40,
            right: isSelf ? 16 : null,
            top: (globalPosition.dy - 80).clamp(80, overlaySize.height - 160),
            child: MessageActionBubble(
              canCopy: canCopy,
              canDelete: true,
              onCopy: () {
                Get.back();
                if (message.content.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: message.content));
                }
              },
              onDelete: () async {
                Get.back();
                final im = TencentIMService.instance;
                if (message.id.isNotEmpty) {
                  await im.deleteMessageFromLocal(msgID: message.id);
                }
                controller.messages.remove(message);
              },
            ),
          ),
        ],
      ),
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) => menu,
      ),
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


