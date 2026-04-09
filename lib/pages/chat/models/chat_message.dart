/// 聊天消息类型
enum MessageType {
  text, // 文字消息
  image, // 图片消息
  location, // 位置消息
  locationNotice, // 位置通知（居中显示，不带气泡，用地图快照展示）
  systemEvent, // 系统事件消息（图标+文字，居中显示）
  defecate, // 一起便便消息（特殊气泡样式）
  lockPhone, // 锁机提醒卡片消息（开启悬浮窗权限）
  phoneUse, // 应用使用记录权限提醒卡片消息
  connectApp, // 关联app卡片消息
  sayGuess, // 你说我猜邀请卡片消息
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
  final String? vipIcon; // VIP用户显示的图标URL（非VIP用户显示iconUrl）
  final String? crapDuration; // 拉屎时长（用于endDefecate类型，如"0分30秒"）
  final String? jumpPage; // 跳转页面标识（用于敏感事件systemEvent）
  final List<FontColorItem>? imFontColor; // 文本需要变色的配置项
  final Map<String, dynamic>? defaultExt; // 原始扩展字段（用于位置等）
  final int? isVip; // 服务端字段 is_vip: 1 表示 VIP 优先展示
  final String? imVipContent; // VIP用户显示的内容（非VIP用户显示content）
  final String? groupId; // 游戏群ID（用于sayGuess邀请消息）

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
    this.vipIcon, // VIP用户显示的图标URL
    this.crapDuration, // 拉屎时长（用于endDefecate类型）
    this.jumpPage, // 跳转页面标识
    this.imFontColor,
    this.defaultExt,
    this.isVip,
    this.imVipContent,
    this.groupId,
  });

  /// 创建一个带有更新字段的新消息副本
  ChatMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    bool? isSent,
    DateTime? time,
    String? avatarUrl,
    String? imageUrl,
    double? imageWidth,
    double? imageHeight,
    String? locationName,
    double? latitude,
    double? longitude,
    bool? isRead,
    String? iconUrl,
    String? vipIcon,
    String? crapDuration,
    String? jumpPage,
    List<FontColorItem>? imFontColor,
    Map<String, dynamic>? defaultExt,
    int? isVip,
    String? imVipContent,
    String? groupId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      isSent: isSent ?? this.isSent,
      time: time ?? this.time,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isRead: isRead ?? this.isRead,
      iconUrl: iconUrl ?? this.iconUrl,
      vipIcon: vipIcon ?? this.vipIcon,
      crapDuration: crapDuration ?? this.crapDuration,
      jumpPage: jumpPage ?? this.jumpPage,
      imFontColor: imFontColor ?? this.imFontColor,
      defaultExt: defaultExt ?? this.defaultExt,
      isVip: isVip ?? this.isVip,
      imVipContent: imVipContent ?? this.imVipContent,
      groupId: groupId ?? this.groupId,
    );
  }
}

/// 富文本颜色替换项（从服务端 im_font_color 字段解析）
class FontColorItem {
  final String changeText;
  final String colorHex;

  FontColorItem({
    required this.changeText,
    required this.colorHex,
  });
}
