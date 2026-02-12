import 'dart:convert';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:kissu_app/utils/user_manager.dart';
import '../models/chat_message.dart';

/// IM消息转换工具类
/// 负责将腾讯IM消息转换为应用内的ChatMessage模型
class MessageConverter {
  /// 对方头像URL（用于接收的消息）
  final String partnerAvatarUrl;

  MessageConverter({required this.partnerAvatarUrl});

  /// 将腾讯 IM 消息转换为 ChatMessage（仅处理当前会话、文字、图片、自定义等）
  ChatMessage? convert(
    V2TimMessage msg, {
    required String? currentUserId,
    required String? partnerId,
  }) {
    // 只处理单聊
    if ((msg.groupID ?? '').isNotEmpty) return null;

    final sender = msg.sender;
    final peerId = msg.userID;
    final isSelf = sender == currentUserId;

    // 只处理当前聊天对象的消息
    if (partnerId != null && partnerId.isNotEmpty) {
      final isFromPartner = sender == partnerId;
      final isToPartner = peerId == partnerId;
      if (!(isFromPartner || (isSelf && isToPartner))) {
        return null;
      }
    }

    // 时间
    final msgTimeSeconds =
        msg.timestamp ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final msgTime =
        DateTime.fromMillisecondsSinceEpoch(msgTimeSeconds * 1000);

    // 自定义消息处理
    if (msg.customElem?.data != null && msg.customElem!.data!.isNotEmpty) {
      final customResult = _parseCustomMessage(msg, isSelf, msgTime);
      if (customResult != null) return customResult;
    }

    // 文本消息
    if (msg.textElem?.text != null && msg.textElem!.text!.isNotEmpty) {
      final text = msg.textElem!.text!;

      return ChatMessage(
        id: msg.msgID ?? DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        type: MessageType.text,
        isSent: isSelf,
        time: msgTime,
        avatarUrl: isSelf ? UserManager.userAvatar : partnerAvatarUrl,
      );
    }

    // 图片消息
    if (msg.imageElem != null) {
      return _parseImageMessage(msg, isSelf, msgTime);
    }

    // 其他类型暂不处理
    return null;
  }

  /// 解析自定义消息
  ChatMessage? _parseCustomMessage(V2TimMessage msg, bool isSelf, DateTime msgTime) {
    try {
      final raw = msg.customElem!.data!;
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        // 处理敏感事件（sensitive）——可能是文本或位置通知，支持 im_font_color 和 default_ext
        final String? msgType = decoded['msg_type'] as String?;
        if (msgType == 'sensitive') {
          return _parseSensitiveMessage(decoded, msg, isSelf, msgTime);
        }

        // 处理一起便便消息（msg_bubble: "defecate" 或 "endDefecate"）
        final String? msgBubble = decoded['msg_bubble'] as String?;
        if (msgBubble == 'defecate') {
          return ChatMessage(
            id: msg.msgID ?? DateTime.now().millisecondsSinceEpoch.toString(),
            content: '亲爱的，我们开始拉屎吧～',
            type: MessageType.defecate,
            isSent: isSelf,
            time: msgTime,
            avatarUrl: isSelf ? UserManager.userAvatar : partnerAvatarUrl,
          );
        }
        // 处理结束拉屎消息（msg_bubble: "endDefecate"）
        if (msgBubble == 'endDefecate') {
          final String? duration = decoded['crap_duration'] as String?;
          return ChatMessage(
            id: msg.msgID ?? DateTime.now().millisecondsSinceEpoch.toString(),
            content: '亲爱的，我结束拉屎啦，共拉了${duration ?? ''}',
            type: MessageType.defecate,
            isSent: isSelf,
            time: msgTime,
            avatarUrl: isSelf ? UserManager.userAvatar : partnerAvatarUrl,
            crapDuration: duration,
          );
        }
      }
    } catch (_) {
      // 自定义消息解析异常时忽略，继续按其他类型处理
    }
    return null;
  }

  /// 解析敏感事件消息
  ChatMessage? _parseSensitiveMessage(
    Map<String, dynamic> decoded,
    V2TimMessage msg,
    bool isSelf,
    DateTime msgTime,
  ) {
    final String messageType = (decoded['message_type'] as String?) ?? 'text';

    // 通用字段
    final String content =
        (decoded['content'] as String?)?.trim().isNotEmpty == true
            ? (decoded['content'] as String?)!
            : '系统通知';
    final String? icon = decoded['icon'] as String?;
    final String? jumpPage = decoded['jump_page'] as String?;

    // 解析 im_font_color（可选）
    List<FontColorItem>? fontItems;
    try {
      final rawFont = decoded['im_font_color'];
      if (rawFont is List && rawFont.isNotEmpty) {
        fontItems = rawFont.map<FontColorItem?>((e) {
          try {
            if (e is Map) {
              final changeText = (e['change_text'] as String?) ?? '';
              final colorHex = (e['color'] as String?) ?? '#4E90FF';
              if (changeText.isEmpty) return null;
              return FontColorItem(changeText: changeText, colorHex: colorHex);
            }
          } catch (_) {}
          return null;
        }).whereType<FontColorItem>().toList();
        if (fontItems.isEmpty) fontItems = null;
      }
    } catch (_) {
      fontItems = null;
    }

    // 解析 is_vip（可选）
    int? isVip;
    try {
      final rawVip = decoded['is_vip'];
      if (rawVip != null) {
        if (rawVip is int) {
          isVip = rawVip;
        } else {
          isVip = int.tryParse(rawVip.toString());
        }
      }
    } catch (_) {
      isVip = null;
    }

    // 解析 im_vip_content（VIP用户显示的内容）
    String? imVipContent;
    try {
      imVipContent = decoded['im_vip_content'] as String?;
    } catch (_) {
      imVipContent = null;
    }

    // 解析 vip_icon（VIP用户显示的图标）
    String? vipIcon;
    try {
      vipIcon = decoded['vip_icon'] as String?;
    } catch (_) {
      vipIcon = null;
    }

    // 如果服务端把敏感事件标记为位置类型，则构建居中的位置通知（不走气泡）
    if (messageType == 'location') {
      final Map<String, dynamic>? ext =
          (decoded['default_ext'] is Map) ? Map<String, dynamic>.from(decoded['default_ext']) : null;
      double? lat;
      double? lng;
      String? locName;
      if (ext != null) {
        lat = double.tryParse((ext['latitude'] ?? ext['lat'] ?? '').toString());
        lng = double.tryParse((ext['longitude'] ?? ext['lon'] ?? ext['lng'] ?? '').toString());
        locName = (ext['location_name'] as String?) ?? (ext['location'] as String?) ?? ext['location_name']?.toString();
      }

      return ChatMessage(
        id: msg.msgID ?? DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        type: MessageType.locationNotice,
        isSent: isSelf,
        time: msgTime,
        avatarUrl: null,
        locationName: locName,
        latitude: lat,
        longitude: lng,
        iconUrl: icon,
        jumpPage: (jumpPage != null && jumpPage.isNotEmpty) ? jumpPage : null,
        defaultExt: ext,
      );
    }

    // 否则按文本型敏感事件处理（保留原有 systemEvent 展示，但支持富文本替换）
    return ChatMessage(
      id: msg.msgID ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.systemEvent,
      isSent: isSelf, // systemEvent 显示居中，不区分左右
      time: msgTime,
      avatarUrl: null,
      iconUrl: icon,
      vipIcon: vipIcon, // VIP用户显示的图标
      jumpPage: (jumpPage != null && jumpPage.isNotEmpty) ? jumpPage : null,
      imFontColor: fontItems,
      isVip: isVip,
      imVipContent: imVipContent,
    );
  }

  /// 解析图片消息
  ChatMessage? _parseImageMessage(V2TimMessage msg, bool isSelf, DateTime msgTime) {
    // 尝试优先使用大图/原图/缩略图中的 URL，其次使用本地路径
    String? imageUrl;
    double? imageWidth;
    double? imageHeight;
    if (msg.imageElem!.imageList != null &&
        msg.imageElem!.imageList!.isNotEmpty) {
      // 这里简单取第一张（通常是缩略图），具体可以按类型筛选
      final first = msg.imageElem!.imageList!.first;
      imageUrl = first?.url ?? first?.localUrl;
      // 腾讯 IM 的 V2TimImage 一般会带宽高信息，这里用于前端展示比例
      try {
        if (first != null) {
          final w = first.width;
          final h = first.height;
          if (w != null && h != null && w > 0 && h > 0) {
            imageWidth = w.toDouble();
            imageHeight = h.toDouble();
          }
        }
      } catch (_) {
        // 忽略宽高解析异常，走默认展示比例
      }
    }
    imageUrl ??= msg.imageElem!.path;

    return ChatMessage(
      id: msg.msgID ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: '[图片]',
      type: MessageType.image,
      isSent: isSelf,
      time: msgTime,
      avatarUrl: isSelf ? UserManager.userAvatar : partnerAvatarUrl,
      imageUrl: imageUrl,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      isRead: msg.isRead ?? false,
    );
  }
}
