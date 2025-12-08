/// 解绑原因相关数据模型

/// 解绑原因项
class UnbindReasonModel {
  final int id;
  final String name; // 显示名称，从 reason 字段获取
  final int supplementReason; // 0: 不需要输入框, 1: 需要输入框（从 is_require_reason 字段获取）

  UnbindReasonModel({
    required this.id,
    required this.name,
    required this.supplementReason,
  });

  factory UnbindReasonModel.fromJson(Map<String, dynamic> json) {
    return UnbindReasonModel(
      id: json['id'] as int? ?? 0,
      name: json['reason'] as String? ?? '', // 使用新的 reason 字段
      supplementReason: json['is_require_reason'] as int? ?? 0, // 使用新的 is_require_reason 字段
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reason': name, // 序列化时使用 reason 字段名
      'is_require_reason': supplementReason, // 序列化时使用 is_require_reason 字段名
    };
  }

  /// 是否需要补充说明（输入框）
  /// 根据 is_require_reason 是否为 1 来判断
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

