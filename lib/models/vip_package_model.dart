class VipPackageModel {
  final int id;
  final String title;
  final int isDoubleVip;
  final int isForEverVip;
  final String vipPrice;
  final String vipOriginalPrice;
  final int vipDays;
  final String productId;
  final int isSubscribe;
  final int isDiscounts;
  final String discountsImg;

  VipPackageModel({
    required this.id,
    required this.title,
    required this.isDoubleVip,
    required this.isForEverVip,
    required this.vipPrice,
    required this.vipOriginalPrice,
    required this.vipDays,
    required this.productId,
    required this.isSubscribe,
    required this.isDiscounts,
    required this.discountsImg,
  });

  factory VipPackageModel.fromJson(Map<String, dynamic> json) {
    return VipPackageModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      isDoubleVip: json['is_double_vip'] ?? 0,
      isForEverVip: json['is_for_ever_vip'] ?? 0,
      vipPrice: json['vip_price'] ?? '0.00',
      vipOriginalPrice: json['vip_original_price'] ?? '0.00',
      vipDays: json['vip_days'] ?? 0,
      productId: json['product_id'] ?? '',
      isSubscribe: json['is_subscribe'] ?? 0,
      isDiscounts: json['is_discounts'] ?? 0,
      discountsImg: json['discounts_img'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'is_double_vip': isDoubleVip,
      'is_for_ever_vip': isForEverVip,
      'vip_price': vipPrice,
      'vip_original_price': vipOriginalPrice,
      'vip_days': vipDays,
      'product_id': productId,
      'is_subscribe': isSubscribe,
      'is_discounts': isDiscounts,
      'discounts_img': discountsImg,
    };
  }

  /// 是否为双人VIP
  bool get isDouble => isDoubleVip == 1;

  /// 是否为永久VIP
  bool get isForever => isForEverVip == 1;

  /// 获取价格显示文本
  String get priceText => '¥$vipPrice';

  /// 获取原价显示文本
  String get originalPriceText => '¥$vipOriginalPrice';

  /// 获取天数显示文本
  String get daysText => isForever ? '永久' : '$vipDays天';

  /// 获取时长显示文本（用于价格项标题）
  String get durationText => title;

  /// 是否有折扣
  bool get hasDiscount => isDiscounts == 1;

  /// 是否为订阅套餐
  bool get isSubscription => isSubscribe == 1;
}