import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:kissu_app/utils/user_manager.dart';

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
      print('开始检查QQ安装状态...');
      
      // 首先尝试友盟检测
      final umResult = await _channel.invokeMethod('umCheckInstall', 1); // 1 = QQ
      print('友盟QQ检测结果: $umResult');
      
      if (umResult is Map) {
        final umInstalled = umResult['isInstalled'] ?? false;
        print('友盟检测QQ安装状态: $umInstalled');
        
        // 如果友盟检测到已安装，直接返回
        if (umInstalled) {
          return true;
        }
      }
      
      // 友盟检测失败或未安装，尝试备用检测方法
      print('友盟检测失败，尝试备用检测方法...');
      final backupResult = await _channel.invokeMethod('checkQQInstallBackup');
      print('备用QQ检测结果: $backupResult');
      
      if (backupResult is Map) {
        final backupInstalled = backupResult['isInstalled'] ?? false;
        print('备用检测QQ安装状态: $backupInstalled');
        return backupInstalled;
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
      
      // 先检查QQ是否安装
      final isInstalled = await isQQInstalled();
      if (!isInstalled) {
        print('QQ未安装，无法分享');
        return {'success': false, 'message': 'QQ未安装'};
      }
      
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
        return {'success': false, 'message': '分享失败'};
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

  /// 🔧 内部方法：构建分享参数
  /// 
  /// 提取公共逻辑，避免代码重复
  /// 返回值：Map包含 title, description, cover, url 或 error
  Map<String, dynamic> _buildShareParams({
    String? bindCode,
    String? customTitle,
    String? customDescription,
    String? customUrl,
    bool useDefaultFallback = true,
  }) {
    try {
      // 获取用户配置
      final user = UserManager.currentUser;
      final shareConfig = user?.shareConfig;
      
      print('📋 用户配置: shareConfig=${shareConfig?.toJson()}');
      
      // 构建标题
      String shareTitle;
      if (shareConfig?.shareTitle != null) {
        shareTitle = shareConfig!.shareTitle!;
      } else if (customTitle != null) {
        shareTitle = customTitle;
      } else if (useDefaultFallback) {
        shareTitle = "Kissu - 情侣专属App";
      } else {
        return {'error': '分享标题未配置'};
      }
      
      // 构建描述
      String shareDescription;
      if (shareConfig?.shareIntroduction != null) {
        shareDescription = shareConfig!.shareIntroduction!;
      } else if (customDescription != null) {
        shareDescription = customDescription;
      } else if (useDefaultFallback) {
        shareDescription = '实时定位，足迹记录，专属空间，快来和TA一起体验甜蜜吧！';
      } else {
        return {'error': '分享描述未配置'};
      }
      
      // 封面图：优先使用接口配置
      String? shareCover = shareConfig?.shareCover;
      
      // 构建分享链接
      String shareUrl;
      if (customUrl != null) {
        shareUrl = customUrl;
      } else {
        // 获取bindCode
        final code = bindCode ?? user?.friendCode ?? '1000000';
        
        // 获取基础页面URL
        final basePage = shareConfig?.sharePage ?? 
          (useDefaultFallback ? 'https://www.ikissu.cn/share/matchingcode.html' : null);
        
        if (basePage == null) {
          return {'error': '分享链接未配置'};
        }
        
        // 智能拼接URL参数
        if (basePage.contains('?')) {
          shareUrl = '$basePage&bindCode=$code';
        } else {
          shareUrl = '$basePage?bindCode=$code';
        }
      }
      
      return {
        'title': shareTitle,
        'description': shareDescription,
        'cover': shareCover,
        'url': shareUrl,
      };
    } catch (e) {
      return {'error': '构建分享参数异常: $e'};
    }
  }

  /// 🎯 统一的QQ分享方法（高级封装）- 自动获取用户配置
  /// 
  /// 此方法会自动从用户配置中获取分享信息，适用于大部分场景
  /// 
  /// 参数说明：
  /// - [bindCode] 绑定码，如果为null则使用当前用户的friendCode
  /// - [customTitle] 自定义标题，如果为null则使用配置中的标题
  /// - [customDescription] 自定义描述，如果为null则使用配置中的描述
  /// - [customUrl] 自定义分享链接，如果为null则自动构建链接
  /// - [useDefaultFallback] 当配置不存在时是否使用默认值（默认true）
  /// 
  /// 返回值：
  /// - Map包含 success(bool) 和 message(String)
  Future<Map<String, dynamic>> shareToQQWithConfig({
    String? bindCode,
    String? customTitle,
    String? customDescription,
    String? customUrl,
    bool useDefaultFallback = true,
  }) async {
    try {
      print('🔍 开始QQ分享（使用配置）...');
      
      // 1. 先检查QQ是否安装
      final isInstalled = await isQQInstalled();
      if (!isInstalled) {
        print('❌ QQ未安装');
        return {
          'success': false,
          'message': 'QQ未安装',
        };
      }
      
      // 2. 构建分享参数（使用提取的公共方法）
      final params = _buildShareParams(
        bindCode: bindCode,
        customTitle: customTitle,
        customDescription: customDescription,
        customUrl: customUrl,
        useDefaultFallback: useDefaultFallback,
      );
      
      // 检查是否有错误
      if (params.containsKey('error')) {
        return {
          'success': false,
          'message': params['error'],
        };
      }
      
      // 打印调试信息
      print('📤 QQ分享参数:');
      print('  - 标题: ${params['title']}');
      print('  - 描述: ${params['description']}');
      print('  - 封面: ${params['cover']}');
      print('  - 链接: ${params['url']}');
      print('🔗 分享链接域名需要在QQ开放平台配置白名单');
      
      // 3. 调用底层分享方法
      final result = await shareToQQ(
        title: params['title'],
        description: params['description'],
        imageUrl: params['cover'],
        webpageUrl: params['url'],
      );
      
      print('✅ QQ分享结果: $result');
      return result;
      
    } catch (e) {
      print('❌ QQ分享异常: $e');
      return {
        'success': false,
        'message': '分享异常: $e',
      };
    }
  }

  /// 🎯 统一的微信分享方法（高级封装）- 自动获取用户配置
  /// 
  /// 此方法会自动从用户配置中获取分享信息，适用于大部分场景
  /// 
  /// 参数说明：
  /// - [bindCode] 绑定码，如果为null则使用当前用户的friendCode
  /// - [customTitle] 自定义标题，如果为null则使用配置中的标题
  /// - [customDescription] 自定义描述，如果为null则使用配置中的描述
  /// - [customUrl] 自定义分享链接，如果为null则自动构建链接
  /// - [useDefaultFallback] 当配置不存在时是否使用默认值（默认true）
  Future<void> shareToWeChatWithConfig({
    String? bindCode,
    String? customTitle,
    String? customDescription,
    String? customUrl,
    bool useDefaultFallback = true,
  }) async {
    try {
      print('🔍 开始微信分享（使用配置）...');
      
      // 1. 先检查微信是否安装
      final isInstalled = await isWeChatInstalled();
      if (!isInstalled) {
        print('❌ 微信未安装');
        throw Exception('微信未安装');
      }
      
      // 2. 构建分享参数（使用提取的公共方法）
      final params = _buildShareParams(
        bindCode: bindCode,
        customTitle: customTitle,
        customDescription: customDescription,
        customUrl: customUrl,
        useDefaultFallback: useDefaultFallback,
      );
      
      // 检查是否有错误
      if (params.containsKey('error')) {
        throw Exception(params['error']);
      }
      
      print('📤 微信分享参数:');
      print('  - 标题: ${params['title']}');
      print('  - 描述: ${params['description']}');
      print('  - 封面: ${params['cover']}');
      print('  - 链接: ${params['url']}');
      
      // 3. 调用底层分享方法
      await shareToWeChat(
        title: params['title'],
        description: params['description'],
        imageUrl: params['cover'],
        webpageUrl: params['url'],
      );
      
      print('✅ 微信分享已调起');
      
    } catch (e) {
      print('❌ 微信分享异常: $e');
      rethrow;
    }
  }
}