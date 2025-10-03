import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/services/share_service.dart';

/// 分享底部弹窗组件
class ShareBottomSheet extends StatelessWidget {
  final String? matchCode;
  final bool isShareApp;
  
  const ShareBottomSheet({
    super.key, 
    this.matchCode,
    this.isShareApp = false,
  });

  /// 显示分享弹窗（分享匹配码）
  static void show(BuildContext context, String matchCode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ShareBottomSheet(matchCode: matchCode),
    );
  }

  /// 显示分享APP弹窗
  static void showShareApp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ShareBottomSheet(isShareApp: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          const Text(
            '分享',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 24),
          
          // 分享选项
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareOption(
                icon: 'assets/kissu_share_mine_wx.webp',
                label: '微信分享',
                onTap: () => isShareApp ? _shareAppToWeChat(context) : _shareToWeChat(context),
              ),
              _buildShareOption(
                icon: 'assets/kissu_share_mine_qq.webp',
                label: 'QQ分享',
                onTap: () => isShareApp ? _shareAppToQQ(context) : _shareToQQ(context),
              ),
              _buildShareOption(
                icon: 'assets/kissu_share_mine_fx.webp',
                label: '复制链接',
                onTap: () => isShareApp ? _copyAppLink(context) : _copyLink(context),
               ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // 取消按钮
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(25),
              ),
              alignment: Alignment.center,
              child: const Text(
                '取消',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
            ),
          ),
          
          // 底部安全区域
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// 构建分享选项
  Widget _buildShareOption({
    dynamic icon,
    required String label,
    required VoidCallback onTap,
    bool isIcon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80, // 设置固定宽度，扩大点击区域
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), // 增加内边距扩大点击区域
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
           Center(
                child: isIcon
                    ? Icon(
                        icon as IconData,
                        size: 40,
                        color: const Color(0xFF666666),
                      )
                    : Image.asset(
                        icon as String,
                        width: 40,
                        height: 40,
                      ),
              ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center, // 文字居中对齐
            ),
          ],
        ),
      ),
    );
  }

  /// 分享到微信（分享匹配码）
  void _shareToWeChat(BuildContext context) async {
    Navigator.of(context).pop();
    
    try {
      // 使用统一的ShareService高级封装方法
      final shareService = Get.find<ShareService>();
      
      // 调用新的统一方法，只传入bindCode，标题和描述使用接口配置
      await shareService.shareToWeChatWithConfig(
        bindCode: matchCode,
      );
      // 微信分享暂时不返回结果，假设成功
      // OKToastUtil.show('已调起微信分享');
      
    } catch (e) {
      OKToastUtil.show('分享失败: $e');
    }
  }

  /// 分享到QQ（分享匹配码）
  void _shareToQQ(BuildContext context) async {
    Navigator.of(context).pop();
    
    try {
      // 使用统一的ShareService高级封装方法
      final shareService = Get.find<ShareService>();
      
      // 调用新的统一方法，只传入bindCode，标题和描述使用接口配置
      final shareResult = await shareService.shareToQQWithConfig(
        bindCode: matchCode,
      );
      
      // 处理分享结果
      if (shareResult['success'] == true) {
        OKToastUtil.show('QQ分享成功');
      } else {
        final errorMsg = shareResult['message'] ?? '分享失败';
        OKToastUtil.show('QQ分享失败: $errorMsg');
      }
      
    } catch (e) {
      OKToastUtil.show('分享失败: $e');
    }
  }

  /// 复制链接
  void _copyLink(BuildContext context) {
    Navigator.of(context).pop();
    
    const appLink = 'https://www.kissu.app/download'; // 替换为实际的下载链接
    
    Clipboard.setData(const ClipboardData(text: appLink)).then((_) {
      // OKToastUtil.show('链接已复制到剪贴板');
    }).catchError((error) {
      OKToastUtil.show('复制失败: $error');
    });
  }

  /// 使用系统分享功能分享应用
//   void _shareApp() {
//     const String shareText = '''
// 🌟 KissU - 情侣必备的专属App！

// 💕 实时定位，随时知道TA在哪里
// 📱 足迹记录，记录你们的美好时光
// 💌 专属空间，只属于你们两个人的世界

// 快来下载，和TA一起体验甜蜜吧！
// 下载链接：https://www.kissu.app/download
// ''';

//     Share.share(
//       shareText,
//       subject: 'Kissu - 情侣专属App',
//     ).catchError((error) {
//       OKToastUtil.show('分享失败: $error');
//       return ShareResult.unavailable;
//     });
//   }

  /// 分享APP到微信（使用用户配置）
  void _shareAppToWeChat(BuildContext context) async {
    Navigator.of(context).pop();
    
    try {
      // 使用统一的ShareService高级封装方法
      final shareService = Get.find<ShareService>();
      
      // 调用新的统一方法，不传入自定义参数，完全使用配置中的值
      // bindCode会自动使用当前用户的friendCode
      await shareService.shareToWeChatWithConfig();
      
    } catch (e) {
      OKToastUtil.show('分享失败: $e');
    }
  }

  /// 分享APP到QQ（使用用户配置）
  void _shareAppToQQ(BuildContext context) async {
    Navigator.of(context).pop();
    
    try {
      // 使用统一的ShareService高级封装方法
      final shareService = Get.find<ShareService>();
      
      // 调用新的统一方法，不传入自定义参数，完全使用配置中的值
      // bindCode会自动使用当前用户的friendCode
      final shareResult = await shareService.shareToQQWithConfig();
      
      // 处理分享结果
      if (shareResult['success'] == true) {
        OKToastUtil.show('QQ分享成功');
      } else {
        // final errorMsg = shareResult['message'] ?? '分享失败';
        // OKToastUtil.show('QQ分享失败: $errorMsg');
      }
      
    } catch (e) {
      OKToastUtil.show('分享失败: $e');
    }
  }

  /// 复制APP下载链接
  void _copyAppLink(BuildContext context) {
    Navigator.of(context).pop();
    
    // 获取分享配置中的链接，并拼接匹配码（与分享时保持一致）
    final user = UserManager.currentUser;
    final shareConfig = user?.shareConfig;
    final matchCode = user?.friendCode ?? '1000000';
    
    // 获取基础页面URL
    final basePage = shareConfig?.sharePage ?? 
        'https://www.ikissu.cn/share/matchingcode.html';
    
    // 智能拼接URL参数（与ShareService._buildShareParams保持一致）
    String appLink;
    if (basePage.contains('?')) {
      appLink = '$basePage&bindCode=$matchCode';
    } else {
      appLink = '$basePage?bindCode=$matchCode';
    }
    
    Clipboard.setData(ClipboardData(text: appLink)).then((_) {
      // OKToastUtil.show('链接已复制到剪贴板');
    }).catchError((error) {
      OKToastUtil.show('复制失败: $error');
    });
  }
}
