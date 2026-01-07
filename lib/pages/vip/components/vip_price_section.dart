import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/models/vip_package_model.dart';
import 'package:kissu_app/pages/vip/vip_controller.dart';

/// 价格套餐区域：负责套餐布局和选中逻辑，支付流程仍由 [VipController] 控制。
class VipPriceSection extends StatelessWidget {
  const VipPriceSection({
    super.key,
    required this.controller,
  });

  final VipController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingPackages.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.vipPackages.isEmpty) {
        return const Center(child: Text('暂无套餐数据'));
      }

      // ========== 新版横向排列布局 ==========
      return _buildHorizontalLayout(controller);

      // ========== 原版上下排列布局（已注释） ==========
      // final planList = controller.vipPackages
      //     .asMap()
      //     .entries
      //     .map((entry) => _VipPlanData(entry.value, entry.key))
      //     .toList();

      // final _VipPlanData? lifetimePlan = _extractPlan(
      //   planList,
      //   (plan) => plan.package.isForever,
      // );

      // final List<_VipPlanData> remainingPlans =
      //     planList.where((plan) => !plan.package.isForever).toList()
      //       ..sort((a, b) => a.package.vipDays.compareTo(b.package.vipDays));

      // final List<_VipPlanData> selectablePlans = List<_VipPlanData>.from(
      //   remainingPlans,
      // );

      // _VipPlanData? monthlyPlan = _extractPlan(
      //   selectablePlans,
      //   (plan) => plan.package.title.contains('月'),
      // );
      // _VipPlanData? annualPlan = _extractPlan(
      //   selectablePlans,
      //   (plan) => plan.package.title.contains('年'),
      // );

      // if (monthlyPlan == null && selectablePlans.isNotEmpty) {
      //   monthlyPlan = selectablePlans.removeAt(0);
      // }
      // if (annualPlan == null && selectablePlans.isNotEmpty) {
      //   annualPlan = selectablePlans.removeAt(0);
      // }

      // final currentSelectedIndex = controller.selectedPriceIndex.value;

      // final List<Widget> children = [];

      // if (lifetimePlan != null) {
      //   children.add(
      //     _buildLifetimePlanCard(
      //       lifetimePlan,
      //       currentSelectedIndex,
      //       controller,
      //     ),
      //   );
      //   children.add(const SizedBox(height: 10));
      // }

      // final List<Widget> rowChildren = [];
      // if (monthlyPlan != null) {
      //   rowChildren.add(
      //     Expanded(
      //       child: _buildPeriodPlanCard(
      //         monthlyPlan,
      //         currentSelectedIndex,
      //         isMonthly: true,
      //         controller: controller,
      //       ),
      //     ),
      //   );
      // }
      // if (monthlyPlan != null && annualPlan != null) {
      //   rowChildren.add(const SizedBox(width: 10));
      // }
      // if (annualPlan != null) {
      //   rowChildren.add(
      //     Expanded(
      //       child: _buildPeriodPlanCard(
      //         annualPlan,
      //         currentSelectedIndex,
      //         isMonthly: false,
      //         controller: controller,
      //       ),
      //     ),
      //   );
      // }

      // if (rowChildren.isNotEmpty) {
      //   children.add(Row(children: rowChildren));
      // }

      // return Column(
      //   crossAxisAlignment: CrossAxisAlignment.stretch,
      //   children: children,
      // );
    });
  }

  /// 新版横向排列布局
  Widget _buildHorizontalLayout(VipController controller) {
    final planList = controller.vipPackages
        .asMap()
        .entries
        .map((entry) => _VipPlanData(entry.value, entry.key))
        .toList();

    // 提取各类型套餐
    _VipPlanData? monthlyPlan;
    _VipPlanData? annualPlan;
    _VipPlanData? lifetimePlan;

    for (final plan in planList) {
      if (plan.package.isForever) {
        lifetimePlan = plan;
      } else if (plan.package.title.contains('月')) {
        monthlyPlan = plan;
      } else if (plan.package.title.contains('年')) {
        annualPlan = plan;
      }
    }

    final currentSelectedIndex = controller.selectedPriceIndex.value;

    // 按顺序排列：月度、年度、终身
    final List<Widget> rowChildren = [];
    
    if (monthlyPlan != null) {
      rowChildren.add(
        Expanded(
          child: _buildHorizontalPlanCard(
            plan: monthlyPlan,
            isSelected: currentSelectedIndex == monthlyPlan.index,
            controller: controller,
            tagText: '新人限时优惠',
            tagColor: const Color(0xFFF6F275),
          ),
        ),
      );
    }

    if (annualPlan != null) {
      if (rowChildren.isNotEmpty) {
        rowChildren.add(const SizedBox(width: 6));
      }
      rowChildren.add(
        Expanded(
          child: _buildHorizontalPlanCard(
            plan: annualPlan,
            isSelected: currentSelectedIndex == annualPlan.index,
            controller: controller,
          ),
        ),
      );
    }

    if (lifetimePlan != null) {
      if (rowChildren.isNotEmpty) {
        rowChildren.add(const SizedBox(width: 6));
      }
      rowChildren.add(
        Expanded(
          child: _buildHorizontalPlanCard(
            plan: lifetimePlan,
            isSelected: currentSelectedIndex == lifetimePlan.index,
            controller: controller,
            tagImg: '99%用户选择',
            tagColor: const Color(0xFF333333),
            showCountdown: true,
          ),
        ),
      );
    }

    return Row(children: rowChildren);
  }

  /// 横向排列的套餐卡片
  Widget _buildHorizontalPlanCard({
    required _VipPlanData plan,
    required bool isSelected,
    required VipController controller,
    String? tagText,
    Color? tagColor,
    String? tagImg,
    bool showCountdown = false,
  }) {
    final priceParts = _splitPriceParts(plan.package.vipPrice);
    final hasOriginalPrice = _hasOriginalPrice(plan.package.vipOriginalPrice);
    final originalPrice = _formatPriceWithSymbol(plan.package.vipOriginalPrice);

    return GestureDetector(
      onTap: () {
        if (plan.index >= 0) {
          controller.selectPrice(plan.index);
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 主卡片 - 使用ClipRRect包裹以实现圆角裁剪
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // 卡片主体
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF6885) : const Color(0xFFE8E8E8),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF6885).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 套餐标题
                      Text(
                        plan.package.title,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xcc000000),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 价格
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: priceParts[0],
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFFFF6885),
                                fontFamily: 'AlimamaShuHeiTi',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: priceParts[1],
                              style: const TextStyle(
                                fontSize: 23,
                                fontFamily: 'AlimamaShuHeiTi',
                                color: Color(0xFFFF6885),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // 折扣价格显示逻辑：dailyAveragePrice为空时显示vipOriginalPrice并使用斜线样式，有值时正常显示
                      SizedBox(
                        height: 17,
                        child: plan.package.dailyAveragePrice.isEmpty
                            ? (hasOriginalPrice
                                ? Text(
                                    originalPrice,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF999999),
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: Color(0xFF999999),
                                    ),
                                  )
                                : const SizedBox.shrink())
                            : Text(
                                "${plan.package.dailyAveragePrice}/天",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF999999),
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                // 倒计时（在ClipRRect内部，紧贴底部）
                if (showCountdown)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right:0,
                    child: Obx(() {
                      final countdown = controller.lifetimeCountdownText;
                      if (countdown.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration:   BoxDecoration(
                          color: Color(0xFFF6F275),
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12),bottomRight: Radius.circular(12))
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '倒计时 $countdown',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xcc000000),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
          // 顶部标签
          if (tagText != null)
            Positioned(
              top: -12,
              left: 0,
              right: 4,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagColor ?? const Color(0xFFF6F275),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFffffff), width: 1),
                  ),
                  child: Text(
                    tagText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xcc000000),
                      fontWeight: FontWeight.bold,
                            fontFamily: 'Resource-Han-Rounded',
                     ),
                  ),
                ),
              ),
            ),
          if(tagImg != null)Positioned(
            top: -15,
            left: 0,
            child: Image.asset(
              "assets/4.0/kissu4_vip_open_bg_tip.webp",
              width: 110,
              height: 34,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _VipPlanData {
  final VipPackageModel package;
  final int index;

  _VipPlanData(this.package, this.index);
}

_VipPlanData? _extractPlan(
  List<_VipPlanData> list,
  bool Function(_VipPlanData) test,
) {
  for (var i = 0; i < list.length; i++) {
    if (test(list[i])) {
      return list.removeAt(i);
    }
  }
  return null;
}

Widget _buildLifetimePlanCard(
  _VipPlanData plan,
  int currentSelectedIndex,
  VipController controller,
) {
  final priceParts = _splitPriceParts(plan.package.vipPrice);
  final hasOriginalPrice = _hasOriginalPrice(plan.package.vipOriginalPrice);
  final originalPrice = _formatPriceWithSymbol(plan.package.vipOriginalPrice);
  final isSelected = currentSelectedIndex == plan.index;

  final backgroundAsset = isSelected
      ? "assets/4.0/kissu4_vip_open_bg.webp"
      : "assets/4.0/kissu4_vip_open_bg_sel.webp";

  return GestureDetector(
    onTap: () {
      if (plan.index >= 0) {
        controller.selectPrice(plan.index);
      }
    },
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 105,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(backgroundAsset),
              fit: BoxFit.fitWidth,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: priceParts[0],
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xffFF6885),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: priceParts[1],
                          style: const TextStyle(
                            fontSize: 24,
                            color: Color(0xffFF6885),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasOriginalPrice)
                    Text(
                      originalPrice,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0x66000000),
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Color(0x66000000),
                      ),
                    ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.package.title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xcc000000),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '永久在一起，久久不分离',
                    style: TextStyle(fontSize: 11, color: Color(0x66000000)),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  final packages = controller.vipPackages;
                  if (packages.isEmpty) {
                    return;
                  }
                  final index =
                      packages.indexWhere((element) => element.type == 4);
                  if (index == -1) {
                    return;
                  }
                  controller.selectedPriceIndex.value = index;
                  controller.purchaseVip();
                },
                child: Container(
                  width: 80,
                  height: 26,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/4.0/kissu4_vip_open_bt.webp"),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -15,
          left: 0,
          child: Image.asset(
            "assets/4.0/kissu4_vip_open_bg_tip.webp",
            width: 110,
            height: 34,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          top: isSelected?6:0,
          right: isSelected?5:0,
          child: Obx(() {
            final desc = controller.lifetimeActivityDesc.value;
            final countdown = controller.lifetimeCountdownText;
            if (desc.isEmpty && countdown.isEmpty) {
              return const SizedBox.shrink();
            }

            final parts = <String>[];
            if (desc.isNotEmpty) {
              parts.add(desc);
            }
            if (countdown.isNotEmpty) {
              parts.add(countdown);
            }
            final displayText = parts.join(' ');

            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: const BoxDecoration(
                color: Color(0xffF6F275),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                displayText,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xff000000),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),
        ),
      ],
    ),
  );
}

Widget _buildPeriodPlanCard(
  _VipPlanData plan,
  int currentSelectedIndex, {
  required bool isMonthly,
  required VipController controller,
}) {
  final priceParts = _splitPriceParts(plan.package.vipPrice);
  final isSelected = currentSelectedIndex == plan.index;
  final perDayPriceText = plan.package.perDayPriceText;
  final backgroundAsset = isSelected
      ? "assets/4.0/kissu4_vip_open_second_bg_sel.webp"
      : "assets/4.0/kissu4_vip_open_second_bg.webp";

  return GestureDetector(
    onTap: () {
      if (plan.index >= 0) {
        controller.selectPrice(plan.index);
      }
    },
    child: Container(
      height: 113,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundAsset),
          fit: BoxFit.fill,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (isMonthly)
            Transform.translate(
              offset: const Offset(0, -5),
              child: Align(
                alignment: Alignment.topRight,
                child: Image.asset(
                  "assets/4.0/kissu4_vip_open_second_tip.webp",
                  width: 78,
                  height: 19,
                ),
              ),
            ),
          SizedBox(height: isMonthly ? 5 : 24),
          Text(
            plan.package.title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xcc000000),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: priceParts[0],
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xffFF6885),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: priceParts[1],
                  style: const TextStyle(
                    fontSize: 24,
                    color: Color(0xffFF6885),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(width: 80, height: 0.5, color: const Color(0xff22000000)),
          const SizedBox(height: 5),
          if (perDayPriceText.isNotEmpty)
            Text(
              perDayPriceText,
              style: const TextStyle(fontSize: 11, color: Color(0x66000000)),
            ),
        ],
      ),
    ),
  );
}

List<String> _splitPriceParts(String? price) {
  final clean = _stripCurrencySymbol(price);
  final display = clean.isEmpty ? '0.00' : clean;
  return ['￥', display];
}

bool _hasOriginalPrice(String? price) {
  final clean = _stripCurrencySymbol(price);
  if (clean.isEmpty) return false;
  final value = double.tryParse(clean);
  if (value == null) {
    return true;
  }
  return value > 0;
}

String _formatPriceWithSymbol(String? price) {
  final clean = _stripCurrencySymbol(price);
  if (clean.isEmpty) return '';
  return '￥$clean';
}

String _stripCurrencySymbol(String? price) {
  final raw = price?.trim() ?? '';
  if (raw.isEmpty) return '';
  return raw.replaceFirst(RegExp(r'^[¥￥]'), '');
}


