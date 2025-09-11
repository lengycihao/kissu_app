class VipBannerModel {
  final List<VipIconBanner> vipIconBanner;
  final List<CommentItem> commentList;

  VipBannerModel({
    required this.vipIconBanner,
    required this.commentList,
  });

  factory VipBannerModel.fromJson(Map<String, dynamic> json) {
    return VipBannerModel(
      vipIconBanner: (json['vip_icon_banner'] as List<dynamic>?)
          ?.map((item) => VipIconBanner.fromJson(item))
          .toList() ?? [],
      commentList: (json['comment_list'] as List<dynamic>?)
          ?.map((item) => CommentItem.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vip_icon_banner': vipIconBanner.map((item) => item.toJson()).toList(),
      'comment_list': commentList.map((item) => item.toJson()).toList(),
    };
  }
}

class VipIconBanner {
  final String vipIconVideo;
  final String vipIconBanner;
  final String vipIcon;
  final String vipIconSelect;

  VipIconBanner({
    required this.vipIconVideo,
    required this.vipIconBanner,
    required this.vipIcon,
    required this.vipIconSelect,
  });

  factory VipIconBanner.fromJson(Map<String, dynamic> json) {
    return VipIconBanner(
      vipIconVideo: json['vip_icon_video'] ?? '',
      vipIconBanner: json['vip_icon_banner'] ?? '',
      vipIcon: json['vip_icon'] ?? '',
      vipIconSelect: json['vip_icon_select'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vip_icon_video': vipIconVideo,
      'vip_icon_banner': vipIconBanner,
      'vip_icon': vipIcon,
      'vip_icon_select': vipIconSelect,
    };
  }

  // 获取轮播图展示内容（优先视频，其次图片）
  String get displayContent {
    return vipIconVideo.isNotEmpty ? vipIconVideo : vipIconBanner;
  }

  // 判断是否有视频
  bool get hasVideo {
    return vipIconVideo.isNotEmpty;
  }
}

class CommentItem {
  final String date;
  final String nickname;
  final String content;

  CommentItem({
    required this.date,
    required this.nickname,
    required this.content,
  });

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    return CommentItem(
      date: json['date'] ?? '',
      nickname: json['nickname'] ?? '',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'nickname': nickname,
      'content': content,
    };
  }
}