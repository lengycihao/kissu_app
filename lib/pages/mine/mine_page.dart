import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'mine_controller.dart';

class MinePage extends GetView<MineController> {
  const MinePage({super.key});

  // 固定的应用设置菜单项
  static const List<Map<String, String>> settingItems = [
    {"icon": "assets/3.0/kissu3_mine_ftp_icon.webp", "title": "防偷拍检测"},
    {"icon": "assets/kissu_mine_item_syst.webp", "title": "首页视图"},
    {"icon": "assets/kissu_mine_item_xtqx.webp", "title": "系统权限"},
    {"icon": "assets/kissu_mine_item_gywm.webp", "title": "关于我们"},
    {"icon": "assets/kissu_mine_item_cjwt.webp", "title": "常见问题"},
    {"icon": "assets/kissu_mine_item_lxwm.webp", "title": "联系我们"},
    {"icon": "assets/kissu_mine_item_yjfk.webp", "title": "意见反馈"},
    {"icon": "assets/kissu_mine_item_ysaq.webp", "title": "账号及隐私安全"},
  ];

  
  // 顶部导航
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16).copyWith(bottom: 30),
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
                style: TextStyle(fontSize: 18, color: Color(0xff333333)),
              ),
            ),
          ),
          const SizedBox(width: 22), // 占位保持居中
        ],
      ),
    );
  }

  
  //新个人信息模块
  Widget _buildNewUserInfo() {
    return GestureDetector(
      onTap: controller.onLabelTap, // 点击进入恋爱信息页面
      child: Container(
        color: Colors.transparent, // 添加透明背景色确保空白区域也能点击
        padding: EdgeInsets.only(left: 18, right: 36),
        child: Row(
          children: [
            _buildNewAvatarSection(),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.nickname.value,
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xff333333),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Obx(() {
                  if (controller.isBound.value) {
                    return Row(
                      children: [
                        Text(
                          "在一起",
                          style: TextStyle(fontSize: 10, color: Color(0xff333333)),
                        ),
                        SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xffFFE8D3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            controller.days.value,
                            style: TextStyle(fontSize: 14, color: Color(0xff333333)),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          "天",
                          style: TextStyle(fontSize: 10, color: Color(0xff333333)),
                        ),
                      ],
                    );
                  } else {
                    return Text(
                      "未绑定另一半",
                      style: TextStyle(fontSize: 12, color: Color(0xff999999)),
                    );
                  }
                }),
              ],
            ),

            Spacer(),
            Image(image: AssetImage("assets/kissu_mine_arrow.webp"), width: 14),
          ],
        ),
      ),
    );
  }

  
  //新头像区域
  Widget _buildNewAvatarSection() {
    return Row(
      children: [
        Obx(
          () => Stack(
            children: [
              // 用户头像 - 只有这个有点击事件
              GestureDetector(
                onTap: controller.onAvatarTap,
                child: _buildAvatar(),
              ),
              // 另一半头像或添加按钮 - 独立的点击事件
              Positioned(
                right: 0, 
                bottom: 0, 
                child: GestureDetector(
                  onTap: controller.onPartnerAvatarTap,
                  child: _buildPartnerAvatar(),
                ),
              ),
              // 心形图标
              Positioned(
                right: 30,
                top: 40,
                child: Image(
                  image: AssetImage("assets/kissu_heart.webp"),
                  width: 29,
                  height: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xffFFE0E0), width: 2),
        borderRadius: BorderRadius.circular(80),
      ),
      child: ClipOval(
          child: controller.userAvatar.value.startsWith('assets/')
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
                        size: 80,
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
                        size: 80,
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
                        size: 80,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
      ),
    );
  }

  // 另一半头像显示逻辑
  Widget _buildPartnerAvatar() {
    // 未绑定时不显示第二个头像
    if (!controller.isBound.value) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFFB6C1), width: 1),
      ),
      child: ClipOval(
        child: controller.partnerAvatar.value.startsWith('assets/')
            ? Image.asset(
                controller.partnerAvatar.value,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: const Color(0xFFE8B4CB),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 24,
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
                      borderRadius: BorderRadius.circular(25),
                      color: const Color(0xFFE8B4CB),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 24,
                      color: Colors.white,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: const Color(0xFFE8B4CB),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 24,
                      color: Colors.white,
                    ),
                  );
                },
              ),
      ),
    );
  }

  // 会员模块
  Widget _buildVipCard() {
    return Obx(
      () => Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ).copyWith(top: 38),
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage("assets/3.0/kissu3_mine_vip_bg.webp"),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 左边文字
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.isVip.value
                          ? (controller.isForeverVip.value
                                ? "KissU终身会员"
                                : "KissU会员")
                          : "KissU会员",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xff6D4128),
                        fontWeight: FontWeight.bold,
                        fontFamily: "LiuHuanKaTongShouShu",
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.vipDateText.value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF915B3D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 6,
              bottom: 9,
              child: Row(
                children: [
                 GestureDetector(
                  onTap: controller.onLocationTap,
                  child:  Container(
                    width: 35,
                    height: 35,
                     color: Colors.transparent,
                  ),
                 ),
                  SizedBox(width: 18),
                  GestureDetector(
                    onTap: controller.onTrackTap,
                    child:  Container(
                      width: 35,
                      height: 35,
                      color: Colors.transparent,
                    ),
                  ),
                  SizedBox(width: 18),
                  GestureDetector(
                    onTap: controller.onHisstoryTap,
                    child:  Container(
                    width: 35,
                    height: 35, 
                    color: Colors.transparent,
                  ),
                  ),
                ],
              ),
            ),
            // 会员按钮
            Positioned(
              right: 0,
              bottom: 9,
              child: GestureDetector(
                onTap: controller.onRenewTap,
                child: Container(
                  width: 120,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(0xffFF0A6C),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    controller.vipButtonText.value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFffffff),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  //新会员模块

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
            separatorBuilder: (_, __) => _buildDashedDivider(),
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
                        child: Row(
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF333333),
                              ),
                            ),
                            index == 0
                                ? Padding(padding:  EdgeInsets.only(left: 6),child: Image(
                                    image: AssetImage(
                                      "assets/3.0/kissu3_mine_ftp_tip.webp",
                                    ),
                                    width: 75,height: 14,
                                  ),)
                                : SizedBox(),
                          ],
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

  Widget _buildDashedDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 2.0;
          const dashSpace = 1.0;
          final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xffE6E2E3)),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/3.0/kissu3_view_bg.webp",
              fit: BoxFit.fill,
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: controller.onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopBar(),
                    _buildNewUserInfo(),
                    // const SizedBox(height: 16),
                    _buildVipCard(),
                    const SizedBox(height: 24),
                    _buildSettings(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
