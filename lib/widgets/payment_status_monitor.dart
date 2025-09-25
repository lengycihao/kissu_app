import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/services/payment_service.dart';
import 'package:logger/logger.dart';

/// 支付状态监控工具
/// 用于调试和监控支付状态
class PaymentStatusMonitor extends StatefulWidget {
  const PaymentStatusMonitor({Key? key}) : super(key: key);

  @override
  State<PaymentStatusMonitor> createState() => _PaymentStatusMonitorState();
}

class _PaymentStatusMonitorState extends State<PaymentStatusMonitor> {
  final Logger _logger = Logger();
  final PaymentService _paymentService = PaymentService.to;
  
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isPaymentInProgress = _paymentService.paymentInProgress;
      final isInitialized = _paymentService.isInitialized;
      
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '支付状态监控',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusRow('支付服务初始化', isInitialized, Colors.blue),
            _buildStatusRow('支付进行中', isPaymentInProgress, Colors.orange),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    _logger.i('手动重置支付状态');
                    _paymentService.forceResetPaymentState();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('重置支付状态'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _logger.i('检查支付可用性');
                    _checkPaymentAvailability();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('检查支付可用性'),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
  
  Widget _buildStatusRow(String label, bool status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: status ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ${status ? "是" : "否"}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _checkPaymentAvailability() async {
    try {
      final availability = await _paymentService.getPaymentAvailability();
      _logger.i('支付可用性检查结果: $availability');
      
      final wechatAvailable = availability['wechat'] ?? false;
      final alipayAvailable = availability['alipay'] ?? false;
      
      Get.snackbar(
        '支付可用性',
        '微信: ${wechatAvailable ? "可用" : "不可用"}\n支付宝: ${alipayAvailable ? "可用" : "不可用"}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      _logger.e('检查支付可用性失败: $e');
      Get.snackbar(
        '错误',
        '检查支付可用性失败: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}

/// 支付状态监控浮窗
class PaymentStatusFloatingWidget extends StatelessWidget {
  const PaymentStatusFloatingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      right: 16,
      child: const PaymentStatusMonitor(),
    );
  }
}
