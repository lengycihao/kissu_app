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
  Widget _buildDashLine({EdgeInsets margin = const EdgeInsets.symmetric(vertical: 8)}) {
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
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xff69686F))),
          Text(value.value, style: const TextStyle(fontSize: 14, color: Color(0xff593A37))),
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
            child: Image.asset("assets/kissu_mine_back.webp", width: 22, height: 22),
          ),
          const Expanded(
            child: Center(
              child: Text("我的", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        image: const DecorationImage(image: AssetImage("assets/kissu_mine_info_bg.webp"), fit: BoxFit.cover),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  image: DecorationImage(
                    image: AssetImage("assets/kissu_mine_avatar.webp"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: controller.onLabelTap,
                child: Row(
                  children: [
                    Image.asset("assets/kissu_mine_label_laxx.webp", width: 56, height: 16),
                    const SizedBox(width: 4),
                    Image.asset("assets/kissu_mine_arrow.webp", width: 14, height: 14),
                  ],
                ),
              ),
            ],
          ),
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

  // 会员模块
  Widget _buildVipCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        image: const DecorationImage(image: AssetImage("assets/kissu_mine_vipbg.webp"), fit: BoxFit.fill),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左边文字
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("KissU会员", style: TextStyle(fontSize: 18, color: Colors.black)),
              SizedBox(height: 6),
              Text("2025.10.09到期", style: TextStyle(fontSize: 12, color: Color(0xFF6D4128))),
            ],
          ),
          // 去续费按钮
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
              child: const Text("去续费", style: TextStyle(fontSize: 16, color: Color(0xFF6D4128), fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

 // 应用设置模块
Widget _buildSettings() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 18),
    padding: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      image: const DecorationImage(image: AssetImage("assets/kissu_mine_bottom_bg.webp"), fit: BoxFit.fill),
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
                Image.asset("assets/kissu_mine_yygn_bg.webp", width: 77, height: 11, fit: BoxFit.contain),
                Positioned(
                  left: 15,
                  child: Image.asset("assets/kissu_mine_label_yygn.webp", width: 82, height: 24, fit: BoxFit.contain),
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
          separatorBuilder: (_, __) => Container(
            height: 0.6,
            color: const Color(0xFFE6E2E3),
            margin: const EdgeInsets.only(top: 8, bottom: 14, left: 25, right: 25),
          ),
          itemBuilder: (_, index) {
            final item = controller.settingItems[index];
            return GestureDetector(
              onTap: item.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 19),
                    Image.asset(item.icon, width: 22, height: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item.title, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 19),
                      child: Image.asset("assets/kissu_mine_arrow.webp", width: 16, height: 16),
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
          Positioned.fill(child: Image.asset("assets/kissu_mine_bg.webp", fit: BoxFit.cover)),
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
