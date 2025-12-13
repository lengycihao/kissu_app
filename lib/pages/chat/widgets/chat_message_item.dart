import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'location_preview_widget.dart';
import '../utils/map_marker_util.dart';
import '../chat_controller.dart';

/// 聊天消息类型
enum MessageType {
  text, // 文字消息
  image, // 图片消息
  location, // 位置消息
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
  final String? locationName;
  final double? latitude; // 纬度
  final double? longitude; // 经度
  final bool isRead; // 是否已读（仅用于自己发送的消息）

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.isSent,
    required this.time,
    this.avatarUrl,
    this.imageUrl,
    this.locationName,
    this.latitude,
    this.longitude,
    this.isRead = false, // 默认为未读
  });
}

/// 聊天消息气泡组件
class ChatMessageItem extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onLongPress;

  const ChatMessageItem({super.key, required this.message, this.onLongPress});

  @override
  State<ChatMessageItem> createState() => _ChatMessageItemState();
}

class _ChatMessageItemState extends State<ChatMessageItem> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: widget.message.isSent
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end, // 底部对齐
        children: [
          // 接收消息显示对方头像（只有非图片消息才向下调整）
          if (!widget.message.isSent) _buildAvatarWithOffset(),
          if (!widget.message.isSent) const SizedBox(width: 8),

          // 已读/未读状态（仅自己发送的消息，在气泡左侧）
          if (widget.message.isSent &&
              (widget.message.type == MessageType.text ||
                  widget.message.type == MessageType.image))
            Padding(
              padding: const EdgeInsets.only(right: 1, bottom: 0),
              child: _buildReadStatus(),
            ),

          // 消息气泡
          Flexible(
            child: GestureDetector(
              onLongPress: widget.onLongPress,
              child: _buildMessageBubble(context),
            ),
          ),

          // 发送消息显示自己头像（只有非图片消息才向下调整）
          if (widget.message.isSent) const SizedBox(width: 8),
          if (widget.message.isSent) _buildAvatarWithOffset(),
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
    // 有气泡的消息向下调整10px
    return Transform.translate(
      offset: const Offset(0, 10),
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
          onTap: () => _showImagePreview(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: widget.message.imageUrl != null
                ? _buildImage(widget.message.imageUrl!)
                : Container(
                    width: 150,
                    height: 150,
                    child: const Icon(Icons.image, size: 48),
                  ),
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
  Widget _buildImage(String imagePath) {
    // 判断是本地文件还是网络URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // 网络图片
      return Image.network(
        imagePath,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 150,
            height: 150,
            child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 150,
            height: 150,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else {
      // 本地文件
      return Image.file(
        File(imagePath),
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 150,
            height: 150,
            child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
          );
        },
      );
    }
  }

  // 显示图片预览
  void _showImagePreview(BuildContext context) {
    if (widget.message.imageUrl == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ImagePreviewPage(imageUrl: widget.message.imageUrl!),
        fullscreenDialog: true,
      ),
    );
  }

  /// 构建已读/未读状态显示
  Widget _buildReadStatus() {
    // 只对自己发送的消息显示
    if (!widget.message.isSent) {
      return const SizedBox.shrink();
    }

    // 只对气泡消息和图片消息显示
    if (widget.message.type != MessageType.text &&
        widget.message.type != MessageType.image) {
      return const SizedBox.shrink();
    }

    return widget.message.isRead
        ? Image.asset(
            'assets/chat/kissu3_chat_hasread.webp',
            width: 16,
            height: 16,
            fit: BoxFit.contain,
          )
        : const Text(
            '未读',
            style: TextStyle(
              fontSize: 11,
              color: Color(0x99000000), // 0x99000000 = 60% 透明度的黑色
            ),
          );
  }
}

// 图片预览页面
class ImagePreviewPage extends StatefulWidget {
  final String imageUrl;

  const ImagePreviewPage({super.key, required this.imageUrl});

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  late TransformationController _transformationController;
  late InteractiveViewer _interactiveViewer;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _interactiveViewer = InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 4.0,
      child: GestureDetector(
        onTap: () {}, // 阻止事件冒泡，点击图片不关闭预览
        child: _buildImage(),
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Widget _buildImage() {
    // 判断是本地文件还是网络URL
    if (widget.imageUrl.startsWith('http://') ||
        widget.imageUrl.startsWith('https://')) {
      // 网络图片
      return Image.network(
        widget.imageUrl,
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
        File(widget.imageUrl),
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
        onTap: () => Navigator.of(context).pop(),
        child: Center(child: _interactiveViewer),
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
