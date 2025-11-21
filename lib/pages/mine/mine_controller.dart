import 'package:get/get.dart';
import 'package:kissu_app/pages/mine/app_usage/app_usage_debug_page.dart';
import 'package:kissu_app/pages/mine/app_usage/app_usage_test_page.dart';
import 'package:kissu_app/pages/mine/love_info/love_info_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/privacy_setting_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/question_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/setting_about_us_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/setting_homeview_page.dart';
// import 'package:kissu_app/pages/mine/sub_pages/system_permission_page.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/utils/oaid_util.dart';
import 'package:flutter/material.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import '../usage_report/usage_report_controller.dart';
import 'package:kissu_app/utils/permission_helper.dart';
import 'package:kissu_app/utils/vip_navigation_helper.dart';
import 'package:kissu_app/widgets/share_bottom_sheet.dart';
import 'package:kissu_app/pages/track/track_page.dart';
import 'package:kissu_app/pages/track/track_binding.dart';
import 'package:kissu_app/pages/usage_report/usage_report_page.dart';
import 'package:kissu_app/pages/usage_report/usage_report_binding.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog_controller.dart';
import 'package:kissu_app/widgets/dialogs/binding_close_confirm_dialog.dart';
import 'package:kissu_app/services/screen_usage_service.dart';
import 'package:kissu_app/services/tracking_service.dart';
import 'package:kissu_app/pages/debug/screen_lock_debug_page.dart';
import 'package:kissu_app/pages/mine/app_usage/app_usage_page.dart';
import 'package:kissu_app/pages/mine/app_usage/app_usage_binding.dart';
import 'package:kissu_app/services/permission_service.dart';

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

  // 页面浏览时长统计
  DateTime? _pageEnterTime;

  // 滑动相关
  late ScrollController scrollController;
  var scrollTimes = 0.obs; // 滑动次数
  var hasScrolled = false.obs; // 是否滑动过

  // 权限状态
  var areAllPermissionsGranted = false.obs; // 4个权限是否全部开启
  final PermissionService _permissionService = PermissionService();

  @override
  void onInit() {
    super.onInit();
    _initSettingItems();
    _initCommonFunctionItems();

    // 初始化滚动控制器
    scrollController = ScrollController();

    // 记录页面进入时间（用于计算停留时长）
    _pageEnterTime = DateTime.now();

    // 先加载本地用户信息（立即显示）
    loadUserInfo();
    // 然后静默刷新用户信息
    _silentRefreshUserInfo();
    // 检查权限状态
    checkAllPermissions();
  }

  @override
  void onReady() {
    super.onReady();
    // 页面准备就绪时，确保已经静默刷新
  }

  @override
  void onClose() {
    // 上报页面浏览埋点
    _trackPageView();

    // 释放滚动控制器
    scrollController.dispose();

    super.onClose();
  }

  /// 处理滑动事件
  void handleScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      // 只要发生滚动，标记为已滑动
      if (!hasScrolled.value) {
        hasScrolled.value = true;
      }

      // 滑动距离超过 10 像素时，计数一次
      if (notification.scrollDelta!.abs() > 10) {
        scrollTimes.value++;
        debugPrint('📊 我的页面：滑动次数 = ${scrollTimes.value}');
      }
    }
  }

  /// 上报页面浏览埋点
  Future<void> _trackPageView() async {
    if (_pageEnterTime == null) return;

    try {
      // 计算停留时长
      final duration = DateTime.now().difference(_pageEnterTime!);
      final seconds = duration.inSeconds;
      final stayDuration = '${seconds}s';

      // 上报埋点
      await TrackingService.trackMyPageView(
        stayDuration: stayDuration,
        canScroll: hasScrolled.value,
        scrollTimes: scrollTimes.value,
      );

      debugPrint(
        '✅ 我的页面浏览埋点上报成功: 停留时长=$stayDuration, 是否滑动=${hasScrolled.value}, 滑动次数=${scrollTimes.value}',
      );
    } catch (e) {
      debugPrint('❌ 我的页面浏览埋点上报失败: $e');
    }
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
      final permissions = await _permissionService.checkAllPermissions();

      // 检查4个关键权限是否全部开启
      final isLocationGranted = permissions[PermissionType.location] ?? false;
      final isNotificationGranted =
          permissions[PermissionType.notification] ?? false;
      final isBatteryOptimized = permissions[PermissionType.battery] ?? false;
      final isUsageAccessGranted = permissions[PermissionType.usage] ?? false;

      // 只有当4个权限都开启时，才设置为true
      areAllPermissionsGranted.value =
          isLocationGranted &&
          isNotificationGranted &&
          isBatteryOptimized &&
          isUsageAccessGranted;

      logDebug(
        '权限状态检查完成: 位置=$isLocationGranted, 通知=$isNotificationGranted, 电池=$isBatteryOptimized, 使用情况=$isUsageAccessGranted',
        tag: 'Mine',
      );
      logDebug('所有权限是否全部开启: ${areAllPermissionsGranted.value}', tag: 'Mine');
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
        icon: "assets/4.0/kissu4_mine_change_homeview.webp",
        title: "更换首页视图",
        onTap: () => _onChangeHomeViewTap(),
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
      // SettingItem(
      //   icon: "assets/3.0/kissu3_mine_ftp_icon.webp",
      //   title: "防偷拍检测",
      //   onTap: () => _onAntiSpyTap(),
      // ),
      // SettingItem(
      //   icon: "assets/kissu_mine_item_gywm.webp",
      //   title: "Banner预览",
      //   onTap: () => _onBannerPreviewTap(),
      // ),
      SettingItem(
        icon: "assets/4.0/kissu4_share.webp",
        title: "分享APP",
        onTap: () => _onShareAppTap(),
      ),
      // SettingItem(
      //   icon: "assets/images/kissu_home_tab_history.webp", // 使用系统权限图标作为弹窗展示图标
      //   title: "弹窗展示",
      //   onTap: () => Get.to(() => const DialogShowcasePage()),
      // ),

      // SettingItem(
      //   icon: "assets/images/kissu_home_tab_history.webp",
      //   title: "🔧 锁屏监听调试",
      //   onTap: () => _onScreenLockDebugTap(),
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
      // SettingItem(
      //   icon: "assets/4.0/kissu4_notice.webp",
      //   title: "测试 OAID",
      //   onTap: () async {
      //     await _testOaid();
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
          await TrackingService.trackFaq();
          Get.to(QuestionPage(), transition: Transition.rightToLeft);
        },
      ),

      SettingItem(
        icon: "assets/4.0/kissu4_feedback.webp",
        title: "意见反馈",
        onTap: () async {
          await TrackingService.trackFeedback();
          Get.toNamed(KissuRoutePath.feedback);
        },
      ),
      SettingItem(
        icon: "assets/4.0/kissu4_mine_aboutus.webp",
        title: "关于我们",
        onTap: () async {
          await TrackingService.trackAboutUs();
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

  /// 打开 Banner 预览页面
  void _onBannerPreviewTap() {
    // Get.to(() => const BannerPreviewPage());
    // 测试页面已移除
  }

  /// 打开锁屏监听调试页面
  void _onScreenLockDebugTap() {
    Get.to(
      () => const ScreenLockDebugPage(),
      transition: Transition.rightToLeft,
    );
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

  /// 显示屏幕使用数据
  Future<void> _showScreenUsageData() async {
    final screenUsageService = ScreenUsageService();

    // 显示加载中
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // 获取今日屏幕使用时长
      final todayMs = await screenUsageService.getTodayScreenTime();
      final todayMinutes = (todayMs / (1000 * 60)).round();
      final todayHours = todayMinutes ~/ 60;
      final todayMins = todayMinutes % 60;

      // 获取今日应用使用详情（前5个）
      final appStats = await screenUsageService.getTodayAppUsageStats(limit: 5);

      // 获取今日解锁次数
      final unlockCount = await screenUsageService.getTodayUnlockCount();

      // 关闭加载
      Get.back();

      // 构建应用列表文本
      String appListText = '';
      if (appStats.isNotEmpty) {
        for (var i = 0; i < appStats.length; i++) {
          final stat = appStats[i];
          final appName = stat.appName; // 使用真实的应用名称
          final minutes = (stat.totalTimeInForeground / (1000 * 60)).round();
          appListText += '\n${i + 1}. $appName: ${minutes}分钟';
        }
      } else {
        appListText = '\n暂无应用使用数据';
      }

      // 显示结果
      Get.dialog(
        AlertDialog(
          title: const Text('📊 屏幕使用统计'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '今日总使用时长：',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${todayHours}小时${todayMins}分钟',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Color(0xFFFF839E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '今日解锁次数：$unlockCount 次',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  '应用使用排行 TOP 5：',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(appListText, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('关闭')),
            TextButton(
              onPressed: () {
                Get.back();
                Get.to(
                  () => const UsageReportPage(),
                  binding: UsageReportBinding(),
                  transition: Transition.rightToLeft,
                );
              },
              child: const Text('查看详情'),
            ),
          ],
        ),
      );
    } catch (e) {
      // 关闭加载
      Get.back();

      // 显示错误
      Get.dialog(
        AlertDialog(
          title: const Text('错误'),
          content: Text('获取屏幕使用数据失败：\n$e'),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('确定')),
          ],
        ),
      );
    }
  }

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
    // 上报返回按钮点击埋点
    TrackingService.trackMyLeaveEvent();
    Get.back();
  }

  // 右上角设置按钮
  void onSettingTap() async {
    // 上报账号及隐私安全点击埋点
    await TrackingService.trackAccountPrivacySecurity();
    Get.to(PrivacySettingPage(), transition: Transition.rightToLeft);
  }

  // 点击恋爱信息标签
  void onLabelTap() async {
    // 上报恋爱信息入口点击埋点
    await TrackingService.trackEditInfoPage();

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
      // 上报绑定页面点击埋点
      await TrackingService.trackMyBindPage();

      if (Get.context != null) {
        CustomBottomDialog.show(
          context: Get.context!,
          caller: BindingDialogCaller.mine,
        );
      }
    } else {
      // 上报恋爱信息入口点击埋点
      await TrackingService.trackEditInfoPage();

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

      // 上报恋爱信息入口点击埋点
      await TrackingService.trackEditInfoPage();

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

      // 上报绑定页面点击埋点
      await TrackingService.trackMyBindPage();

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

      // 上报开通会员点击埋点（终身会员页面）
      await TrackingService.trackMyOpenMembership(vipPageType: '终身会员页面');

      Get.toNamed(
        KissuRoutePath.foreverVip,
        arguments: {'previousPageName': '我的页面', 'previousPageId': 'my_page'},
      );
    } else {
      // 普通会员或非会员，跳转到VIP页面
      logDebug('💫 普通会员或非会员，跳转到VIP页面', tag: 'Mine');

      // 上报开通会员点击埋点（会员页面）
      await TrackingService.trackMyOpenMembership(vipPageType: '会员页面');

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
      // 🔧 修复：直接调用 UserManager.logout()，内部会处理API调用
      // 避免重复调用退出登录API导致两次跳转到登录页
      await UserManager.logout();

      // 跳转到登录页面
      Get.offAllNamed('/login');

      OKToastUtil.show('已退出登录');
    } catch (e) {
      OKToastUtil.showError('退出登录失败：$e');
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
    // 上报分享App点击埋点
    await TrackingService.trackMyShare();
    ShareBottomSheet.showShareApp(Get.context!);
  }

  /// 防偷拍检测点击事件
  void _onAntiSpyTap() async {
    // 上报防偷拍检查点击埋点
    await TrackingService.trackSafeCheck();
    Get.toNamed(KissuRoutePath.antiSpy);
  }

  /// 联系我们点击事件
  void _onContactTap() async {
    // 上报联系我们点击埋点
    await TrackingService.trackContactCustomerService();
    openContact();
  }

  /// app使用记录点击事件
  void _onAppUsageRecordTap() {
    Get.to(
      () => const AppUsagePage(),
      binding: AppUsageBinding(),
      transition: Transition.rightToLeft,
    );
  }

  /// 个性化首页点击事件
  void _onPersonalizedHomeTap() {
    // // TODO: 实现个性化首页功能
    // OKToastUtil.show('个性化首页功能开发中');

    // 调试：跳转到 App 使用记录测试页面
    // 需要先注入 AppUsageController，否则页面中 Get.find<AppUsageController>() 会报错
    Get.to(
      () => const AppUsageDebugPage(),
      binding: AppUsageBinding(),
      transition: Transition.rightToLeft,
    );
  }

  /// 更换首页视图点击事件
  void _onChangeHomeViewTap() async {
    await TrackingService.trackHomeView();
    Get.to(SettingHomePage(), transition: Transition.rightToLeft);
  }

  /// 更换app图标点击事件
  void _onChangeAppIconTap() {
    Get.toNamed(KissuRoutePath.appIconSelector);
  }

  /// 测试 OAID 获取
  Future<void> _testOaid() async {
    try {
      OKToastUtil.show('正在获取 OAID...');

      final oaid = await OaidUtil.instance.getOaid();

      if (oaid != null && oaid.isNotEmpty) {
        logger.info('OAID 获取成功: $oaid');
        Get.dialog(
          AlertDialog(
            title: const Text('OAID 获取成功'),
            content: SelectableText('OAID: $oaid'),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('确定')),
            ],
          ),
        );
      } else {
        OKToastUtil.show('OAID 获取失败');
      }
    } catch (e) {
      logger.error('OAID 获取异常: $e');
      OKToastUtil.show('OAID 获取异常: $e');
    }
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
