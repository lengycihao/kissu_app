import 'package:get/get.dart';
import 'package:kissu_app/pages/mine/love_info/love_info_page.dart';
import 'package:kissu_app/pages/mine/love_info/love_info_controller.dart';
import 'package:kissu_app/pages/mine/sub_pages/privacy_setting_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/question_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/setting_about_us_page.dart';
 // import 'package:kissu_app/pages/mine/sub_pages/system_permission_page.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:flutter/material.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import '../usage_report/usage_report_controller.dart';
import '../usage_report/usage_report_page.dart';
import '../usage_report/usage_report_binding.dart';
import 'package:kissu_app/utils/permission_helper.dart';
import 'package:kissu_app/utils/vip_navigation_helper.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/utils/login_navigation_lock.dart';
import 'package:kissu_app/widgets/share_bottom_sheet.dart';
import 'package:kissu_app/pages/track/track_page.dart';
import 'package:kissu_app/pages/track/track_binding.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog_controller.dart';
import 'package:kissu_app/widgets/dialogs/binding_close_confirm_dialog.dart'; 
import 'package:kissu_app/pages/mine/app_usage/app_usage_page.dart';
import 'package:kissu_app/pages/mine/app_usage/app_usage_binding.dart';
import 'package:kissu_app/services/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get_utils/src/platform/platform.dart';

class MineController extends GetxController {
  // 用户信息
  var nickname = "小可爱".obs;
  var partnerNickname = "小可爱".obs;
  var matchCode = "1000000".obs;
  var bindDate = "".obs;
  var days = "".obs;

  // 头像信息
  var userAvatar = "assets/3.0/kissu3_love_avater.webp".obs;
  var partnerAvatar = "assets/images/kissu_home_add_avair.webp".obs;

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
    // 添加会员检查
    VipNavigationHelper.navigateToLocationWithVipCheck();
  }

  void onTrackTap() {
    Get.to(
      () => TrackPage(),
      binding: TrackBinding(),
      transition: Transition.rightToLeft,
    );
  }

  void onHisstoryTap() {
    // 跳转到新的用机记录页面
    Get.toNamed(KissuRoutePath.deviceUsage);
  }

  // 设置项
  late final List<SettingItem> settingItems;

  // 常用功能项
  late final List<CommonFunctionItem> commonFunctionItems;

  // 下拉刷新相关
  var isRefreshing = false.obs;

 

 

  // 权限状态
  /// 是否已经完成「系统权限」页面中所有需要开启的权限 / 教程项
  /// - 包括：实时定位、通知、使用情况访问、电池优化
  /// - 以及：允许后台运行、防止程序休眠、让程序锁在后台（部分机型为 5 项）
  var areAllPermissionsGranted = false.obs;
  final PermissionService _permissionService = PermissionService();

  // 与系统权限页保持一致的教程完成状态持久化 key
  static const String _guidePreventSleepKey =
      'system_permission_guide_prevent_sleep_completed';
  static const String _guideBackgroundRunKey =
      'system_permission_guide_background_run_completed';
  static const String _guideLockBackgroundKey =
      'system_permission_guide_lock_background_completed';

  // 机型信息（用于判断是否是小米系机型，从而决定是否需要“让程序锁在后台”这一项）
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  bool _isXiaomiDevice = false;
  bool _deviceBrandInited = false;

  Future<void> _initDeviceBrandIfNeeded() async {
    if (_deviceBrandInited) return;

    _deviceBrandInited = true;

    if (!GetPlatform.isAndroid) {
      _isXiaomiDevice = false;
      return;
    }

    try {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      final brand = (androidInfo.brand).toLowerCase();
      _isXiaomiDevice = brand.contains('xiaomi') ||
          brand.contains('mi') ||
          brand.contains('redmi');
    } catch (e) {
      // 获取品牌失败时，默认按非小米处理，保证逻辑可用
      _isXiaomiDevice = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initSettingItems();
    _initCommonFunctionItems();

 

    // 先加载本地用户信息（立即显示）
    loadUserInfo();
    // 然后静默刷新用户信息
    _silentRefreshUserInfo();
    // 检查权限状态
    checkAllPermissions();
  }

 
 
 

  /// 页面重新获得焦点时的回调（从其他页面返回时会调用）
  void onPageResumed() {
    debugPrint('👤 我的页面重新获得焦点，静默刷新用户信息');
    // 先用本地数据（已经在onInit中加载）
    // 然后静默刷新用户信息
    _silentRefreshUserInfo();
    // 重新检查权限状态（从权限设置页面返回时）
    checkAllPermissions();
  }

  /// 检查所有权限状态
  Future<void> checkAllPermissions() async {
    try {
      // 1. 检查系统级权限状态（与系统权限页保持一致）
      final permissions = await _permissionService.checkAllPermissions();

      final isLocationGranted = permissions[PermissionType.location] ?? false;
      final isNotificationGranted =
          permissions[PermissionType.notification] ?? false;
      final isBatteryOptimized = permissions[PermissionType.battery] ?? false;
      final isUsageAccessGranted = permissions[PermissionType.usage] ?? false;

      // 2. 读取「教程类」开关的完成状态（与系统权限页使用同一份本地缓存）
      final prefs = await SharedPreferences.getInstance();
      final preventSleepCompleted =
          prefs.getBool(_guidePreventSleepKey) ?? false;
      final backgroundRunCompleted =
          prefs.getBool(_guideBackgroundRunKey) ?? false;
      final lockBackgroundCompleted =
          prefs.getBool(_guideLockBackgroundKey) ?? false;

      // 3. 初始化机型信息，用于处理“小米机型只有 5 项”的情况
      await _initDeviceBrandIfNeeded();

      // 系统权限页总体有 6 项开关（部分小米机型隐藏“让程序锁在后台”，变为 5 项）
      // 这里的「全部开启」含义完全对齐系统权限页：
      // - 所有权限型 item 的按钮文案为“已开启”
      // - 所有教程型 item 已被标记为完成（按钮文案为“已开启”）
      final allGuidesCompleted = preventSleepCompleted &&
          backgroundRunCompleted &&
          (_isXiaomiDevice ? true : lockBackgroundCompleted);

      areAllPermissionsGranted.value = isLocationGranted &&
          isNotificationGranted &&
          isBatteryOptimized &&
          isUsageAccessGranted &&
          allGuidesCompleted;

      logDebug(
        '权限状态检查完成: 位置=$isLocationGranted, 通知=$isNotificationGranted, 电池=$isBatteryOptimized, 使用情况=$isUsageAccessGranted, '
        '防休眠=$preventSleepCompleted, 后台运行指引=$backgroundRunCompleted, 锁后台指引=$lockBackgroundCompleted, '
        '是否小米系=$_isXiaomiDevice',
        tag: 'Mine',
      );
      logDebug('系统权限开关是否全部开启: ${areAllPermissionsGranted.value}', tag: 'Mine');
    } catch (e) {
      logError('检查权限状态失败: $e', tag: 'Mine', error: e);
      // 出错时默认显示图标（保守策略）
      areAllPermissionsGranted.value = false;
    }
  }

  /// 静默刷新用户信息（不阻塞UI）
  Future<void> _silentRefreshUserInfo() async {
    try {
      debugPrint('🔄 我的页面：静默刷新用户信息');
      final success = await UserManager.refreshUserInfo();
      if (success) {
        // 刷新成功后重新加载本地数据到UI
        loadUserInfo();
      }
    } catch (e) {
      debugPrint('❌ 我的页面：静默刷新用户信息失败: $e');
    }
  }

  void loadUserInfo() {
    // 使用 UserManager 统一获取用户基本信息
    final userInfo = UserManager.getUserBasicInfo();

    // 基础信息
    nickname.value = userInfo['nickname'];
    partnerNickname.value = userInfo['partnerNickname'];
    matchCode.value = userInfo['matchCode'];
    userAvatar.value = userInfo['avatar'].isNotEmpty ? userInfo['avatar'] : '';

    // 调试输出
    debugPrint('👤 我的页面用户信息：');
    debugPrint('   昵称: ${nickname.value}');
    debugPrint('   另一半昵称: ${partnerNickname.value}');
    debugPrint('   绑定状态: ${userInfo['isBound']}');

    // 绑定状态
    isBound.value = userInfo['isBound'];

    if (isBound.value) {
      // 已绑定状态
      partnerAvatar.value = userInfo['partnerAvatar'].isNotEmpty
          ? userInfo['partnerAvatar']
          : "assets/images/kissu_home_add_avair.webp";
      bindDate.value = userInfo['bindDate'];
      days.value = userInfo['days'];

      // 如果有用户对象，继续处理绑定状态的其他数据
      final user = UserManager.currentUser;
      if (user != null) {
        debugPrint('   loverInfo.nickname: ${user.loverInfo?.nickname}');
        debugPrint('   halfUserInfo.nickname: ${user.halfUserInfo?.nickname}');
        _handleBoundState(user);
      }
    } else {
      // 未绑定状态
      bindDate.value = "";
      days.value = "";
      partnerAvatar.value = "assets/images/kissu_home_add_avair.webp";
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

      // 如果有恋爱天数，直接使用服务器数据（包括0）
      if (user.loverInfo!.loveDays != null) {
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
          logWarning('解析LoverInfo bindTime失败: $e', tag: 'Mine', error: e);
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
      partnerAvatar.value = "assets/3.0/kissu3_love_avater.webp";
    } else {
      // 如果没有绑定关系，显示添加头像
      partnerAvatar.value = "assets/images/kissu_home_add_avair.webp";
    }
  }

  /// 处理会员信息
  void _handleVipInfo(user) {
    final vipStatus = user.isVip ?? 0;
    final foreverVipStatus = user.isForEverVip ?? 0;

    isVip.value = vipStatus == 1;
    isForeverVip.value = foreverVipStatus == 1;

    // 设置会员到期日期
    vipEndDate.value = user.vipEndDate ?? "";

    // 如果未绑定，显示"立即去绑定"
    if (!isBound.value) {
      vipButtonText.value = "立即去绑定";
      vipDateText.value = "一人开通，两人均能享受六大专属权益";
    } else if (isForeverVip.value) {
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
      vipDateText.value = "一人开通，两人均能享受六大专属权益";
    }
  }

  /// 格式化日期为 YYYY.MM.DD 格式
  String _formatDate(DateTime dateTime) {
    return "${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}";
  }

  void _initCommonFunctionItems() {
    commonFunctionItems = [
      CommonFunctionItem(
        icon: "assets/4.0/kissu4_mine_location.webp",
        title: "实时定位",
        onTap: () => onLocationTap(),
      ),
      CommonFunctionItem(
        icon: "assets/4.0/kissu4_mine_app_time.webp",
        title: "app使用记录",
        onTap: () => _onAppUsageRecordTap(),
      ),
      CommonFunctionItem(
        icon: "assets/4.0/kissu4_mine_history.webp",
        title: "用机记录",
        onTap: () => onHisstoryTap(),
      ),
      CommonFunctionItem(
        icon: "assets/4.0/kissu4_mine_track.webp",
        title: "足迹",
        onTap: () => onTrackTap(),
      ),
      CommonFunctionItem(
        icon: "assets/4.0/kissu4_mine_scan.webp",
        title: "酒店防偷拍",
        onTap: () => _onAntiSpyTap(),
      ),
      CommonFunctionItem(
        icon: "assets/4.0/kissu4_mine_newhome.webp",
        title: "个性化首页",
        onTap: () => _onPersonalizedHomeTap(),
      ),
      CommonFunctionItem(
        icon: "assets/4.0/kissu4_mine_minganjilu.webp",
        title: "敏感操作记录",
        onTap: () => _onMinganJiluTap(),
      ),
      CommonFunctionItem(
        icon: "assets/4.0/kissu4_mine_change_logo.webp",
        title: "更换app图标",
        onTap: () => _onChangeAppIconTap(),
      ),
    ];
  }

  void _initSettingItems() {
    settingItems = [
     
      SettingItem(
        icon: "assets/4.0/kissu4_share.webp",
        title: "分享APP",
        onTap: () => _onShareAppTap(),
      ),
      SettingItem(
        icon: "assets/4.0/kissu4_notice.webp",
        title: "通知设置",
        onTap: () => _onNotificationSettingsTap(),
      ),

      // SettingItem(
      //   icon: "assets/images/kissu_home_tab_history.webp", // 使用系统权限图标作为弹窗展示图标
      //   title: "弹窗展示",
      //   onTap: () => Get.to(() => const DialogShowcasePage()),
      // ),

      // SettingItem(
      //   icon: "assets/images/kissu_home_tab_history.webp",
      //   title: "用机记录",
      //   onTap: () => Get.to(() => const UsageReportPage(), binding: UsageReportBinding()),
      // ),
      // SettingItem(
      //   icon: "assets/3.0/kissu3_mine_ftp_icon.webp",
      //   title: "屏幕使用测试",
      //   onTap: () => Get.toNamed(KissuRoutePath.trackPlayTest),

      // ),
      // SettingItem(
      //   icon: "assets/images/kissu_home_tab_history.webp",
      //   title: "首页视图",
      //   onTap: () async {
      //     await TrackingService.trackHomeView();
      //     Get.to(
      //       SettingHomePage(),
      //       transition: Transition.rightToLeft,
      //     );
      //   },
      // ),
      SettingItem(
        icon: "assets/4.0/kissu4_mine_contact.webp",
        title: "联系我们",
        onTap: _onContactTap,
      ),

      SettingItem(
        icon: "assets/4.0/kissu4_mine_question.webp",
        title: "常见问题",
        onTap: () async { 
          Get.to(QuestionPage(), transition: Transition.rightToLeft);
        },
      ),

      SettingItem(
        icon: "assets/4.0/kissu4_feedback.webp",
        title: "意见反馈",
        onTap: () async { 
          Get.toNamed(KissuRoutePath.feedback);
        },
      ),
      SettingItem(
        icon: "assets/4.0/kissu4_mine_aboutus.webp",
        title: "关于我们",
        onTap: () async { 
          Get.to(AboutUsPage(), transition: Transition.rightToLeft);
        },
      ),
      // SettingItem(
      //   icon: "assets/kissu_mine_item_ysaq.webp",
      //   title: "账号及隐私安全",
      //   onTap: () async {
      //     await TrackingService.trackAccountPrivacySecurity();
      //     Get.to(
      //       PrivacySettingPage(),
      //       transition: Transition.rightToLeft,
      //     );
      //   },
      // ),
    ];
  }

  // /// 屏幕使用测试
  // Future<void> _onScreenUsageTestTap() async {
  //   final permissionService = PermissionService();

  //   // 检查权限
  //   final hasPermission = await permissionService.isUsageAccessGranted();

  //   if (!hasPermission) {
  //     // 显示权限引导
  //     Get.dialog(
  //       AlertDialog(
  //         title: const Text('需要使用统计权限'),
  //         content: const Text(
  //           '屏幕使用时长统计需要"使用情况访问权限"。\n\n'
  //           '点击"去授权"后，请在设置页面找到 Kissu 并开启权限。',
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Get.back(),
  //             child: const Text('取消'),
  //           ),
  //           TextButton(
  //             onPressed: () async {
  //               Get.back();
  //               await permissionService.requestUsageAccessPermission();
  //               // 再次检查权限
  //               final granted = await permissionService.isUsageAccessGranted();
  //               if (granted) {
  //                 _showScreenUsageData();
  //               } else {
  //                 OKToastUtil.show('未授予权限');
  //               }
  //             },
  //             child: const Text('去授权'),
  //           ),
  //         ],
  //       ),
  //     );
  //     return;
  //   }

  //   // 有权限，直接显示数据
  //   _showScreenUsageData();
  // }


  /// 打开联系渠道（企业微信客服）
  Future<void> openContact() async {
    // 企业微信配置信息
    const String corpId = 'ww5c345e5aa1a2a697'; // 企业微信ID (ww开头)
    const String kfId = 'kfcf77b8b4a2a2a61d9'; // 客服 ID

    try {
      logDebug('📞 开始拉起企业微信客服', tag: 'Mine');
      // 直接使用客服ID拉起会话
      await PermissionHelper.openWeComKfWithParams(corpId: corpId, kfId: kfId);
      logDebug('✅ 企业微信客服拉起成功', tag: 'Mine');
    } catch (e) {
      logError('❌ 拉起企业微信客服失败: $e', tag: 'Mine', error: e);
      OKToastUtil.show('拉起企业微信客服失败: $e');
    }
  }

  // 顶部返回
  void onBackTap() {
     
    Get.back();
  }

  // 右上角设置按钮
  void onSettingTap() async {
     
    Get.to(PrivacySettingPage(), transition: Transition.rightToLeft);
  }

  // 点击恋爱信息标签
  void onLabelTap() async {
    

    await Get.to(LoveInfoPage(), transition: Transition.rightToLeft);
    // 从恋爱信息页面返回时，刷新我的页面
    onPageResumed();
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
  void onPartnerAvatarTap() async {
    // 如果未绑定，显示绑定弹窗
    if (!isBound.value) {
    
      if (Get.context != null) {
        CustomBottomDialog.show(
          context: Get.context!,
          caller: BindingDialogCaller.mine,
        );
      }
    } else {
    

      // 如果已绑定，跳转到恋爱信息页面
      await Get.to(LoveInfoPage(), transition: Transition.rightToLeft);
      // 从恋爱信息页面返回时，刷新我的页面
      onPageResumed();
    }
  }

  // 点击自己的头像
  void onAvatarTap() async {
    logDebug('🔥 头像被点击了！', tag: 'Mine');
    logDebug('🔥 当前绑定状态: ${isBound.value}', tag: 'Mine');

    // 如果已绑定，跳转到恋爱信息页面
    if (isBound.value) {
      logDebug('🔥 用户已绑定，跳转到恋爱信息页面', tag: 'Mine');

       

      await Get.to(LoveInfoPage(), transition: Transition.rightToLeft);
      // 从恋爱信息页面返回时，刷新我的页面
      onPageResumed();
    } else {
      logDebug('🔥 用户未绑定，不执行跳转', tag: 'Mine');
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

        // 同时刷新用机记录页面数据（如果绑定状态发生变化）
        _refreshUsageReportPage();

        // 下拉刷新时不显示snackbar，避免界面干扰
        if (!isRefreshing.value) {
          OKToastUtil.show('用户信息已更新');
        }
      } else {
        OKToastUtil.show('刷新用户信息失败');
      }
    } catch (e) {
      logError('刷新用户信息失败: $e', tag: 'Mine', error: e);
      OKToastUtil.show('刷新用户信息失败: $e');
    }
  }

  // 会员续费/开通
  void onRenewTap() async {
    logDebug('💫 VIP按钮被点击', tag: 'Mine');

    // 如果未绑定，弹出绑定弹窗
    if (!isBound.value) {
      logDebug('💫 用户未绑定，弹出绑定弹窗', tag: 'Mine');

      
      if (Get.context != null) {
        CustomBottomDialog.show(
          context: Get.context!,
          caller: BindingDialogCaller.mine,
          isDismissible: false, // 禁用点击背景关闭
          enableDrag: false, // 禁用向下滑动关闭
          onCloseConfirm: () async {
            // 点击关闭按钮时，弹出二次确认弹窗
            return await _showBindingCloseConfirmDialog();
          },
        ).then((_) {
          // 绑定弹窗关闭后，刷新页面数据
          onPageResumed();
        });
      }
      return;
    }

    if (isForeverVip.value) {
      // 永久会员，跳转到权益页面
      logDebug('💫 永久会员，跳转到权益页面', tag: 'Mine');

   
      Get.toNamed(
        KissuRoutePath.foreverVip,
        arguments: {'previousPageName': '我的页面', 'previousPageId': 'my_page'},
      );
    } else {
      // 普通会员或非会员，跳转到VIP页面
      logDebug('💫 普通会员或非会员，跳转到VIP页面', tag: 'Mine');

     
      Get.toNamed(
        KissuRoutePath.vip,
        arguments: {'previousPageName': '我的页面', 'previousPageId': 'my_page'},
      );
    }
  }

  /// 显示绑定弹窗关闭确认弹窗
  /// 返回 true 表示用户选择关闭绑定弹窗，返回 false 表示继续留在绑定弹窗
  Future<bool> _showBindingCloseConfirmDialog() async {
    try {
      final currentContext = Get.context;
      if (currentContext == null) {
        debugPrint('❌ 无法获取Context，跳过显示关闭确认弹窗');
        return true; // 出错时允许关闭
      }

      debugPrint('💬 显示绑定弹窗关闭确认');

      // 使用 BindingCloseConfirmDialog
      final result = await BindingCloseConfirmDialog.show(
        context: currentContext,
        barrierDismissible: true,
        onCancel: () {
          // 点击"再想想"，关闭所有弹窗
          debugPrint('💬 用户点击"再想想"，关闭所有弹窗');
        },
        onConfirm: () {
          // 点击"立即绑定"，只关闭确认弹窗
          debugPrint('💬 用户点击"立即绑定"，保持绑定弹窗显示');
        },
      );

      // result 为 true 表示点击了"再想想"，应该关闭绑定弹窗
      // result 为 false 表示点击了"立即绑定"，不关闭绑定弹窗
      // result 为 null 表示点击了背景或其他方式关闭，默认不关闭绑定弹窗
      return result ?? false;
    } catch (e) {
      debugPrint('❌ 显示绑定弹窗关闭确认时发生错误: $e');
      return true; // 出错时允许关闭
    }
  }


  /// 执行退出登录
  Future<void> performLogout() async {
    Get.back(); // 关闭对话框

    // 清理恋爱信息控制器，防止跨账号复用旧数据
    _clearLoveInfoController();

    try {
      // 🔧 使用登录页导航锁，防止重复跳转导致闪烁
      // 先尝试获取锁并跳转到登录页
      final navigated = LoginNavigationLock.navigateToLoginSafely();
      if (!navigated) {
        // 如果已经有其他线程正在导航，直接返回
        logDebug('⏸️ 正在导航到登录页，跳过重复操作', tag: 'Mine');
        return;
      }
      
      // 然后在后台调用退出登录API（不阻塞UI）
      UserManager.logout().catchError((e) {
        // 退出登录API失败不影响UI，因为已经跳转到登录页了
        logError('退出登录API调用失败: $e', tag: 'Mine');
      });

      OKToastUtil.show('已退出登录');
    } catch (e) {
      OKToastUtil.showError('退出登录失败：$e');
    }
  }

  void _clearLoveInfoController() {
    if (Get.isRegistered<LoveInfoController>()) {
      Get.delete<LoveInfoController>(force: true);
      logDebug('🧹 恋爱信息控制器已清理', tag: 'Mine');
    }
  }

  /// 刷新用机记录页面数据
  void _refreshUsageReportPage() {
    try {
      if (Get.isRegistered<UsageReportController>()) {
        final usageReportController = Get.find<UsageReportController>();
        usageReportController.loadData();
        logDebug('已刷新用机记录页面数据', tag: 'Mine');
      }
    } catch (e) {
      logError('刷新用机记录页面数据失败: $e', tag: 'Mine', error: e);
    }
  }

  /// 分享APP点击事件
  void _onShareAppTap() async {
     
    ShareBottomSheet.showShareApp(Get.context!);
  }

  /// 通知设置点击事件
  void _onNotificationSettingsTap() {
    Get.toNamed(KissuRoutePath.notificationSettings);
  }

  /// 防偷拍检测点击事件
  void _onAntiSpyTap() async {
    
    Get.toNamed(KissuRoutePath.antiSpy);
  }

  /// 联系我们点击事件
  void _onContactTap() async {
    
    openContact();
  }

  /// app使用记录点击事件
  Future<void> _onAppUsageRecordTap() async {
    // 1. 未绑定：先引导绑定
    if (!isBound.value) {
      logDebug('app使用记录：用户未绑定，先弹出绑定弹窗', tag: 'Mine');

    
      if (Get.context != null) {
        await CustomBottomDialog.show(
          context: Get.context!,
          caller: BindingDialogCaller.mine,
          isDismissible: false, // 禁用点击背景关闭
          enableDrag: false, // 禁用向下滑动关闭
          onCloseConfirm: () async {
            // 复用 VIP 逻辑中的二次确认弹窗
            return await _showBindingCloseConfirmDialog();
          },
        );

        // 绑定弹窗关闭后，刷新页面数据（可能已经完成绑定）
        onPageResumed();
      }
      return;
    }

    // 2. 已绑定但非会员：跳转到开通会员页面
    if (!UserManager.isVip) {
      logDebug('app使用记录：已绑定但非会员，跳转到开通会员页面', tag: 'Mine');
      Get.toNamed(
        KissuRoutePath.vip,
        arguments: {
          'previousPageName': '我的-APP使用记录',
          'previousPageId': 'mine_app_usage',
        },
      );
      return;
    }

    // 3. 已绑定且是会员：进入 App 使用记录页面
    logDebug('app使用记录：已绑定且为会员，进入App使用记录页面', tag: 'Mine');
    Get.to(
      () => const AppUsagePage(),
      binding: AppUsageBinding(),
      transition: Transition.rightToLeft,
    );
  }

  /// 个性化首页点击事件
  void _onPersonalizedHomeTap() {
    // 改为简单的 Toast 提示，而不是弹窗
    OKToastUtil.show('敬请期待！');
  }

  /// 敏感操作记录页面
  void _onMinganJiluTap() {
    Get.to(() => const UsageReportPage(), binding: UsageReportBinding());
  }

  /// 更换app图标点击事件
  void _onChangeAppIconTap() {
    Get.toNamed(KissuRoutePath.appIconSelector);
  }

}

class SettingItem {
  final String icon;
  final String title;
  final void Function()? onTap;

  SettingItem({required this.icon, required this.title, this.onTap});
}

class CommonFunctionItem {
  final String icon;
  final String title;
  final void Function()? onTap;

  CommonFunctionItem({required this.icon, required this.title, this.onTap});
}
