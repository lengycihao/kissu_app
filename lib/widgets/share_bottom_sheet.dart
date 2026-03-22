import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/services/share_service.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';
import 'package:kissu_app/services/analytics/analytics_params.dart';
import 'package:kissu_app/constants/app_constants.dart';

/// 分享底部弹窗组件
class ShareBottomSheet extends StatelessWidget {
  final String? matchCode;
  final bool isShareApp;
  final String? h5Image; // H5分享的图片URL
  final String? h5Url; // H5分享的链接URL（已拼接bindCode）
  
  const ShareBottomSheet({
    super.key, 
    this.matchCode,
    this.isShareApp = false,
    this.h5Image,
    this.h5Url,
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

  /// 显示H5分享弹窗（用于H5页面触发的分享）
  static void showH5Share(BuildContext context, {required String image, required String url}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ShareBottomSheet(
        h5Image: image,
        h5Url: url,
      ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 30,),
              const Text(
            '分享App',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          GestureDetector(
             onTap: () {
               // 埋点：记录分享弹窗关闭
               AnalyticsHelper.trackMyPageShareClose();
               Navigator.of(context).pop();
             },
             child: Image(image: AssetImage('assets/images/kissu_location_close.webp'),width: 20,height: 20,),
          )
            ],
          ),
          const SizedBox(height: 24),
          
          // 分享选项
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareOption(
                icon: 'assets/images/kissu_share_mine_wx.webp',
                label: '微信分享',
                onTap: () {
                  if (h5Image != null && h5Url != null) {
                    _shareH5ToWeChat(context);
                  } else if (isShareApp) {
                    _shareAppToWeChat(context);
                  } else {
                    _shareToWeChat(context);
                  }
                },
              ),
              _buildShareOption(
                icon: 'assets/images/kissu_share_mine_qq.webp',
                label: 'QQ分享',
                onTap: () {
                  if (h5Image != null && h5Url != null) {
                    _shareH5ToQQ(context);
                  } else if (isShareApp) {
                    _shareAppToQQ(context);
                  } else {
                    _shareToQQ(context);
                  }
                },
              ),
              _buildShareOption(
                icon: 'assets/images/kissu_share_mine_fx.webp',
                label: '复制链接',
                onTap: () {
                  if (h5Image != null && h5Url != null) {
                    _copyH5Link(context);
                  } else if (isShareApp) {
                    _copyAppLink(context);
                  } else {
                    _copyLink(context);
                  }
                },
               ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          
          
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
    // bool isIcon = false,
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
                child:   Image.asset(
                        icon as String,
                        width: 46,
                        height: 70,
                      ),
              ),
            // const SizedBox(height: 8),
            // Text(
            //   label,
            //   style: const TextStyle(
            //     fontSize: 14,
            //     color: Color(0xFF333333),
            //   ),
            //   textAlign: TextAlign.center, // 文字居中对齐
            // ),
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
      final shareResult = await shareService.shareToWeChatWithConfig(
        bindCode: matchCode,
      );
      
      // 处理分享结果并上报埋点
      if (shareResult['success'] == true) {
        // OKToastUtil.show('微信分享成功');
        AnalyticsHelper.trackMyPageShareChannel(
          channelName: ShareChannelValue.wechat,
          shareStatus: ShareStatusValue.success,
        );
      } else {
        final errorMsg = shareResult['message'] ?? '分享失败';
        logError('微信分享失败: $errorMsg');
        OKToastUtil.show('微信分享失败: $errorMsg');
        AnalyticsHelper.trackMyPageShareChannel(
          channelName: ShareChannelValue.wechat,
          shareStatus: ShareStatusValue.failed,
        );
      }
      
    } catch (e) {
      logError('微信分享异常: $e');
      OKToastUtil.show('分享失败: $e');
      AnalyticsHelper.trackMyPageShareChannel(
        channelName: ShareChannelValue.wechat,
        shareStatus: ShareStatusValue.failed,
      );
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
        // OKToastUtil.show('QQ分享成功');
      } else {
        final errorMsg = shareResult['message'] ?? '分享失败';
        logError('QQ分享失败: $errorMsg');
        OKToastUtil.show('QQ分享失败: $errorMsg');
      }
      
    } catch (e) {
      logError('分享失败: $e');
      OKToastUtil.show('分享失败: $e');
    }
  }

  /// 复制链接
  void _copyLink(BuildContext context) {
    Navigator.of(context).pop();
    
    const appLink = 'https://www.kissu.app/download'; // 替换为实际的下载链接
    
    Clipboard.setData(const ClipboardData(text: appLink)).then((_) {
       OKToastUtil.show('复制成功');
    }).catchError((error) {
      logError('复制失败: $error');
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
      final shareResult = await shareService.shareToWeChatWithConfig();
      
      // 处理分享结果并上报埋点
      if (shareResult['success'] == true) {
        // OKToastUtil.show('微信分享成功');
        AnalyticsHelper.trackMyPageShareChannel(
          channelName: ShareChannelValue.wechat,
          shareStatus: ShareStatusValue.success,
        );
      } else {
        final errorMsg = shareResult['message'] ?? '分享失败';
        logError('微信分享失败: $errorMsg');
        OKToastUtil.show('微信分享失败: $errorMsg');
        AnalyticsHelper.trackMyPageShareChannel(
          channelName: ShareChannelValue.wechat,
          shareStatus: ShareStatusValue.failed,
        );
      }
      
    } catch (e) {
      logError('微信分享异常: $e');
      OKToastUtil.show('分享失败: $e');
      
      // 埋点：记录分享失败
      AnalyticsHelper.trackMyPageShareChannel(
        channelName: ShareChannelValue.wechat,
        shareStatus: ShareStatusValue.failed,
      );
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
        // OKToastUtil.show('QQ分享成功');
        
        // 埋点：记录分享成功
        AnalyticsHelper.trackMyPageShareChannel(
          channelName: ShareChannelValue.qq,
          shareStatus: ShareStatusValue.success,
        );
      } else {
        final errorMsg = shareResult['message'] ?? '分享失败';
        logError('QQ分享失败: $errorMsg');
        OKToastUtil.show('QQ分享失败: $errorMsg');
        
        // 埋点：记录分享失败
        AnalyticsHelper.trackMyPageShareChannel(
          channelName: ShareChannelValue.qq,
          shareStatus: ShareStatusValue.failed,
        );
      }
      
    } catch (e) {
      logError('分享失败: $e');
      OKToastUtil.show('分享失败: $e');
      
      // 埋点：记录分享失败
      AnalyticsHelper.trackMyPageShareChannel(
        channelName: ShareChannelValue.qq,
        shareStatus: ShareStatusValue.failed,
      );
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
        AppConstants.defaultSharePage;
    
    // 智能拼接URL参数（与ShareService._buildShareParams保持一致）
    String appLink;
    if (basePage.contains('?')) {
      appLink = '$basePage&bindCode=$matchCode';
    } else {
      appLink = '$basePage?bindCode=$matchCode';
    }
    
    Clipboard.setData(ClipboardData(text: appLink)).then((_) {
      OKToastUtil.show('复制成功');
      
      // 埋点：记录复制成功
      AnalyticsHelper.trackMyPageShareChannel(
        channelName: ShareChannelValue.copyLink,
        shareStatus: ShareStatusValue.copied,
      );
    }).catchError((error) {
      logError('复制失败: $error');
      OKToastUtil.show('复制失败: $error');
      
      // 埋点：记录复制失败
      AnalyticsHelper.trackMyPageShareChannel(
        channelName: ShareChannelValue.copyLink,
        shareStatus: ShareStatusValue.failed,
      );
    });
  }

  /// H5分享到微信
  void _shareH5ToWeChat(BuildContext context) async {
    Navigator.of(context).pop();
    
    try {
      final shareService = Get.find<ShareService>();
      
      // 使用H5传入的图片和链接
      await shareService.shareToWeChat(
        title: '分享',
        description: '来自Kissu的分享',
        imageUrl: h5Image ?? '',
        webpageUrl: h5Url ?? '',
      );
      
    } catch (e) {
      logError('分享失败: $e');
      OKToastUtil.show('分享失败: $e');
    }
  }

  /// H5分享到QQ
  void _shareH5ToQQ(BuildContext context) async {
    Navigator.of(context).pop();
    
    try {
      final shareService = Get.find<ShareService>();
      
      // 使用H5传入的图片和链接
      final shareResult = await shareService.shareToQQ(
        title: '分享',
        description: '来自Kissu的分享',
        imageUrl: h5Image ?? '',
        webpageUrl: h5Url ?? '',
      );
      
      // 处理分享结果
      if (shareResult['success'] == true) {
        // OKToastUtil.show('QQ分享成功');
      } else {
        final errorMsg = shareResult['message'] ?? '分享失败';
        logError('QQ分享失败: $errorMsg');
        OKToastUtil.show('QQ分享失败: $errorMsg');
      }
      
    } catch (e) {
      logError('分享失败: $e');
      OKToastUtil.show('分享失败: $e');
    }
  }

  /// 复制H5分享链接
  void _copyH5Link(BuildContext context) {
    Navigator.of(context).pop();
    
    Clipboard.setData(ClipboardData(text: h5Url ?? '')).then((_) {
      OKToastUtil.show('复制成功');
    }).catchError((error) {
      logError('复制失败: $error');
      OKToastUtil.show('复制失败: $error');
    });
  }
}
