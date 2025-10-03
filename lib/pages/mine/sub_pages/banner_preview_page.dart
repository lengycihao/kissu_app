import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/kissu_banner_builder.dart';
import 'package:kissu_app/pages/mine/mine_controller.dart';

/// Banner 预览页面
/// 展示所有8种 Banner 样式
class BannerPreviewPage extends StatelessWidget {
  const BannerPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取 MineController 以访问用户头像
    final mineController = Get.find<MineController>();
    final userAvatarUrl = mineController.userAvatar.value;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Banner 预览'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBannerCardWithWidget(
            title: '1. 未绑定 + 未开通VIP - 定位',
            description: '背景图 + 头像背景(27,28) + 用户头像(29,30)',
            bannerWidget: KissuBannerBuilder.buildLocationBannerWidget(
              isBound: false,
              isVip: false,
              userAvatarUrl: userAvatarUrl,
            ),
          ),
          _buildBannerCardWithWidget(
            title: '2. 未绑定 + 未开通VIP - 足迹',
            description: '背景图',
            bannerWidget: KissuBannerBuilder.buildFootprintBannerWidget(
              isBound: false,
              isVip: false,
            ),
          ),
          _buildBannerCardWithWidget(
            title: '3. 未绑定 + 开通VIP - 定位',
            description: '背景图 + 头像背景(27,28) + 用户头像(29,30)',
            bannerWidget: KissuBannerBuilder.buildLocationBannerWidget(
              isBound: false,
              isVip: true,
              userAvatarUrl: userAvatarUrl,
            ),
          ),
          _buildBannerCardWithWidget(
            title: '4. 未绑定 + 开通VIP - 足迹',
            description: '背景图',
            bannerWidget: KissuBannerBuilder.buildFootprintBannerWidget(
              isBound: false,
              isVip: true,
            ),
          ),
          _buildBannerCardWithWidget(
            title: '5. 绑定 + 未开通VIP - 定位',
            description: '背景图 + 出行工具(21,30) + 自己头像(80,27) + 另一半头像(249,14)',
            bannerWidget: KissuBannerBuilder.buildLocationBannerWidget(
              isBound: true,
              isVip: false,
              userAvatarUrl: userAvatarUrl,
              partnerAvatarUrl: 'https://avatar.githubusercontent.com/u/1000000', // 示例另一半头像
            ),
          ),
          _buildBannerCardWithWidget(
            title: '6. 绑定 + 未开通VIP - 足迹',
            description: '背景图 + 定位图标(21,30) + 另一半头像(94,29)',
            bannerWidget: KissuBannerBuilder.buildFootprintBannerWidget(
              isBound: true,
              isVip: false,
              partnerAvatarUrl: 'https://avatar.githubusercontent.com/u/1000000', // 示例另一半头像
            ),
          ),
          _buildBannerCardWithWidget(
            title: '7. 绑定 + 开通VIP - 定位',
            description: '背景图 + 出行工具(21,30) + 自己头像(80,28) + 另一半头像(249,15)',
            bannerWidget: KissuBannerBuilder.buildLocationBannerWidget(
              isBound: true,
              isVip: true,
              userAvatarUrl: userAvatarUrl,
              partnerAvatarUrl: 'https://avatar.githubusercontent.com/u/1000000', // 示例另一半头像
            ),
          ),
          _buildBannerCardWithWidget(
            title: '8. 绑定 + 开通VIP - 足迹',
            description: '背景图 + 定位图标(21,30) + 另一半头像(94,29) + 计数文字"5个"',
            bannerWidget: KissuBannerBuilder.buildFootprintBannerWidget(
              isBound: true,
              isVip: true,
              partnerAvatarUrl: 'https://avatar.githubusercontent.com/u/1000000', // 示例另一半头像
              footprintCount: 5, // 示例足迹数量
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBannerCardWithWidget({
    required String title,
    required String description,
    required Widget bannerWidget,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          // 描述
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 12),
          // Banner Widget
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: bannerWidget,
          ),
        ],
      ),
    );
  }

}

