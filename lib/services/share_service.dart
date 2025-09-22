import 'package:get/get.dart';
import 'package:flutter/services.dart';

/// ShareService: unified WeChat / QQ share entry points via UMeng U-Share
class ShareService extends GetxService {
  static const MethodChannel _channel = MethodChannel('umshare');
  
  @override
  void onInit() {
    super.onInit();
    // 🔒 隐私合规：不在服务初始化时自动启动友盟SDK
    // 等待隐私政策同意后再启动
    // _initUMengShare(); // 移除自动初始化
    print('友盟分享服务已注册（等待隐私政策同意后初始化）');
  }

  /// 隐私合规启动方法 - 只有在用户同意隐私政策后才调用
  Future<void> startPrivacyCompliantService() async {
    print('🔒 启动隐私合规友盟分享服务');
    await _initUMengShare();
    print('✅ 隐私合规友盟分享服务启动完成');
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
  Future<Map<String, dynamic>> shareToQQ({
    required String title,
    required String description,
    String? imageUrl,
    required String webpageUrl,
  }) async {
    try {
      print('开始分享到QQ好友: title=$title, description=$description, webpageUrl=$webpageUrl');
      
      final result = await _channel.invokeMethod('umShare', {
        'title': title,
        'text': description,
        'img': imageUrl ?? '',
        'weburl': webpageUrl,
        'sharemedia': 2, // 2 = QQ好友
      });
      
      print('QQ好友分享结果: $result');
      
      if (result is Map<String, dynamic>) {
        return result;
      } else {
        return {'success': false, 'message': '分享结果格式错误'};
      }
    } catch (e) {
      print('QQ好友分享异常: $e');
      return {'success': false, 'message': '分享异常: $e'};
    }
  }

  // 分享到QQ空间
  Future<Map<String, dynamic>> shareToQZone({
    required String title,
    required String description,
    String? imageUrl,
    required String webpageUrl,
  }) async {
    try {
      print('开始分享到QQ空间: title=$title, description=$description, webpageUrl=$webpageUrl');
      
      final result = await _channel.invokeMethod('umShare', {
        'title': title,
        'text': description,
        'img': imageUrl ?? '',
        'weburl': webpageUrl,
        'sharemedia': 3, // 3 = QQ空间
      });
      
      print('QQ空间分享结果: $result');
      
      if (result is Map<String, dynamic>) {
        return result;
      } else {
        return {'success': false, 'message': '分享结果格式错误'};
      }
    } catch (e) {
      print('QQ空间分享异常: $e');
      return {'success': false, 'message': '分享异常: $e'};
    }
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
  
  /// 测试QQ分享功能
  Future<Map<String, dynamic>> testQQShare() async {
    try {
      print('🧪 开始测试QQ分享功能...');
      
      // 1. 检查QQ是否安装
      final isInstalled = await isQQInstalled();
      print('📱 QQ安装状态: $isInstalled');
      
      if (!isInstalled) {
        return {
          'success': false,
          'message': 'QQ未安装，请先安装QQ应用',
          'details': {
            'qqInstalled': false,
            'testStep': '安装检查'
          }
        };
      }
      
      // 2. 测试分享到QQ好友
      print('📤 测试分享到QQ好友...');
      final shareResult = await shareToQQ(
        title: "KISSU测试分享",
        description: "这是一个测试分享，用于验证QQ分享功能是否正常工作。",
        webpageUrl: "https://www.ikissu.cn",
        imageUrl: "https://www.ikissu.cn/logo.png",
      );
      
      print('📊 QQ分享测试结果: $shareResult');
      
      return {
        'success': shareResult['success'] ?? false,
        'message': shareResult['message'] ?? '测试完成',
        'details': {
          'qqInstalled': true,
          'shareResult': shareResult,
          'testStep': '分享测试'
        }
      };
      
    } catch (e) {
      print('❌ QQ分享测试异常: $e');
      return {
        'success': false,
        'message': '测试异常: $e',
        'details': {
          'error': e.toString(),
          'testStep': '异常处理'
        }
      };
    }
  }
}