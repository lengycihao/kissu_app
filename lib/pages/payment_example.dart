import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/services/payment_service.dart';
import 'package:kissu_app/services/vip_service.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';

/// 支付功能使用示例
class PaymentExample {
  static final PaymentService _paymentService = PaymentService.to;
  static final VipService _vipService = VipService();

  /// 示例：购买VIP套餐
  static Future<void> purchaseVipPackage({
    required int packageId,
    required int paymentMethod, // 0: 支付宝, 1: 微信
  }) async {
    try {
      // 1. 检查支付服务状态
      if (!_paymentService.isInitialized) {
        CustomToast.show(Get.context!, '支付服务未初始化');
        return;
      }

      // 2. 检查支付应用是否安装
      final availability = await _paymentService.getPaymentAvailability();
      if (paymentMethod == 0 && !availability['alipay']!) {
        CustomToast.show(Get.context!, '请先安装支付宝客户端');
        return;
      }
      if (paymentMethod == 1 && !availability['wechat']!) {
        CustomToast.show(Get.context!, '请先安装微信客户端');
        return;
      }

      // 3. 创建支付订单
      bool paymentResult = false;
      if (paymentMethod == 0) {
        // 支付宝支付
        final aliPayResult = await _vipService.aliPay(vipPackageId: packageId);
        if (aliPayResult.isSuccess && aliPayResult.data != null) {
          paymentResult = await _paymentService.payWithAlipay(
            orderInfo: aliPayResult.data!.orderString ?? '',
          );
        } else {
          CustomToast.show(Get.context!, '支付宝订单创建失败: ${aliPayResult.msg}');
          return;
        }
      } else {
        // 微信支付
        final wxPayResult = await _vipService.wxPay(vipPackageId: packageId);
        if (wxPayResult.isSuccess && wxPayResult.data != null) {
          final payData = wxPayResult.data!;
          paymentResult = await _paymentService.payWithWechat(
            appId: payData.appId ?? '',
            partnerId: payData.partnerId ?? '',
            prepayId: payData.prepayId ?? '',
            packageValue: payData.packageValue ?? '',
            nonceStr: payData.nonceStr ?? '',
            timeStamp: payData.timestamp ?? '',
            sign: payData.sign ?? '',
          );
        } else {
          CustomToast.show(Get.context!, '微信支付订单创建失败: ${wxPayResult.msg}');
          return;
        }
      }

      // 4. 处理支付结果
      if (paymentResult) {
        CustomToast.show(Get.context!, '支付成功！');
        // 这里可以更新用户的VIP状态
      } else {
        CustomToast.show(Get.context!, '支付失败，请重试');
      }
    } catch (e) {
      CustomToast.show(Get.context!, '支付过程中出现错误: $e');
    }
  }

  /// 示例：检查支付服务状态
  static Future<Map<String, dynamic>> checkPaymentStatus() async {
    final availability = await _paymentService.getPaymentAvailability();
    return {
      'initialized': _paymentService.isInitialized,
      'paymentInProgress': _paymentService.paymentInProgress,
      'wechatInstalled': availability['wechat'] ?? false,
      'alipayInstalled': availability['alipay'] ?? false,
    };
  }
}

/// 支付示例页面
class PaymentExamplePage extends StatefulWidget {
  const PaymentExamplePage({super.key});

  @override
  State<PaymentExamplePage> createState() => _PaymentExamplePageState();
}

class _PaymentExamplePageState extends State<PaymentExamplePage> {
  Map<String, dynamic>? _paymentStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPaymentStatus();
  }

  Future<void> _checkPaymentStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await PaymentExample.checkPaymentStatus();
      setState(() => _paymentStatus = status);
    } catch (e) {
      CustomToast.show(Get.context!, '检查支付状态失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('支付功能示例'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 支付状态显示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '支付服务状态',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Text('检查中...')
                    else if (_paymentStatus != null) ...[
                      Text('初始化状态: ${_paymentStatus!['initialized'] ? "已初始化" : "未初始化"}'),
                      Text('支付进行中: ${_paymentStatus!['paymentInProgress'] ? "是" : "否"}'),
                      Text('微信已安装: ${_paymentStatus!['wechatInstalled'] ? "是" : "否"}'),
                      Text('支付宝已安装: ${_paymentStatus!['alipayInstalled'] ? "是" : "否"}'),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 示例按钮
            ElevatedButton(
              onPressed: _paymentStatus?['initialized'] == true
                  ? () => PaymentExample.purchaseVipPackage(
                        packageId: 1,
                        paymentMethod: 0, // 支付宝
                      )
                  : null,
              child: const Text('示例：支付宝支付（套餐ID: 1）'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _paymentStatus?['initialized'] == true
                  ? () => PaymentExample.purchaseVipPackage(
                        packageId: 1,
                        paymentMethod: 1, // 微信
                      )
                  : null,
              child: const Text('示例：微信支付（套餐ID: 1）'),
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _checkPaymentStatus,
              child: const Text('刷新支付状态'),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              '注意：此页面仅用于演示支付功能的使用方法。实际使用时请根据业务需求调整参数。',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
