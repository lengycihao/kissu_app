import 'package:flutter/material.dart';
import 'package:kissu_app/models/vip_package_model.dart';

/// 折扣底部弹窗组件
class DiscountBottomSheet extends StatefulWidget {
  final VipPackageModel package;
  final Function(int paymentMethod) onPayment;

  const DiscountBottomSheet({
    super.key,
    required this.package,
    required this.onPayment,
  });

  @override
  State<DiscountBottomSheet> createState() => _DiscountBottomSheetState();
}

class _DiscountBottomSheetState extends State<DiscountBottomSheet> {
  // 选中的支付方式 (0: 微信, 1: 支付宝)
  int selectedPaymentMethod = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
         image: DecorationImage(
                image: AssetImage('assets/3.0/kissu3_vip_sale_bg.webp'),
                fit: BoxFit.cover,
              ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(left: 34, right: 34, bottom: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖拽指示器
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 背景图容器
          Container(
            // margin: const EdgeInsets.symmetric(horizontal: 34),
            // decoration: const BoxDecoration(
            //   image: DecorationImage(
            //     image: AssetImage('assets/3.0/kissu3_vip_sale_bg.webp'),
            //     fit: BoxFit.cover,
            //   ),
            //   borderRadius: BorderRadius.all(Radius.circular(12)),
            // ),
            child:  
                    AspectRatio(
                      aspectRatio: 305 / 216,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.package.discountsImg,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 50,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
          ),
          
          const SizedBox(height: 30),
          
          // 立即支付按钮
         GestureDetector(
              onTap: () => widget.onPayment(selectedPaymentMethod),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF3988), Color(0xFFA953FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '立即支付',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 14),
          
          // 支付方式选择
           Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPaymentOption(
                  'assets/kissu_vip_wechat.webp',
                  '微信支付',
                  selectedPaymentMethod == 0,
                  () => setState(() => selectedPaymentMethod = 0),
                ),
                _buildPaymentOption(
                  'assets/kissu_vip_alipay.webp',
                  '支付宝支付',
                  selectedPaymentMethod == 1,
                  () => setState(() => selectedPaymentMethod = 1),
                ),
              ],
            ),
          
          // 底部安全区域
          SizedBox(height: MediaQuery.of(context).padding.bottom ),
        ],
      ),
    );
  }

  // 支付方式选项
  Widget _buildPaymentOption(
    String iconPath,
    String title,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric( vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 支付方式图标
            Container(
              width: 20,
              height: 20,
              child: Image.asset(
                isSelected ? 'assets/kissu_vip_agree.webp' : 'assets/kissu_select_circle.webp',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
