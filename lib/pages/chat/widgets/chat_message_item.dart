import 'dart:io';
import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:audioplayers/audioplayers.dart';
import 'location_preview_widget.dart';
import '../utils/map_marker_util.dart';

/// 聊天消息类型
enum MessageType {
  text,      // 文字消息
  voice,     // 语音消息
  image,     // 图片消息
  location,  // 位置消息
}

/// 消息模型
class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final bool isSent; // true: 发送的消息, false: 接收的消息
  final DateTime time;
  final String? avatarUrl;
  final int? voiceDuration; // 语音时长(秒)
  final String? voiceUrl; // 语音文件URL
  final String? imageUrl;
  final String? locationName;
  final double? latitude;   // 纬度
  final double? longitude;  // 经度

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.isSent,
    required this.time,
    this.avatarUrl,
    this.voiceDuration,
    this.voiceUrl,
    this.imageUrl,
    this.locationName,
    this.latitude,
    this.longitude,
  });
}

/// 聊天消息气泡组件
class ChatMessageItem extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onLongPress;

  const ChatMessageItem({
    super.key,
    required this.message,
    this.onLongPress,
  });

  @override
  State<ChatMessageItem> createState() => _ChatMessageItemState();
}

class _ChatMessageItemState extends State<ChatMessageItem> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    // 监听播放状态
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // 播放/停止音频
  Future<void> _toggleAudioPlayback() async {
    if (widget.message.voiceUrl == null) return;

    if (_isPlaying) {
      await _audioPlayer.stop();
    } else {
      try {
        // 判断是本地文件还是网络URL
        if (widget.message.voiceUrl!.startsWith('http://') || 
            widget.message.voiceUrl!.startsWith('https://')) {
          await _audioPlayer.play(UrlSource(widget.message.voiceUrl!));
        } else {
          await _audioPlayer.play(DeviceFileSource(widget.message.voiceUrl!));
        }
      } catch (e) {
        debugPrint('音频播放失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment:
            widget.message.isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 接收消息显示对方头像
          if (!widget.message.isSent) _buildAvatar(),
          if (!widget.message.isSent) const SizedBox(width: 8),

          // 消息气泡
          Flexible(
            child: GestureDetector(
              onLongPress: widget.onLongPress,
              child: _buildMessageBubble(context),
            ),
          ),

          // 发送消息显示自己头像
          if (widget.message.isSent) const SizedBox(width: 8),
          if (widget.message.isSent) _buildAvatar(),
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

  Widget _buildMessageBubble(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
      ),
      padding: widget.message.type == MessageType.image 
          ? EdgeInsets.zero  // 图片消息不需要内边距
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: widget.message.type == MessageType.image 
          ? null  // 图片消息不需要背景装饰
          : BoxDecoration(
              color: widget.message.isSent ? const Color(0xffFF72C6) : Colors.white,
              borderRadius: widget.message.isSent 
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(10),  // 左下圆角5
                      bottomRight: Radius.circular(20),
                    )
                  : const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(10), // 右下圆角5
                    ),
              border: widget.message.isSent ? null : Border.all(
                color: const Color(0xffFFD4D0),
                width: 1,
              ),
            ),
      child: _buildMessageContent(context),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (widget.message.type) {
      case MessageType.text:
        return Text(
          widget.message.content,
          style: TextStyle(
            color: widget.message.isSent ? Colors.white : Colors.black87,
            fontSize: 15,
            height: 1.4,
          ),
        );

      case MessageType.voice:
        return GestureDetector(
          onTap: _toggleAudioPlayback,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 我发送的：时长在左，图标在右
              if (widget.message.isSent) ...[
                Text(
                  '${widget.message.voiceDuration ?? 0}′′',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/chat/kissu3_audio_chat_mine.webp',
                  width: 32,
                  height: 22,
                  fit: BoxFit.contain,
                ),
              ]
              // 对方发送的：图标在左，时长在右
              else ...[
                Image.asset(
                  'assets/chat/kissu3_audio_chat_love.webp',
                  width: 32,
                  height: 22,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.message.voiceDuration ?? 0}′′',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
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
            if (widget.message.latitude != null && widget.message.longitude != null)
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
        builder: (context) => ImagePreviewPage(imageUrl: widget.message.imageUrl!),
        fullscreenDialog: true,
      ),
    );
  }
}

// 图片预览页面
class ImagePreviewPage extends StatefulWidget {
  final String imageUrl;

  const ImagePreviewPage({
    super.key,
    required this.imageUrl,
  });

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
    if (widget.imageUrl.startsWith('http://') || widget.imageUrl.startsWith('https://')) {
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
          child: Center(
            child: _interactiveViewer,
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
                        snippet: '纬度: ${widget.latitude.toStringAsFixed(6)}, 经度: ${widget.longitude.toStringAsFixed(6)}',
                      ),
                    ),
                  }
                : {
                    Marker(
                      position: LatLng(widget.latitude, widget.longitude),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      infoWindow: InfoWindow(
                        title: widget.locationName,
                        snippet: '纬度: ${widget.latitude.toStringAsFixed(6)}, 经度: ${widget.longitude.toStringAsFixed(6)}',
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
                padding: const EdgeInsets.only(left: 20, right: 20, top: 12,bottom: 30),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
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

