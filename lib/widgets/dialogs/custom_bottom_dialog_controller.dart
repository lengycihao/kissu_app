import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'package:kissu_app/network/public/auth_api.dart';
import 'package:kissu_app/pages/mine/mine_controller.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/share_service.dart';
import 'package:kissu_app/services/tencent_im_service.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/utils/source_page_utils.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
import 'package:kissu_app/pages/track/track_controller.dart';
import 'package:kissu_app/pages/location/location_v2_controller.dart';
import 'package:kissu_app/pages/usage_report/usage_report_controller.dart';
import 'package:kissu_app/pages/mine/love_info/love_info_controller.dart';
import 'package:kissu_app/pages/mine/device_usage/device_usage_controller.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/services/analytics/analytics_manager.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';
import 'package:kissu_app/services/analytics/analytics_params.dart';
import 'package:kissu_app/services/analytics/analytics_page_ids.dart';

/// 自定义底部弹窗控制器
class CustomBottomDialogController extends GetxController {
  // 调用者页面类型
  SourcePageUtilsCaller? caller;
  // 来源事件ID（触发绑定弹窗的事件ID）
  String? sourceEvent;
  // 匹配码输入框控制器
  late TextEditingController matchCodeController;

  // 用户匹配码
  var userMatchCode = ''.obs;

  // 用户二维码URL
  var qrCodeUrl = ''.obs;

  // 加载状态
  var isLoading = false.obs;

  // 输入的匹配码（用于响应式更新UI）
  var inputMatchCode = ''.obs;

  // 是否应该关闭弹窗（用于IM绑定消息触发关闭）
  var shouldClose = false.obs;

  // 埋点相关：页面进入时间（十位时间戳）
  int? _pageEnterTime;

  // 埋点相关：离开方式
  int _exitType = ExitTypeValue.back;
  // 是否已记录页面离开
  bool _hasTrackedPageExit = false;

  // 页面离开回调
  VoidCallback? onNavigateToNextPage;

  @override
  void onInit() {
    super.onInit();
    matchCodeController = TextEditingController();

    // 监听输入框变化
    matchCodeController.addListener(() {
      inputMatchCode.value = matchCodeController.text;
      logDebug(
        '输入框内容变化: ${matchCodeController.text}, inputMatchCode: ${inputMatchCode.value}',
        tag: 'BindingDialog',
      );
    });

    // 埋点：记录页面进入时间（十位时间戳）
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 注册页面离开回调
    onNavigateToNextPage = () {
      _trackPageExit(ExitTypeValue.nextPage);
    };

    _loadUserInfo();

    // 监听IM绑定消息，当收到绑定消息时自动关闭弹窗
    _setupBindMessageListener();
  }

  /// 设置绑定消息监听器
  /// 当收到IM绑定消息时，自动关闭绑定弹窗
  void _setupBindMessageListener() {
    try {
      if (Get.isRegistered<TencentIMService>()) {
        final imService = TencentIMService.instance;
        imService.setOnBindMessageReceived(() {
          logDebug('💬 收到IM绑定消息，准备自动关闭绑定弹窗', tag: 'BindingDialog');
          // 设置标志，通知弹窗关闭
          shouldClose.value = true;
          logDebug('✅ 已设置弹窗关闭标志', tag: 'BindingDialog');
        });
        logDebug('✅ 已设置IM绑定消息监听器', tag: 'BindingDialog');
      }
    } catch (e) {
      logError('❌ 设置IM绑定消息监听器失败: $e', tag: 'BindingDialog', error: e);
    }
  }

  @override
  void onClose() {
    // 埋点：记录页面离开事件
    _trackPageView();

    // 清除IM绑定消息监听器
    _removeBindMessageListener();

    matchCodeController.dispose();
    super.onClose();
  }

  /// 移除绑定消息监听器
  void _removeBindMessageListener() {
    try {
      if (Get.isRegistered<TencentIMService>()) {
        final imService = TencentIMService.instance;
        // 将回调设置为null，表示不再监听
        imService.onBindMessageReceived.value = null;
        logDebug('✅ 已移除IM绑定消息监听器', tag: 'BindingDialog');
      }
    } catch (e) {
      logError('❌ 移除IM绑定消息监听器失败: $e', tag: 'BindingDialog', error: e);
    }
  }

  /// 获取上一个页面信息（基于调用者类型）
  // Map<String, String> _getPreviousPageInfo() {
  //   if (caller == null) {
  //     return {'name': '未知页面', 'id': 'unknown'};
  //   }

  //   switch (caller!) {
  //     case BindingDialogCaller.home:
  //       return {'name': '首页', 'id': 'home'};
  //     case BindingDialogCaller.mine:
  //       return {'name': '我的页面', 'id': 'mine'};
  //     case BindingDialogCaller.loveInfo:
  //       return {'name': '恋爱信息页面', 'id': 'love_info'};
  //     case BindingDialogCaller.track:
  //       return {'name': '足迹页面', 'id': 'track'};
  //     case BindingDialogCaller.location:
  //       return {'name': '定位页面', 'id': 'location'};
  //     case BindingDialogCaller.usageReport:
  //       return {'name': '用机记录页面', 'id': 'usage_report'};
  //     case BindingDialogCaller.deviceUsage:
  //       return {'name': '用机记录页面', 'id': 'device_usage'};
  //   }
  // }

  /// 加载用户信息
  void _loadUserInfo() {
    // 使用 UserManager 统一获取用户信息
    userMatchCode.value = UserManager.friendCodeOrDefault;

    final user = UserManager.currentUser;
    // 设置二维码
    if (user?.friendQrCode?.isNotEmpty == true) {
      qrCodeUrl.value = user!.friendQrCode!;
    }

    logDebug('弹窗用户信息加载完成:', tag: 'BindingDialog');
    logDebug('匹配码: ${userMatchCode.value}', tag: 'BindingDialog');
    logDebug('二维码: ${qrCodeUrl.value}', tag: 'BindingDialog');
  }

  /// 绑定另一半
  Future<void> bindPartner({required int bindType}) async {
    final inputCode = matchCodeController.text.trim();
    if (inputCode.isEmpty) {
      OKToastUtil.show('请输入匹配码');
      return;
    }

    if (inputCode == userMatchCode.value) {
      OKToastUtil.show('不能绑定自己');
      return;
    }

    try {
      isLoading.value = true;

      // 调用绑定API
      final authApi = AuthApi();
      final result = await authApi.bindPartner(friendCode: inputCode);

      if (result.isSuccess) {
        // 埋点：确认绑定事件
        trackBindSure(
          success: result.isSuccess,
          bindType: bindType,
          friendCode: inputCode,
          errorMsg: '绑定成功',
        );
        // 关闭弹窗
        Get.back();
        logDebug('绑定成功，关闭弹窗', tag: 'BindingDialog');

        // 刷新用户信息（确保本地缓存是最新的）
        await _refreshUserInfo();

        // 刷新当前页面数据（等待完成）
        await _refreshCurrentPageData();

        // 注意：绑定成功后的动画播放和VIP页面跳转由 TencentIMService._handleBindMessage 统一处理
        // TencentIMService 会在收到 bindAndroid 消息后：
        // 1. 刷新用户信息
        // 2. 刷新当前页面
        // 3. 播放绑定动画
        // 4. 动画完成后根据VIP状态决定是否跳转到VIP页面
        //
        // 这里不再播放动画，避免与 TencentIMService 产生竞态条件
        logDebug(
          '✅ BindingDialog处理完成，动画和VIP跳转由TencentIMService处理',
          tag: 'BindingDialog',
        );
      } else {
        trackBindSure(
          success: false,
          bindType: bindType,
          friendCode: inputCode,
          errorMsg: result.msg ?? '绑定失败',
        );
        logError(result.msg ?? '绑定失败', tag: 'BindingDialog');
        OKToastUtil.show(result.msg ?? '绑定失败');
      }
    } catch (e) {
      trackBindSure(
        success: false,
        bindType: bindType,
        friendCode: inputCode,
        errorMsg: '绑定失败: $e',
      );
      logError('绑定失败: $e', tag: 'BindingDialog', error: e);
      OKToastUtil.show('绑定失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新用户信息
  Future<void> _refreshUserInfo() async {
    try {
      final authApi = AuthApi();
      final result = await authApi.getUserInfo();
      if (result.isSuccess && result.data != null) {
        await UserManager.updateUserInfo(result.data!);
        logDebug('用户信息刷新成功', tag: 'BindingDialog');
      }
    } catch (e) {
      logError('刷新用户信息失败: $e', tag: 'BindingDialog', error: e);
    }
  }

  /// 刷新当前页面数据（根据调用者只刷新对应页面）
  Future<void> _refreshCurrentPageData() async {
    try {
      logDebug('开始刷新当前页面数据，调用者: $caller', tag: 'BindingDialog');

      if (caller == null) {
        logWarning('❌ 调用者未指定，跳过页面数据刷新', tag: 'BindingDialog');
        return;
      }

      // 根据调用者类型刷新对应的控制器
      switch (caller!) {
        case SourcePageUtilsCaller.home:
          if (Get.isRegistered<HomeController>()) {
            try {
              final homeController = Get.find<HomeController>();
              await homeController.refreshUserInfoFromServer();
              logDebug('✅ 首页数据刷新完成', tag: 'BindingDialog');
            } catch (e) {
              logError('❌ 刷新首页控制器失败: $e', tag: 'BindingDialog', error: e);
            }
          }
          break;

        case SourcePageUtilsCaller.mine:
          if (Get.isRegistered<MineController>()) {
            try {
              final mineController = Get.find<MineController>();
              mineController.loadUserInfo();
              logDebug('✅ 我的页面数据刷新完成', tag: 'BindingDialog');
            } catch (e) {
              logError('❌ 刷新我的页面控制器失败: $e', tag: 'BindingDialog', error: e);
            }
          }
          break;

        case SourcePageUtilsCaller.loveInfo:
          if (Get.isRegistered<LoveInfoController>()) {
            try {
              final loveInfoController = Get.find<LoveInfoController>();
              // 🔥 修复：从服务器刷新用户信息，而不是只读取本地缓存
              await loveInfoController.refreshFromServer();
              logDebug('✅ 恋爱信息页数据刷新完成', tag: 'BindingDialog');
            } catch (e) {
              logError('❌ 刷新恋爱信息页控制器失败: $e', tag: 'BindingDialog', error: e);
            }
          }
          break;

        case SourcePageUtilsCaller.track:
          if (Get.isRegistered<TrackController>()) {
            try {
              final trackController = Get.find<TrackController>();
              trackController.refreshCurrentUserData();
              logDebug('✅ 足迹页数据刷新完成', tag: 'BindingDialog');
            } catch (e) {
              logError('❌ 刷新足迹页控制器失败: $e', tag: 'BindingDialog', error: e);
            }
          }
          break;

        case SourcePageUtilsCaller.location:
          if (Get.isRegistered<LocationV2Controller>()) {
            try {
              final locationController = Get.find<LocationV2Controller>();
              locationController.refreshUserInfo();
              logDebug('✅ 定位页数据刷新完成', tag: 'BindingDialog');
            } catch (e) {
              logError('❌ 刷新定位页控制器失败: $e', tag: 'BindingDialog', error: e);
            }
          }
          break;

        case SourcePageUtilsCaller.usageReport:
          if (Get.isRegistered<UsageReportController>()) {
            try {
              final usageReportController = Get.find<UsageReportController>();
              await usageReportController.loadData();
              logDebug('✅ 用机记录页数据刷新完成', tag: 'BindingDialog');
            } catch (e) {
              logError('❌ 刷新用机记录页控制器失败: $e', tag: 'BindingDialog', error: e);
            }
          }
          break;

        case SourcePageUtilsCaller.deviceUsage:
          if (Get.isRegistered<DeviceUsageController>()) {
            try {
              final deviceUsageController = Get.find<DeviceUsageController>();
              // 刷新状态并重新加载数据
              deviceUsageController.updateBindStatus();
              logDebug('✅ 用机记录页（新）数据刷新完成', tag: 'BindingDialog');
            } catch (e) {
              logError('❌ 刷新用机记录页（新）控制器失败: $e', tag: 'BindingDialog', error: e);
            }
          }
          break;
        case SourcePageUtilsCaller.chat:
          // 聊天页面不需要刷新数据
          break;
        case SourcePageUtilsCaller.bind:
          break;
        case SourcePageUtilsCaller.changeLogo:
          // 更换Logo页面不需要刷新数据
          break;
        case SourcePageUtilsCaller.unbindPage:
          // 更换Logo页面不需要刷新数据
          break;
      }

      logDebug('✅ 当前页面数据刷新完成', tag: 'BindingDialog');
    } catch (e) {
      logError('❌ 刷新当前页面数据失败: $e', tag: 'BindingDialog', error: e);
    }
  }

  /// 复制匹配码
  void copyMatchCode() {
    Clipboard.setData(ClipboardData(text: userMatchCode.value));
    OKToastUtil.show('复制成功');
  }

  /// 分享到QQ
  void shareToQQ() {
    Get.back(); // 关闭弹窗
    _shareInvite(target: 'QQ');
  }

  /// 分享到微信
  void shareToWechat() {
    Get.back(); // 关闭弹窗
    _shareInvite(target: '微信');
  }

  /// 扫描二维码
  void scanQRCode() {
    // 埋点：页面离开（进入下一页）
    _trackPageExit(ExitTypeValue.nextPage);

    Get.toNamed(KissuRoutePath.qrScanPage)?.then((value) {
      if (value is String && value.isNotEmpty) {
        // 根据扫码结果做处理
        final scanned = value.trim();
        final friendCode = _extractFriendCode(scanned);
        if (friendCode != null) {
          // 扫描成功，直接开始绑定流程
          matchCodeController.text = friendCode;
          // 自动执行绑定
          bindPartner(bindType: BindTypeValue.scan);
        } else {
          OKToastUtil.show('未识别到匹配码');
        }
      }
    });
  }

  /// 查看二维码
  void viewQRCode() {
    if (qrCodeUrl.value.isNotEmpty) {
      // 显示二维码对话框
      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '仅适用于对方使用Kissu进行扫码',
                      style: TextStyle(fontSize: 16, color: Color(0xffFF0A6C)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 262,
                      height: 262,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: NetworkImageHelper.loadImage(
                          imageUrl: qrCodeUrl.value,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Get.back();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image(
                    image: AssetImage("assets/3.0/kissu3_dialog_close.webp"),
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      logError('二维码未生成', tag: 'BindingDialog');
      OKToastUtil.show('二维码未生成');
    }
  }

  String? _extractFriendCode(String input) {
    // 纯数字认为是匹配码
    final numeric = RegExp(r'^\d{4,}$');
    if (numeric.hasMatch(input)) return input;

    // invite:// 格式，如 invite://1000060
    final inviteMatch = RegExp(r'^invite://(\d{4,})$').firstMatch(input);
    if (inviteMatch != null) {
      return inviteMatch.group(1);
    }

    // URL 中形如 friendCode=123456 或 code=123456
    final paramMatch = RegExp(
      r'(?:(?:friendCode|code)=)(\d{4,})',
    ).firstMatch(input);
    if (paramMatch != null) {
      return paramMatch.group(1);
    }

    return null;
  }

  /// 统一分享逻辑（重构后使用ShareService的高级封装）
  Future<void> _shareInvite({required String target}) async {
    try {
      final shareService = Get.find<ShareService>();

      if (target == '微信') {
        // 微信分享 - 使用统一的高级封装方法
        try {
          await shareService.shareToWeChatWithConfig(
            bindCode: userMatchCode.value,
          );
          OKToastUtil.show('已调起微信分享');
        } catch (e) {
          logError('微信分享异常: $e', tag: 'BindingDialog', error: e);
          OKToastUtil.show('微信分享异常: $e');
        }
      } else if (target == 'QQ') {
        // QQ分享 - 使用统一的高级封装方法
        try {
          // 调用新的统一方法，自动处理安装检查、配置获取等
          final shareResult = await shareService.shareToQQWithConfig(
            bindCode: userMatchCode.value,
          );

          logDebug('QQ分享结果: $shareResult', tag: 'BindingDialog');

          if (shareResult['success'] == true) {
            // OKToastUtil.show('QQ分享成功');
          } else {
            final errorMsg = shareResult['message'] ?? '分享失败';
            OKToastUtil.show('QQ分享失败: $errorMsg');
          }
        } catch (e) {
          logError('QQ分享异常: $e', tag: 'BindingDialog', error: e);
          OKToastUtil.show('QQ分享异常: $e');
        }
      }
    } catch (e) {
      logError('分享异常: $e', tag: 'BindingDialog', error: e);
      OKToastUtil.show('分享异常: $e');
    }
  }

  /// 系统分享备用方案
  // Future<void> _systemShare(String text) async {
  //   try {
  //     // 使用剪贴板作为备用
  //     await Clipboard.setData(ClipboardData(text: text));
  //     OKToastUtil.show('分享文本已复制到剪贴板，可以粘贴到QQ发送给好友');
  //   } catch (e) {
  //     print('复制到剪贴板失败: $e');
  //     OKToastUtil.show('复制失败，请手动复制匹配码：${userMatchCode.value}');
  //   }
  // }

  // ==================== 埋点方法 ====================

  /// 根据 caller 获取来源页面ID
  String? _getSourcePageFromCaller() {
    if (caller == null) return PageSourceIds.home;

    switch (caller!) {
      case SourcePageUtilsCaller.home:
        return PageSourceIds.home;
      case SourcePageUtilsCaller.mine:
        return PageSourceIds.myPage;
      case SourcePageUtilsCaller.loveInfo:
        return PageSourceIds.editProfile; // 恋爱信息页面归类到编辑资料
      case SourcePageUtilsCaller.track:
        return PageSourceIds.track;
      case SourcePageUtilsCaller.location:
        return PageSourceIds.location;
      case SourcePageUtilsCaller.usageReport:
        return PageSourceIds.sensitiveRecords; // 用机记录（敏感操作）
      case SourcePageUtilsCaller.deviceUsage:
        return PageSourceIds.phoneHistory; // 用机记录页面
      case SourcePageUtilsCaller.chat:
        return PageSourceIds.chat; // 聊天页面
      case SourcePageUtilsCaller.bind:
        return PageSourceIds.bind; // 绑定页面
      case SourcePageUtilsCaller.changeLogo:
        return PageSourceIds.changeLogo; // 更换Logo页面
      case SourcePageUtilsCaller.unbindPage:
        return PageSourceIds.unbindPage; // 更换Logo页面
    }
  }

  /// 设置离开方式
  void setExitType(int exitType) {
    _exitType = exitType;
  }

  /// 记录页面浏览埋点
  void _trackPageView() {
    _trackPageExit(_exitType);
  }

  /// 上报页面离开埋点
  void _trackPageExit(int exitType) {
    if (_pageEnterTime == null || _hasTrackedPageExit) return;
    _hasTrackedPageExit = true;

    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final duration = currentTime - _pageEnterTime!;

    AnalyticsManager.instance.trackPageView(
      pageId: BindEvents.pageId,
      eventId: BindEvents.page,
      enterTime: _pageEnterTime!,
      duration: duration,
      sourcePage: _getSourcePageFromCaller(),
      sourceEvent: sourceEvent,
      exitType: exitType,
    );

    if (exitType == ExitTypeValue.nextPage) {
      _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _hasTrackedPageExit = false;
      _exitType = ExitTypeValue.back;
    }
  }

  void onAppPaused() {
    _exitType = ExitTypeValue.toBackground;
    _trackPageExit(ExitTypeValue.toBackground);
  }

  void onAppResumed() {
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _hasTrackedPageExit = false;
    _exitType = ExitTypeValue.back;
  }

  /// 记录输入匹配码事件
  void trackBindInput() {
    AnalyticsHelper.trackBindInput();
  }

  /// 记录确认绑定事件
  void trackBindSure({
    required bool success,
    required int bindType,
    required String friendCode,
    required String errorMsg,
  }) {
    AnalyticsHelper.trackBindSure(
      success: success,
      bindType: bindType,
      friendCode: friendCode,
      errorMsg: errorMsg,
    );
  }

  /// 记录取消绑定事件
  void trackBindCancel() {
    AnalyticsHelper.trackBindCancel();
  }
}
