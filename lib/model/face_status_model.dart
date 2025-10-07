/// 状态表情相关数据模型

/// 表情状态响应模型
class FaceStatusResponseModel {
  final List<FaceCategory> faceList;
  final CurrentFaceStatus? nowFace;

  FaceStatusResponseModel({
    required this.faceList,
    this.nowFace,
  });

  factory FaceStatusResponseModel.fromJson(Map<String, dynamic> json) {
    return FaceStatusResponseModel(
      faceList: (json['face_list'] as List<dynamic>?)
              ?.map((e) => FaceCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nowFace: json['now_face'] != null
          ? CurrentFaceStatus.fromJson(json['now_face'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'face_list': faceList.map((e) => e.toJson()).toList(),
      'now_face': nowFace?.toJson(),
    };
  }
}

/// 表情分类
class FaceCategory {
  final int classId;
  final String className;
  final List<FaceItem> faceList;

  FaceCategory({
    required this.classId,
    required this.className,
    required this.faceList,
  });

  factory FaceCategory.fromJson(Map<String, dynamic> json) {
    return FaceCategory(
      classId: json['class_id'] as int? ?? 0,
      className: json['class_name'] as String? ?? '',
      faceList: (json['face_list'] as List<dynamic>?)
              ?.map((e) => FaceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'class_name': className,
      'face_list': faceList.map((e) => e.toJson()).toList(),
    };
  }
}

/// 表情项
class FaceItem {
  final int id;
  final String faceUrl;
  final String faceText;

  FaceItem({
    required this.id,
    required this.faceUrl,
    required this.faceText,
  });

  factory FaceItem.fromJson(Map<String, dynamic> json) {
    return FaceItem(
      id: json['id'] as int? ?? 0,
      faceUrl: json['face_url'] as String? ?? '',
      faceText: json['face_text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'face_url': faceUrl,
      'face_text': faceText,
    };
  }
}

/// 当前用户状态
class CurrentFaceStatus {
  final String faceText;
  final int classId;
  final int id;
  final String faceUrl;
  final String className;
  final int createTime;
  final int faceExpire; // 有效期（小时）：1,2,4,6,8,12

  CurrentFaceStatus({
    required this.faceText,
    required this.classId,
    required this.id,
    required this.faceUrl,
    required this.className,
    required this.createTime,
    required this.faceExpire,
  });

  factory CurrentFaceStatus.fromJson(Map<String, dynamic> json) {
    return CurrentFaceStatus(
      faceText: json['face_text'] as String? ?? '',
      classId: json['class_id'] as int? ?? 0,
      id: json['id'] as int? ?? 0,
      faceUrl: json['face_url'] as String? ?? '',
      className: json['class_name'] as String? ?? '',
      createTime: json['create_time'] as int? ?? 0,
      faceExpire: json['face_expire'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'face_text': faceText,
      'class_id': classId,
      'id': id,
      'face_url': faceUrl,
      'class_name': className,
      'create_time': createTime,
      'face_expire': faceExpire,
    };
  }

  /// 获取状态创建时间
  DateTime get createDateTime =>
      DateTime.fromMillisecondsSinceEpoch(createTime * 1000);
}

