import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:kissu_app/pages/agreement/agreement_webview_page.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/public/service_locator.dart';
import 'location_preview_widget.dart';
import '../utils/map_marker_util.dart';
import '../chat_controller.dart';

/// 聊天消息类型
enum MessageType {
  text, // 文字消息
  image, // 图片消息
  location, // 位置消息
  systemEvent, // 系统事件消息（图标+文字，居中显示）
  defecate, // 一起便便消息（特殊气泡样式）
}

/// 消息模型
class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final bool isSent; // true: 发送的消息, false: 接收的消息
  final DateTime time;
  final String? avatarUrl;
  final String? imageUrl;
  final double? imageWidth;   // 图片原始宽度（用于计算展示比例）
  final double? imageHeight;  // 图片原始高度（用于计算展示比例）
  final String? locationName;
  final double? latitude; // 纬度
  final double? longitude; // 经度
  final bool isRead; // 是否已读（仅用于自己发送的消息）
  final String? iconUrl; // 图标URL（用于systemEvent类型，支持网络图片）
  final String? crapDuration; // 拉屎时长（用于endDefecate类型，如"0分30秒"）
  final String? jumpPage; // 跳转页面标识（用于敏感事件systemEvent）

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.isSent,
    required this.time,
    this.avatarUrl,
    this.imageUrl,
    this.imageWidth,
    this.imageHeight,
    this.locationName,
    this.latitude,
    this.longitude,
    this.isRead = false, // 默认为未读
    this.iconUrl, // 图标URL（用于systemEvent类型）
    this.crapDuration, // 拉屎时长（用于endDefecate类型）
    this.jumpPage, // 跳转页面标识
  });
}

/// 聊天消息气泡组件
class ChatMessageItem extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onLongPress;
  final bool showTimestamp; // 是否显示时间戳（用于systemEvent类型）
  // 图片点击回调（用于外部实现多图预览）
  final void Function(ChatMessage message)? onImageTap;

  const ChatMessageItem({
    super.key,
    required this.message,
    this.onLongPress,
    this.showTimestamp = true,
    this.onImageTap,
  });

  @override
  State<ChatMessageItem> createState() => _ChatMessageItemState();
}

class _ChatMessageItemState extends State<ChatMessageItem> {
  @override
  Widget build(BuildContext context) {
    // 系统事件消息使用特殊的居中布局
    if (widget.message.type == MessageType.systemEvent) {
      return _buildSystemEventMessage();
    }

    // 是否为图片消息（需要特殊布局对齐头像）
    final bool isSelfImageMessage =
        widget.message.isSent && widget.message.type == MessageType.image;
    final bool isOtherImageMessage =
        !widget.message.isSent && widget.message.type == MessageType.image;

    // 是否为一起便便消息（需要特殊布局对齐头像，和图片消息一样）
    final bool isSelfDefecateMessage =
        widget.message.isSent && widget.message.type == MessageType.defecate;
    final bool isOtherDefecateMessage =
        !widget.message.isSent && widget.message.type == MessageType.defecate;

    // 预先计算图片高度，用于对齐头像（仅图片消息时使用）
    Size? imageSize;
    if (isSelfImageMessage || isOtherImageMessage) {
      final ratioType = _getImageRatioType();
      imageSize = _getImageSize(ratioType);
    }

    // 计算一起便便消息高度（用于对齐头像）
    // 内容高度：标题(13) + 间距(8) + 图标(48) + 气泡padding(top:20 + bottom:8) + 标题上方间距(2) ≈ 91
    // 加上一些额外空间，使用固定高度
    const double defecateMessageHeight = 91.0;

    // 普通消息：上方可选时间气泡 + 下方消息行
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showTimestamp) _buildTimeChip(),
        Padding(
          // 适当增大消息间垂直间距
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: (imageSize != null && (isSelfImageMessage || isOtherImageMessage)) ||
                  (isSelfDefecateMessage || isOtherDefecateMessage)
              ? Row(
                  mainAxisAlignment: widget.message.isSent
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 对方图片/一起便便消息：左侧头像与消息顶部对齐
                    if (isOtherImageMessage || isOtherDefecateMessage) ...[
                      SizedBox(
                        height: isOtherImageMessage
                            ? imageSize!.height
                            : defecateMessageHeight,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: _buildAvatar(),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // 消息内容（自己消息在右侧展示头像）
                    Flexible(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onLongPress: widget.onLongPress,
                        child: _buildMessageBubble(context),
                      ),
                    ),
                    // 自己图片/一起便便消息：右侧头像与消息顶部对齐
                    if (isSelfImageMessage || isSelfDefecateMessage) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        height: isSelfImageMessage
                            ? imageSize!.height
                            : defecateMessageHeight,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: _buildAvatar(),
                        ),
                      ),
                    ],
                  ],
                )
              : Row(
                  mainAxisAlignment: widget.message.isSent
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  // 文本/位置等气泡类消息：统一用底部对齐
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!widget.message.isSent) _buildAvatarWithOffset(),
                    if (!widget.message.isSent) const SizedBox(width: 8),
                    Flexible(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onLongPress: widget.onLongPress,
                        child: _buildMessageBubble(context),
                      ),
                    ),
                    if (widget.message.isSent) const SizedBox(width: 8),
                    if (widget.message.isSent) _buildAvatarWithOffset(),
                  ],
                ),
        ),
      ],
    );
  }

  /// 构建系统事件消息（居中显示，图标+文字）
  Widget _buildSystemEventMessage() {
    final bool hasJump =
        widget.message.jumpPage != null && widget.message.jumpPage!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Column(
        children: [
          // 时间戳（根据showTimestamp决定是否显示）
          if (widget.showTimestamp) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 10,top: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _formatTime(widget.message.time),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0x99000000),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // 图标+文字（带背景，可选跳转）
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: hasJump ? _handleSystemEventTap : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 图标
                  if (widget.message.iconUrl != null)
                    _buildEventIcon(widget.message.iconUrl!),
                  if (widget.message.iconUrl != null) const SizedBox(width: 4),
                  // 文字 + 可选右箭头
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.message.content,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF333333),
                        ),
                      ),
                      if (hasJump) ...[
                        const SizedBox(width: 4),
                        Image.asset(
                          'assets/4.0/kissu4_new_use_right.webp',
                          width: 6,
                          height: 6,
                          color: Color(0xff009BFE),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理系统事件（敏感操作）点击跳转
  void _handleSystemEventTap() {
    final jump = widget.message.jumpPage;
    if (jump == null || jump.isEmpty) return;

    switch (jump) {
      case 'appUsePage':
        // 跳转到App使用统计页面
        Get.toNamed(KissuRoutePath.appUsage);
        break;
      case 'tracePage':
        // 跳转到足迹页面
        Get.toNamed(KissuRoutePath.track);
        break;
      case 'unlockPhonePage':
        // 跳转到设备使用记录页面（解锁记录）
        Get.toNamed(KissuRoutePath.appUsageInfo);
        break;
      default:
        break;
    }
  }

  /// 构建事件图标（支持网络图片和本地资源）
  Widget _buildEventIcon(String iconUrl) {
    // 判断是网络图片还是本地资源
    if (iconUrl.startsWith('http://') || iconUrl.startsWith('https://')) {
      // 网络图片
      return Image.network(
        iconUrl,
        width: 18,
        height: 18,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            width: 18,
            height: 18,
            child: Icon(Icons.info_outline, size: 18, color: Colors.grey),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const SizedBox(
            width: 18,
            height: 18,
            child: Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    } else {
      // 本地资源（assets）
      return Image.asset(
        iconUrl,
        width: 18,
        height: 18,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            width: 18,
            height: 18,
            child: Icon(Icons.info_outline, size: 20, color: Colors.grey),
          );
        },
      );
    }
  }

  /// 格式化时间显示：
  /// - 今天：显示“今天 HH:mm”
  /// - 昨天：显示“昨天 HH:mm”
  /// - 更早：显示“MM月dd日 HH:mm”
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(time.year, time.month, time.day);

    final diffDays = targetDay.difference(today).inDays;

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    if (diffDays == 0) {
      // 今天
      return '今天 $hour:$minute';
    } else if (diffDays == -1) {
      // 昨天
      return '昨天 $hour:$minute';
    } else {
      final month = time.month;
      final day = time.day;
      return '$month月$day日 $hour:$minute';
    }
  }

  /// 普通消息上方的时间气泡（类似微信）
  Widget _buildTimeChip() {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _formatTime(widget.message.time),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0x99000000),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(21), // 圆形头像
        image: widget.message.avatarUrl != null
            ? DecorationImage(
                image: NetworkImage(widget.message.avatarUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: widget.message.avatarUrl == null
          ? Icon(Icons.person, color: Colors.grey[600], size: 24)
          : null,
    );
  }

  // 构建带偏移的头像（只用于有气泡的消息）
  Widget _buildAvatarWithOffset() {
    // 图片消息不调整位置
    if (widget.message.type == MessageType.image) {
      return _buildAvatar();
    }
    // 有气泡的消息向下调整2px
    return Transform.translate(
      offset: const Offset(0, 2),
      child: _buildAvatar(),
    );
  }

  /// 构建消息气泡
  Widget _buildMessageBubble(BuildContext context) {
    // 图片消息不需要气泡背景
    if (widget.message.type == MessageType.image) {
      return Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        child: _buildMessageContent(context),
      );
    }

    // 使用 Obx 包裹，响应气泡样式变化
    return Obx(() {
      // 获取当前气泡样式和对应的气泡图片路径
      final bubbleImagePath = _getBubbleImagePath();
      final centerSlice = _getBubbleCenterSlice();

      return ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 57,
          minHeight: 50,
          maxWidth: 230,
        ),
        child: Stack(
          children: [
            // 气泡背景图片
            Positioned.fill(
              child: Image.asset(
                bubbleImagePath,
                fit: BoxFit.fill,
                centerSlice: centerSlice,
              ),
            ),
            // 消息内容
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                  .copyWith(bottom: 8, top: 20),
              child: _buildMessageContent(context),
            ),
          ],
        ),
      );
    });
  }

  /// 获取气泡图片路径
  /// 根据消息发送/接收状态和当前气泡样式返回对应的图片路径
  String _getBubbleImagePath() {
    try {
      // 获取聊天控制器以获取当前气泡样式
      final chatController = Get.find<ChatController>();
      final bubbleStyle = chatController.bubbleStyle.value;

      // 根据消息发送/接收状态选择对应的气泡图片
      // 自己的消息使用 self，对方的消息使用 other
      if (widget.message.isSent) {
        // 自己的气泡：kissu_chat_bubble_self_1.webp, kissu_chat_bubble_self_2.webp, ...
        return 'assets/chat/kissu_chat_bubble_self_$bubbleStyle.webp';
      } else {
        // 对方的气泡：kissu_chat_bubble_other_1.webp, kissu_chat_bubble_other_2.webp, ...
        return 'assets/chat/kissu_chat_bubble_other_$bubbleStyle.webp';
      }
    } catch (e) {
      // 如果获取控制器失败，使用默认样式1
      debugPrint('💬 获取气泡样式失败，使用默认样式: $e');
      final defaultPath = widget.message.isSent
          ? 'assets/chat/kissu_chat_bubble_self_1.webp'
          : 'assets/chat/kissu_chat_bubble_other_1.webp';
      return defaultPath;
    }
  }

  /// 获取气泡九宫格切片参数

  Rect _getBubbleCenterSlice() {
    return const Rect.fromLTRB(23, 28, 30, 30);
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (widget.message.type) {
      case MessageType.text:
        return Text(
          widget.message.content,
          style: TextStyle(color: Color(0xff333333), fontSize: 13, height: 1.4),
        );

      case MessageType.image:
        return GestureDetector(
          onTap: () {
            if (widget.onImageTap != null) {
              widget.onImageTap!(widget.message);
            } else {
              _showImagePreview(context);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: widget.message.imageUrl != null
                ? _buildSizedImage(widget.message.imageUrl!)
                : _buildPlaceholderContainer(),
          ),
        );

      case MessageType.location:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 位置名称在上面
            Text(
              widget.message.locationName ?? '位置信息',
              style: TextStyle(
                color: widget.message.isSent ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            // 地图在下面
            // 如果有经纬度坐标，显示真实地图预览
            if (widget.message.latitude != null &&
                widget.message.longitude != null)
              LocationPreviewWidget(
                latitude: widget.message.latitude!,
                longitude: widget.message.longitude!,
                locationName: widget.message.locationName ?? '位置信息',
                width: 206,
                height: 48,
                avatarUrl: widget.message.avatarUrl, // 传递头像 URL
                onTap: () => _showLocationDetail(context, widget.message),
              )
            else
              // 如果没有坐标，显示简化版本
              SimpleLocationPreviewWidget(
                locationName: widget.message.locationName ?? '位置信息',
                width: 206,
                height: 48,
                onTap: () => _showLocationDetail(context, widget.message),
              ),
          ],
        );

      case MessageType.systemEvent:
        // systemEvent类型在build方法中已经单独处理，这里不会执行到
        return const SizedBox.shrink();

      case MessageType.defecate:
        // 一起便便消息：标题+图标+内容
        return _buildDefecateMessage();
    }
  }

  /// 构建一起便便消息内容
  Widget _buildDefecateMessage() {
    // 判断是开始还是结束拉屎（通过crapDuration字段）
    final bool isEndDefecate = widget.message.crapDuration != null;
    
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _handleDefecateMessageTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题："一起便便"
          SizedBox(height: 2),
          const Text(
            '一起便便',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          // 图标和内容横向对齐
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 图标
              Image.asset(
                'assets/chat/kissu_chat_crap.webp',
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              // 内容（根据是否有crapDuration显示不同文案）
              Expanded(
                child: Text(
                  isEndDefecate
                      ? widget.message.content // 结束拉屎：使用content（已包含时长）
                      : '亲爱的，我们开始拉屎吧～', // 开始拉屎：固定文案
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 处理一起便便消息点击，跳转到H5页面
  void _handleDefecateMessageTap() {
    try {
      const baseUrl = 'http://devweb.ikissu.cn/share/couplesdeFecating.html';
      String url = baseUrl;

      // 尝试获取token并拼接
      try {
        final authService = getIt<AuthService>();
        final token = authService.userToken;
        if (token != null && token.isNotEmpty) {
          final encodedToken = Uri.encodeComponent(token);
          url = '$baseUrl?token=$encodedToken';
        }
      } catch (_) {
        // 获取 token 失败时，降级为不带 token 的 H5
        url = baseUrl;
      }

      // 跳转到H5页面
      Get.to(
        () => AgreementWebViewPage(
          title: '',
          url: url,
          showAppBar: false,
          backgroundColor: Colors.white,
          showLoadingIndicator: false, // 拉屎H5不显示加载动画
        ),
        transition: Transition.rightToLeft,
      );
    } catch (e) {
      debugPrint('跳转一起便便H5页面失败: $e');
    }
  }

  // 显示位置详情
  void _showLocationDetail(BuildContext context, ChatMessage message) {
    if (message.latitude == null || message.longitude == null) {
      // 如果没有坐标信息，显示简单的信息对话框
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('位置信息'),
          content: Text(message.locationName ?? '位置信息'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      return;
    }

    // 如果有坐标信息，显示全屏地图
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _LocationDetailPage(
          latitude: message.latitude!,
          longitude: message.longitude!,
          locationName: message.locationName ?? '位置信息',
          avatarUrl: message.avatarUrl, // 传递头像 URL
        ),
      ),
    );
  }

  // 根据路径类型加载图片（本地文件或网络图片）
  Widget _buildImage(String imagePath, {required String placeholderAsset}) {
    // 判断是本地文件还是网络URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // 网络图片：统一走带磁盘缓存的帮助类，避免每次进入聊天都重新拉取
      return NetworkImageHelper.loadImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        placeholder: placeholderAsset,
      );
    } else {
      // 本地文件
      return Stack(
        fit: StackFit.expand,
        children: [
          // 底层占位图
          Image.asset(
            placeholderAsset,
            fit: BoxFit.cover,
          ),
          // 顶层真实图片
          Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  Icons.broken_image,
                  size: 32,
                  color: Colors.grey[400],
                ),
              );
            },
          ),
        ],
      );
    }
  }

  /// 根据图片原始宽高，计算展示比例（正方形 / 16:9 / 9:16）
  _ImageRatioType _getImageRatioType() {
    final w = widget.message.imageWidth;
    final h = widget.message.imageHeight;

    if (w == null || h == null || w <= 0 || h <= 0) {
      // 没有宽高信息时，走居中正方形
      return _ImageRatioType.square;
    }

    final ratio = w / h;

    // 约等于 1:1
    if (ratio > 0.9 && ratio < 1.1) {
      return _ImageRatioType.square;
    }

    // 宽 > 高，视为 16:9
    if (ratio >= 1.1) {
      return _ImageRatioType.landscape16_9;
    }

    // 高 > 宽，视为 9:16
    return _ImageRatioType.portrait9_16;
  }

  /// 不同比例对应不同展示尺寸
  Size _getImageSize(_ImageRatioType type) {
    switch (type) {
      case _ImageRatioType.square:
        return const Size(120, 120); // 1:1
      case _ImageRatioType.landscape16_9:
        return const Size(160, 90); // 16:9
      case _ImageRatioType.portrait9_16:
        return const Size(90, 160); // 9:16
    }
  }

  /// 根据比例 & 发送方，选占位图
  String _getPlaceholderAsset(_ImageRatioType type) {
    final isSelf = widget.message.isSent;
    switch (type) {
      case _ImageRatioType.square:
        return isSelf
            ? 'assets/chat/kissu_chat_pc_self_9_9.webp'
            : 'assets/chat/kissu_chat_pc_other_9_9.webp';
      case _ImageRatioType.landscape16_9:
        return isSelf
            ? 'assets/chat/kissu_chat_pc_self_16_9.webp'
            : 'assets/chat/kissu_chat_pc_other_16_9.webp';
      case _ImageRatioType.portrait9_16:
        return isSelf
            ? 'assets/chat/kissu_chat_pc_self_9_16.webp'
            : 'assets/chat/kissu_chat_pc_other_9_16.webp';
    }
  }

  /// 根据比例包装成固定宽高的图片容器
  Widget _buildSizedImage(String imagePath) {
    final ratioType = _getImageRatioType();
    final size = _getImageSize(ratioType);
    final placeholder = _getPlaceholderAsset(ratioType);

    return SizedBox(
      width: size.width,
      height: size.height,
      child: _buildImage(imagePath, placeholderAsset: placeholder),
    );
  }

  /// 当没有 imageUrl 时的占位容器（很少出现）
  Widget _buildPlaceholderContainer() {
    final ratioType = _ImageRatioType.square;
    final size = _getImageSize(ratioType);
    final placeholder = _getPlaceholderAsset(ratioType);

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Image.asset(
        placeholder,
        fit: BoxFit.cover,
      ),
    );
  }

  // 显示图片预览
  void _showImagePreview(BuildContext context) {
    if (widget.message.imageUrl == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImagePreviewPage(
          imageUrls: [widget.message.imageUrl!],
          initialIndex: 0,
        ),
        fullscreenDialog: true,
      ),
    );
  }

}

// 图片预览页面
class ImagePreviewPage extends StatefulWidget {
  /// 需要预览的图片列表
  final List<String> imageUrls;

  /// 初始显示的图片索引
  final int initialIndex;

  const ImagePreviewPage({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = (widget.initialIndex >= 0 &&
            widget.initialIndex < widget.imageUrls.length)
        ? widget.initialIndex
        : 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImage(String imageUrl) {
    // 判断是本地文件还是网络URL
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // 网络图片
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 64, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    '图片加载失败',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    '加载中...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // 本地文件
      return Image.file(
        File(imageUrl),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 64, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    '图片加载失败',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.imageUrls.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final url = widget.imageUrls[index];
            return Center(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => Navigator.of(context).pop(), // 点击大图也关闭
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: _buildImage(url),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 位置详情页面
class _LocationDetailPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;
  final String? avatarUrl;

  const _LocationDetailPage({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.avatarUrl,
  });

  @override
  State<_LocationDetailPage> createState() => _LocationDetailPageState();
}

class _LocationDetailPageState extends State<_LocationDetailPage> {
  BitmapDescriptor? _markerIcon;

  @override
  void initState() {
    super.initState();
    _createMarkerIcon();
  }

  /// 创建自定义标记图标（圆形头像）
  Future<void> _createMarkerIcon() async {
    try {
      final icon = await MapMarkerUtil.createCircleAvatarMarker(
        widget.avatarUrl,
        size: 80.0, // 详情页使用更大的标记
        borderWidth: 4.0,
      );
      if (mounted) {
        setState(() {
          _markerIcon = icon;
        });
      }
    } catch (e) {
      debugPrint('创建标记图标失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 全屏地图
          AMapWidget(
            onMapCreated: (AMapController controller) {
              // 地图创建完成后，移动到指定位置
              controller.moveCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: LatLng(widget.latitude, widget.longitude),
                    zoom: 16.0,
                  ),
                ),
              );
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.latitude, widget.longitude),
              zoom: 16.0,
            ),
            markers: _markerIcon != null
                ? {
                    Marker(
                      position: LatLng(widget.latitude, widget.longitude),
                      icon: _markerIcon!,
                      infoWindow: InfoWindow(
                        title: widget.locationName,
                        snippet:
                            '纬度: ${widget.latitude.toStringAsFixed(6)}, 经度: ${widget.longitude.toStringAsFixed(6)}',
                      ),
                    ),
                  }
                : {
                    Marker(
                      position: LatLng(widget.latitude, widget.longitude),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                      infoWindow: InfoWindow(
                        title: widget.locationName,
                        snippet:
                            '纬度: ${widget.latitude.toStringAsFixed(6)}, 经度: ${widget.longitude.toStringAsFixed(6)}',
                      ),
                    ),
                  },
            // 启用所有手势
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
          ),

          // 返回按钮 - 左上角
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Image.asset(
                'assets/kissu_mine_back.webp',
                width: 22,
                height: 22,
              ),
            ),
          ),

          // 底部位置信息模块
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 126,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/chat/kissu3_map_preview_bg.webp'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: 30,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 12,
                  ),
                  child: Text(
                    widget.locationName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 图片展示比例枚举：正方形 / 16:9 / 9:16
enum _ImageRatioType {
  square,
  landscape16_9,
  portrait9_16,
}
