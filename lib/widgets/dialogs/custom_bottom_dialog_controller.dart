import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/public/auth_api.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/share_service.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
import 'package:kissu_app/pages/mine/mine_controller.dart';
import 'package:kissu_app/pages/track/track_controller.dart';
import 'package:kissu_app/pages/location/location_controller.dart';
import 'package:kissu_app/pages/phone_history/phone_history_controller.dart';

/// 自定义底部弹窗控制器
class CustomBottomDialogController extends GetxController {
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

  @override
  void onInit() {
    super.onInit();
    matchCodeController = TextEditingController();

    // 监听输入框变化
    matchCodeController.addListener(() {
      inputMatchCode.value = matchCodeController.text;
      print(
        '输入框内容变化: ${matchCodeController.text}, inputMatchCode: ${inputMatchCode.value}',
      );
    });

    _loadUserInfo();
  }

  @override
  void onClose() {
    matchCodeController.dispose();
    super.onClose();
  }

  /// 加载用户信息
  void _loadUserInfo() {
    final user = UserManager.currentUser;
    if (user != null) {
      // 设置用户匹配码
      userMatchCode.value = user.friendCode ?? '1000000';

      // 设置二维码
      if (user.friendQrCode?.isNotEmpty == true) {
        qrCodeUrl.value = user.friendQrCode!;
      }

      print('弹窗用户信息加载完成:');
      print('匹配码: ${userMatchCode.value}');
      print('二维码: ${qrCodeUrl.value}');
    } else {
      print('用户信息为空，使用默认值');
      userMatchCode.value = '1000000';
    }
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
        OKToastUtil.show('绑定成功');

        // 刷新用户信息
        await _refreshUserInfo();

        // 关闭弹窗
        Get.back();
        print('绑定成功，关闭弹窗');

        // 延迟刷新当前页面数据
        Future.delayed(const Duration(milliseconds: 500), () {
          _refreshCurrentPageData();
        });
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
        print('用户信息刷新成功');
      }
    } catch (e) {
      print('刷新用户信息失败: $e');
    }
  }

  /// 刷新当前页面数据
  Future<void> _refreshCurrentPageData() async {
    try {
      print('开始刷新当前页面数据...');

      // 尝试刷新各个可能已注册的控制器
      // 1. 尝试刷新首页控制器
      if (Get.isRegistered<HomeController>()) {
        try {
          final homeController = Get.find<HomeController>();
          await homeController.refreshUserInfoFromServer();
          print('首页数据刷新完成');
        } catch (e) {
          print('刷新首页控制器失败: $e');
        }
      }

      // 2. 尝试刷新Mine页控制器
      if (Get.isRegistered<MineController>()) {
        try {
          final mineController = Get.find<MineController>();
          mineController.loadUserInfo();
          print('Mine页数据刷新完成');
        } catch (e) {
          print('刷新Mine页控制器失败: $e');
        }
      }

      // 3. 刷新定位页控制器
      if (Get.isRegistered<LocationController>()) {
        try {
          final locationController = Get.find<LocationController>();
          locationController.refreshUserInfo();
          print('定位页数据刷新完成');
        } catch (e) {
          print('刷新定位页控制器失败: $e');
        }
      }

      // 4. 刷新足迹页控制器
      if (Get.isRegistered<TrackController>()) {
        try {
          final trackController = Get.find<TrackController>();
          trackController.refreshCurrentUserData();
          print('足迹页数据刷新完成');
        } catch (e) {
          print('刷新足迹页控制器失败: $e');
        }
      }

      // 5. 刷新敏感记录页控制器
      if (Get.isRegistered<PhoneHistoryController>()) {
        try {
          final phoneHistoryController = Get.find<PhoneHistoryController>();
          await phoneHistoryController.refreshBindingStatus();
          print('敏感记录页数据刷新完成');
        } catch (e) {
          print('刷新敏感记录页控制器失败: $e');
        }
      }

      print('当前页面数据刷新完成');
    } catch (e) {
      print('刷新当前页面数据失败: $e');
    }
  }

  /// 复制匹配码
  void copyMatchCode() {
    Clipboard.setData(ClipboardData(text: userMatchCode.value));
    OKToastUtil.show('复制成功');
  }

  /// 分享到QQ
  void shareToQQ() {
    _shareInvite(target: 'QQ');
  }

  /// 分享到微信
  void shareToWechat() {
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
                        child: Image.network(
                          qrCodeUrl.value,
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

  /// 统一分享逻辑
  Future<void> _shareInvite({required String target}) async {
    try {
      final shareService = Get.put(ShareService(), permanent: true);
      Map<String, dynamic>? shareResult;

      // 获取分享配置
      final user = UserManager.currentUser;
      final shareConfig = user?.shareConfig;
      
      // 使用登录接口返回的分享配置，如果没有则使用默认值
      final shareTitle = shareConfig?.shareTitle ?? "绑定邀请";
      final shareDescription = shareConfig?.shareIntroduction ?? '快来和我绑定吧！';
      final shareCover = shareConfig?.shareCover;
      final sharePage = '${shareConfig?.sharePage }?bindCode=${userMatchCode.value}';
           

      if (target == '微信') {
        // 微信分享
        try {
          await shareService.shareToWeChat(
            title: shareTitle,
            description: shareDescription,
            imageUrl: shareCover,
            webpageUrl: sharePage,
          );
          OKToastUtil.show('已调起微信分享');
        } catch (e) {
          print('微信分享异常: $e');
          OKToastUtil.show('微信分享异常: $e');
        }
      } else if (target == 'QQ') {
        // QQ分享 - 优化处理逻辑
        try {
          // 先检查QQ是否安装
          final isQQInstalled = await shareService.isQQInstalled();
          print('QQ安装状态: $isQQInstalled');

          if (!isQQInstalled) {
            // QQ未安装
            OKToastUtil.show('检测到QQ未安装');
            return;
          }

          // QQ已安装，尝试分享
          shareResult = await shareService.shareToQQ(
            title: shareTitle,
            description: shareDescription,
            imageUrl: shareCover,
            webpageUrl: sharePage,
          );

          print('QQ分享结果: $shareResult');

          if (shareResult['success'] == true) {
            OKToastUtil.show('QQ分享成功');
          } else {
            final errorMsg = shareResult['message'] ?? '分享失败';
            print('QQ分享失败: $errorMsg');

            // 根据错误类型给出不同提示
            OKToastUtil.show('QQ分享失败: $errorMsg');
          }
        } catch (e) {
          print('QQ分享异常: $e');
          OKToastUtil.show('QQ分享异常: $e');
        }
      }
    } catch (e) {
      print('分享异常: $e');
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
