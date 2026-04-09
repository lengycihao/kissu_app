import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../check_in_188_controller.dart';

/// 188打卡页面 - 底部按钮组件
class CheckIn188BottomButton extends StatelessWidget {
  final CheckIn188Controller controller;

  const CheckIn188BottomButton({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: EdgeInsets.only(bottom: Get.mediaQuery.padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 支付按钮
          _buildPayButton(),
          const SizedBox(height: 12),
          // 协议同意
          _buildAgreementCheckbox(),
        ],
      ),
    );
  }

  /// 构建支付按钮
  Widget _buildPayButton() {
    return GestureDetector(
      onTap: controller.onPayButtonTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.asset(
          'assets/188/kissu_188_pay_btn.webp',
          width: double.infinity,
          height: 44,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }

  /// 构建协议复选框
  Widget _buildAgreementCheckbox() {
    return GestureDetector(
      onTap: controller.toggleAgreement,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => Image.asset(
              controller.isAgreed.value
                  ? 'assets/188/kissu_188_pay_agree.webp'
                  : 'assets/images/kissu_login_privite_unsel.webp',
              width: 16,
              height: 16,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: '我已知晓并同意Kissu',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const TextSpan(
                    text: '《用户协议》',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const TextSpan(
                    text: '《活动规则》',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const TextSpan(
                    text: '《补签规则》',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const TextSpan(
                    text: '且承诺参与双方当前已年满16周岁',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
