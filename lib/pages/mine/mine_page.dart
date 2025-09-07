import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'mine_controller.dart';

class MinePage extends GetView<MineController> {
  const MinePage({super.key});

  // 固定的应用设置菜单项
  static const List<Map<String, String>> settingItems = [
    {"icon": "assets/kissu_mine_item_syst.webp", "title": "首页视图"},
    {"icon": "assets/kissu_mine_item_xtqx.webp", "title": "系统权限"},
    {"icon": "assets/kissu_mine_item_gywm.webp", "title": "关于我们"},
    {"icon": "assets/kissu_mine_item_cjwt.webp", "title": "常见问题"},
    {"icon": "assets/kissu_mine_item_lxwm.webp", "title": "联系我们"},
    {"icon": "assets/kissu_mine_item_yjfk.webp", "title": "意见反馈"},
    {"icon": "assets/kissu_mine_item_ysaq.webp", "title": "账号及隐私安全"},
  ];

  // 通用虚线分隔
  Widget _buildDashLine({
    EdgeInsets margin = const EdgeInsets.symmetric(vertical: 8),
  }) {
    return Container(
      height: 0.6,
      color: const Color(0xFFE6E2E3),
      margin: margin,
    );
  }

  // 通用信息行
  Widget _buildInfoRow(String title, RxString value) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xff69686F)),
          ),
         value.value.isEmpty? Container(
              height: 4,
              width: 30,
              decoration: BoxDecoration(
                color: Color(0xffFFD4D1),
                borderRadius: BorderRadius.circular(5),
              ),
            ): Text(
            value.value,
            style: const TextStyle(fontSize: 12, color: Color(0xff593A37)),
          ),
        ],
      ),
    );
  }

  // 顶部导航
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: controller.onBackTap,
            child: Image.asset(
              "assets/kissu_mine_back.webp",
              width: 22,
              height: 22,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "我的",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 22), // 占位保持居中
        ],
      ),
    );
  }

  // 个人信息模块
  Widget _buildUserInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage("assets/kissu_mine_info_bg.webp"),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 头像区域
          _buildAvatarSection(),
          const SizedBox(width: 50),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                _buildInfoRow("昵称", controller.nickname),
                _buildDashLine(),
                _buildInfoRow("匹配码", controller.matchCode),
                _buildDashLine(),
                _buildInfoRow("绑定时间", controller.bindDate),
                _buildDashLine(),
                _buildInfoRow("在一起", controller.days),
                const SizedBox(height: 15),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  // 头像区域（支持双头像显示）
  Widget _buildAvatarSection() {
    return Obx(() => Column(
      children: [
        // 头像显示区域
        SizedBox(
          width: 100,
          height: 60,
          child: Stack(
            children: [
              // 用户头像
              Positioned(
                left: 0,
                bottom: 0,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: controller.userAvatar.value.startsWith('assets/')
                          ? AssetImage(controller.userAvatar.value)
                          : NetworkImage(controller.userAvatar.value) as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // 另一半头像（右上角，小一点，底部对齐重合）
              Positioned(
                right: 0,
                bottom: 5, // 稍微向上偏移，让底部对齐重合
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    image: DecorationImage(
                      image: controller.partnerAvatar.value.startsWith('assets/')
                          ? AssetImage(controller.partnerAvatar.value)
                          : NetworkImage(controller.partnerAvatar.value) as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: controller.onLabelTap,
          child: Row(
            children: [
              Image.asset(
                "assets/kissu_mine_label_laxx.webp",
                width: 56,
                height: 16,
              ),
              const SizedBox(width: 4),
              Image.asset(
                "assets/kissu_mine_arrow.webp",
                width: 14,
                height: 14,
              ),
            ],
          ),
        ),
      ],
    ));
  }

  // 会员模块
  Widget _buildVipCard() {
    return Obx(() => Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage("assets/kissu_mine_vipbg.webp"),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左边文字
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.isForeverVip.value ? "KissU终身会员" : "KissU会员",
                style: const TextStyle(fontSize: 18, color: Colors.black),
              ),
              const SizedBox(height: 6),
              Text(
                controller.vipDateText.value,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6D4128)),
              ),
            ],
          ),
          // 会员按钮
          GestureDetector(
            onTap: controller.onRenewTap,
            child: Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage("assets/kissu_mine__vip_btnbg.webp"),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                controller.vipButtonText.value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6D4128),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  // 应用设置模块
  Widget _buildSettings() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage("assets/kissu_mine_bottom_bg.webp"),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部标题
          Padding(
            padding: const EdgeInsets.only(left: 19, top: 16, bottom: 8),
            child: SizedBox(
              height: 24,
              width: 120,
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  Image.asset(
                    "assets/kissu_mine_yygn_bg.webp",
                    width: 77,
                    height: 11,
                    fit: BoxFit.contain,
                  ),
                  Positioned(
                    left: 15,
                    child: Image.asset(
                      "assets/kissu_mine_label_yygn.webp",
                      width: 82,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 列表
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.settingItems.length,
            separatorBuilder:
                (_, __) => Container(
                  height: 0.6,
                  color: const Color(0xFFE6E2E3),
                  margin: const EdgeInsets.only(
                    top: 8,
                    bottom: 14,
                    left: 25,
                    right: 25,
                  ),
                ),
            itemBuilder: (_, index) {
              final item = controller.settingItems[index];
              return GestureDetector(
                onTap: item.onTap,
                behavior: HitTestBehavior.opaque, // 确保整个区域都能响应点击
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 19,
                    vertical: 8, // 增加垂直内边距，扩大点击区域
                  ),
                  child: Row(
                    children: [
                      Image.asset(item.icon, width: 22, height: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      Image.asset(
                        "assets/kissu_mine_arrow.webp",
                        width: 16,
                        height: 16,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/kissu_mine_bg.webp", fit: BoxFit.cover),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(),
                  _buildUserInfo(),
                  const SizedBox(height: 16),
                  _buildVipCard(),
                  const SizedBox(height: 24),
                  _buildSettings(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
