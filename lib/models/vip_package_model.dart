class VipPackageModel {
  final int id;
  final String title;
  final int isDoubleVip;
  final int isForEverVip;
  final int type;
  final String vipPrice;
  final String vipOriginalPrice;
  final int vipDays;
  final String dailyAveragePrice;
  final String productId;
  final int isChecked;
  final int isSubscribe;
  final int isDiscounts;
  final String discountsImg;
  final String activityDesc;
  final int activityRemainDuration;

  VipPackageModel({
    required this.id,
    required this.title,
    required this.isDoubleVip,
    required this.isForEverVip,
    required this.type,
    required this.vipPrice,
    required this.vipOriginalPrice,
    required this.vipDays,
    required this.dailyAveragePrice,
    required this.productId,
    required this.isSubscribe,
    required this.isChecked,
    required this.isDiscounts,
    required this.discountsImg,
    required this.activityDesc,
    required this.activityRemainDuration,
  });

  factory VipPackageModel.fromJson(Map<String, dynamic> json) {
    return VipPackageModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      isDoubleVip: json['is_double_vip'] ?? 0,
      isForEverVip: json['is_for_ever_vip'] ?? 0,
      type: json['type'] ?? 0,
      vipPrice: json['vip_price'] ?? '0.00',
      vipOriginalPrice: json['vip_original_price'] ?? '0.00',
      vipDays: json['vip_days'] ?? 0,
      dailyAveragePrice: json['daily_average_price'] ?? '',
      isChecked: json['is_checked'] ?? 0,
      productId: json['product_id'] ?? '',
      isSubscribe: json['is_subscribe'] ?? 0,
      isDiscounts: json['is_discounts'] ?? 0,
      discountsImg: json['discounts_img'] ?? '',
      activityDesc: json['activity_desc'] ?? '',
      activityRemainDuration: json['activity_remain_duration'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'is_double_vip': isDoubleVip,
      'is_for_ever_vip': isForEverVip,
      'type': type,
      'vip_price': vipPrice,
      'vip_original_price': vipOriginalPrice,
      'vip_days': vipDays,
      'daily_average_price': dailyAveragePrice,
      'product_id': productId,
      'is_subscribe': isSubscribe,
      'is_checked': isChecked,
      'is_discounts': isDiscounts,
      'discounts_img': discountsImg,
      'activity_desc': activityDesc,
      'activity_remain_duration': activityRemainDuration,
    };
  }

  /// 是否为双人VIP
  bool get isDouble => isDoubleVip == 1;

  /// 是否为永久VIP
  bool get isForever => isForEverVip == 1;

  /// 获取价格显示文本
  String get priceText => vipPrice;

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

  /// 是否包含活动信息
  bool get hasActivity => activityDesc.isNotEmpty && activityRemainDuration > 0;

  double get priceValue =>
      double.tryParse(_normalizeNumberString(vipPrice)) ?? 0;

  double get originalPriceValue =>
      double.tryParse(_normalizeNumberString(vipOriginalPrice)) ?? 0;

  /// 每日价格显示文本
  String get perDayPriceText {
    if (vipDays <= 0) {
      return '';
    }
    final perDayPrice = priceValue / vipDays;
    return '¥${perDayPrice.toStringAsFixed(2)}/天';
  }

  /// 支付按钮展示的周期标签
  String get periodLabel {
    switch (type) {
      case 1:
        return '月度';
      case 3:
        return '年度';
      case 4:
        return '终身';
      default:
        return '';
    }
  }

  String _normalizeNumberString(String value) {
    return value.replaceFirst(RegExp(r'^[¥￥]'), '');
  }
}
