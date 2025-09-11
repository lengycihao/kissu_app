/// 支付结果枚举
enum PaymentResult {
  success,  // 支付成功
  cancel,   // 用户取消
  failed,   // 支付失败
}

/// 微信支付模型
class WxPayModel {
  final String? appId;
  final String? partnerId;
  final String? prepayId;
  final String? packageValue;
  final String? nonceStr;
  final String? timestamp;
  final String? sign;

  WxPayModel({
    this.appId,
    this.partnerId,
    this.prepayId,
    this.packageValue,
    this.nonceStr,
    this.timestamp,
    this.sign,
  });

  factory WxPayModel.fromJson(Map<String, dynamic> json) {
    return WxPayModel(
      appId: json['appid'],
      partnerId: json['partnerid'],
      prepayId: json['prepayid'],
      packageValue: json['package'],
      nonceStr: json['noncestr'],
      timestamp: json['timestamp']?.toString(), // 将int转换为String
      sign: json['sign'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appid': appId,
      'partnerid': partnerId,
      'prepayid': prepayId,
      'package': packageValue,
      'noncestr': nonceStr,
      'timestamp': timestamp,
      'sign': sign,
    };
  }
}

/// 支付宝支付模型
class AliPayModel {
  final String? orderString;

  AliPayModel({
    this.orderString,
  });

  factory AliPayModel.fromJson(Map<String, dynamic> json) {
    return AliPayModel(
      orderString: json['order_string'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_string': orderString,
    };
  }
}