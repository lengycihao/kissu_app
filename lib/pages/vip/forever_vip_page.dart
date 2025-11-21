import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
          Padding(
            padding: EdgeInsets.only(
              left: 15,
              top: MediaQuery.of(context).padding.top + 20,
              right: 15,
            ),
            child: Column(
              children: [
                // 自定义顶部导航栏
                _buildTopBar(),
                // 页面内容
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // 会员信息组件
                        _buildAvatarAndNicknameSection(),
                        // _buildInfoImage(),
                        const SizedBox(height: 20),
                        // Tips图片
                        _buildTipsImage(),
                        const SizedBox(height: 20),
                        // 信息背景图片
                        _buildInfoImage(),
                        const SizedBox(height: 20),
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
          child: Image.asset(
            "assets/images/kissu_mine_back.webp",
            width: 22,
            height: 22,
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
        const SizedBox(width: 22), // 占位保持居中
      ],
    );
  }

  // Tips图片
  Widget _buildTipsImage() {
    return Container(
      width: 164,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      child: Image.asset("assets/images/kissu_vip_forver_tip.webp", fit: BoxFit.fill),
    );
  }

  // 信息背景图片
  Widget _buildInfoImage() {
    return Container(
      child: Image.asset("assets/images/kissu_vip_info_bg.webp", fit: BoxFit.fill),
    );
  }

  /// 构建头像和昵称区域 - 重新设计与"我的"页面保持一致
  Widget _buildAvatarAndNicknameSection() {
    return Container(
      width: double.infinity,
      height: 130,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/kissu_vip_back_info.webp"),
          fit: BoxFit.fill,
        ),
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
                  : Image.network(
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
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
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
                  : Image.network(
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
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
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
