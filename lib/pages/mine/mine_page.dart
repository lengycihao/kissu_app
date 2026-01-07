import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'mine_controller.dart';
import 'widgets/mine_top_bar.dart';
import 'widgets/mine_user_info.dart';
import 'widgets/mine_avatar_section.dart';
import 'widgets/mine_vip_card.dart';
import 'widgets/mine_common_functions.dart';
import 'widgets/mine_settings.dart';
import 'sub_pages/system_permission_page.dart';
import 'sub_pages/system_permission_binding.dart';

class MinePage extends GetView<MineController> {
  const MinePage({super.key});

  // 会员模块 - 根据状态选择显示哪个卡片
  Widget _buildVipCard() {
    return Obx(() {
      VipCardType cardType;
      // 优先级：永久会员 > 普通会员 > 未绑定 > 非会员
      if (controller.isForeverVip.value) {
        cardType = VipCardType.foreverVip;
      } else if (controller.isVip.value) {
        cardType = VipCardType.normalVip;
      } else if (!controller.isBound.value) {
        cardType = VipCardType.unbound;
      } else {
        cardType = VipCardType.nonVip;
      }

      return MineVipCard(
        cardType: cardType,
        vipEndDate: controller.vipEndDate.value,
        onRenewTap: controller.onRenewTap,
        areAllPermissionsGranted: controller.areAllPermissionsGranted.value,
        onPermissionSettingTap: () async {
          // 埋点：记录权限模块点击
          controller.trackPermissionModuleClick();
          
          await Get.to(
            () => const SystemPermissionPage(),
            binding: SystemPermissionBinding(),
            transition: Transition.rightToLeft,
          );
          // 从权限设置页面返回时，重新检查权限状态
          controller.checkAllPermissions();
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/4.0/kissu4_mine_topbg.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 固定的顶部导航栏
                MineTopBar(
                  onBackTap: controller.onBackTap,
                  onSettingTap: controller.onSettingTap,
                ),
                // 可滚动的内容区域
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.onRefresh,
                    child:SingleChildScrollView(
                         physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: 15),
                            Obx(() => MineUserInfo(
                                  nickname: controller.nickname.value,
                                  partnerNickname:
                                      controller.partnerNickname.value,
                                  isBound: controller.isBound.value,
                                  days: controller.days.value,
                                  onLabelTap: controller.onLabelTap,
                                  avatarSection: Obx(() => MineAvatarSection(
                                        userAvatar: controller.userAvatar.value,
                                        partnerAvatar:
                                            controller.partnerAvatar.value,
                                        isBound: controller.isBound.value,
                                        onAvatarTap: controller.onAvatarTap,
                                        onPartnerAvatarTap:
                                            controller.onPartnerAvatarTap,
                                      )),
                                )),
                            const SizedBox(height: 16),
                            _buildVipCard(),
                            const SizedBox(height: 16),
                            // 常用功能模块
                            MineCommonFunctions(
                              items: controller.commonFunctionItems,
                            ),
                            const SizedBox(height: 16),
                            MineSettings(
                              items: controller.settingItems,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
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
}
 