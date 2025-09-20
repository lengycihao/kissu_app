import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/public/auth_api.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/services/share_service.dart';
import 'package:path_provider/path_provider.dart';

class ShareController extends GetxController {
  // 用户信息
  var userAvatar = ''.obs;
  var matchCode = ''.obs;
  var qrCodeUrl = ''.obs;

  // 匹配码输入框控制器
  late TextEditingController matchCodeController;

  // 加载状态
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    matchCodeController = TextEditingController();
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
      // 设置用户头像
      if (user.headPortrait?.isNotEmpty == true) {
        userAvatar.value = user.headPortrait!;
      } else {
        userAvatar.value = 'assets/kissu_icon.webp';
      }

      // 设置匹配码
      matchCode.value = user.friendCode ?? '1000000';

      // 设置二维码
      if (user.friendQrCode?.isNotEmpty == true) {
        qrCodeUrl.value = user.friendQrCode!;
      }

      print('分享页面用户信息加载完成:');
      print('头像: ${userAvatar.value}');
      print('匹配码: ${matchCode.value}');
      print('二维码: ${qrCodeUrl.value}');
    } else {
      print('用户信息为空，使用默认值');
      userAvatar.value = 'assets/kissu_icon.webp';
      matchCode.value = '1000000';
    }
  }

  /// 安全显示Toast
  void _showToast(String message) {
    OKToastUtil.show(message);
  }

  /// 绑定另一半
  Future<void> bindPartner() async {
    final inputCode = matchCodeController.text.trim();
    if (inputCode.isEmpty) {
      OKToastUtil.show('请输入匹配码');
      return;
    }

    if (inputCode == matchCode.value) {
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

        // 跳转到首页
        Get.offAllNamed(KissuRoutePath.home);
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

  /// 复制匹配码
  void copyMatchCode() {
    Clipboard.setData(ClipboardData(text: matchCode.value));
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

  /// 分享二维码
  void shareQRCode() {
    Get.toNamed(KissuRoutePath.qrScanPage)?.then((value) {
      if (value is String && value.isNotEmpty) {
        // 根据扫码结果做处理：
        // 1) 若是匹配码，填入输入框；
        // 2) 若是包含 friendCode 的 URL，解析后填入；
        final scanned = value.trim();
        final friendCode = _extractFriendCode(scanned);
        if (friendCode != null) {
          matchCodeController.text = friendCode;
          OKToastUtil.show('已识别匹配码：$friendCode');
        } else {
          OKToastUtil.show('未识别到匹配码');
        }
      }
    });
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
    final paramMatch = RegExp(r'(?:(?:friendCode|code)=)(\d{4,})').firstMatch(input);
    if (paramMatch != null) {
      return paramMatch.group(1);
    }
    
    return null;
  }

  /// 统一分享逻辑（先用系统分享兜底，后续可替换为友盟渠道分享）
  Future<void> _shareInvite({required String target}) async {
    try {
      final code = matchCode.value;
      // final shareText = '和我一起用KISSU恋爱日常吧～ 我的匹配码：$code \n下载并输入匹配码即可绑定～';
 
      // 使用友盟分享
      try {
        final shareService = Get.put(ShareService(), permanent: true);
        Map<String, dynamic>? shareResult;
        // String? imageUrl = await getLocalImageUrl('assets/kissu_icon.png');
        if (target == '微信') {
          await shareService.shareToWeChat(
            title: "绑定邀请",
            description: '快来和我绑定吧！',
            // imageUrl: imageUrl,
            webpageUrl: 'http://devweb.ikissu.cn/share/matchingcode.html?bindCode=${matchCode.value}',
          );
          // 微信分享暂时不返回结果，假设成功
          OKToastUtil.show('已调起微信分享');
        } else if (target == 'QQ') {
          shareResult = await shareService.shareToQQ(
            title: "绑定邀请",
            // imageUrl: imageUrl,
            description: '快来和我绑定吧！',
            webpageUrl: 'http://devweb.ikissu.cn/share/matchingcode.html?bindCode=${matchCode.value}',
          );
          
          print('QQ分享结果: $shareResult');
          
          if (shareResult['success'] == true) {
            OKToastUtil.show('QQ分享成功');
          } else {
            final errorMsg = shareResult['message'] ?? '分享失败';
            print('QQ分享失败: $errorMsg');
            OKToastUtil.show('QQ分享失败: $errorMsg');
            
            // 如果友盟QQ分享失败，尝试系统分享
            final shareText = '和我一起用KISSU恋爱日常吧～ 我的匹配码：$code \n下载并输入匹配码即可绑定～';
            await _systemShare(shareText);
          }
        }
      } catch (e) {
        print('分享异常: $e');
        OKToastUtil.show('分享失败: $e');
        
        // 异常时使用系统分享作为备用
        final shareText = '和我一起用KISSU恋爱日常吧～ 我的匹配码：$code \n下载并输入匹配码即可绑定～';
        await _systemShare(shareText);
       }
    } catch (e) {
      OKToastUtil.show('分享失败: $e');
    }
  }

  /// 系统分享备用方案
  Future<void> _systemShare(String text) async {
    try {
      // 使用Flutter的share插件作为备用
      await Clipboard.setData(ClipboardData(text: text));
      OKToastUtil.show('分享文本已复制到剪贴板');
    } catch (e) {
      OKToastUtil.show('复制失败: $e');
    }
  }

  /// 测试Toast显示
  void testToast() {
    _showToast('Toast测试消息 - 如果你看到这个，说明Toast工作正常！');
  }

  Future<String?> getLocalImageUrl(String assetPath) async {
  try {
    // 获取应用文档目录
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${assetPath.split('/').last}');
    
    // 如果文件不存在，则从assets复制
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ));
    }
    
    // 返回文件的URI作为imageUrl
    return file.uri.toString();
  } catch (e) {
    print('获取本地图片URL失败: $e');
    return null;
  }
}
}
