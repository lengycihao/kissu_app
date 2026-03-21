import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/pages/chat/chat_controller.dart';
import 'package:kissu_app/pages/chat/widgets/chat_message_item.dart';
import 'package:kissu_app/pages/chat/widgets/image_preview_page.dart';
import 'package:kissu_app/pages/chat/widgets/location_preview_widget.dart';
import 'package:kissu_app/pages/chat/models/chat_message.dart';
import 'package:kissu_app/pages/track/track_binding.dart';
import 'package:kissu_app/pages/track/track_page.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/services/analytics/analytics_manager.dart';
import 'package:kissu_app/utils/source_page_utils.dart';

/// 聊天消息列表区域，只负责列表渲染
class ChatMessageListView extends StatefulWidget {
  const ChatMessageListView({super.key, required this.controller});

  final ChatController controller;

  @override
  State<ChatMessageListView> createState() => _ChatMessageListViewState();
}

class _ChatMessageListViewState extends State<ChatMessageListView> {
  /// 存储需要折叠的消息组的展开状态
  /// key: 折叠组的起始消息ID, value: 是否展开
  final Map<String, bool> _expandedGroups = {};
  
  /// 🔥 修复：记录已展开组中包含的所有消息ID
  /// 用于在加载更多历史消息后，即使groupId变化也能保持展开状态
  final Set<String> _expandedMessageIds = {};

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.controller.hideAllPanels(),
      child: Obx(() {
        final messages = widget.controller.messages;

        // 每次都重新计算渲染项，确保折叠状态正确
        final renderItems = _buildRenderItems(messages);

        return Align(
          alignment: Alignment.topCenter,
          child: ListView.builder(
            controller: widget.controller.scrollController,
            reverse: true,
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: renderItems.length,
            itemBuilder: (context, index) {
              // reverse:true时，index=0是列表底部（最新消息）
              final reverseIndex = renderItems.length - 1 - index;
              final item = renderItems[reverseIndex];

              if (item is _CollapseGroupItem) {
                return _buildCollapseGroup(context, item);
              } else if (item is _SingleMessageItem) {
                return _buildSingleMessage(context, item);
              }
              return const SizedBox.shrink();
            },
          ),
        );
      }),
    );
  }

  /// 判断消息是否是敏感消息（需要折叠的类型）
  /// 敏感消息包括：systemEvent（系统事件）和 locationNotice（位置通知）
  bool _isSensitiveMessage(ChatMessage message) {
    return message.type == MessageType.systemEvent ||
           message.type == MessageType.locationNotice;
  }

  /// 构建渲染项列表，将连续超过3条的敏感消息合并为折叠组
  /// 敏感消息包括：systemEvent（系统事件）和 locationNotice（位置通知）
  List<_RenderItem> _buildRenderItems(List<ChatMessage> messages) {
    final List<_RenderItem> items = [];
    int i = 0;

    // 检查是否开启了敏感消息折叠
    final isCollapseEnabled = widget.controller.sensitiveCollapseEnabled.value;

    while (i < messages.length) {
      final message = messages[i];

      // 检查是否是敏感消息类型，且开启了折叠功能
      if (_isSensitiveMessage(message) && isCollapseEnabled) {
        // 查找连续的敏感消息
        int endIndex = i;
        int sensitiveCount = 1; // 计算敏感消息数量
        
        // 继续向后查找，直到遇到非敏感消息
        while (endIndex + 1 < messages.length) {
          final nextMessage = messages[endIndex + 1];
          if (_isSensitiveMessage(nextMessage)) {
            sensitiveCount++;
            endIndex++;
          } else {
            // 遇到非敏感消息，停止查找
            break;
          }
        }

        // 如果敏感消息超过3条，创建折叠组
        if (sensitiveCount > 3) {
          final groupMessages = messages.sublist(i, endIndex + 1);
          final groupId = groupMessages.first.id;
          
          // 🔥 修复：检查该组中是否有任何消息之前处于展开状态
          // 这样即使加载更多历史消息导致groupId变化，也能保持展开状态
          final hasExpandedMessage = groupMessages.any((m) => _expandedMessageIds.contains(m.id));
          if (hasExpandedMessage && !(_expandedGroups[groupId] ?? false)) {
            // 如果组中有之前展开的消息，自动设置该组为展开状态
            _expandedGroups[groupId] = true;
          }
          
          items.add(
            _CollapseGroupItem(
              groupId: groupId,
              messages: groupMessages,
              startIndex: i,
            ),
          );
          i = endIndex + 1;
        } else {
          // 不足3条，逐条添加
          for (int j = i; j <= endIndex; j++) {
            items.add(
              _SingleMessageItem(message: messages[j], originalIndex: j),
            );
          }
          i = endIndex + 1;
        }
      } else {
        // 非敏感消息或未开启折叠，直接添加
        items.add(_SingleMessageItem(message: message, originalIndex: i));
        i++;
      }
    }

    return items;
  }

  /// 构建折叠组
  Widget _buildCollapseGroup(BuildContext context, _CollapseGroupItem item) {
    final isExpanded = _expandedGroups[item.groupId] ?? false;

    if (isExpanded) {
      return _buildExpandedGroup(context, item);
    } else {
      return _buildCollapsedGroup(context, item);
    }
  }

  /// 构建折叠状态的组
  Widget _buildCollapsedGroup(BuildContext context, _CollapseGroupItem item) {
    // 判断是否需要显示时间戳（折叠组的第一条消息与前一条消息的时间差）
    final allMessages = widget.controller.messages;
    bool showTimestamp = false;
    if (item.startIndex == 0) {
      // 第一条消息总是显示时间
      showTimestamp = true;
    } else if (item.startIndex > 0) {
      final firstMessage = item.messages.first;
      final prevMessage = allMessages[item.startIndex - 1];
      final currentTime = firstMessage.time;
      final prevTime = prevMessage.time;
      
      // 跨天：一定显示
      final isSameDay = currentTime.year == prevTime.year &&
          currentTime.month == prevTime.month &&
          currentTime.day == prevTime.day;
      if (!isSameDay) {
        showTimestamp = true;
      } else {
        // 同一天：间隔超过1分钟则显示时间戳
        final timeDiff = currentTime.difference(prevTime);
        showTimestamp = timeDiff.inMinutes >= 1;
      }
    }
    
    return Column(
      children: [
        // 时间戳（根据需要显示）
        // 🔥 修复：间距与正常状态保持一致（margin: bottom: 12, top: 6）
        if (showTimestamp)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 12, top: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _formatTime(item.messages.first.time),
              style: const TextStyle(fontSize: 11, color: Color(0x99000000)),
            ),
          ),
        // 时间戳和折叠内容之间的间距（与正常状态一致）
        if (showTimestamp)
          const SizedBox(height: 8),
        // 折叠内容
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _expandedGroups[item.groupId] = true;
                    // 🔥 修复：记录该组中所有消息的ID，用于在加载更多历史消息后保持展开状态
                    for (final msg in item.messages) {
                      _expandedMessageIds.add(msg.id);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.messages.length}条敏感信息已收起',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF999999),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Image(
                        image: AssetImage('assets/188/kissu_chat_show_down.webp'),
                        width: 14,
                        height: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建展开状态的组
  Widget _buildExpandedGroup(BuildContext context, _CollapseGroupItem item) {
    // 获取折叠组前面的消息（用于判断第一条消息是否需要显示时间）
    final allMessages = widget.controller.messages;
    ChatMessage? messageBeforeGroup;
    if (item.startIndex > 0) {
      messageBeforeGroup = allMessages[item.startIndex - 1];
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 消息列表（包括所有消息，不仅仅是systemEvent）
          ...item.messages.asMap().entries.map((entry) {
            final index = entry.key;
            final message = entry.value;
            // 传入上一条消息用于判断是否显示时间戳
            // 第一条消息需要考虑折叠组前面的消息
            final prevMessage = index > 0 ? item.messages[index - 1] : messageBeforeGroup;
            return _buildExpandedMessageItem(message, index == 0 && messageBeforeGroup == null, prevMessage);
          }),
          // 收起按钮
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedGroups[item.groupId] = false;
                // 🔥 修复：收起时清除该组消息的展开记录
                for (final msg in item.messages) {
                  _expandedMessageIds.remove(msg.id);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(color: Colors.transparent),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '收起',
                      style: TextStyle(fontSize: 13, color: Color(0xFFaaaaaa)),
                    ),
                    SizedBox(width: 4),
                    Image(
                      image: AssetImage('assets/188/kissu_chat_show_up.webp'),
                      width: 14,
                      height: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建展开状态下的单条消息
  Widget _buildExpandedMessageItem(ChatMessage message, bool isFirst, ChatMessage? prevMessage) {
    // 根据消息类型选择不同的渲染方式
    if (message.type == MessageType.locationNotice) {
      return _buildExpandedLocationNoticeItem(message, isFirst, prevMessage);
    }
    
    // systemEvent 类型的渲染
    return _buildExpandedSystemEventItem(message, isFirst, prevMessage);
  }

  /// 构建展开状态下的 systemEvent 消息
  Widget _buildExpandedSystemEventItem(ChatMessage message, bool isFirst, ChatMessage? prevMessage) {
    final bool hasJump =
        message.jumpPage != null && message.jumpPage!.isNotEmpty;
    final bool messageIsVip = (message.isVip ?? 0) == 1;
    final bool isUserVip = widget.controller.isVip.value;
    
    // 根据用户VIP状态获取显示内容
    final String displayContent = _getDisplayContent(message, isUserVip);
    // 根据用户VIP状态获取显示图标（VIP用户显示vipIcon，非VIP用户显示iconUrl）
    final String? displayIcon = _getDisplayIcon(message, isUserVip);

    return Column(
      children: [
        // 时间戳（根据需要显示）
        // 🔥 修复：间距与正常状态保持一致（margin: bottom: 12, top: 6）
        if (_shouldShowTimestampInGroup(message, isFirst, prevMessage))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 12, top: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _formatTime(message.time),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0x99000000),
              ),
            ),
          ),
        // 时间戳和消息之间的间距（与正常状态一致：SizedBox(height: 8)）
        if (_shouldShowTimestampInGroup(message, isFirst, prevMessage))
          const SizedBox(height: 8),
        // 消息内容（🔥 修复：添加白色背景，与正常状态一致）
        Center(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: _shouldShowTimestampInGroup(message, isFirst, prevMessage) ? 0 : 6,
              bottom: 6,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: hasJump ? () => _handleMessageTap(message) : null,
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
                    if (displayIcon != null) ...[
                      _buildEventIcon(displayIcon),
                      const SizedBox(width: 4),
                    ],
                    // 文字内容
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: _buildTextWithColorOverrides(
                              displayContent,
                              message.imFontColor,
                              const TextStyle(fontSize: 13, color: Color(0xFF333333)),
                            ),
                          ),
                      // 仅当消息标记is_vip=1且用户非VIP时显示VIP按钮
                      if (messageIsVip && !isUserVip) ...[
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
                              logError('跳转 VIP 页面失败: $e');
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
                        Image.asset(
                          'assets/4.0/kissu4_new_use_right.webp',
                          width: 6,
                          height: 6,
                          color: const Color(0xff009BFE),
                        ),
                      ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建展开状态下的 locationNotice 消息（位置通知）
  /// 样式与 ChatMessageItem._buildLocationNoticeMessage 保持一致
  Widget _buildExpandedLocationNoticeItem(ChatMessage message, bool isFirst, ChatMessage? prevMessage) {
    // 获取用户VIP状态
    final bool isUserVip = widget.controller.isVip.value;

    // 处理非VIP用户的位置名称（保留前6位+*****）
    String displayLocationName = message.locationName ?? '位置信息';
    if (!isUserVip) {
      if (displayLocationName.length > 6) {
        displayLocationName = '${displayLocationName.substring(0, 6)}*****';
      } else if (displayLocationName.isNotEmpty) {
        displayLocationName = '$displayLocationName*****';
      }
    }

    return Column(
      children: [
        // 时间戳（根据需要显示）
        if (_shouldShowTimestampInGroup(message, isFirst, prevMessage))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 12, top: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _formatTime(message.time),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0x99000000),
              ),
            ),
          ),
        // 时间戳和消息之间的间距
        if (_shouldShowTimestampInGroup(message, isFirst, prevMessage))
          const SizedBox(height: 8),
        // 位置通知内容（与 ChatMessageItem._buildLocationNoticeMessage 样式一致）
        // 🔥 修复：外层 _buildExpandedGroup 已有 margin: horizontal: 16，所以这里 padding 需要减去 16
        // ChatMessageItem 使用 horizontal: 60，这里需要 60 - 16 = 44
        Padding(
          padding: EdgeInsets.only(
            left: 44,
            right: 44,
            top: _shouldShowTimestampInGroup(message, isFirst, prevMessage) ? 0 : 7,
            bottom: 7,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: isUserVip
                ? (message.latitude != null && message.longitude != null
                    ? () => _showLocationDetail(message)
                    : null)
                : () => _navigateToVipPage(),
            child: Container(
              width: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xffE8E8E8), width: 1),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0f000000),
                    blurRadius: 7.3,
                    offset: Offset(0, 0),
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
                                message.content.contains("到达")
                                    ? 'assets/chat/chat_location_come.webp'
                                    : message.content.contains("离开")
                                        ? 'assets/chat/chat_location_away.webp'
                                        : 'assets/chat/chat_location_stay.webp',
                              ),
                              width: 18,
                            ),
                            Expanded(
                              child: Text(
                                message.content,
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
                        const SizedBox(height: 5),
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
                        if (message.latitude != null && message.longitude != null)
                          _buildLocationPreviewWithMask(message, isUserVip)
                        else
                          _buildSimpleLocationPreviewWithMask(message, isUserVip),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建带蒙版的地图快照（非VIP用户显示蒙版）
  Widget _buildLocationPreviewWithMask(ChatMessage message, bool isUserVip) {
    final locationPreview = LocationPreviewWidget(
      latitude: message.latitude!,
      longitude: message.longitude!,
      locationName: message.locationName ?? '位置信息',
      width: 206,
      height: 48,
      avatarUrl: message.avatarUrl,
      onTap: isUserVip
          ? () => _showLocationDetail(message)
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
                  color: const Color(0x52000000),
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
  Widget _buildSimpleLocationPreviewWithMask(ChatMessage message, bool isUserVip) {
    final simplePreview = SimpleLocationPreviewWidget(
      locationName: message.locationName ?? '位置信息',
      width: 206,
      height: 48,
      onTap: isUserVip
          ? () => _showLocationDetail(message)
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
                  color: const Color(0x52000000),
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

  /// 显示位置详情
  /// 🔥 修复：统一跳转到轨迹页面（而非定位详情页面）
  void _showLocationDetail(ChatMessage message) {
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

    // 🔥 修复：跳转到轨迹页面（与非折叠模式保持一致）
    Get.to(
      () => TrackPage(
        initialLatitude: message.latitude,
        initialLongitude: message.longitude,
        initialLocationName: message.locationName,
        autoShowInfoWindow: true,
      ),
      binding: TrackBinding(),
      transition: Transition.rightToLeft,
    );
  }

  /// 跳转到VIP页面
  void _navigateToVipPage() {
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
      logError('跳转 VIP 页面失败: $e');
    }
  }

  /// 根据用户VIP状态获取消息显示内容
  String _getDisplayContent(ChatMessage message, bool isUserVip) {
    // 如果消息标记了is_vip=1，根据用户VIP状态显示不同内容
    if ((message.isVip ?? 0) == 1) {
      if (isUserVip) {
        // VIP用户：优先显示imVipContent，如果没有则显示content
        return message.imVipContent ?? message.content;
      } else {
        // 非VIP用户：显示content
        return message.content;
      }
    }
    // 普通消息直接显示content
    return message.content;
  }

  /// 根据用户VIP状态获取消息显示图标（VIP用户显示vipIcon，非VIP用户显示iconUrl）
  String? _getDisplayIcon(ChatMessage message, bool isUserVip) {
    if (isUserVip) {
      // VIP用户：优先显示vipIcon，如果没有则显示iconUrl
      return message.vipIcon ?? message.iconUrl;
    } else {
      // 非VIP用户：显示iconUrl
      return message.iconUrl;
    }
  }

  /// 判断在折叠组中是否显示时间戳
  bool _shouldShowTimestampInGroup(ChatMessage message, bool isFirst, ChatMessage? prevMessage) {
    // 如果是第一条消息且没有前置消息，总是显示时间
    if (isFirst && prevMessage == null) return true;
    
    // 如果没有上一条消息，不显示
    if (prevMessage == null) return false;
    
    final currentTime = message.time;
    final prevTime = prevMessage.time;
    
    // 跨天：一定显示
    final isSameDay = currentTime.year == prevTime.year &&
        currentTime.month == prevTime.month &&
        currentTime.day == prevTime.day;
    if (!isSameDay) {
      return true;
    }
    
    // 同一天：间隔超过1分钟则显示时间戳
    final timeDiff = currentTime.difference(prevTime);
    return timeDiff.inMinutes >= 1;
  }

  /// 格式化时间显示
  /// - 今天：显示"今天 HH:mm"
  /// - 昨天：显示"昨天 HH:mm"
  /// - 更早：显示"MM月dd日 HH:mm"
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

  /// 构建事件图标
  Widget _buildEventIcon(String iconUrl) {
    if (iconUrl.startsWith('http://') || iconUrl.startsWith('https://')) {
      return Image.network(
        iconUrl,
        width: 16,
        height: 16,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(width: 16, height: 16);
        },
      );
    } else {
      return Image.asset(
        iconUrl,
        width: 16,
        height: 16,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(width: 16, height: 16);
        },
      );
    }
  }

  /// 构建带颜色覆盖的文本
  Widget _buildTextWithColorOverrides(
    String content,
    List<FontColorItem>? fontItems,
    TextStyle baseStyle,
  ) {
    if (fontItems == null || fontItems.isEmpty) {
      return Text(content, style: baseStyle);
    }

    List<TextSpan> spans = [];
    String remaining = content;

    for (final item in fontItems) {
      final index = remaining.indexOf(item.changeText);
      if (index >= 0) {
        if (index > 0) {
          spans.add(
            TextSpan(text: remaining.substring(0, index), style: baseStyle),
          );
        }
        spans.add(
          TextSpan(
            text: item.changeText,
            style: baseStyle.copyWith(color: _parseColor(item.colorHex)),
          ),
        );
        remaining = remaining.substring(index + item.changeText.length);
      }
    }

    if (remaining.isNotEmpty) {
      spans.add(TextSpan(text: remaining, style: baseStyle));
    }

    return Text.rich(TextSpan(children: spans));
  }

  /// 解析颜色
  Color _parseColor(String hex) {
    try {
      String colorStr = hex.replaceAll('#', '');
      if (colorStr.length == 6) {
        colorStr = 'FF$colorStr';
      }
      return Color(int.parse(colorStr, radix: 16));
    } catch (_) {
      return const Color(0xFF4E90FF);
    }
  }

  /// 处理消息点击跳转
  Future<void> _handleMessageTap(ChatMessage message) async {
    final jump = message.jumpPage;
    try {
      if (jump == null || jump.isEmpty) {
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
          Get.toNamed(KissuRoutePath.track);
          break;
        case 'unlockPhonePage':
          Get.toNamed(KissuRoutePath.appUsageInfo);
          break;
        case 'mobileUse':
          Get.toNamed(KissuRoutePath.deviceUsage, arguments: {'source_event': ChatEvents.page});
          break;
        case 'locationPage':
          Get.toNamed(KissuRoutePath.location);
          break;
        case 'locationReminder':
          Get.toNamed(KissuRoutePath.locationReminder);
          break;
        default:
          break;
      }
    } catch (e) {
      logError('导航失败: $e');
    }
  }

  /// 构建单条消息
  Widget _buildSingleMessage(BuildContext context, _SingleMessageItem item) {
    final message = item.message;
    final reverseIndex = item.originalIndex;

    // 通用时间显示规则由 ChatController 统一管理
    bool showTimestamp = widget.controller.shouldShowTimestampForIndex(
      reverseIndex,
    );

    // 对于敏感消息类型（systemEvent 和 locationNotice），再加一条去重规则
    if (_isSensitiveMessage(message) && reverseIndex > 0) {
      final messages = widget.controller.messages;
      final prevMessage = messages[reverseIndex - 1];
      if (_isSensitiveMessage(prevMessage)) {
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
        _openImageGallery(context, widget.controller, msg);
      },
    );
  }
}

/// 渲染项基类
abstract class _RenderItem {}

/// 单条消息渲染项
class _SingleMessageItem extends _RenderItem {
  final ChatMessage message;
  final int originalIndex;

  _SingleMessageItem({required this.message, required this.originalIndex});
}

/// 折叠组渲染项
class _CollapseGroupItem extends _RenderItem {
  final String groupId;
  final List<ChatMessage> messages;
  final int startIndex;

  _CollapseGroupItem({
    required this.groupId,
    required this.messages,
    required this.startIndex,
  });
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
  final initialIndex = imageMessages.indexWhere(
    (m) => m.id == targetMessage.id,
  );
  if (initialIndex < 0) return;

  final imageUrls = imageMessages.map((m) => m.imageUrl!).toList();

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) =>
          ImagePreviewPage(imageUrls: imageUrls, initialIndex: initialIndex),
      fullscreenDialog: true,
    ),
  );
}
