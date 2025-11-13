/// 解绑原因相关数据模型

/// 解绑原因项
class UnbindReasonModel {
  final int id;
  final String name;
  final int supplementReason; // 0: 不需要输入框, 1: 需要输入框

  UnbindReasonModel({
    required this.id,
    required this.name,
    required this.supplementReason,
  });

  factory UnbindReasonModel.fromJson(Map<String, dynamic> json) {
    return UnbindReasonModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      supplementReason: json['supplement_reason'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'supplement_reason': supplementReason,
    };
  }

  /// 是否需要补充说明（输入框）
  bool get needSupplement => supplementReason == 1;
}

/// 解绑原因列表响应模型
class UnbindReasonListResponse {
  final List<UnbindReasonModel> list;

  UnbindReasonListResponse({
    required this.list,
  });

  factory UnbindReasonListResponse.fromJson(Map<String, dynamic> json) {
    return UnbindReasonListResponse(
      list: (json['list'] as List<dynamic>?)
              ?.map((e) => UnbindReasonModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'list': list.map((e) => e.toJson()).toList(),
    };
  }
}

