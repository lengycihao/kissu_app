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

      final planList = controller.vipPackages
          .asMap()
          .entries
          .map((entry) => _VipPlanData(entry.value, entry.key))
          .toList();

      final _VipPlanData? lifetimePlan = _extractPlan(
        planList,
        (plan) => plan.package.isForever,
      );

      final List<_VipPlanData> remainingPlans =
          planList.where((plan) => !plan.package.isForever).toList()
            ..sort((a, b) => a.package.vipDays.compareTo(b.package.vipDays));

      final List<_VipPlanData> selectablePlans = List<_VipPlanData>.from(
        remainingPlans,
      );

      _VipPlanData? monthlyPlan = _extractPlan(
        selectablePlans,
        (plan) => plan.package.title.contains('月'),
      );
      _VipPlanData? annualPlan = _extractPlan(
        selectablePlans,
        (plan) => plan.package.title.contains('年'),
      );

      if (monthlyPlan == null && selectablePlans.isNotEmpty) {
        monthlyPlan = selectablePlans.removeAt(0);
      }
      if (annualPlan == null && selectablePlans.isNotEmpty) {
        annualPlan = selectablePlans.removeAt(0);
      }

      final currentSelectedIndex = controller.selectedPriceIndex.value;

      final List<Widget> children = [];

      if (lifetimePlan != null) {
        children.add(
          _buildLifetimePlanCard(
            lifetimePlan,
            currentSelectedIndex,
            controller,
          ),
        );
        children.add(const SizedBox(height: 10));
      }

      final List<Widget> rowChildren = [];
      if (monthlyPlan != null) {
        rowChildren.add(
          Expanded(
            child: _buildPeriodPlanCard(
              monthlyPlan,
              currentSelectedIndex,
              isMonthly: true,
              controller: controller,
            ),
          ),
        );
      }
      if (monthlyPlan != null && annualPlan != null) {
        rowChildren.add(const SizedBox(width: 10));
      }
      if (annualPlan != null) {
        rowChildren.add(
          Expanded(
            child: _buildPeriodPlanCard(
              annualPlan,
              currentSelectedIndex,
              isMonthly: false,
              controller: controller,
            ),
          ),
        );
      }

      if (rowChildren.isNotEmpty) {
        children.add(Row(children: rowChildren));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    });
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
              fit: BoxFit.contain,
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
          top: 6,
          right: 5,
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


