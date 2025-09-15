import 'package:get/get.dart';
import 'package:flutter/services.dart';

/// ShareService: unified WeChat / QQ share entry points via UMeng U-Share
class ShareService extends GetxService {
  static const MethodChannel _channel = MethodChannel('umshare');
  
  @override
  void onInit() {
    super.onInit();
    _initUMengShare();
  }

  /// 初始化友盟分享SDK
  Future<void> _initUMengShare() async {
    try {
      // 初始化友盟SDK（包含合规预初始化和隐私授权）
      await _channel.invokeMethod('umInit', {
        'appKey': '6879fbe579267e0210b67be9',
        'channel': 'umengshare',
        'logEnabled': true,
      });
      
      // 配置支持的平台
      await _channel.invokeMethod('platformConfig', {
        'qqAppKey': '102797447',
        'qqAppSecret': 'c5KJ2VipiMRMCpJf',
        'qqUniversalLink': 'https://kissu.app/qq/redirect',
        'weChatAppId': 'wxca15128b8c388c13',
        'weChatUniversalLink': 'https://ulink.ikissu.cn/',
        'weChatFileProvider': 'com.yuluo.kissu.fileprovider', // 微信FileProvider配置
      });
      
      print('友盟分享SDK初始化成功');
    } catch (e) {
      print('友盟分享SDK初始化失败: $e');
    }
  }

  /// 设置隐私政策授权状态
  /// [granted] 用户是否同意隐私政策
  Future<void> setPrivacyPolicyGranted(bool granted) async {
    try {
      await _channel.invokeMethod('setPrivacyPolicy', {'granted': granted});
      print('友盟隐私政策授权状态已设置: $granted');
    } catch (e) {
      print('设置友盟隐私政策授权失败: $e');
    }
  }

  // 检查微信是否安装
  Future<bool> isWeChatInstalled() async {
    try {
      final result = await _channel.invokeMethod('umCheckInstall', 0); // 0 = 微信
      if (result is Map) {
        return result['isInstalled'] ?? false;
      }
      return false;
    } catch (e) {
      print('检查微信安装状态失败: $e');
      return false;
    }
  }

  // 检查QQ是否安装
  Future<bool> isQQInstalled() async {
    try {
      final result = await _channel.invokeMethod('umCheckInstall', 1); // 1 = QQ
      if (result is Map) {
        return result['isInstalled'] ?? false;
      }
      return false;
    } catch (e) {
      print('检查QQ安装状态失败: $e');
      return false;
    }
  }

  // 分享到微信好友
  Future<void> shareToWeChat({
    required String title,
    required String description,
    String? imageUrl,
    required String webpageUrl,
  }) async {
    await _channel.invokeMethod('umShare', {
      'title': title,
      'text': description,
      'img': imageUrl ?? '',
      'weburl': webpageUrl,
      'sharemedia': 0, // 0 = 微信好友
    });
  }

  // 分享到微信朋友圈
  Future<void> shareToWeChatTimeline({
    required String title,
    required String description,
    String? imageUrl,
    required String webpageUrl,
  }) async {
    await _channel.invokeMethod('umShare', {
      'title': title,
      'text': description,
      'img': imageUrl ?? '',
      'weburl': webpageUrl,
      'sharemedia': 1, // 1 = 微信朋友圈
    });
  }

  // 分享到QQ好友
  Future<void> shareToQQ({
    required String title,
    required String description,
    String? imageUrl,
    required String webpageUrl,
  }) async {
    await _channel.invokeMethod('umShare', {
      'title': title,
      'text': description,
      'img': imageUrl ?? '',
      'weburl': webpageUrl,
      'sharemedia': 2, // 2 = QQ好友
    });
  }

  // 分享到QQ空间
  Future<void> shareToQZone({
    required String title,
    required String description,
    String? imageUrl,
    required String webpageUrl,
  }) async {
    await _channel.invokeMethod('umShare', {
      'title': title,
      'text': description,
      'img': imageUrl ?? '',
      'weburl': webpageUrl,
      'sharemedia': 3, // 3 = QQ空间
    });
  }

  // 分享文本到微信好友
  Future<bool> shareTextToWeChatSession({required String text}) async {
    try {
      // 检查是否安装微信
      final isInstalled = await isWeChatInstalled();
      if (!isInstalled) {
        print('微信未安装');
        return false;
      }
      
      // 分享纯文本
      await _channel.invokeMethod('umShare', {
        'text': text,
        'sharemedia': 0, // 0 = 微信好友
      });
      return true;
    } catch (e) {
      print('分享到微信失败: $e');
      return false;
    }
  }

  // 分享文本到QQ好友
  Future<bool> shareTextToQQ({required String text}) async {
    try {
      // 检查是否安装QQ
      final isInstalled = await isQQInstalled();
      if (!isInstalled) {
        print('QQ未安装');
        return false;
      }
      
      // 分享纯文本
      await _channel.invokeMethod('umShare', {
        'text': text,
        'sharemedia': 2, // 2 = QQ好友
      });
      return true;
    } catch (e) {
      print('分享到QQ失败: $e');
      return false;
    }
  }
}