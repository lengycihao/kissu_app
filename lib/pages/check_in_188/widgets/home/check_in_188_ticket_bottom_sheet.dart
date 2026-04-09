import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../check_in_188_controller.dart';

/// 188打卡页面 - 活动打卡门票底部弹窗
class CheckIn188TicketBottomSheet extends StatelessWidget {
  final CheckIn188Controller controller;

  const CheckIn188TicketBottomSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部标题栏
          _buildHeader(),
          // 门票选项
          _buildTicketOptions(),
          // 支付方式
          _buildPaymentMethods(),
          // 协议说明
          _buildAgreementText(),
          // 立即支付按钮
          _buildPayButton(),
          SizedBox(height: Get.mediaQuery.padding.bottom + 16),
        ],
      ),
    );
  }

  /// 构建顶部标题栏
  Widget _buildHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Spacer(),
          const Text(
            '活动打卡门票',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(Icons.close, color: Color(0xFF999999), size: 24),
          ),
        ],
      ),
    );
  }

  /// 构建门票选项
  Widget _buildTicketOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 最畅销套餐
          Obx(
            () => _buildTicketOption(
              isSelected: controller.selectedTicketIndex.value == 0,
              onTap: () => controller.selectTicket(0),
              showMostLabel: true,
              title: '0元打卡门票+1张补签卡',
              subtitle: ['成功提现后返还', '9.99', '元'],
              price: '¥9.90',
              originalPrice: '¥19.90',
            ),
          ),
          const SizedBox(height: 14),
          // 普通门票
          Obx(
            () => _buildTicketOption(
              isSelected: controller.selectedTicketIndex.value == 1,
              onTap: () => controller.selectTicket(1),
              showMostLabel: false,
              title: '打卡门票',
              subtitle: [],
              price: '¥9.90',
              originalPrice: '¥19.90',
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个门票选项
  Widget _buildTicketOption({
    required bool isSelected,
    required VoidCallback onTap,
    required bool showMostLabel,
    required String title,
    required List<String> subtitle,
    required String price,
    required String originalPrice,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFFE8EB)
                  : const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF1A76)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // 标题和副标题
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: showMostLabel
                            ? const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF333333),
                              )
                            : const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF000000),
                              ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: subtitle[0],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              TextSpan(
                                text: subtitle[1],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFFF0040),
                                ),
                              ),
                              TextSpan(
                                text: subtitle[2],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // 价格
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000000),
                      ),
                    ),
                    Text(
                      originalPrice,
                      style: TextStyle(
                        fontSize: 12,
                        color: showMostLabel
                            ? Color(0xFF000000)
                            : Color(0xFF999999),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 最畅销标签
          if (showMostLabel)
            Positioned(
              top: 0,
              left: 0,
              child: Transform.translate(
                offset: Offset(-5, -20),
                child: Image.asset(
                  'assets/188/kissu_188_most_label.webp',
                  width: 66,
                  height: 40,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建支付方式
  Widget _buildPaymentMethods() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          // 微信支付
          Expanded(
            child: Obx(
              () => _buildPaymentMethod(
                isSelected: controller.selectedPaymentMethod.value == 0,
                onTap: () => controller.selectPaymentMethod(0),
                icon: 'assets/188/kissu_188_wechat.webp',
                label: '微信支付',
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 支付宝
          Expanded(
            child: Obx(
              () => _buildPaymentMethod(
                isSelected: controller.selectedPaymentMethod.value == 1,
                onTap: () => controller.selectPaymentMethod(1),
                icon: 'assets/188/kissu_188_alipay.webp',
                label: '支付宝',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个支付方式
  Widget _buildPaymentMethod({
    required bool isSelected,
    required VoidCallback onTap,
    required String icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(icon, width: 28, height: 28),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF000000),
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            // 选择框
            Container(
              width: 30,
              height: 30,
              padding: EdgeInsets.all(6),
              child: isSelected
                  ? Image(
                      image: AssetImage(
                        'assets/images/kissu_login_privite_sel.webp',
                      ),
                      width: 18,
                    )
                  : Image(
                      image: AssetImage(
                        'assets/images/kissu_login_privite_unsel.webp',
                      ),
                      color: Color(0xffCECECE),
                      width: 18,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建协议说明
  Widget _buildAgreementText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text.rich(
        
        TextSpan(
          
          children: [
            const TextSpan(
              text: '情侣任意一方购买门票后，双方即可获得参与资格，参与成功即视为同意',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFaaaaaa),
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: '《用户协议》',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFFF1A76),
                fontWeight: FontWeight.w500,
              ),
            ),
            const TextSpan(
              text: '和',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: '《活动规则》',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFFF1A76),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  /// 构建立即支付按钮
  Widget _buildPayButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
      child: GestureDetector(
        onTap: controller.onConfirmPayment,
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: const Text(
            '立即支付',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// 显示门票底部弹窗
  static void show(CheckIn188Controller controller) {
    Get.bottomSheet(
      CheckIn188TicketBottomSheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
