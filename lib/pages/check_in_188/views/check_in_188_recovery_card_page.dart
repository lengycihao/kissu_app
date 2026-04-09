import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'check_in_188_recovery_card_controller.dart';

/// 188补签卡购买页面
class CheckIn188RecoveryCardPage
    extends GetView<CheckIn188RecoveryCardController> {
  const CheckIn188RecoveryCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFffffff),
      body: Column(
        children: [
          // 导航栏
          _buildNavBar(),
          // 内容区域
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // 顶部头像背景区域
                  _buildTopBanner(),
                  const SizedBox(height: 16),
                  // 购买补签卡模块
                  _buildPurchaseSection(),
                  _buildBottomButton(),
                  // 底部链接
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: controller.onGetCardByActivity,
                        child: const Text(
                          '参与活动获取补签卡 ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF777777),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '|',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF777777),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: controller.onViewCardLog,
                        child: const Text(
                          ' 补签卡日志',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF777777),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建导航栏
  Widget _buildNavBar() {
    return Container(
      padding: EdgeInsets.only(top: Get.mediaQuery.padding.top),
      color: Colors.white,
      child: SizedBox(
        height: 44,
        child: Stack(
          children: [
            // 返回按钮
            Positioned(
              left: 0,
              child: GestureDetector(
                onTap: controller.goBack,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: const Icon(Icons.chevron_left, size: 28),
                ),
              ),
            ),
            // 标题
            const Center(
              child: Text(
                '补签卡',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            // 补卡规则
            Positioned(
              right: 12,
              child: GestureDetector(
                onTap: () {
                  // TODO: 显示补卡规则
                },
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: const Text(
                    '补卡规则',
                    style: TextStyle(fontSize: 14, color: Color(0xFFaaaaaa)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建顶部头像背景区域
  Widget _buildTopBanner() {
    return Obx(
      () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 126,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: const DecorationImage(
            image: AssetImage('assets/188/kissu_188_card_top_bg.webp'),
            fit: BoxFit.fill,
          ),
        ),
        child: Row(
          children: [
            // 左侧：头像和打卡天数
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 头像（这里使用占位，实际应该从用户信息获取）
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 15),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 30,
                          color: Color(0xFFCCCCCC),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 30,
                          color: Color(0xFFCCCCCC),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '已累计打卡${controller.checkedInDays.value}天',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),

            // 右侧：补签卡数量
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${controller.recoveryCardCount.value}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '已有补签卡',
                    style: TextStyle(fontSize: 12, color: Color(0xFF333333)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建购买补签卡模块
  Widget _buildPurchaseSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(13).copyWith(left: 12, right: 12),
      decoration: BoxDecoration(
        color: Color(0xffFBF6F6),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和提示
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '购买补签卡',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
              // const SizedBox(width: 12),
              Obx(
                () => Text(
                  '提示：根据当前阶段，你需要${10 - controller.recoveryCardCount.value}张补签卡',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF6A68),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 35),
          // 新人福利卡（如果显示）
          _buildNewUserCard(),
          const SizedBox(height: 12),
          // 普通补签卡选项
          _buildNormalCardOptions(),
          const SizedBox(height: 25),
          _buildPaymentSection(),
          const SizedBox(height: 16),
          // 提示信息
          _buildTipText(),

          // 底部按钮
        ],
      ),
    );
  }

  /// 构建新人福利卡
  Widget _buildNewUserCard() {
    return Obx(() {
      final isSelected = controller.selectedCardIndex.value == 0;
      return GestureDetector(
        onTap: () => controller.selectCard(0),
        child: Container(
          padding: EdgeInsets.only(left: 10, right: 10, top: 15, bottom: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE8ED),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF3D63)
                  : const Color(0xFFFFE8ED),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  // 补签卡图片
                  Image.asset(
                    'assets/188/kissu_188_recovery_card.webp',
                    width: 54,
                    height: 72,
                  ),
                  const SizedBox(width: 16),
                  // 数量
                  const Text(
                    '*1',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const Spacer(),
                  // 价格
                  if (!controller.showNewUserCard.value)
                    Text(
                      '¥20.00',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    )
                  else
                    Row(
                      children: [
                        const Text(
                          '¥9.00',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(
                          '¥20.00',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF999999),
                            decoration: TextDecoration.lineThrough,
                            decorationColor: const Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              // 新人福利标签
              if (!controller.showNewUserCard.value)
                SizedBox.shrink()
              else
                Transform.translate(
                  offset: Offset(-12, -40),
                  child: Image.asset(
                    'assets/188/kissu_188_new_label.webp',
                    width: 74,
                    height: 38,
                  ),
                ),
              // 仅限4张标签
              if (!controller.showNewUserCard.value)
                SizedBox.shrink()
              else
                Transform.translate(
                  offset: Offset(Get.width - 80 - 43, -16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1A76),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    width: 55,
                    height: 20,
                    alignment: Alignment.center,
                    child: const Text(
                      '仅限4张',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  /// 构建普通补签卡选项
  Widget _buildNormalCardOptions() {
    return Obx(() {
      final showNewUser = controller.showNewUserCard.value;
      return Row(
        children: List.generate(controller.cardOptions.length, (index) {
          final option = controller.cardOptions[index];
          final cardIndex = showNewUser ? index + 1 : index;
          final isSelected = controller.selectedCardIndex.value == cardIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => controller.selectCard(cardIndex),
              child: Stack(
                children: [
                  Container(
                    margin: EdgeInsets.only(right: index < 2 ? 10 : 0),
                    padding: const EdgeInsets.all(10).copyWith(right: 5),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF1A76)
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // 补签卡图片
                        Row(
                          children: [
                            Image.asset(
                              'assets/188/kissu_188_recovery_card.webp',
                              width: 50,
                              height: 66,
                            ),
                            const SizedBox(width: 6),
                            // 数量
                            Text(
                              '*${option.count}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        // 价格
                        Text(
                          '¥${option.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (option.discount != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          option.discount!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      );
    });
  }

  /// 构建支付方式选择
  Widget _buildPaymentSection() {
    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 微信支付
          Expanded(
            child: Obx(
              () => GestureDetector(
                onTap: () => controller.selectPaymentMethod(0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/188/kissu_188_wechat.webp',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '微信支付',
                      style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
                    ),
                    const SizedBox(width: 18),
                    _buildCheckbox(controller.paymentMethod.value == 0),
                  ],
                ),
              ),
            ),
          ),
          // const SizedBox(width: 20),
          // 支付宝
          Expanded(
            child: Obx(
              () => GestureDetector(
                onTap: () => controller.selectPaymentMethod(1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Image.asset(
                      'assets/188/kissu_188_alipay.webp',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '支付宝',
                      style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
                    ),
                    const SizedBox(width: 18),
                    _buildCheckbox(controller.paymentMethod.value == 1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建勾选框（参考会员页面样式）
  Widget _buildCheckbox(bool isChecked) {
    return SizedBox(
      width: 18,
      height: 18,

      child: isChecked
          ? Image(
              image: AssetImage('assets/images/kissu_login_privite_sel.webp'),
            )
          : Image(
              image: AssetImage('assets/images/kissu_login_privite_unsel.webp'),
              color: Color(0xffCECECE),
            ),
    );
  }

  /// 构建提示文本
  Widget _buildTipText() {
    return Text(
      '补签卡价格可能因活动等因素调整(含降价或恢复原价)，具体请以页面实时显示为准。该商品为特殊商品，一经购买，不予退款。',
      style: TextStyle(fontSize: 10, color: Color(0xFFaaaaaa), height: 1.5),
    );
  }

  /// 构建底部按钮
  Widget _buildBottomButton() {
    return // 立即购买按钮
    Container(
      decoration: BoxDecoration(
        color: Color(0xffFBF6F6),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.only(top: 6, bottom: 30, left: 6, right: 6),

      child: GestureDetector(
        onTap: controller.onBuyNow,
        child: Container(
          width: double.infinity,
          height: 50,
          // margin: EdgeInsets.only(top: 14, bottom: 30),
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: const Text(
            '立即购买',
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
}

/// 虚线绘制器
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashHeight = 4;
    const dashSpace = 4;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
