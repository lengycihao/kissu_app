import 'dart:ffi';

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
            child: Image.asset("assets/kissu_mine_bg.webp", fit: BoxFit.cover),
          ),
          Padding(
            padding: EdgeInsets.only(left: 15, top: MediaQuery.of(context).padding.top+20, right: 15),
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
            "assets/kissu_mine_back.webp",
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
      child: Image.asset("assets/kissu_vip_forver_tip.webp", fit: BoxFit.fill),
    );
  }

  // 信息背景图片
  Widget _buildInfoImage() {
    return Container(
       child: Image.asset("assets/kissu_vip_info_bg.webp", fit: BoxFit.fill),
    );
  }

  /// 构建头像和昵称区域
  Widget _buildAvatarAndNicknameSection() {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/kissu_vip_back_info.png"),
          fit: BoxFit.fill,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 双人头像（保持原有样式）
                  Stack(
                    children: [
                      _buildAvatar(),
                      Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.only(left: 60, top: 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFFFFB6C1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 30,
                          color: Color(0xFFFF69B4),
                        ),
                      ),
                      Positioned(
                        right: 30,
                        top: 40,
                        child: Image(
                          image: const AssetImage("assets/kissu_heart.webp"),
                          width: 29,
                          height: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  // 昵称信息
                  Expanded(child: _buildNicknameSection()),
                ],
              ),
            ),
            _buildVipMemberInfo(),
            const SizedBox(height: 5),
            Text(
              "尊贵权益终身有效",
              style: TextStyle(
                fontSize: 10,
                color: Color(0xff593A37),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建双人头像
  /// 构建头像
  Widget _buildAvatar() {
    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/kissu_loveinfo_header_bg.webp'),
          fit: BoxFit.fill,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 6, top: 6, right: 0, bottom: 3),
        child: ClipOval(
          child: controller.userAvatar.value.isNotEmpty
              ? Image.network(
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
                        size: 40,
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
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xff593A37),
              fontFamily: "LiuHuanKaTongShouShu",
            ),
          ),
          const SizedBox(height: 8),
          // 另一半的昵称
          Text(
            controller.partnerNickname.value,
            style: TextStyle(
              fontSize: 14,
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
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "终身会员：",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF593A37), // 金色
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              controller.vipMemberId.value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666), // 金色
              ),
            ),
          ],
        ),
      ),
    );
  }
}
