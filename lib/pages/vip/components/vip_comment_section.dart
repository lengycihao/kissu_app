import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/models/vip_banner_model.dart';
import 'package:kissu_app/pages/vip/vip_controller.dart';
import 'vip_comment_item.dart';
import 'vip_price_section.dart';

/// 会员页底部的用户评价 + 再次展示价格区域
/// 不包含任何支付逻辑，支付仍在 [VipPriceSection] 和 [VipController] 中处理。
class VipCommentSection extends StatelessWidget {
  const VipCommentSection({
    super.key,
    required this.controller,
  });

  final VipController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 标题
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '会员用户五星评价',
            style: TextStyle(
              color: Color(0xff000000),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'AlimamaShuHeiTi',
            ),
          ),
        ),
        const SizedBox(height: 15),
        _buildCommentCarousel(),
        const SizedBox(height: 30),
        VipPriceSection(controller: controller),
        const SizedBox(height: 15),
      ],
    );
  }

  /// 用户评价轮播图
  Widget _buildCommentCarousel() {
    return Obx(() {
      final List<CommentItem> commentList =
          controller.bannerData.value?.commentList ?? [];
      if (commentList.isEmpty) {
        return const SizedBox();
      }

      return SizedBox(
        height: 115,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            controller.onCommentScroll();
            return false;
          },
          child: ListView.builder(
            controller: controller.commentScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: commentList.length,
            itemBuilder: (context, index) {
              final comment = commentList[index];
              return Container(
                width: 266,
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 13,
                ),
                child: VipCommentItem(comment: comment),
              );
            },
          ),
        ),
      );
    });
  }
}


