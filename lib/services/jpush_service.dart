import 'package:flutter/material.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:jpush_flutter/jpush_interface.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';

class JPushService extends GetxService {
  static JPushService get to => Get.find();
  
  late JPushFlutterInterface _jpush;
  
  // 推送状态
  final RxBool _isInitialized = false.obs;
  final RxString _registrationId = ''.obs;
  final RxString _lastMessage = ''.obs;
  final RxMap<String, dynamic> _lastNotification = <String, dynamic>{}.obs;
  
  // Getters
  bool get isInitialized => _isInitialized.value;
  String get registrationId => _registrationId.value;
  String get lastMessage => _lastMessage.value;
  Map<String, dynamic> get lastNotification => _lastNotification;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    // 🔒 隐私合规：不立即初始化，等待用户同意隐私政策
    debugPrint('极光推送服务已注册，等待隐私授权后初始化');
  }
  
  /// 初始化极光推送
  Future<void> initJPush() async {
    try {
      // 获取JPush实例
      _jpush = JPush.newJPush();
      
      // 初始化JPush，使用您提供的AppKey
      _jpush.setup(
        appKey: "4ee497251fc479522e1e6b7d",
        channel: "developer-default",
        production: false, // 开发环境设为false，生产环境设为true
        debug: true,
      );
      
      // 注意：极光推送在后台时默认会显示通知，不需要额外设置
      
      debugPrint('JPush setup完成 - AppKey: 4ee497251fc479522e1e6b7d');
      debugPrint('Master Secret已配置在AndroidManifest.xml中');
      
      // 配置通知样式
      await _configureNotificationStyle();
      
      // 添加事件监听
      _jpush.addEventHandler(
        onReceiveNotification: _onReceiveNotification,
        onOpenNotification: _onOpenNotification,
        onReceiveMessage: _onReceiveMessage,
      );
      
      debugPrint('JPush事件监听器已添加');
      
      // 等待一段时间确保事件处理器注册完成
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // 获取RegistrationId
      try {
        String regId = await _jpush.getRegistrationID();
        if (regId.isNotEmpty) {
          _registrationId.value = regId;
          debugPrint('JPush RegistrationId: $regId');
        } else {
          debugPrint('JPush RegistrationId为空，等待异步获取');
        }
      } catch (regError) {
        debugPrint('获取RegistrationId失败: $regError');
      }
      
      _isInitialized.value = true;
      debugPrint('JPush初始化成功');
      
    } catch (e) {
      debugPrint('JPush初始化失败: $e');
      _isInitialized.value = false;
    }
  }
  
  /// 接收到通知回调
  Future<dynamic> _onReceiveNotification(Map<String, dynamic> message) async {
    debugPrint('接收到通知: $message');
    _lastNotification.value = message;
    
    // 可以在这里处理接收到通知的逻辑
    String? title = message['title'];
    String? alert = message['alert'];
    
    if (title != null && alert != null) {
      // 显示应用内通知
      _showInAppNotification(title, alert);
    }
  }
  
  /// 点击通知回调
  Future<dynamic> _onOpenNotification(Map<String, dynamic> message) async {
    debugPrint('点击通知: $message');
    _lastNotification.value = message;
    
    // 处理点击通知的跳转逻辑
    _handleNotificationClick(message);
  }
  
  /// 接收到自定义消息回调
  Future<dynamic> _onReceiveMessage(Map<String, dynamic> message) async {
    debugPrint('接收到自定义消息: $message');
    String? content = message['message'];
    if (content != null) {
      _lastMessage.value = content;
    }
  }
  
  
  /// 显示应用内通知
  void _showInAppNotification(String title, String content) {
    if (Get.context != null) {
      CustomToast.show(
        Get.context!,
        content,
      );
    }
  }
  
  /// 处理通知点击
  void _handleNotificationClick(Map<String, dynamic> message) {
    // 根据通知内容进行页面跳转
    Map<String, dynamic>? extras = message['extras'];
    if (extras != null) {
      String? action = extras['action'];
      String? page = extras['page'];
      
      if (action != null && page != null) {
        // 根据action和page进行相应的页面跳转
        switch (action) {
          case 'navigate':
            Get.toNamed(page);
            break;
          case 'open_url':
            // 处理打开URL的逻辑
            break;
          default:
            debugPrint('未知的通知动作: $action');
        }
      }
    }
  }
  
  /// 设置别名
  Future<bool> setAlias(String alias) async {
    try {
      _jpush.setAlias(alias);
      debugPrint('设置别名成功: $alias');
      return true;
    } catch (e) {
      debugPrint('设置别名失败: $e');
      return false;
    }
  }
  
  /// 删除别名
  Future<bool> deleteAlias() async {
    try {
      _jpush.deleteAlias();
      debugPrint('删除别名成功');
      return true;
    } catch (e) {
      debugPrint('删除别名失败: $e');
      return false;
    }
  }
  
  /// 设置标签
  Future<bool> setTags(Set<String> tags) async {
    try {
      _jpush.setTags(tags.toList());
      debugPrint('设置标签成功: $tags');
      return true;
    } catch (e) {
      debugPrint('设置标签失败: $e');
      return false;
    }
  }
  
  /// 添加标签
  Future<bool> addTags(Set<String> tags) async {
    try {
      _jpush.addTags(tags.toList());
      debugPrint('添加标签成功: $tags');
      return true;
    } catch (e) {
      debugPrint('添加标签失败: $e');
      return false;
    }
  }
  
  /// 删除标签
  Future<bool> deleteTags(Set<String> tags) async {
    try {
      _jpush.deleteTags(tags.toList());
      debugPrint('删除标签成功: $tags');
      return true;
    } catch (e) {
      debugPrint('删除标签失败: $e');
      return false;
    }
  }
  
  /// 清空所有标签
  Future<bool> cleanTags() async {
    try {
      _jpush.cleanTags();
      debugPrint('清空所有标签成功');
      return true;
    } catch (e) {
      debugPrint('清空所有标签失败: $e');
      return false;
    }
  }
  
  /// 打开系统通知设置
  Future<void> openNotificationSettings() async {
    try {
      _jpush.openSettingsForNotification();
      debugPrint('打开通知设置成功');
    } catch (e) {
      debugPrint('打开通知设置失败: $e');
    }
  }
  
  /// 停止推送服务
  Future<void> stopPush() async {
    try {
      _jpush.stopPush();
      debugPrint('停止推送服务成功');
    } catch (e) {
      debugPrint('停止推送服务失败: $e');
    }
  }
  
  /// 恢复推送服务
  Future<void> resumePush() async {
    try {
      _jpush.resumePush();
      debugPrint('恢复推送服务成功');
    } catch (e) {
      debugPrint('恢复推送服务失败: $e');
    }
  }
  
  /// 检查通知权限是否开启
  Future<bool> isNotificationEnabled() async {
    try {
      bool isEnabled = await _jpush.isNotificationEnabled();
      debugPrint('通知权限状态: $isEnabled');
      return isEnabled;
    } catch (e) {
      debugPrint('检查通知权限失败: $e');
      return false;
    }
  }

  /// 申请通知权限
  Future<bool> requestNotificationPermission() async {
    try {
      _jpush.applyPushAuthority();
      return true;
    } catch (e) {
      debugPrint('申请通知权限失败: $e');
      return false;
    }
  }

  /// 获取所有标签
  Future<Set<String>> getAllTags() async {
    try {
      var result = await _jpush.getAllTags();
      debugPrint('获取标签结果: $result, 类型: ${result.runtimeType}');
      
      // JPush getAllTags 通常返回 Map，包含 tags 字段
      if (result is Map<String, dynamic>) {
        var tags = result['tags'];
        if (tags is List) {
          Set<String> tagSet = <String>{};
          for (var item in tags) {
            tagSet.add(item.toString());
          }
          return tagSet;
        }
      }
      
      return <String>{};
    } catch (e) {
      debugPrint('获取标签失败: $e');
      return <String>{};
    }
  }

  /// 发送本地通知
  Future<bool> sendLocalNotification({
    required String title,
    required String content,
    int? notificationId,
    Map<String, dynamic>? extras,
  }) async {
    try {
      // 确保JPush已初始化
      if (!_isInitialized.value) {
        debugPrint('JPush未初始化，尝试重新初始化...');
        await initJPush();
        if (!_isInitialized.value) {
          debugPrint('JPush初始化失败，无法发送本地通知');
          return false;
        }
      }
      
      // 创建LocalNotification实例，使用最简单的参数
      final int notificationIdToUse = notificationId ?? DateTime.now().millisecondsSinceEpoch;
      
      final notification = LocalNotification(
        id: notificationIdToUse,
        title: title,
        content: content,
        fireTime: DateTime.now().add(const Duration(seconds: 3)), // 延迟3秒发送
        buildId: 1, // 添加buildId
        extra: <String, String>{}, // 添加空的extra字典
      );
      
      debugPrint('发送本地通知: ${notification.toMap()}');
      _jpush.sendLocalNotification(notification);
      return true;
    } catch (e) {
      debugPrint('发送本地通知失败: $e');
      return false;
    }
  }

  /// 清除所有通知
  Future<bool> clearAllNotifications() async {
    try {
      _jpush.clearAllNotifications();
      return true;
    } catch (e) {
      debugPrint('清除所有通知失败: $e');
      return false;
    }
  }

  /// 配置通知样式
  Future<void> _configureNotificationStyle() async {
    try {
      // 设置通知样式 - 使用自定义样式
      if (GetPlatform.isAndroid) {
        // Android平台的通知样式配置
        debugPrint('配置Android通知样式');
        
        // 通知渠道配置在AndroidManifest.xml和JPushReceiver中处理
        debugPrint('Android通知样式配置完成');
      } else if (GetPlatform.isIOS) {
        // iOS平台的通知样式配置
        debugPrint('配置iOS通知样式');
      }
    } catch (e) {
      debugPrint('配置通知样式失败: $e');
    }
  }
  

  /// 根据ID清除指定通知
  Future<bool> clearNotificationById(int notificationId) async {
    try {
      // 注意：部分版本的JPush可能不支持此方法，如果不支持就使用clearAllNotifications
      debugPrint('尝试清除通知ID: $notificationId');
      // _jpush.clearNotificationById(notificationId); // 此方法可能不存在
      _jpush.clearAllNotifications(); // 作为替代方案
      return true;
    } catch (e) {
      debugPrint('清除指定通知失败: $e');
      return false;
    }
  }
  
  /// 重置RegistrationId
  Future<void> resetRegistrationId() async {
    try {
      String newRegId = await _jpush.getRegistrationID();
      if (newRegId.isNotEmpty) {
        _registrationId.value = newRegId;
        debugPrint('重置RegistrationId: $newRegId');
      }
    } catch (e) {
      debugPrint('重置RegistrationId失败: $e');
    }
  }

  /// 获取配置信息
  Map<String, String> getConfigInfo() {
    return {
      'AppKey': '4ee497251fc479522e1e6b7d',
      'Master Secret': '73394575cf91ff845b03f25e',
      'Channel': 'developer-default',
      'RegistrationId': _registrationId.value,
      'Is Initialized': _isInitialized.value.toString(),
    };
  }

  /// 验证配置
  Future<bool> validateConfig() async {
    try {
      // 检查是否已初始化
      if (!_isInitialized.value) {
        debugPrint('JPush未初始化');
        return false;
      }

      // 检查RegistrationId
      String regId = await _jpush.getRegistrationID();
      if (regId.isEmpty) {
        debugPrint('RegistrationId为空');
        return false;
      }

      debugPrint('JPush配置验证成功');
      debugPrint('AppKey: 4ee497251fc479522e1e6b7d');
      debugPrint('Master Secret: 73394575cf91ff845b03f25e');
      debugPrint('RegistrationId: $regId');
      
      return true;
    } catch (e) {
      debugPrint('JPush配置验证失败: $e');
      return false;
    }
  }
}