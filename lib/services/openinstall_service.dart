import 'dart:async';
import 'dart:io';
import 'package:openinstall_flutter_plugin/openinstall_flutter_plugin.dart';
import 'package:flutter/foundation.dart';

/// OpenInstall 服务类
/// 用于处理应用安装统计、渠道统计、参数传递等功能
class OpenInstallService {
  static final OpenInstallService _instance = OpenInstallService._internal();
  factory OpenInstallService() => _instance;
  OpenInstallService._internal();

  late OpeninstallFlutterPlugin _plugin;
  bool _isInitialized = false;
  Function(Map<String, dynamic>)? _wakeupHandler;

  /// 初始化OpenInstall服务
  static Future<void> init() async {
    final service = OpenInstallService._instance;
    if (service._isInitialized) return;

    service._plugin = OpeninstallFlutterPlugin();
    
    // 设置调试模式（开发环境可以开启）
    service._plugin.setDebug(kDebugMode);
    
    // 初始化插件，注册拉起回调
    service._plugin.init(service._defaultWakeupHandler);
    
    service._isInitialized = true;
    if (kDebugMode) {
      print('OpenInstall服务初始化完成');
    }
  }

  /// 默认的拉起回调处理
  Future<void> _defaultWakeupHandler(Map<String, Object> data) async {
    if (kDebugMode) {
      print('OpenInstall唤醒参数: $data');
    }
    
    // 如果有自定义的唤醒处理器，则调用
    if (_wakeupHandler != null) {
      _wakeupHandler!(data.cast<String, dynamic>());
    }
    return;
  }

  /// 注册自定义的唤醒处理器
  static void registerWakeupHandler(Function(Map<String, dynamic>) handler) {
    final service = OpenInstallService._instance;
    service._wakeupHandler = handler;
  }

  /// 获取安装参数
  /// [timeoutSeconds] 超时时间（秒），默认10秒
  static Future<Map<String, dynamic>?> getInstallParamsWithTimeout({
    int timeoutSeconds = 10,
  }) async {
    final service = OpenInstallService._instance;
    if (!service._isInitialized) {
      throw Exception('OpenInstall服务未初始化');
    }

    final completer = Completer<Map<String, dynamic>?>();
    
    service._plugin.install((data) async {
      if (!completer.isCompleted) {
        completer.complete(data.cast<String, dynamic>());
      }
    }, timeoutSeconds);

    // 设置超时
    Timer(Duration(seconds: timeoutSeconds + 2), () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    return completer.future;
  }

  /// 获取安装参数（简化版本）
  static Future<Map<String, dynamic>?> getInstallParams() async {
    return getInstallParamsWithTimeout();
  }

  /// 获取安装参数（可重试版本，仅Android平台）
  /// [timeoutSeconds] 超时时间（秒），默认3秒
  static Future<Map<String, dynamic>?> getInstallParamsCanRetry({
    int timeoutSeconds = 3,
  }) async {
    final service = OpenInstallService._instance;
    if (!service._isInitialized) {
      throw Exception('OpenInstall服务未初始化');
    }

    if (!Platform.isAndroid) {
      if (kDebugMode) {
        print('getInstallParamsCanRetry方法仅支持Android平台');
      }
      return null;
    }

    final completer = Completer<Map<String, dynamic>?>();
    
    service._plugin.getInstallCanRetry((data) async {
      if (!completer.isCompleted) {
        completer.complete(data.cast<String, dynamic>());
      }
    }, timeoutSeconds);

    // 设置超时
    Timer(Duration(seconds: timeoutSeconds + 2), () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    return completer.future;
  }

  /// 上报注册事件
  static Future<void> reportRegister() async {
    final service = OpenInstallService._instance;
    if (!service._isInitialized) {
      throw Exception('OpenInstall服务未初始化');
    }
    
    service._plugin.reportRegister();
    if (kDebugMode) {
      print('OpenInstall注册事件上报完成');
    }
  }

  /// 上报效果点
  /// [pointId] 效果点ID
  /// [pointValue] 效果点值
  /// [extraMap] 额外参数
  static Future<void> reportEffectPoint({
    required String pointId,
    required int pointValue,
    Map<String, String>? extraMap,
  }) async {
    final service = OpenInstallService._instance;
    if (!service._isInitialized) {
      throw Exception('OpenInstall服务未初始化');
    }
    
    service._plugin.reportEffectPoint(pointId, pointValue, extraMap);
    if (kDebugMode) {
      print('OpenInstall效果点上报完成: $pointId = $pointValue');
    }
  }

  /// 上报分享事件
  /// [shareCode] 分享码
  /// [platform] 分享平台
  static Future<Map<String, dynamic>> reportShare({
    required String shareCode,
    required String platform,
  }) async {
    final service = OpenInstallService._instance;
    if (!service._isInitialized) {
      throw Exception('OpenInstall服务未初始化');
    }
    
    final result = await service._plugin.reportShare(shareCode, platform);
    if (kDebugMode) {
      print('OpenInstall分享事件上报完成: $shareCode -> $platform');
    }
    return result.cast<String, dynamic>();
  }

  /// 获取OPID
  static Future<String?> getOpid() async {
    final service = OpenInstallService._instance;
    if (!service._isInitialized) {
      throw Exception('OpenInstall服务未初始化');
    }
    
    return await service._plugin.getOpid();
  }

  /// 设置渠道代码（仅Android平台）
  /// [channelCode] 渠道代码
  static Future<void> setChannel(String channelCode) async {
    final service = OpenInstallService._instance;
    if (!service._isInitialized) {
      throw Exception('OpenInstall服务未初始化');
    }
    
    if (Platform.isAndroid) {
      service._plugin.setChannel(channelCode);
      if (kDebugMode) {
        print('OpenInstall渠道代码设置完成: $channelCode');
      }
    } else {
      if (kDebugMode) {
        print('setChannel方法仅支持Android平台');
      }
    }
  }

  /// 配置Android平台参数
  /// [config] 配置参数
  static Future<void> configAndroid(Map<String, dynamic> config) async {
    final service = OpenInstallService._instance;
    if (!service._isInitialized) {
      throw Exception('OpenInstall服务未初始化');
    }
    
    if (Platform.isAndroid) {
      service._plugin.configAndroid(config);
      if (kDebugMode) {
        print('OpenInstall Android配置完成: $config');
      }
    } else {
      if (kDebugMode) {
        print('configAndroid方法仅支持Android平台');
      }
    }
  }

  /// 配置iOS平台参数
  /// [config] 配置参数
  static Future<void> configIos(Map<String, dynamic> config) async {
    final service = OpenInstallService._instance;
    if (!service._isInitialized) {
      throw Exception('OpenInstall服务未初始化');
    }
    
    if (Platform.isIOS) {
      service._plugin.configIos(config);
      if (kDebugMode) {
        print('OpenInstall iOS配置完成: $config');
      }
    } else {
      if (kDebugMode) {
        print('configIos方法仅支持iOS平台');
      }
    }
  }

  /// 设置剪切板读取状态（仅Android平台）
  /// [enabled] 是否启用剪切板读取
  static Future<void> setClipboardEnabled(bool enabled) async {
    final service = OpenInstallService._instance;
    if (!service._isInitialized) {
      throw Exception('OpenInstall服务未初始化');
    }
    
    if (Platform.isAndroid) {
      service._plugin.clipBoardEnabled(enabled);
      if (kDebugMode) {
        print('OpenInstall剪切板读取状态设置完成: $enabled');
      }
    } else {
      if (kDebugMode) {
        print('setClipboardEnabled方法仅支持Android平台');
      }
    }
  }

  /// 获取渠道信息
  static Future<String?> getChannelCode() async {
    try {
      final params = await getInstallParams();
      return params?['channelCode'] as String?;
    } catch (e) {
      if (kDebugMode) {
        print('获取渠道信息失败: $e');
      }
      return null;
    }
  }

  /// 获取携带参数
  static Future<String?> getBindData() async {
    try {
      final params = await getInstallParams();
      return params?['bindData'] as String?;
    } catch (e) {
      if (kDebugMode) {
        print('获取携带参数失败: $e');
      }
      return null;
    }
  }

  /// 检查是否通过OpenInstall安装
  static Future<bool> isFromOpenInstall() async {
    try {
      final params = await getInstallParams();
      return params != null && params.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('检查OpenInstall安装状态失败: $e');
      }
      return false;
    }
  }

  /// 获取邀请码（从OpenInstall参数中提取）
  /// 支持多种格式：friendCode、inviteCode、code等
  static Future<String?> getInviteCode() async {
    try {
      final params = await getInstallParams();
      if (params == null || params.isEmpty) {
        return null;
      }

      // 尝试多种可能的邀请码字段名
      final possibleKeys = ['friendCode', 'inviteCode', 'code', 'friend_code', 'invite_code'];
      
      for (final key in possibleKeys) {
        final value = params[key];
        if (value != null && value.toString().isNotEmpty) {
          if (kDebugMode) {
            print('从OpenInstall参数中获取到邀请码: $key = $value');
          }
          return value.toString();
        }
      }

      // 如果没有找到标准字段，尝试从bindData中解析
      final bindData = params['bindData'] as String?;
      if (bindData != null && bindData.isNotEmpty) {
        final inviteCode = _parseInviteCodeFromBindData(bindData);
        if (inviteCode != null) {
          if (kDebugMode) {
            print('从bindData中解析到邀请码: $inviteCode');
          }
          return inviteCode;
        }
      }

      if (kDebugMode) {
        print('未在OpenInstall参数中找到邀请码，参数: $params');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('获取邀请码失败: $e');
      }
      return null;
    }
  }

  /// 从bindData中解析邀请码
  static String? _parseInviteCodeFromBindData(String bindData) {
    try {
      // 尝试解析JSON格式
      if (bindData.startsWith('{') && bindData.endsWith('}')) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          Uri.splitQueryString(bindData.replaceAll('{', '').replaceAll('}', ''))
        );
        
        final possibleKeys = ['friendCode', 'inviteCode', 'code', 'friend_code', 'invite_code'];
        for (final key in possibleKeys) {
          final value = data[key];
          if (value != null && value.toString().isNotEmpty) {
            return value.toString();
          }
        }
      }
      
      // 尝试解析URL参数格式
      final uri = Uri.tryParse('?$bindData');
      if (uri != null) {
        final possibleKeys = ['friendCode', 'inviteCode', 'code', 'friend_code', 'invite_code'];
        for (final key in possibleKeys) {
          final value = uri.queryParameters[key];
          if (value != null && value.isNotEmpty) {
            return value;
          }
        }
      }
      
      // 尝试直接匹配数字格式的邀请码
      final numericMatch = RegExp(r'\d{4,}').firstMatch(bindData);
      if (numericMatch != null) {
        return numericMatch.group(0);
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('解析bindData中的邀请码失败: $e');
      }
      return null;
    }
  }

  /// 获取并缓存邀请码（应用启动时调用一次）
  static String? _cachedInviteCode;
  static Future<String?> getCachedInviteCode() async {
    if (_cachedInviteCode != null) {
      return _cachedInviteCode;
    }
    
    _cachedInviteCode = await getInviteCode();
    return _cachedInviteCode;
  }

  /// 清除缓存的邀请码
  static void clearCachedInviteCode() {
    _cachedInviteCode = null;
  }
}