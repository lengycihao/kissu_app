import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/services/analytics/analytics_manager.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/pages/agreement/agreement_webview_page.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/public/service_locator.dart';
import 'package:kissu_app/utils/source_page_utils.dart';
import 'location_preview_widget.dart';
import 'image_preview_page.dart';
import '../models/chat_message.dart';
import '../chat_controller.dart';
import 'package:kissu_app/pages/location/location_detail_page.dart';
import 'package:kissu_app/pages/track/track_page.dart';
import 'package:kissu_app/pages/track/track_binding.dart';

// 导出模型类，保持向后兼容
export '../models/chat_message.dart';

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
    // 居中显示的位置通知（服务端下发的敏感位置消息）
    if (widget.message.type == MessageType.locationNotice) {
      return _buildLocationNoticeMessage();
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
    // 气泡padding(top:20) + 标题上方间距(2) + 标题高度(~15) + 标题和图标间距(8) + 图标高度(48) + 气泡padding(bottom:8) ≈ 101
    const double defecateMessageHeight = 101.0;

    // 普通消息：上方可选时间气泡 + 下方消息行
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showTimestamp) _buildTimeChip(),
        Padding(
          // 消息间垂直间距设为12px
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child:
              (imageSize != null &&
                      (isSelfImageMessage || isOtherImageMessage)) ||
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
                  // 所有消息类型统一用顶部对齐
                  crossAxisAlignment: CrossAxisAlignment.start,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          // 时间戳（根据showTimestamp决定是否显示）
          if (widget.showTimestamp) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12, top: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _formatTime(widget.message.time),
                style: const TextStyle(fontSize: 11, color: Color(0x99000000)),
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
                  // 图标（VIP用户显示vipIcon，非VIP用户显示iconUrl）
                  if (_getSystemEventDisplayIcon() != null)
                    _buildEventIcon(_getSystemEventDisplayIcon()!),
                  if (_getSystemEventDisplayIcon() != null) const SizedBox(width: 4),
                  // 文字 + 可选右箭头
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 根据用户VIP状态显示不同内容：VIP用户显示imVipContent，非VIP用户显示content
                      _buildTextWithColorOverrides(
                        _getSystemEventDisplayContent(),
                        widget.message.imFontColor,
                        const TextStyle(fontSize: 13, color: Color(0xFF333333)),
                      ),
                      // 仅当消息标记is_vip=1且用户非VIP时显示VIP按钮
                      if ((widget.message.isVip ?? 0) == 1 && !_isCurrentUserVip()) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            try {
                              // 埋点：页面离开（进入下一页）
                              try {
                                final controller = Get.find<ChatController>();
                                controller.onNavigateToNextPage?.call();
                              } catch (_) {}

                              // 埋点：非会员点击消息跳转VIP
                              AnalyticsManager.instance.trackClick(
                                pageId: ChatEvents.pageId,
                                eventId: ChatEvents.imVip,
                              );
                              Get.toNamed(
                                KissuRoutePath.vip,
                                arguments: {
                                  'source_page': SourcePageUtilsCaller.chat,
                                  'source_event': ChatEvents.imVip,
                                },
                              );
                            } catch (e) {
                              debugPrint('跳转 VIP 页面失败: $e');
                            }
                          },
                          child: Image.asset(
                            'assets/chat/kissu_chat_vip.webp',
                            width: 56,
                            height: 21,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ] else if (hasJump) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: _handleSystemEventTap,
                          child: Image.asset(
                            'assets/4.0/kissu4_new_use_right.webp',
                            width: 6,
                            height: 6,
                            color: const Color(0xff009BFE),
                          ),
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

  /// 居中显示的位置通知（不使用气泡，白色背景，展示地图快照）
  /// VIP用户正常展示，非VIP用户显示会员查看按钮和蒙版
  Widget _buildLocationNoticeMessage() {
    // 获取用户VIP状态
    bool isUserVip = false;
    try {
      final chatController = Get.find<ChatController>();
      isUserVip = chatController.isVip.value;
    } catch (_) {
      isUserVip = false;
    }

    // 处理非VIP用户的位置名称（保留前6位+*****）
    String displayLocationName = widget.message.locationName ?? '位置信息';
    if (!isUserVip) {
      if (displayLocationName.length > 6) {
        displayLocationName = '${displayLocationName.substring(0, 6)}*****';
      } else if (displayLocationName.isNotEmpty) {
        displayLocationName = '$displayLocationName*****';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 7),
      child: Column(
        children: [
          if (widget.showTimestamp) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12, top: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _formatTime(widget.message.time),
                style: const TextStyle(fontSize: 11, color: Color(0x99000000)),
              ),
            ),
            const SizedBox(height: 8),
          ],
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: isUserVip
                ? (widget.message.latitude != null &&
                        widget.message.longitude != null
                    ? () => _showLocationDetail(context, widget.message)
                    : null)
                : () => _navigateToVipPage(),
            child: Container(
              width: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Color(0xffE8E8E8), width: 1),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0f000000),
                    blurRadius: 7.3,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 位置名称 + 地图快照
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题行：图标 + 内容 + (非VIP时显示会员查看按钮)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image(
                              image: AssetImage(
                                widget.message.content.contains("到达")
                                    ? 'assets/chat/chat_location_come.webp'
                                    : widget.message.content.contains("离开")
                                    ? 'assets/chat/chat_location_away.webp'
                                    : 'assets/chat/chat_location_stay.webp',
                              ),
                              width: 18,
                            ),
                            Expanded(
                              child: Text(
                                widget.message.content,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xe6000000),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // 非VIP用户显示会员查看按钮
                            if (!isUserVip)
                              Image.asset(
                                'assets/chat/kissu_chat_vip.webp',
                                width: 56,
                                height: 21,
                                fit: BoxFit.contain,
                              ),
                          ],
                        ),
                        SizedBox(height: 5),
                        // 副标题：VIP显示完整地址，非VIP显示缩略地址
                        Text(
                          displayLocationName,
                          maxLines: null,
                          softWrap: true,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0x66000000),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 地图快照部分
                        if (widget.message.latitude != null &&
                            widget.message.longitude != null)
                          _buildLocationPreviewWithMask(isUserVip)
                        else
                          _buildSimpleLocationPreviewWithMask(isUserVip),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建带蒙版的地图快照（非VIP用户显示蒙版）
  Widget _buildLocationPreviewWithMask(bool isUserVip) {
    final locationPreview = LocationPreviewWidget(
      latitude: widget.message.latitude!,
      longitude: widget.message.longitude!,
      locationName: widget.message.locationName ?? '位置信息',
      width: 206,
      height: 48,
      avatarUrl: widget.message.avatarUrl,
      onTap: isUserVip
          ? () => _showLocationDetail(context, widget.message)
          : () => _navigateToVipPage(),
    );

    if (isUserVip) {
      return locationPreview;
    }

    // 非VIP用户：添加毛玻璃蒙版和按钮
    return Stack(
      children: [
        locationPreview,
        // 毛玻璃蒙版
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x52000000), // 000000 32%透明度
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/chat/chat_location_vip_show.webp',
                    fit: BoxFit.contain,
                    width: 63,
                    height: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建带蒙版的简单位置预览（非VIP用户显示蒙版）
  Widget _buildSimpleLocationPreviewWithMask(bool isUserVip) {
    final simplePreview = SimpleLocationPreviewWidget(
      locationName: widget.message.locationName ?? '位置信息',
      width: 206,
      height: 48,
      onTap: isUserVip
          ? () => _showLocationDetail(context, widget.message)
          : () => _navigateToVipPage(),
    );

    if (isUserVip) {
      return simplePreview;
    }

    // 非VIP用户：添加毛玻璃蒙版和按钮
    return Stack(
      children: [
        simplePreview,
        // 毛玻璃蒙版
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x52000000), // 000000 32%透明度
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/chat/chat_location_vip_show.webp',
                    fit: BoxFit.contain,
                    width: 63,
                    height: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 获取当前用户是否为VIP
  bool _isCurrentUserVip() {
    try {
      final chatController = Get.find<ChatController>();
      return chatController.isVip.value;
    } catch (_) {
      return false;
    }
  }

  /// 获取系统事件消息的显示内容（VIP用户显示imVipContent，非VIP用户显示content）
  String _getSystemEventDisplayContent() {
    // 如果消息标记了is_vip=1，根据用户VIP状态显示不同内容
    if ((widget.message.isVip ?? 0) == 1) {
      if (_isCurrentUserVip()) {
        // VIP用户：优先显示imVipContent，如果没有则显示content
        return widget.message.imVipContent ?? widget.message.content;
      } else {
        // 非VIP用户：显示content
        return widget.message.content;
      }
    }
    // 普通消息直接显示content
    return widget.message.content;
  }

  /// 获取系统事件消息的显示图标（VIP用户显示vipIcon，非VIP用户显示iconUrl）
  String? _getSystemEventDisplayIcon() {
    if (_isCurrentUserVip()) {
      // VIP用户：优先显示vipIcon，如果没有则显示iconUrl
      return widget.message.vipIcon ?? widget.message.iconUrl;
    } else {
      // 非VIP用户：显示iconUrl
      return widget.message.iconUrl;
    }
  }

  /// 跳转到VIP开通页面
  void _navigateToVipPage() {
    try {
      // 通知ChatController即将跳转到下一页
      try {
        final controller = Get.find<ChatController>();
        controller.onNavigateToNextPage?.call();
      } catch (_) {}

      // 埋点：非会员点击消息跳转VIP
      AnalyticsManager.instance.trackClick(
        pageId: ChatEvents.pageId,
        eventId: ChatEvents.imVip,
      );
      Get.toNamed(
        KissuRoutePath.vip,
        arguments: {
          'source_page': SourcePageUtilsCaller.chat,
          'source_event': ChatEvents.imVip,
        },
      );
    } catch (e) {
      debugPrint('跳转VIP页面失败: $e');
    }
  }

  /// 处理系统事件（敏感操作）点击跳转
  /// 统一的 jump_page -> 路由 映射函数（供多个点击入口复用）
  Future<void> _navigateByJumpPage(
    String? jump, {
    Map<String, dynamic>? args,
  }) async {
    try {
      if (jump == null || jump.isEmpty) {
        // 没有 jump，若有经纬度则默认定位页
        if (args != null &&
            args['latitude'] != null &&
            args['longitude'] != null) {
          Get.toNamed(KissuRoutePath.location, arguments: args);
        }
        return;
      }

      // 埋点：页面离开（进入下一页）
      try {
        final controller = Get.find<ChatController>();
        controller.onNavigateToNextPage?.call();
      } catch (_) {}

      switch (jump) {
        case 'appUsePage':
          Get.toNamed(KissuRoutePath.appUsage);
          break;
        case 'tracePage':
          // 跳转到轨迹页面，如果有坐标则显示infowindow和圆圈
          if (args != null &&
              args['latitude'] != null &&
              args['longitude'] != null) {
            Get.to(
              () => TrackPage(
                initialLatitude: double.tryParse(args['latitude'].toString()),
                initialLongitude: double.tryParse(args['longitude'].toString()),
                initialLocationName: args['locationName'] as String?,
                autoShowInfoWindow: true,
              ),
              binding: TrackBinding(),
              transition: Transition.rightToLeft,
            );
          } else {
            Get.toNamed(KissuRoutePath.track);
          }
          break;
        case 'unlockPhonePage':
          Get.toNamed(KissuRoutePath.appUsageInfo);
          break;
        case 'mobileUse':
          Get.toNamed(KissuRoutePath.deviceUsage, arguments: {'source_event': ChatEvents.page});
          break;
        case 'locationPage':
          Get.toNamed(KissuRoutePath.location, arguments: args ?? {});
          break;
        case 'locationReminder':
          Get.toNamed(KissuRoutePath.locationReminder);
          break;
        default:
          // 未知 jump，降级到定位页（若有坐标）
          if (args != null &&
              args['latitude'] != null &&
              args['longitude'] != null) {
            Get.toNamed(KissuRoutePath.location, arguments: args);
          }
          break;
      }
    } catch (e) {
      debugPrint('导航失败: $e');
      // 兜底：若有坐标则打开详情页
      try {
        if (args != null &&
            args['latitude'] != null &&
            args['longitude'] != null) {
          Navigator.of(Get.context!).push(
            MaterialPageRoute(
              builder: (context) => LocationDetailPage(
                latitude: double.tryParse(args['latitude'].toString()) ?? 0.0,
                longitude: double.tryParse(args['longitude'].toString()) ?? 0.0,
                locationName: args['locationName'] ?? '',
                avatarUrl: args['avatarUrl'],
                isMyself: args['isMyself'] ?? false,
              ),
            ),
          );
        }
      } catch (_) {}
    }
  }

  /// 处理系统事件（敏感操作）点击跳转（现在委托到统一导航函数）
  Future<void> _handleSystemEventTap() async {
    await _navigateByJumpPage(widget.message.jumpPage);
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
              style: const TextStyle(fontSize: 11, color: Color(0x99000000)),
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
    // 所有消息类型都统一顶部对齐，不再向下偏移
    return Align(alignment: Alignment.topCenter, child: _buildAvatar());
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ).copyWith(bottom: 8, top: 20),
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

  /// 根据服务端 im_font_color 列表对 content 中指定文本片段替换为对应颜色
  Widget _buildTextWithColorOverrides(
    String content,
    List<FontColorItem>? items,
    TextStyle defaultStyle, {
    int maxLines = 1000,
  }) {
    if (items == null || items.isEmpty) {
      return Text(content, style: defaultStyle, maxLines: maxLines);
    }

    // 构建一个按位置切分的 TextSpan 列表，优先匹配最近的下一处替换文本
    final List<TextSpan> spans = [];
    int cursor = 0;
    while (cursor < content.length) {
      int nextStart = content.length;
      FontColorItem? nextItem;
      // 找到最近的下一个匹配
      for (final it in items) {
        final idx = content.indexOf(it.changeText, cursor);
        if (idx >= 0 && idx < nextStart) {
          nextStart = idx;
          nextItem = it;
        }
      }

      if (nextItem == null) {
        // 剩余全部普通文本
        spans.add(
          TextSpan(text: content.substring(cursor), style: defaultStyle),
        );
        break;
      }

      // 普通文本片段
      if (nextStart > cursor) {
        spans.add(
          TextSpan(
            text: content.substring(cursor, nextStart),
            style: defaultStyle,
          ),
        );
      }

      // 匹配片段（高亮）
      final matchText = nextItem.changeText;
      Color color;
      try {
        final hex = nextItem.colorHex.replaceFirst('#', '0xff');
        color = Color(int.parse(hex));
      } catch (_) {
        color = const Color(0xFF4E90FF);
      }
      spans.add(
        TextSpan(
          text: matchText,
          style: defaultStyle.copyWith(color: color),
        ),
      );

      cursor = nextStart + matchText.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (widget.message.type) {
      case MessageType.text:
        return _buildTextWithColorOverrides(
          widget.message.content,
          widget.message.imFontColor,
          const TextStyle(color: Color(0xff333333), fontSize: 13, height: 1.4),
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

      case MessageType.locationNotice:
        // locationNotice 在 build() 顶部已单独处理，这里不会执行到
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
            '【拉了么】',
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
                      ? widget
                            .message
                            .content // 结束拉屎：使用content（已包含时长）
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
      // 优先使用后端返回的 crapLink（若可用），否则降级到生产 HTTPS 链接
      String baseUrl = '';
      try {
        if (Get.isRegistered<HomeController>()) {
          final homeController = Get.find<HomeController>();
          baseUrl = homeController.crapLink.value;
        }
      } catch (_) {
        baseUrl = '';
      }

      if (baseUrl.isEmpty) {
        // 如果接口没有返回链接，使用默认链接（与首页保持一致）
        baseUrl = 'http://devweb.ikissu.cn/share/couplesdeFecating.html';
      }
      // 注意：不强制转换为 HTTPS，因为开发环境 SSL 证书可能有问题

      String url = baseUrl;

      // 尝试获取 token 并拼接为参数（若存在）
      try {
        final authService = getIt<AuthService>();
        final token = authService.userToken;
        if (token != null && token.isNotEmpty) {
          final encodedToken = Uri.encodeComponent(token);
          final separator = baseUrl.contains('?') ? '&' : '?';
          url = '$baseUrl${separator}token=$encodedToken';
        }
      } catch (_) {
        url = baseUrl;
      }

      // 埋点：页面离开（进入下一页）
      try {
        final controller = Get.find<ChatController>();
        controller.onNavigateToNextPage?.call();
      } catch (_) {}

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

    // 统一导航入口：把经纬度等参数交给 _navigateByJumpPage 处理
    final args = {
      'latitude': message.latitude!.toString(),
      'longitude': message.longitude!.toString(),
      'avatarUrl': message.avatarUrl,
      'locationName': message.locationName ?? '',
      'isMyself': message.isSent,
    };
    _navigateByJumpPage(message.jumpPage, args: args);
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
          Image.asset(placeholderAsset, fit: BoxFit.cover),
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
      child: Image.asset(placeholder, fit: BoxFit.cover),
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

/// 图片展示比例枚举：正方形 / 16:9 / 9:16
enum _ImageRatioType { square, landscape16_9, portrait9_16 }
