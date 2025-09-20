import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/login/login_controller.dart';

/// 首次协议测试页面
class FirstAgreementTestPage extends StatelessWidget {
  const FirstAgreementTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loginController = Get.find<LoginController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('首次协议测试'),
        backgroundColor: const Color(0xFFFF839E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '首次协议弹窗测试',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '此页面用于测试首次协议弹窗功能：\n'
              '1. 点击"重置首次协议状态"按钮\n'
              '2. 返回登录页面\n'
              '3. 应该会弹出首次协议弹窗\n'
              '4. 测试"同意"和"暂不同意"功能',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
             ElevatedButton(
               onPressed: () {
                 loginController.resetFirstAgreementForTesting();
               },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF839E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '重置首次协议状态',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF999999),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '返回登录页面',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
