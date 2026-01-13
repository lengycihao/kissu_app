import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/mine/sub_pages/break_relationship_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/account_cancellation_page.dart';
import 'package:kissu_app/pages/mine/love_info/love_info_controller.dart';
import 'package:kissu_app/pages/mine/love_info/phone_change_page.dart';
import 'package:kissu_app/widgets/dialogs/dialog_manager.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/utils/login_navigation_lock.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/utils/agreement_utils.dart';
import 'package:kissu_app/pages/mine/sub_pages/cache_manager.dart';

class PrivacySettingPage extends StatefulWidget {
  const PrivacySettingPage({super.key});

  @override
  State<PrivacySettingPage> createState() => _PrivacySettingPageState();
}

class _PrivacySettingPageState extends State<PrivacySettingPage> {
  @override
  void initState() {
    super.initState();
    // 计算缓存大小
    CacheManager.calculateCacheSize();
  }

  @override
  Widget build(BuildContext context) {
    // 示例手机号
    final phoneNumber = UserManager.formatPhoneWithExcept(
      UserManager.userPhone ?? "",
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          // 背景图
          Positioned.fill(
            child: Image.asset(
              "assets/4.0/kissu4_new_use_bg.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
        child:Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 标题
              SizedBox(
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
                          "设置",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Item 列表 - 带动画
              _AnimatedSettingItem(
                delay: 0,
                iconPath: "assets/images/kissu_setting_account_ysaq.webp",
                title: "隐私安全",
                onTap: () => AgreementUtils.toPrivacySecurity(),
              ),
              const SizedBox(height: 14),
              // 根据绑定状态显示解除关系选项
              _buildBreakRelationshipItem(),
              _AnimatedSettingItem(
                delay: 100,
                iconPath: "assets/images/kissu_setting_account_zxzh.webp",
                title: "注销账号",
                onTap: () => Get.to(
                  () => AccountCancellationPage(),
                  transition: Transition.rightToLeft,
                ),
              ),
              const SizedBox(height: 14),
              _AnimatedSettingItem(
                delay: 200,
                iconPath: "assets/images/kissu_setting_account_sjh.webp",
                title: "更换账号",
                trailingText: phoneNumber,
                onTap: () => _handlePhoneChange(context, phoneNumber),
              ),
              const SizedBox(height: 14),
              _AnimatedCacheItem(
                delay: 300,
                iconPath: "assets/4.0/kissu4_feedback.webp",
                title: "清除缓存",
                onTap: () => CacheManager.clearCache(),
              ),

              const Spacer(),

              // 退出登录按钮
              Padding(padding: const EdgeInsets.symmetric(horizontal: 45),child: SizedBox(
                width: double.maxFinite,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFfFFA9E0),
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),),
              SizedBox(height: 60),
            ],
          ),
      
      ),
        ],
      ),
    );
  }

  /// 构建解除关系选项（根据绑定状态显示）
  Widget _buildBreakRelationshipItem() {
    final user = UserManager.currentUser;
    if (user == null) return const SizedBox.shrink();

     final bindStatus = user.bindStatus.toString();
    final isBindPartner = bindStatus.toString() == "1";

    if (isBindPartner) {
      return Column(
        children: [
          _AnimatedSettingItem(
            delay: 50,
            iconPath: "assets/images/kissu_setting_account_jcgx.webp",
            title: "解除关系",
            onTap: () => Get.to(
              () => const BreakRelationshipPage(),
              transition: Transition.rightToLeft,
            ),
          ),
          const SizedBox(height: 14),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  /// 处理手机号更改
  void _handlePhoneChange(BuildContext context, String phoneNumber) async {
    // 先显示确认弹窗
    final result = await DialogManager.showPhoneChangeConfirm(
      context,
      phoneNumber,
    );
    
    if (result == true) {
      // 用户确认更改，跳转到手机号更换页面
      Get.to(
        () => PhoneChangePage(),
        transition: Transition.rightToLeft,
      );
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
      // 🔧 使用登录页导航锁，防止重复跳转导致闪烁
      // 先尝试获取锁并跳转到登录页
      final navigated = LoginNavigationLock.navigateToLoginSafely();
      if (!navigated) {
        // 如果已经有其他线程正在导航，直接返回
        return;
      }

      _clearLoveInfoController();
      
      // 然后在后台调用退出登录API（不阻塞UI）
      UserManager.logout().catchError((e) {
        // 退出登录API失败不影响UI，因为已经跳转到登录页了
      });

      CustomToast.show(
        Get.context!,
        '已退出登录',
      );
    } catch (e) {
      CustomToast.show(
        Get.context!,
        '退出登录失败：$e',
      );
    }
  }

  void _clearLoveInfoController() {
    if (Get.isRegistered<LoveInfoController>()) {
      Get.delete<LoveInfoController>(force: true);
    }
  }
}

/// 带动画效果的设置项
class _AnimatedSettingItem extends StatefulWidget {
  final String iconPath;
  final String title;
  final String? trailingText;
  final VoidCallback? onTap;
  final int delay;

  const _AnimatedSettingItem({
    required this.iconPath,
    required this.title,
    this.trailingText,
    this.onTap,
    this.delay = 0,
  });

  @override
  State<_AnimatedSettingItem> createState() => _AnimatedSettingItemState();
}

class _AnimatedSettingItemState extends State<_AnimatedSettingItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

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
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: 54,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              // border: Border.all(color: const Color(0xFFFFD4D1),width: 1),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              
            ),
            child: Row(
              children: [
                Image.asset(widget.iconPath, width: 34, height: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.trailingText != null)
                  Text(
                    widget.trailingText!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0x46777777),
                    ),
                  ),
                if (widget.trailingText != null) const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF333333),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 带缓存大小显示的动画设置项
class _AnimatedCacheItem extends StatefulWidget {
  final String iconPath;
  final String title;
  final VoidCallback? onTap;
  final int delay;

  const _AnimatedCacheItem({
    required this.iconPath,
    required this.title,
    this.onTap,
    this.delay = 0,
  });

  @override
  State<_AnimatedCacheItem> createState() => _AnimatedCacheItemState();
}

class _AnimatedCacheItemState extends State<_AnimatedCacheItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

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
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: 54,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Image.asset(widget.iconPath, width: 34, height: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // 显示缓存大小
                Obx(() => Text(
                  CacheManager.cacheSize.value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0x46777777),
                  ),
                )),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF333333),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
