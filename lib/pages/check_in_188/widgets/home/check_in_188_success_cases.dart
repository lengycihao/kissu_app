import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:card_swiper/card_swiper.dart';
import '../../check_in_188_controller.dart';

/// 188打卡页面 - 提现成功案例组件
class CheckIn188SuccessCases extends StatelessWidget {
  final CheckIn188Controller controller;

  const CheckIn188SuccessCases({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16).copyWith(top: 16, bottom: 16, left: 0, right: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: _buildSectionTitle('提现成功案例'),
          ),
          const SizedBox(height: 16),
          // 横向轮播 - 使用card_swiper
          SizedBox(
            height: 130,
            child: Obx(
              () => Swiper(
                itemBuilder: (context, index) {
                  final caseItem = controller.successCases[index];
                  return Center(child: _buildCaseCard(caseItem));
                },
                itemCount: controller.successCases.length,
                autoplay: true,
                autoplayDelay: 3000,
                onIndexChanged: (index) {
                  controller.currentCaseIndex.value = index;
                },
                viewportFraction: 0.6,
                scale: 0.80,
                loop: true,
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  /// 构建模块标题
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Image.asset(
          'assets/188/kissu_188_label_color.webp',
          width: 7,
          height: 14,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  /// 构建案例卡片
  Widget _buildCaseCard(SuccessCase caseItem) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EBFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像和昵称
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(caseItem.avatar),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caseItem.nickname,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF777777),
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: "已成功提现",
                            style: TextStyle(
                              color: Color(0xFF777777),
                              fontSize: 12,
                            ),
                          ),
                          const TextSpan(
                            text: " 520 ",
                            style: TextStyle(
                              color: Color(0xFFFF1A76),
                              fontSize: 12,
                            ),
                          ),
                          const TextSpan(
                            text: "元",
                            style: TextStyle(
                              color: Color(0xFF777777),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          // 描述
          Expanded(
            child: Text(
              caseItem.description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF777777),
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
