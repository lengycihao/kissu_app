import 'package:get/get.dart';
import 'package:kissu_app/pages/mine/sub_pages/feed_back_page.dart';
import 'package:kissu_app/pages/mine/love_info/love_info_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/privacy_setting_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/question_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/setting_about_us_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/setting_homeview_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/system_permission_page.dart';
import 'package:kissu_app/network/public/auth_api.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/widgets/dialogs/dialog_manager.dart';
import 'package:flutter/material.dart';
import '../phone_history/phone_history_controller.dart';

class MineController extends GetxController {
  // 用户信息
  var nickname = "小可爱".obs;
  var matchCode = "1000000".obs;
  var bindDate = "".obs;
  var days = "".obs;

  // 头像信息
  var userAvatar = "assets/kissu_icon.webp".obs;
  var partnerAvatar = "assets/kissu_home_add_avair.webp".obs;

  // 绑定状态
  var isBound = false.obs;

  // 会员信息
  var isVip = false.obs;
  var isForeverVip = false.obs;
  var vipEndDate = "".obs;
  var vipButtonText = "立即开通".obs;
  var vipDateText = "了解更多权益".obs;

  // 设置项
  late final List<SettingItem> settingItems;

  // 下拉刷新相关
  var isRefreshing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initSettingItems();
    loadUserInfo();
  }

  void loadUserInfo() {
    final user = UserManager.currentUser;
    if (user != null) {
      // 基础信息
      nickname.value = user.nickname ?? "小可爱";
      matchCode.value = user.friendCode ?? "1000000";

      // 用户头像
      if (user.headPortrait?.isNotEmpty == true) {
        userAvatar.value = user.headPortrait!;
      }

      // 绑定状态处理 (1未绑定，2绑定)
      final bindStatus = user.bindStatus ?? "1";
      isBound.value = bindStatus == "2";

      if (isBound.value) {
        // 已绑定状态
        _handleBoundState(user);
      } else {
        // 未绑定状态
        bindDate.value = "";
        days.value = "";
        partnerAvatar.value = "assets/kissu_home_add_avair.webp";
      }

      // 会员信息处理
      _handleVipInfo(user);
    }
  }

  /// 处理已绑定状态的数据
  void _handleBoundState(user) {
    // 优先使用LoverInfo中的绑定信息
    if (user.loverInfo != null) {
      // 如果有绑定日期，使用LoverInfo中的数据
      if (user.loverInfo!.bindDate?.isNotEmpty == true) {
        bindDate.value = user.loverInfo!.bindDate!;
      }

      // 如果有恋爱天数，直接使用
      if (user.loverInfo!.loveDays != null && user.loverInfo!.loveDays! > 0) {
        days.value = "${user.loverInfo!.loveDays}天";
        // return; // 使用了LoverInfo的数据，就不需要再计算了
      }

      // 如果有bindTime但没有loveDays，尝试从bindTime计算
      if (user.loverInfo!.bindTime?.isNotEmpty == true) {
        try {
          final bindTimestamp = int.parse(user.loverInfo!.bindTime!);
          final bindTime = DateTime.fromMillisecondsSinceEpoch(
            bindTimestamp * 1000,
          );

          // 如果bindDate为空，格式化bindTime作为bindDate
          if (user.loverInfo!.bindDate?.isEmpty ?? true) {
            bindDate.value = _formatDate(bindTime);
          }

          // 计算在一起天数
          final now = DateTime.now();
          final difference = now.difference(bindTime).inDays;
          days.value = "${difference}天";
          // return;
        } catch (e) {
          print('解析LoverInfo bindTime失败: $e');
        }
      }
    }

    // 如果LoverInfo没有数据，回退到使用latelyBindTime
    if (user.latelyBindTime != null) {
      final bindTime = DateTime.fromMillisecondsSinceEpoch(
        user.latelyBindTime! * 1000,
      );
      bindDate.value = _formatDate(bindTime);

      // 计算在一起天数
      final now = DateTime.now();
      final difference = now.difference(bindTime).inDays;
      days.value = "${difference}天";
    }

    // 处理另一半头像
    if (user.loverInfo?.headPortrait?.isNotEmpty == true) {
      partnerAvatar.value = user.loverInfo!.headPortrait!;
    } else if (user.halfUserInfo?.headPortrait?.isNotEmpty == true) {
      partnerAvatar.value = user.halfUserInfo!.headPortrait!;
    } else if (isBound.value) {
      // 如果有绑定关系但没有头像，使用默认头像
      partnerAvatar.value = "assets/kissu_icon.webp";
    } else {
      // 如果没有绑定关系，显示添加头像
      partnerAvatar.value = "assets/kissu_home_add_avair.webp";
    }
  }

  /// 处理会员信息
  void _handleVipInfo(user) {
    final vipStatus = user.isVip ?? 0;
    final foreverVipStatus = user.isForEverVip ?? 0;

    isVip.value = vipStatus == 1;
    isForeverVip.value = foreverVipStatus == 1;

    if (isForeverVip.value) {
      // 终身会员
      vipButtonText.value = "查看权益";
      vipDateText.value = "终身陪伴kissu";
    } else if (isVip.value) {
      // 普通会员
      vipButtonText.value = "去续费";
      if (user.vipEndDate?.isNotEmpty == true) {
        vipDateText.value = "${user.vipEndDate}到期";
      } else {
        vipDateText.value = "会员有效期";
      }
    } else {
      // 非会员
      vipButtonText.value = "立即开通";
      vipDateText.value = "了解更多权益";
    }
  }

  /// 格式化日期为 YYYY.MM.DD 格式
  String _formatDate(DateTime dateTime) {
    return "${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}";
  }

  void _initSettingItems() {
    settingItems = [
      SettingItem(
        icon: "assets/kissu_mine_item_syst.webp",
        title: "首页视图",
        onTap: () => Get.to(SettingHomePage()),
      ),
      SettingItem(
        icon: "assets/kissu_mine_item_xtqx.webp",
        title: "系统权限",
        onTap: () => Get.to(SystemPermissionPage()),
      ),
      SettingItem(
        icon: "assets/kissu_mine_item_gywm.webp",
        title: "关于我们",
        onTap: () => Get.to(AboutUsPage()),
      ),
      SettingItem(
        icon: "assets/kissu_mine_item_cjwt.webp",
        title: "常见问题",
        onTap: () => Get.to(QuestionPage()),
      ),
      SettingItem(
        icon: "assets/kissu_mine_item_lxwm.webp",
        title: "联系我们",
        onTap: () => Get.snackbar("点击", "联系我们"),
      ),
      SettingItem(
        icon: "assets/kissu_mine_item_yjfk.webp",
        title: "意见反馈",
        onTap: () => Get.to(FeedbackPage()),
      ),
      SettingItem(
        icon: "assets/kissu_mine_item_ysaq.webp",
        title: "账号及隐私安全",
        onTap: () => Get.to(PrivacySettingPage()),
      ),
    ];
  }

  // 顶部返回
  void onBackTap() {
    Get.back();
  }

  // 点击恋爱信息标签
  void onLabelTap() {
    Get.to(LoveInfoPage());
  }

  // 下拉刷新
  Future<void> onRefresh() async {
    if (isRefreshing.value) return; // 防止重复刷新

    isRefreshing.value = true;
    try {
      await refreshUserInfo();
    } finally {
      isRefreshing.value = false;
    }
  }

  // 点击另一半头像
  void onPartnerAvatarTap() {
    // 如果未绑定，显示绑定输入弹窗
    if (!isBound.value) {
      DialogManager.showBindingInput(
        context: Get.context!,
        onConfirm: (code) {
          // 这个回调实际上在BindingInputDialog内部处理，这里不需要额外操作
          // 因为dialog内部已经会刷新数据并调用loadUserInfo()
        },
      );
    } else {
      // 如果已绑定，跳转到恋爱信息页面
      Get.to(LoveInfoPage());
    }
  }

  // 刷新用户信息（从服务器获取最新数据）
  Future<void> refreshUserInfo() async {
    try {
      // 使用UserManager的刷新方法
      final success = await UserManager.refreshUserInfo();

      if (success) {
        // 刷新成功后重新加载页面数据
        loadUserInfo();
        
        // 同时刷新敏感记录页面数据（如果绑定状态发生变化）
        _refreshPhoneHistoryPage();
        
        // 下拉刷新时不显示snackbar，避免界面干扰
        if (!isRefreshing.value) {
          Get.snackbar(
            '提示',
            '用户信息已更新',
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        Get.snackbar(
          '提示',
          '刷新用户信息失败',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('刷新用户信息失败: $e');
      Get.snackbar(
        '提示',
        '刷新用户信息失败: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // 会员续费
  void onRenewTap() {
    Get.snackbar("提示", "去续费");
  }

  /// 退出登录功能
  void showLogoutDialog() {
    // 显示退出登录确认对话框
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          '退出登录',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          '确定要退出当前账号吗？',
          style: TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.5),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => performLogout(),
            child: const Text(
              '确认',
              style: TextStyle(
                color: Color(0xFFFF4444),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              '我再想想',
              style: TextStyle(color: Color(0xFF999999), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// 执行退出登录
  Future<void> performLogout() async {
    Get.back(); // 关闭对话框

    try {
      // 调用退出登录API
      final authApi = AuthApi();
      final result = await authApi.logout();

      if (result.isSuccess) {
        // 清除本地用户数据
        await UserManager.logout();

        // 跳转到登录页面
        Get.offAllNamed('/login');

        Get.snackbar(
          '提示',
          '已退出登录',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          '错误',
          result.msg ?? '退出登录失败',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
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

  /// 刷新敏感记录页面数据
  void _refreshPhoneHistoryPage() {
    try {
      if (Get.isRegistered<PhoneHistoryController>()) {
        final phoneHistoryController = Get.find<PhoneHistoryController>();
        phoneHistoryController.loadData(isRefresh: true);
        print('已刷新敏感记录页面数据');
      }
    } catch (e) {
      print('刷新敏感记录页面数据失败: $e');
    }
  }
}

class SettingItem {
  final String icon;
  final String title;
  final void Function()? onTap;

  SettingItem({required this.icon, required this.title, this.onTap});
}
