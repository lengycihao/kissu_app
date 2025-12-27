import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'forever_vip_controller.dart';

class ForeverVipPage extends GetView<ForeverVipController> {
  const ForeverVipPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 全屏背景
          Positioned.fill(
            child: Image.asset(
              "assets/3.0/kissu_mine_vip_top_bg.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                // 页面内容
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    child: Column(
                      children: [
                        // const SizedBox(height: 10),
                        // 会员信息组件 - 带动画
                        _AnimatedCard(
                          delay: 0,
                          child: _buildAvatarAndNicknameSection(),
                        ),const SizedBox(height: 10),
                         _AnimatedCard(delay: 100, child: _buildTipsMiddleImage()),
                        const SizedBox(height: 20),
                        // Tips图片 - 带动画
                        _AnimatedCard(delay: 100, child: _buildTipsImage()),
                        const SizedBox(height: 20),
                        // 信息背景图片 - 带动画
                        _AnimatedCard(delay: 200, child: _buildInfoImage()),
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
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          // 返回按钮
          Positioned(
            left: 5,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Image.asset(
                  "assets/images/kissu_mine_back.webp",
                  width: 22,
                  height: 22,
                ),
              ),
            ),
          ),
          // 标题 - 绝对居中
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                "会员权益",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTipsMiddleImage() {
    return Center(
      child: SizedBox(
        // width: 343,
        height: 97,
        child: Image.asset(
          "assets/images/kissu_vip_info_middle.webp",
          fit: BoxFit.contain,
        ),
      ),
    );
  }
  // Tips图片
  Widget _buildTipsImage() {
    return Center(
      child: SizedBox(
        width: 146,
        height: 36,
        child: Image.asset(
          "assets/images/kissu_vip_forver_tip.webp",
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // 信息背景图片
  Widget _buildInfoImage() {
    return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          "assets/images/kissu_vip_info_bg.webp",
          fit: BoxFit.contain,
        ),
      );
  }

  /// 构建头像和昵称区域 - 重新设计与"我的"页面保持一致
  Widget _buildAvatarAndNicknameSection() {
    return Container(
      width: double.infinity,
      // height: 130,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
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
                    const SizedBox(width: 30),
                    // 昵称信息
                    Expanded(child: _buildNicknameSection()),
                  ],
                ),
                 
             
              ],
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
            Transform.translate(
              offset: Offset(44, 26),
              child: _buildPartnerAvatar(),
            ),
        ],
      ),
    );
  }

  /// 构建用户头像 - 重新设计与"我的"页面保持一致
  Widget _buildAvatar() {
    return Container(
      width: 64,
      height: 64,
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
      width: 38,
      height: 38,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 自己的昵称
              Text(
                controller.userNickname.value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff333333),
                  fontFamily: "AlimamaShuHeiTi",
                ),
              ),
              Text(
                " & ",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xff333333),
                  fontWeight: FontWeight.bold,
                  fontFamily: "AlimamaShuHeiTi",
                ),
              ),
              // 另一半的昵称
              Text(
                controller.partnerNickname.value,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xff333333),
                  fontWeight: FontWeight.bold,
                  fontFamily: "AlimamaShuHeiTi",
                ),
              ),
            ],
          ),
          SizedBox(height: 8,),
          Text(
            "终身会员:${controller.vipMemberId.value}",
            style: TextStyle(color: Color(0xff777777), fontSize: 12),
          ),
        ],
      ),
    );
  }

  
}

/// 带动画效果的卡片组件
class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedCard({required this.child, this.delay = 0});

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

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

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
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
