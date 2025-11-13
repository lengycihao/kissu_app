class VipBannerModel {
  final List<VipIconBanner> vipIconBanner;
  final List<CommentItem> commentList;
  final String desc;

  VipBannerModel({
    required this.vipIconBanner,
    required this.commentList,
    required this.desc,
  });

  factory VipBannerModel.fromJson(Map<String, dynamic> json) {
    return VipBannerModel(
      vipIconBanner: (json['vip_icon_banner'] as List<dynamic>?)
              ?.map((item) => VipIconBanner.fromJson(item))
              .toList() ??
          [],
      commentList: (json['comment_list'] as List<dynamic>?)
              ?.map((item) => CommentItem.fromJson(item))
              .toList() ??
          [],
      desc: json['desc'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vip_icon_banner': vipIconBanner.map((item) => item.toJson()).toList(),
      'comment_list': commentList.map((item) => item.toJson()).toList(),
      'desc': desc,
    };
  }
}

class VipIconBanner {
  final String vipIconVideo;
  final String vipIconBanner;
  final String vipIcon;
  final String vipIconSelect;
  final String vipIconBannerDesc;
  // final String vipPagAsset; // 新增PAG动画资源路径 - 暂时移除

  VipIconBanner({
    required this.vipIconVideo,
    required this.vipIconBanner,
    required this.vipIcon,
    required this.vipIconSelect,
    required this.vipIconBannerDesc,
    // this.vipPagAsset = '', // PAG资源路径，默认为空 - 暂时移除
  });

  factory VipIconBanner.fromJson(Map<String, dynamic> json) {
    return VipIconBanner(
      vipIconVideo: json['vip_icon_video'] ?? '',
      vipIconBanner: json['vip_icon_banner'] ?? '',
      vipIcon: json['vip_icon'] ?? '',
      vipIconSelect: json['vip_icon_select'] ?? '',
      vipIconBannerDesc: json['vip_icon_banner_desc'] ?? '',
      // vipPagAsset: json['vip_pag_asset'] ?? '', // 支持从JSON解析PAG资源 - 暂时移除
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vip_icon_video': vipIconVideo,
      'vip_icon_banner': vipIconBanner,
      'vip_icon': vipIcon,
      'vip_icon_select': vipIconSelect,
      'vip_icon_banner_desc': vipIconBannerDesc,
      // 'vip_pag_asset': vipPagAsset, // 序列化PAG资源路径 - 暂时移除
    };
  }

  // 获取轮播图展示内容（PAG动画暂时移除）
  String get displayContent {
    // if (vipPagAsset.isNotEmpty) return vipPagAsset; // PAG暂时移除
    return vipIconVideo.isNotEmpty ? vipIconVideo : vipIconBanner;
  }

  // 判断是否有视频
  bool get hasVideo {
    return vipIconVideo.isNotEmpty;
  }

  bool get hasBannerDesc => vipIconBannerDesc.isNotEmpty;

  // 判断是否有PAG动画 - 暂时移除
  // bool get hasPagAnimation {
  //   return vipPagAsset.isNotEmpty;
  // }
}

class CommentItem {
  final String date;
  final String nickname;
  final String content;
  final String avatar;
  final String vipIcon;
  final String starImage;

  CommentItem({
    required this.date,
    required this.nickname,
    required this.content,
    required this.avatar,
    required this.vipIcon,
    required this.starImage,
  });

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    return CommentItem(
      date: json['date'] ?? '',
      nickname: json['nickname'] ?? '',
      content: json['content'] ?? '',
      avatar: json['avatar'] ?? '',
      vipIcon: json['vip_icon'] ?? '',
      starImage: json['star_image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'nickname': nickname,
      'content': content,
      'avatar': avatar,
      'vip_icon': vipIcon,
      'star_image': starImage,
    };
  }

  bool get hasAvatar => avatar.isNotEmpty;

  bool get hasVipIcon => vipIcon.isNotEmpty;

  bool get hasStarImage => starImage.isNotEmpty;
}