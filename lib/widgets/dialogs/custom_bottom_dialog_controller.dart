import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'package:kissu_app/network/public/auth_api.dart';
import 'package:kissu_app/pages/mine/mine_controller.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/share_service.dart'; 
import 'package:kissu_app/services/relationship_animation_service.dart';
import 'package:kissu_app/services/tencent_im_service.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
import 'package:kissu_app/pages/track/track_controller.dart';
import 'package:kissu_app/pages/location/location_v2_controller.dart';
import 'package:kissu_app/pages/usage_report/usage_report_controller.dart';
import 'package:kissu_app/pages/mine/love_info/love_info_controller.dart';
import 'package:kissu_app/pages/mine/device_usage/device_usage_controller.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

/// 调用绑定弹窗的页面类型
enum BindingDialogCaller {
  home,        // 首页
  mine,        // 我的页面
  loveInfo,    // 恋爱信息页面
  track,       // 足迹页面
  location,    // 定位页面
  usageReport, // 用机记录页面（敏感操作记录）
  deviceUsage, // 用机记录页面（新的用机记录页面）
}

/// 自定义底部弹窗控制器
class CustomBottomDialogController extends GetxController {
  // 调用者页面类型
  BindingDialogCaller? caller;
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
  Map<String, String> _getPreviousPageInfo() {
    if (caller == null) {
      return {'name': '未知页面', 'id': 'unknown'};
    }
    
    switch (caller!) {
      case BindingDialogCaller.home:
        return {'name': '首页', 'id': 'home'};
      case BindingDialogCaller.mine:
        return {'name': '我的页面', 'id': 'mine'};
      case BindingDialogCaller.loveInfo:
        return {'name': '恋爱信息页面', 'id': 'love_info'};
      case BindingDialogCaller.track:
        return {'name': '足迹页面', 'id': 'track'};
      case BindingDialogCaller.location:
        return {'name': '定位页面', 'id': 'location'};
      case BindingDialogCaller.usageReport:
        return {'name': '用机记录页面', 'id': 'usage_report'};
      case BindingDialogCaller.deviceUsage:
        return {'name': '用机记录页面', 'id': 'device_usage'};
    }
  }

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
  Future<void> bindPartner() async {
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
        // 刷新用户信息
        await _refreshUserInfo();

        // 关闭弹窗
        Get.back();
        logDebug('绑定成功，关闭弹窗', tag: 'BindingDialog');

        // 刷新当前页面数据
        _refreshCurrentPageData();

        // 播放绑定成功动画，动画完成后跳转到VIP页面
        try {
          final animationService = RelationshipAnimationService.instance;
          animationService.showBindAnimation(onComplete: () {
            logDebug('🎯 绑定动画播放完成，准备跳转到VIP页面', tag: 'BindingDialog');
            Get.toNamed(
              KissuRoutePath.vip,
              arguments: {
                'previousPageName': '绑定弹窗',
                'previousPageId': 'binding_dialog',
              },
            );
          });
        } catch (e) {
          logError('❌ 播放绑定动画失败: $e', tag: 'BindingDialog', error: e);
          // 如果动画服务失败，直接跳转到VIP页面
          Get.toNamed(
            KissuRoutePath.vip,
            arguments: {
              'previousPageName': '绑定弹窗',
              'previousPageId': 'binding_dialog',
            },
          );
        }
      } else {
        OKToastUtil.show(result.msg ?? '绑定失败');
      }
    } catch (e) {
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
        case BindingDialogCaller.home:
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

        case BindingDialogCaller.mine:
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

        case BindingDialogCaller.loveInfo:
          if (Get.isRegistered<LoveInfoController>()) {
            try {
              final loveInfoController = Get.find<LoveInfoController>();
              // 延迟一下，确保UserManager的数据已经更新
              await Future.delayed(const Duration(milliseconds: 100));
              loveInfoController.refreshUserInfo();
              logDebug('✅ 恋爱信息页数据刷新完成', tag: 'BindingDialog');
            } catch (e) {
              logError('❌ 刷新恋爱信息页控制器失败: $e', tag: 'BindingDialog', error: e);
            }
          }
          break;

        case BindingDialogCaller.track:
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

        case BindingDialogCaller.location:
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

        case BindingDialogCaller.usageReport:
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

        case BindingDialogCaller.deviceUsage:
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
     
    
    Get.toNamed(KissuRoutePath.qrScanPage)?.then((value) {
      if (value is String && value.isNotEmpty) {
        // 根据扫码结果做处理
        final scanned = value.trim();
        final friendCode = _extractFriendCode(scanned);
        if (friendCode != null) {
          // 扫描成功，直接开始绑定流程
          matchCodeController.text = friendCode;
          // 自动执行绑定
          bindPartner();
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
            OKToastUtil.show('QQ分享成功');
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
}
