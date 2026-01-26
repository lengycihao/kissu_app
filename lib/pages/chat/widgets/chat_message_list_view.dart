import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/chat/chat_controller.dart';
import 'package:kissu_app/pages/chat/widgets/chat_message_item.dart';
import 'package:kissu_app/pages/chat/widgets/image_preview_page.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/source_page_utils.dart';

/// 聊天消息列表区域，只负责列表渲染
class ChatMessageListView extends StatefulWidget {
  const ChatMessageListView({
    super.key,
    required this.controller,
  });

  final ChatController controller;

  @override
  State<ChatMessageListView> createState() => _ChatMessageListViewState();
}

class _ChatMessageListViewState extends State<ChatMessageListView> {
  /// 存储需要折叠的消息组的展开状态
  /// key: 折叠组的起始消息ID, value: 是否展开
  final Map<String, bool> _expandedGroups = {};

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

  /// 构建渲染项列表，将连续超过3条的systemEvent消息合并为折叠组
  List<_RenderItem> _buildRenderItems(List<ChatMessage> messages) {
    final List<_RenderItem> items = [];
    int i = 0;
    
    // 检查是否开启了敏感消息折叠
    final isCollapseEnabled = widget.controller.sensitiveCollapseEnabled.value;
    
    while (i < messages.length) {
      final message = messages[i];
      
      // 检查是否是systemEvent类型，且开启了折叠功能
      if (message.type == MessageType.systemEvent && isCollapseEnabled) {
        // 查找连续的systemEvent消息
        int endIndex = i;
        while (endIndex + 1 < messages.length &&
               messages[endIndex + 1].type == MessageType.systemEvent) {
          endIndex++;
        }
        
        final consecutiveCount = endIndex - i + 1;
        
        // 如果连续超过3条，创建折叠组
        if (consecutiveCount > 3) {
          final groupMessages = messages.sublist(i, endIndex + 1);
          final groupId = groupMessages.first.id;
          items.add(_CollapseGroupItem(
            groupId: groupId,
            messages: groupMessages,
            startIndex: i,
          ));
          i = endIndex + 1;
        } else {
          // 不足3条，逐条添加
          for (int j = i; j <= endIndex; j++) {
            items.add(_SingleMessageItem(
              message: messages[j],
              originalIndex: j,
            ));
          }
          i = endIndex + 1;
        }
      } else {
        // 非systemEvent消息或未开启折叠，直接添加
        items.add(_SingleMessageItem(
          message: message,
          originalIndex: i,
        ));
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _expandedGroups[item.groupId] = true;
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
                  Image(image: AssetImage('assets/188/kissu_chat_show_down.webp'),width: 14,height: 14,),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建展开状态的组
  Widget _buildExpandedGroup(BuildContext context, _CollapseGroupItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
       ),
      child: Column(
        children: [
          // 消息列表
          ...item.messages.asMap().entries.map((entry) {
            final index = entry.key;
            final message = entry.value;
            return _buildExpandedMessageItem(message, index == 0);
          }),
          // 收起按钮
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedGroups[item.groupId] = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                    
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '收起',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFaaaaaa),
                      ),
                    ),
                    SizedBox(width: 4),
                    Image(image: AssetImage('assets/188/kissu_chat_show_up.webp'),width: 14,height:   14,),
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
  Widget _buildExpandedMessageItem(ChatMessage message, bool isFirst) {
    final bool hasJump = message.jumpPage != null && message.jumpPage!.isNotEmpty;
    final bool isVip = (message.isVip ?? 0) == 1;
    
    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: isFirst ? 12 : 8,
        bottom: 4,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: hasJump ? () => _handleMessageTap(message) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 图标
            if (message.iconUrl != null) ...[
              _buildEventIcon(message.iconUrl!),
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
                      message.content,
                      message.imFontColor,
                      const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  // 优先级：is_vip == 1 显示 VIP 按钮，否则有 jumpPage 时显示蓝色小箭头
                  if (isVip) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        try {
                          // 埋点：页面离开（进入下一页）
                          try {
                            final controller = Get.find<ChatController>();
                            controller.onNavigateToNextPage?.call();
                          } catch (_) {}
                          
                          Get.toNamed(KissuRoutePath.vip, arguments: {'source_page': SourcePageUtilsCaller.chat});
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
    );
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
          spans.add(TextSpan(text: remaining.substring(0, index), style: baseStyle));
        }
        spans.add(TextSpan(
          text: item.changeText,
          style: baseStyle.copyWith(color: _parseColor(item.colorHex)),
        ));
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
          Get.toNamed(KissuRoutePath.deviceUsage);
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
      debugPrint('导航失败: $e');
    }
  }

  /// 构建单条消息
  Widget _buildSingleMessage(BuildContext context, _SingleMessageItem item) {
    final message = item.message;
    final reverseIndex = item.originalIndex;
    
    // 通用时间显示规则由 ChatController 统一管理
    bool showTimestamp = widget.controller.shouldShowTimestampForIndex(reverseIndex);

    // 对于 systemEvent 类型，再加一条去重规则
    if (message.type == MessageType.systemEvent && reverseIndex > 0) {
      final messages = widget.controller.messages;
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
  
  _SingleMessageItem({
    required this.message,
    required this.originalIndex,
  });
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


