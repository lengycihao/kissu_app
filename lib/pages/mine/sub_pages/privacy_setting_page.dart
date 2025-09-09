import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/mine/sub_pages/break_relationship_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/account_cancellation_page.dart';
import 'package:kissu_app/pages/mine/love_info/phone_change_page.dart';
import 'package:kissu_app/widgets/dialogs/dialog_manager.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';

class PrivacySettingPage extends StatelessWidget {
  const PrivacySettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 示例手机号
    final phoneNumber = UserManager.formatPhoneWithExcept(
      UserManager.userPhone ?? "",
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: Image.asset(
                        "assets/kissu_mine_back.webp",
                        width: 22,
                        height: 22,
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          "账号及隐私安全",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 22), // 占位保持居中
                  ],
                ),
              ),
              const SizedBox(height: 35),

              // Item 列表
              Column(
                children: [
                  _SettingItem(
                    iconPath: "assets/kissu_setting_account_ysaq.webp",
                    title: "隐私安全",
                    onTap: () => Get.snackbar("点击", "隐私安全"),
                  ),
                  const SizedBox(height: 14),
                  // 根据绑定状态显示解除关系选项
                  _buildBreakRelationshipItem(),
                  _SettingItem(
                    iconPath: "assets/kissu_setting_account_zxzh.webp",
                    title: "注销账号",
                    onTap: () => Get.to(() => AccountCancellationPage()),
                  ),
                  const SizedBox(height: 14),
                  _SettingItem(
                    iconPath: "assets/kissu_setting_account_sjh.webp",
                    title: "手机号",
                    trailingText: phoneNumber,
                    onTap: () => Get.to(() => PhoneChangePage()),
                  ),
                ],
              ),

              const Spacer(),

              // 退出登录按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFAFAF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () => _handleLogout(context),
                  child: const Text(
                    "退出登录",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建解除关系选项（根据绑定状态显示）
  Widget _buildBreakRelationshipItem() {
    final user = UserManager.currentUser;
    if (user == null) return const SizedBox.shrink();

    // 检查绑定状态，只有已绑定（bindStatus == "2"）才显示解除关系选项
    final bindStatus = user.bindStatus ?? "1";
    final isBindPartner = bindStatus == "2";

    if (isBindPartner) {
      return Column(
        children: [
          _SettingItem(
            iconPath: "assets/kissu_setting_account_jcgx.webp",
            title: "解除关系",
            onTap: () => Get.to(() => const BreakRelationshipPage()),
          ),
          const SizedBox(height: 14),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  /// 处理退出登录
  void _handleLogout(BuildContext context) async {
    final result = await DialogManager.showLogoutConfirm(context);
    if (result == true) {
      // 执行退出登录逻辑
      _performLogout();
    }
  }

  /// 执行退出登录
  void _performLogout() async {
    try {
      // 清除本地用户数据（这里已经包含了API调用）
      await UserManager.logout();

      // 跳转到登录页面
      Get.offAllNamed(KissuRoutePath.login);

      Get.snackbar(
        '提示',
        '已退出登录',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        '错误',
        '退出登录失败：$e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }
}

/// 设置页面单个Item
class _SettingItem extends StatelessWidget {
  final String iconPath;
  final String title;
  final String? trailingText; // 右侧显示文字（手机号）
  final VoidCallback? onTap;

  const _SettingItem({
    required this.iconPath,
    required this.title,
    this.trailingText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage("assets/kissu_setting_account_itenbg.webp"),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Image.asset(iconPath, width: 34, height: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText!,
                style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
              ),
            if (trailingText != null) const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF999999),
            ),
          ],
        ),
      ),
    );
  }
}
