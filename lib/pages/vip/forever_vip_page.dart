import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'forever_vip_controller.dart';

class ForeverVipPage extends GetView<ForeverVipController> {
  const ForeverVipPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 全屏背景
          Positioned.fill(
            child: Image.asset(
              "assets/3.0/kissu_mine_vip_bg.webp",
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 自定义顶部导航栏
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  child: _buildTopBar(),
                ),
                // 页面内容
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        // 会员信息组件 - 带动画
                        _AnimatedCard(
                          delay: 0,
                          child: _buildAvatarAndNicknameSection(),
                        ),
                        const SizedBox(height: 20),
                        // Tips图片 - 带动画
                        _AnimatedCard(
                          delay: 100,
                          child: _buildTipsImage(),
                        ),
                        const SizedBox(height: 20),
                        // 信息背景图片 - 带动画
                        _AnimatedCard(
                          delay: 200,
                          child: _buildInfoImage(),
                        ),
                        const SizedBox(height: 30),
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

  // 自定义顶部导航栏
  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              "assets/images/kissu_mine_back.webp",
              width: 22,
              height: 22,
            ),
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              "会员权益",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: "LiuHuanKaTongShouShu",
              ),
            ),
          ),
        ),
        const SizedBox(width: 30), // 占位保持居中
      ],
    );
  }

  // Tips图片
  Widget _buildTipsImage() {
    return Center(
      child: Container(
        width: 164,
        height: 22,
        child: Image.asset(
          "assets/images/kissu_vip_forver_tip.webp",
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // 信息背景图片
  Widget _buildInfoImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          "assets/images/kissu_vip_info_bg.webp",
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// 构建头像和昵称区域 - 重新设计与"我的"页面保持一致
  Widget _buildAvatarAndNicknameSection() {
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage("assets/images/kissu_vip_back_info.webp"),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🔥 新的头像区域 - 与"我的"页面保持一致
                    _buildNewAvatarSection(),
                    const SizedBox(width: 15),
                    // 昵称信息
                    Expanded(child: _buildNicknameSection()),
                  ],
                ),
                const SizedBox(height: 8),
                _buildVipMemberInfo(),
                const SizedBox(height: 5),
                Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    Positioned(
                      // bottom: 0,
                      // left: 0,
                      child: Container(
                      width: 85,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Color(0xFFFFD4D0),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    )),
                    Text(
                      "尊贵权益终身有效",
                      style: TextStyle(fontSize: 10, color: Color(0xFF593A37)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            left: 120,
            child: Image.asset(
              "assets/3.0/kissu3_vip_hat.webp",
              width: 12,
              height: 10,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 新的头像区域 - 与"我的"页面保持一致
  Widget _buildNewAvatarSection() {
    return Obx(
      () => Stack(
        children: [
          // 用户头像
          _buildAvatar(),
          // 另一半头像 - 只有绑定时才显示，无+按钮
          if (controller.isBound.value &&
              controller.partnerAvatar.value.isNotEmpty)
            Positioned(right: 0, bottom: 0, child: _buildPartnerAvatar()),
        ],
      ),
    );
  }

  /// 构建用户头像 - 重新设计与"我的"页面保持一致
  Widget _buildAvatar() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffffffff), width: 1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipOval(
        child: controller.userAvatar.value.isNotEmpty
            ? controller.userAvatar.value.startsWith('assets/')
                  ? Image.asset(
                      controller.userAvatar.value,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            color: const Color(0xFFE8B4CB),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 56,
                            color: Colors.white,
                          ),
                        );
                      },
                    )
                  : NetworkImageHelper.loadImage(
                      imageUrl: controller.userAvatar.value,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          color: const Color(0xFFE8B4CB),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: const Color(0xFFE8B4CB),
                ),
                child: const Icon(Icons.person, size: 56, color: Colors.white),
              ),
      ),
    );
  }

  /// 构建另一半头像 - 重新设计与"我的"页面保持一致
  Widget _buildPartnerAvatar() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFffffff), width: 1),
      ),
      child: ClipOval(
        child: controller.partnerAvatar.value.isNotEmpty
            ? controller.partnerAvatar.value.startsWith('assets/')
                  ? Image.asset(
                      controller.partnerAvatar.value,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFFE8B4CB),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 22,
                            color: Colors.white,
                          ),
                        );
                      },
                    )
                  : NetworkImageHelper.loadImage(
                      imageUrl: controller.partnerAvatar.value,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFE8B4CB),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFE8B4CB),
                ),
                child: const Icon(Icons.person, size: 16, color: Colors.white),
              ),
      ),
    );
  }

  /// 构建昵称区域
  Widget _buildNicknameSection() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 自己的昵称
          Text(
            controller.userNickname.value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff593A37),
              fontFamily: "LiuHuanKaTongShouShu",
            ),
          ),
          const SizedBox(height: 3),
          // 另一半的昵称
          Text(
            controller.partnerNickname.value,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xff593A37),
              fontFamily: "LiuHuanKaTongShouShu",
            ),
          ),
        ],
      ),
    );
  }

  /// 构建VIP会员信息
  Widget _buildVipMemberInfo() {
    return Obx(
      () => Stack(
        alignment: Alignment.bottomLeft,
        children: [
           Positioned(
                      // bottom: 0,
                      // left: 0,
                      child: Container(
                      width: 145,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Color(0xFFFFD4D0),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    )),
          Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "终身会员：",
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF593A37), // 金色
            ),
          ),
          Text(
            controller.vipMemberId.value,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF593A37), // 金色
            ),
          ),
        ],
      ),
        ],
      )
    );
  }
}

/// 带动画效果的卡片组件
class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedCard({
    required this.child,
    this.delay = 0,
  });

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // 延迟启动动画
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
