/// 解绑原因相关数据模型

/// 解绑原因项
class UnbindReasonModel {
  final int id;
  final String name; // 显示名称，从 reason 字段获取
  final int supplementReason; // 0: 不需要输入框, 1: 需要输入框（从 is_require_reason 字段获取）
  final String? defaultText; // 输入框占位符文本
  final String? operationType; // 操作类型: privacy(隐私安全), price(价格挽留)

  UnbindReasonModel({
    required this.id,
    required this.name,
    required this.supplementReason,
    this.defaultText,
    this.operationType,
  });

  factory UnbindReasonModel.fromJson(Map<String, dynamic> json) {
    return UnbindReasonModel(
      id: json['id'] as int? ?? 0,
      name: json['reason'] as String? ?? '', // 使用新的 reason 字段
      supplementReason: json['is_require_reason'] as int? ?? 0, // 使用新的 is_require_reason 字段
      defaultText: json['default_text'] as String?, // 输入框占位符
      operationType: json['operation_type'] as String?, // 操作类型
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reason': name, // 序列化时使用 reason 字段名
      'is_require_reason': supplementReason, // 序列化时使用 is_require_reason 字段名
      'default_text': defaultText,
      'operation_type': operationType,
    };
  }

  /// 是否需要补充说明（输入框）
  /// 根据 is_require_reason 是否为 1 来判断
  bool get needSupplement => supplementReason == 1;
  
  /// 是否是隐私安全类型
  bool get isPrivacyType => operationType == 'privacy';
  
  /// 是否是价格挽留类型
  bool get isPriceType => operationType == 'price';
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

