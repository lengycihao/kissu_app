import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/vip/vip_controller.dart';
import 'package:kissu_app/utils/agreement_utils.dart';
import 'package:lottie/lottie.dart';

class VipPaymentComponent extends GetView<VipController> {
  const VipPaymentComponent({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(Get.context!).padding.bottom;
    final actualBottomPadding = 25.0 + bottomPadding;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: actualBottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPaymentOption(
                  'assets/4.0/kissu4_wechat.webp',
                  '微信支付',
                  controller.selectedPaymentMethod.value == 0,
                  () => controller.selectPaymentMethod(0),
                ),
                _buildPaymentOption(
                  'assets/4.0/kissu4_zhifubao.webp',
                  '支付宝支付',
                  controller.selectedPaymentMethod.value == 1,
                  () => controller.selectPaymentMethod(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Obx(() {
            final periodLabel = controller.getCurrentPeriodLabel();
            final periodText = periodLabel.isNotEmpty ? '/$periodLabel' : '';
            return GestureDetector(
              onTap: () {
                if (!controller.agreementChecked.value) {
                  controller.showAgreementWarning();
                  return;
                }
                controller.purchaseVip();
              },
              child: Container(
                width: double.infinity,
                height: 44,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20).copyWith(right: 0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xffFF93ED), Color(0xffFFF6FD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                ),
                alignment: Alignment.center,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: '￥',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: controller.getCurrentPrice(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'AlimamaShuHeiTi',
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: periodText,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(() {
                      // 根据会员状态选择动画文件
                      final isVip = controller.isVipStatus.value;
                      final animationPath = isVip 
                          ? 'assets/json/renew.json' 
                          : 'assets/json/recharge.json';
                      
                      return SizedBox(
                        width: 150,
                        height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Lottie.asset(
                              animationPath,
                              width: 150,
                              height: 44,
                              fit: BoxFit.cover,
                              repeat: true,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 15),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: controller.toggleAgreement,
                  child: Image.asset(
                    controller.agreementChecked.value
                        ? 'assets/images/kissu_vip_agree.webp'
                        : 'assets/images/kissu_select_circle.webp',
                    width: 13,
                    height: 13,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => AgreementUtils.toVipAgreement(),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: '阅读并同意',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                        TextSpan(
                          text: '《会员服务协议》',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF63A9EA),
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                            
                              AgreementUtils.toVipAgreement();
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String iconPath,
    String title,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(
              image: AssetImage(iconPath),
              width: 18,
              height: 18,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 13,
              height: 13,
              child: Image.asset(
                isSelected
                    ? 'assets/images/kissu_vip_agree.webp'
                    : 'assets/images/kissu_select_circle.webp',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
            ),
          ],
        ),
      ),
    );
  }
}


