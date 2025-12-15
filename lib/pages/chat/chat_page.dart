import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:kissu_app/pages/chat/chat_controller.dart';
import 'package:kissu_app/pages/chat/widgets/chat_message_item.dart';
import 'package:kissu_app/pages/chat/widgets/chat_input_bar.dart';
import 'package:kissu_app/pages/chat/widgets/chat_emoji_panel.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/tencent_im_service.dart';

class ChatPage extends GetView<ChatController> {
  ChatPage({super.key});

  // 输入框的 GlobalKey，用于访问输入框的 state
  final GlobalKey<ChatInputBarState> _inputBarKey = GlobalKey<ChatInputBarState>();

  @override
  Widget build(BuildContext context) {
    // 获取键盘高度
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // 改为 false，我们手动处理键盘
      extendBodyBehindAppBar: true, // 让body延伸到AppBar后面
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // 背景层 - 覆盖整个屏幕包括导航栏区域
          Obx(() => controller.backgroundImage.value.isNotEmpty
              ? Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 80, // 底部留出约80像素，让背景稍微延伸到输入框下方，圆角区域能看到背景
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: _getBackgroundImageProvider(controller.backgroundImage.value),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink()),
          
          // 主体内容区域
          Column(
            children: [
              // 消息列表 - 使用 Obx 包裹以响应消息列表变化
              // 添加SafeArea确保消息列表从导航栏下方开始
              Expanded(
                child: SafeArea(
                  bottom: false, // 底部不使用SafeArea，因为我们有输入栏
                  child: Obx(() => _buildMessageList()),
                ),
              ),

              // 输入栏
              Obx(() => ChatInputBar(
                    key: _inputBarKey,
                    onSendText: controller.sendTextMessage,
                    onTyping: controller.notifyTyping,
                    onEmojiTap: controller.toggleEmojiPanel,
                    onAlbumTap: controller.onAlbumTap,
                    onCameraTap: controller.onCameraTap,
                    onLocationTap: controller.onLocationTap,
                    showEmojiPanel: controller.showEmojiPanel.value,
                    focusNode: controller.inputFocusNode,
                    themeButtonColor: controller.getThemeButtonColor(),
                  )),

              // 表情面板
              Obx(() => controller.showEmojiPanel.value
                  ? ChatEmojiPanel(
                      onEmojiSelected: (emoji) {
                        // 点击表情时，插入到输入框而不是直接发送
                        _inputBarKey.currentState?.insertEmoji(emoji);
                      },
                    )
                  : const SizedBox.shrink()),
              
              // 键盘占位空间 - 关键！这会像面板一样占据空间
              Obx(() => SizedBox(
                height: controller.showEmojiPanel.value ? 0 : keyboardHeight,
              )),
            ],
          ),

        ],
      ),
    );
  }

  // 顶部导航栏
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return PreferredSize(
      preferredSize: Size.fromHeight(65 + statusBarHeight), // 增加导航栏高度以容纳设备信息
      child: Container(
        padding: EdgeInsets.only(top: statusBarHeight,left: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xffcccccc),
              Color(0x00ffffff),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // 第一行：返回按钮、头像、昵称、设置按钮 - 横向对齐
            SizedBox(
              height: 56, // AppBar的标准高度
              child: Row(
                children: [
                  // 返回按钮
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.black,
                      size: 22,
                    ),
                    onPressed: () => Get.back(),
                  ),
                  // 另一半头像
                  Obx(() => Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                          image: controller.avatarUrl.value.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(controller.avatarUrl.value),
                                  fit: BoxFit.cover,
                                )
                              : const DecorationImage(
                                  image: AssetImage('assets/3.0/kissu3_love_avater.webp'),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      )),
                  const SizedBox(width: 10),
                  // 昵称 / 正在输入（二选一，同一字体样式）
                  Expanded(
                    child: Obx(() {
                      final typing = controller.isPartnerTyping.value;
                      final title = typing ? '对方正在输入…' : controller.chatName.value;
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xff333333),
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ),
                  // 设置按钮
                  IconButton(
                    icon: Image.asset('assets/chat/kissu_chat_setting.webp', width: 24, height: 24),
                    onPressed: () => Get.toNamed(KissuRoutePath.chatSettings),
                  ),
                ],
              ),
            ),
            // 第二行：设备信息模块
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: _buildDeviceInfoBar(),
            ),
          ],
        ),
      ),
    );
  }

  // 设备信息栏（使用敏感操作记录页面的样式，支持点击展开详情）
  Widget _buildDeviceInfoBar() {
    return Obx(() {
      final selectedType = controller.selectedDeviceInfoType.value;
      
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // 底部四个设备信息项
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            // mainAxisSize: MainAxisSize.min,
            children: [
              // 距离信息
              _buildDeviceInfoItem(
                icon: 'assets/phone_history/kissu_phone_distance.webp',
                text: '120km',
                maxLength: 6,
                type: 'distance',
              ),
              const SizedBox(width: 8),
              // 手机型号
              _buildDeviceInfoItem(
                icon: 'assets/phone_history/kissu_phone_type.webp',
                text: 'Iphone 15 Pro',
                maxLength: 6,
                type: 'mobileModel',
              ),
              const SizedBox(width: 8),
              // 网络信息
              _buildDeviceInfoItem(
                icon: 'assets/phone_history/kissu_phone_wifi.webp',
                text: 'Unknown',
                maxLength: 8,
                type: 'network',
              ),
              const SizedBox(width: 8),
              // 电量信息
              _buildDeviceInfoItem(
                icon: 'assets/phone_history/kissu_phone_barry.webp',
                text: '85%',
                maxLength: null,
                type: 'power',
              ),
            ],
          ),
          // 顶部悬浮黑色气泡样式详情（根据选中项浮在对应图标正上方）
          if (selectedType != null)
            _buildDeviceInfoTooltip(selectedType),
        ],
      );
    });
  }

  // 构建设备信息项（使用敏感操作记录页面的样式，支持点击展开）
  Widget _buildDeviceInfoItem({
    required String icon,
    required String text,
    int? maxLength,
    required String type,
  }) {
    final displayText = maxLength != null && text.length > maxLength
        ? '${text.substring(0, maxLength)}...'
        : text;

    return Obx(() {
      final selectedType = controller.selectedDeviceInfoType.value;
      final isSelected = selectedType == type;

      return GestureDetector(
        onTap: () => controller.toggleDeviceInfo(type),
        child: Container(
          constraints: const BoxConstraints(minWidth: 50),
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'device_info_icon_$type',
                child: Image.asset(icon, width: 16, height: 16),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Hero(
                  tag: 'device_info_content_$type',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF333333),
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // 构建设备信息悬浮气泡（黑色背景 + 小三角），浮在对应图标正上方
  Widget _buildDeviceInfoTooltip(String type) {
    String content;
    switch (type) {
      case 'distance':
        content = '120km';
        break;
      case 'mobileModel':
        content = 'Iphone 15 Pro';
        break;
      case 'network':
        content = 'Unknown';
        break;
      case 'power':
        content = '85%';
        break;
      default:
        content = '';
        break;
    }

    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    // 使用与底部完全相同的 Row 结构，保证对齐
    Widget buildBubble(String bubbleType, String bubbleText) {
      if (bubbleType != type || bubbleText.isEmpty) {
        return const SizedBox.shrink();
      }
      // 在这一列内部居中，气泡的三角正对下面图标的中心
      return Align(
        alignment: Alignment.center,
        child: _DeviceInfoTooltipBubble(text: bubbleText),
      );
    }

    return Positioned(
      top: -40,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: buildBubble('distance', '120km')),
            const SizedBox(width: 8),
            Expanded(child: buildBubble('mobileModel', 'Iphone 15 Pro')),
            const SizedBox(width: 8),
            Expanded(child: buildBubble('network', 'Unknown')),
            const SizedBox(width: 8),
            Expanded(child: buildBubble('power', '85%')),
          ],
        ),
      ),
    );
  }

  // 消息列表
  Widget _buildMessageList() {
    return GestureDetector(
      onTap: () => controller.hideAllPanels(),
      child: ListView.builder(
        controller: controller.scrollController,
        reverse: true,
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: controller.messages.length,
        itemBuilder: (context, index) {
          // reverse:true 时，index=0 对应时间上最新的一条，需要反向取数据
          final reverseIndex = controller.messages.length - 1 - index;
          final message = controller.messages[reverseIndex];

          // 通用时间显示规则（按时间顺序的索引计算）：
          // 1）第一条消息一定显示时间
          // 2）与上一条不在同一天：强制显示时间
          // 3）同一天且与上一条时间间隔 > 2 分钟：显示时间
          bool showTimestamp = _shouldShowTimestamp(message, reverseIndex);

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
            onLongPressStart: (details) =>
                _showMessageActions(context, message, details.globalPosition),
            child: ChatMessageItem(
              message: message,
              onLongPress: null,
              showTimestamp: showTimestamp,
            ),
          );
        },
      ),
    );
  }

  /// 是否需要在当前消息上方显示时间（类似微信的时间气泡）
  bool _shouldShowTimestamp(ChatMessage message, int index) {
    // 第一条消息一定显示
    if (index == 0) return true;

    final prev = controller.messages[index - 1];
    final currentTime = message.time;
    final prevTime = prev.time;

    // 跨天：一定显示
    final isSameDay = currentTime.year == prevTime.year &&
        currentTime.month == prevTime.month &&
        currentTime.day == prevTime.day;
    if (!isSameDay) {
      return true;
    }

    // 同一天：间隔超过 2 分钟才显示
    final diff = currentTime.difference(prevTime);
    return diff > const Duration(minutes: 2);
  }

  // 获取背景图片提供器（支持资产图片和文件图片）
  ImageProvider _getBackgroundImageProvider(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else {
      return FileImage(File(path));
    }
  }


  // 显示消息操作菜单（贴着气泡上方的小菜单）
  void _showMessageActions(
      BuildContext context, ChatMessage message, Offset globalPosition) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final overlaySize = overlay.size;

    final isSelf = message.isSent;
    final canCopy = message.type == MessageType.text;
    final canRevoke = isSelf &&
        DateTime.now().difference(message.time) <= const Duration(minutes: 2);

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
            child: _MessageActionBubble(
              canCopy: canCopy,
              canDelete: true,
              canRevoke: canRevoke,
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
              onRevoke: canRevoke
                  ? () async {
                      Get.back();
                      final im = TencentIMService.instance;
                      if (message.id.isNotEmpty) {
                        final res =
                            await im.revokeMessage(msgID: message.id);
                        if (res == null || res.code != 0) {
                          // 撤回失败可以适当提示
                        }
                      }
                    }
                  : null,
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

/// 社交风格的气泡菜单：复制 / 删除 / 撤回
class _MessageActionBubble extends StatelessWidget {
  final bool canCopy;
  final bool canDelete;
  final bool canRevoke;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;
  final VoidCallback? onRevoke;

  const _MessageActionBubble({
    required this.canCopy,
    required this.canDelete,
    required this.canRevoke,
    this.onCopy,
    this.onDelete,
    this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (canCopy) {
      items.add(_buildItem('复制', Icons.copy_rounded, onCopy));
    }
    if (canDelete) {
      items.add(_buildItem('删除', Icons.delete_outline_rounded, onDelete,
          danger: true));
    }
    if (canRevoke) {
      items.add(_buildItem('撤回', Icons.undo_rounded, onRevoke));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                width: 0.5,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: Colors.white.withOpacity(0.2),
              ),
            items[i],
          ],
        ],
      ),
    );
  }

  Widget _buildItem(
      String text, IconData icon, VoidCallback? onTap,
      {bool danger = false}) {
    final color =
        danger ? const Color(0xFFFF6B6B) : const Color(0xFFFFFFFF);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 3),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/// 单个设备信息的悬浮提示气泡
class _DeviceInfoTooltipBubble extends StatelessWidget {
  final String text;

  const _DeviceInfoTooltipBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      constrainedAxis: Axis.vertical,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
          CustomPaint(
            size: const Size(12, 6),
            painter: _TooltipArrowPainter(),
          ),
        ],
      ),
    );
  }
}

/// 气泡底部的小三角形
class _TooltipArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
