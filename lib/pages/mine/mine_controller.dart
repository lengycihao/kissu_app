import 'package:get/get.dart';
import 'package:kissu_app/pages/mine/sub_pages/feed_back_page.dart';
import 'package:kissu_app/pages/mine/love_info/love_info_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/privacy_setting_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/question_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/setting_about_us_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/setting_homeview_page.dart';
// import 'package:kissu_app/pages/mine/sub_pages/system_permission_page.dart';
import 'package:kissu_app/network/public/auth_api.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:flutter/material.dart';
import '../phone_history/phone_history_controller.dart';
import 'package:kissu_app/utils/permission_helper.dart';
import 'package:kissu_app/widgets/share_bottom_sheet.dart';
import 'package:kissu_app/pages/track/track_page.dart';
import 'package:kissu_app/pages/track/track_binding.dart';
import 'package:kissu_app/pages/phone_history/phone_history_page.dart';
import 'package:kissu_app/pages/phone_history/phone_history_binding.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';

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

  // 点击事件
  void onLocationTap() {
    Get.toNamed(KissuRoutePath.location);
  }
  void onTrackTap() {
    Get.to(() => TrackPage(), binding: TrackBinding());
  }
  void onHisstoryTap() {
    Get.to(() => const PhoneHistoryPage(), binding: PhoneHistoryBinding());
  }

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
    // 使用 UserManager 统一获取用户基本信息
    final userInfo = UserManager.getUserBasicInfo();
    
    // 基础信息
    nickname.value = userInfo['nickname'];
    matchCode.value = userInfo['matchCode'];
    userAvatar.value = userInfo['avatar'].isNotEmpty 
      ? userInfo['avatar'] 
      : '';
    
    // 绑定状态
    isBound.value = userInfo['isBound'];
    
    if (isBound.value) {
      // 已绑定状态
      partnerAvatar.value = userInfo['partnerAvatar'].isNotEmpty 
        ? userInfo['partnerAvatar'] 
        : "assets/kissu_home_add_avair.webp";
      bindDate.value = userInfo['bindDate'];
      days.value = userInfo['days'];
      
      // 如果有用户对象，继续处理绑定状态的其他数据
      final user = UserManager.currentUser;
      if (user != null) {
        _handleBoundState(user);
      }
    } else {
      // 未绑定状态
      bindDate.value = "";
      days.value = "";
      partnerAvatar.value = "assets/kissu_home_add_avair.webp";
    }

    // 会员信息处理
    final user = UserManager.currentUser;
    if (user != null) {
      _handleVipInfo(user);
    }
  }

  /// 处理已绑定状态的数据
  void _handleBoundState(user) {
    // 处理绑定日期和恋爱天数
    _handleDateAndDays(user);
    
    // 处理另一半头像
    _handlePartnerAvatar(user);
  }

  void _handleDateAndDays(user) {
    // 优先使用LoverInfo中的绑定信息
    if (user.loverInfo != null) {
      // 如果有绑定日期，使用LoverInfo中的数据
      if (user.loverInfo!.bindDate?.isNotEmpty == true) {
        bindDate.value = user.loverInfo!.bindDate!;
      }

      // 如果有恋爱天数，直接使用服务器数据
      if (user.loverInfo!.loveDays != null && user.loverInfo!.loveDays! > 0) {
        days.value = "${user.loverInfo!.loveDays}";
        return; // 使用了LoverInfo的数据，就不需要再计算了
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
          days.value = "$difference";
          return;
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
      days.value = "$difference";
    }
  }

  void _handlePartnerAvatar(user) {
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
      // SettingItem(
      //   icon: "assets/3.0/kissu3_mine_ftp_icon.webp",
      //   title: "防偷拍检测",
      //   onTap: () => _onShareAppTap(),
      // ),
      SettingItem(
        icon: "assets/kissu_share_item.webp",
        title: "分享APP",
        onTap: () => _onShareAppTap(),
      ),
      SettingItem(
        icon: "assets/kissu_mine_item_syst.webp",
        title: "首页视图",
        onTap: () => Get.to(SettingHomePage()),
      ),
      SettingItem(
        icon: "assets/kissu_mine_item_xtqx.webp",
        title: "系统权限",
        onTap: () => Get.toNamed(KissuRoutePath.systemPermission),
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
        onTap: openContact,
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

  /// 打开联系渠道（微信/企业微信客服）
  void openContact() {
    // 你的企业微信客服链接（kfid）
    const String kfidUrl =
        'https://work.weixin.qq.com/kfid/kfcf77b8b4a2a2a61d9';

    try {
      PermissionHelper.openWeComKf(kfidUrl);
    } catch (e) {
       OKToastUtil.show('无法打开微信/企业微信: $e');
    }
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
    // 如果未绑定，显示绑定弹窗
    if (!isBound.value) {
      if (Get.context != null) {
        CustomBottomDialog.show(context: Get.context!);
      }
    } else {
      // 如果已绑定，跳转到恋爱信息页面
      Get.to(LoveInfoPage());
    }
  }

  // 点击自己的头像
  void onAvatarTap() {
    print('🔥 头像被点击了！');
    print('🔥 当前绑定状态: ${isBound.value}');
    
    // 如果已绑定，跳转到恋爱信息页面
    if (isBound.value) {
      print('🔥 用户已绑定，跳转到恋爱信息页面');
      Get.to(LoveInfoPage());
    } else {
      print('🔥 用户未绑定，不执行跳转');
    }
    // 如果未绑定，暂时不做任何操作
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
          OKToastUtil.show('用户信息已更新');
        }
      } else {
        OKToastUtil.show('刷新用户信息失败');
      }
    } catch (e) {
      print('刷新用户信息失败: $e');
       OKToastUtil.show('刷新用户信息失败: $e');
    }
  }

  // 会员续费/开通
  void onRenewTap() {
    print('💫 VIP按钮被点击');

    if (isForeverVip.value) {
      // 永久会员，跳转到权益页面
      print('💫 永久会员，跳转到权益页面');
      Get.toNamed(KissuRoutePath.foreverVip);
    } else {
      // 普通会员或非会员，跳转到VIP页面
      print('💫 普通会员或非会员，跳转到VIP页面');
      Get.toNamed(KissuRoutePath.vip);
     }
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

        OKToastUtil.show('已退出登录');
      } else {
        OKToastUtil.showError(result.msg ?? '退出登录失败');
      }
    } catch (e) {
      OKToastUtil.showError('退出登录失败：$e');
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

  /// 分享APP点击事件
  void _onShareAppTap() {
    ShareBottomSheet.showShareApp(Get.context!);
  }
}

class SettingItem {
  final String icon;
  final String title;
  final void Function()? onTap;

  SettingItem({required this.icon, required this.title, this.onTap});
}
