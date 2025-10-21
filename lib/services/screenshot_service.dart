import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// 截屏监听服务
/// 用于监听用户截屏行为,并触发相应的UI反馈
class ScreenshotService extends GetxService {
  static const MethodChannel _channel = MethodChannel('kissu_app/screenshot');
  
  // 截屏回调函数列表
  final List<Function(String)> _listeners = [];
  
  // 是否正在监听
  bool _isListening = false;
  
  @override
  void onInit() {
    super.onInit();
    print('🔧 ScreenshotService.onInit() 被调用');
    _setupMethodCallHandler();
    print('🔧 ScreenshotService 方法调用处理器已设置');
  }
  
  /// 设置方法调用处理器
  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onScreenshotCaptured') {
        final String? screenshotPath = call.arguments as String?;
        if (screenshotPath != null && screenshotPath.isNotEmpty) {
          print('📸 截屏服务: 收到截屏事件 path=$screenshotPath');
          
          // 【关键逻辑】检查权限，如果没有则请求
          final hasPermission = await _checkMediaPermission();
          if (!hasPermission) {
            print('⚠️ 第一次截屏，请求媒体库权限...');
            final granted = await _requestMediaPermission();
            if (!granted) {
              print('⚠️ 用户拒绝了媒体库权限，不显示反馈按钮');
              return; // 不通知监听器，不显示按钮！
            }
            print('✅ 媒体库权限已授予');
          }
          
          // 有权限了，通知监听器显示按钮
          _notifyListeners(screenshotPath);
        }
      }
    });
  }
  
  /// 开始监听截屏（仅Android）
  Future<void> startListening() async {
    print('🔧 startListening() 被调用，平台: ${Platform.operatingSystem}');
    
    if (!Platform.isAndroid) {
      print('⚠️ 截屏监听: 仅支持Android平台');
      return;
    }
    
    if (_isListening) {
      print('⚠️ 截屏监听: 已经在监听中');
      return;
    }
    
    // 【关键修改】只检查权限，不主动请求！让第一次截图时再请求
    print('🔧 检查读取媒体库权限状态...');
    final hasPermission = await _checkMediaPermission();
    if (hasPermission) {
      print('✅ 读取媒体库权限已存在，启动截屏监听');
    } else {
      print('⚠️ 暂无读取媒体库权限，等待第一次截图时请求');
      // 不返回！继续启动监听，等Native检测到截图时再请求权限
    }
    
    try {
      print('🔧 正在调用Native方法 startListening...');
      final result = await _channel.invokeMethod('startListening');
      print('🔧 Native方法返回结果: $result');
      if (result == true) {
        _isListening = true;
        print('✅ 截屏监听: 已启动（权限将在第一次截图时请求）');
      } else {
        print('⚠️ 截屏监听: Native返回false');
      }
    } catch (e, stackTrace) {
      print('❌ 截屏监听启动失败: $e');
      print('❌ 堆栈跟踪: $stackTrace');
    }
  }
  
  // 权限状态缓存，避免重复检查
  bool? _cachedPermissionStatus;
  
  /// 【新增】只检查权限，不请求（避免启动时弹窗）
  Future<bool> _checkMediaPermission() async {
    try {
      // 如果有缓存的权限状态，直接返回
      if (_cachedPermissionStatus != null) {
        print('📸 使用缓存的媒体库权限状态: $_cachedPermissionStatus');
        return _cachedPermissionStatus!;
      }
      
      // Android 13+ 使用系统 Photo Picker，不需要读取媒体权限
      if (Platform.isAndroid) {
        final bool isAndroid13OrAbove = await _isAndroid13OrAbove();
        if (isAndroid13OrAbove) {
          print('📸 Android 13+ 使用系统Photo Picker，无需媒体库权限');
          _cachedPermissionStatus = true;
          return true;
        }
      }
      
      final permission = _getPhotosPermission();
      final status = await permission.status;
      print('📸 媒体库权限状态: $status');
      final result = status.isGranted;
      _cachedPermissionStatus = result;
      return result;
    } catch (e) {
      print('❌ 检查媒体库权限失败: $e');
      return false;
    }
  }
  
  /// 请求读取媒体库权限（用于监听截屏）
  Future<bool> _requestMediaPermission() async {
    try {
      // Android 13+ 使用系统 Photo Picker，不需要请求读取媒体权限
      if (Platform.isAndroid) {
        final bool isAndroid13OrAbove = await _isAndroid13OrAbove();
        if (isAndroid13OrAbove) {
          print('📸 Android 13+ 使用系统Photo Picker，无需申请媒体库权限');
          _cachedPermissionStatus = true;
          return true;
        }
      }
      
      final permission = _getPhotosPermission();
      
      // 检查权限状态
      var status = await permission.status;
      print('📸 媒体库权限状态: $status');
      
      if (status.isGranted) {
        _cachedPermissionStatus = true;
        return true;
      }
      
      if (status.isDenied) {
        // 请求权限
        print('📸 请求媒体库权限...');
        status = await permission.request();
        print('📸 权限请求结果: $status');
        final result = status.isGranted;
        _cachedPermissionStatus = result;
        return result;
      }
      
      if (status.isPermanentlyDenied) {
        print('⚠️ 媒体库权限被永久拒绝');
        _cachedPermissionStatus = false;
        // 可以在这里引导用户到设置页面
        return false;
      }
      
      final result = status.isGranted;
      _cachedPermissionStatus = result;
      return result;
    } catch (e) {
      print('❌ 请求媒体库权限失败: $e');
      return false;
    }
  }
  
  /// 判断是否为 Android 13 及以上（SDK >= 33）
  Future<bool> _isAndroid13OrAbove() async {
    try {
      if (!Platform.isAndroid) return false;
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final int sdkInt = androidInfo.version.sdkInt;
      print('📸 Android SDK版本: $sdkInt');
      return sdkInt >= 33;
    } catch (e) {
      // 获取设备信息失败时，保守返回 false，保持旧逻辑
      print("获取Android版本信息失败: $e");
      return false;
    }
  }
  
  /// 根据平台获取相册权限（和 PermissionService 保持一致）
  Permission _getPhotosPermission() {
    if (Platform.isAndroid) {
      // Android 使用 storage 权限来访问相册
      // permission_handler 会自动根据系统版本选择合适的权限：
      // - Android 13+ 会映射到 READ_MEDIA_IMAGES
      // - Android 13- 会映射到 READ_EXTERNAL_STORAGE
      return Permission.storage;
    } else {
      // iOS 使用 photos 权限
      return Permission.photos;
    }
  }
  
  /// 清除权限缓存（当权限状态可能发生变化时调用）
  void _clearPermissionCache() {
    _cachedPermissionStatus = null;
  }
  
  /// 停止监听截屏
  Future<void> stopListening() async {
    if (!Platform.isAndroid) return;
    
    if (!_isListening) {
      print('⚠️ 截屏监听: 未在监听中');
      return;
    }
    
    try {
      final result = await _channel.invokeMethod('stopListening');
      if (result == true) {
        _isListening = false;
        _clearPermissionCache(); // 停止监听时清除权限缓存
        print('✅ 截屏监听: 已停止');
      }
    } catch (e) {
      print('❌ 截屏监听停止失败: $e');
    }
  }
  
  /// 【测试方法】手动触发截屏回调（用于调试）
  void testTrigger() {
    print('🧪 测试: 手动触发截屏回调');
    _notifyListeners('/storage/emulated/0/Pictures/Screenshots/test_screenshot.png');
  }
  
  /// 添加监听器
  void addListener(Function(String) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
      print('📎 截屏监听: 添加监听器，当前监听器数量=${_listeners.length}');
    }
  }
  
  /// 移除监听器
  void removeListener(Function(String) listener) {
    _listeners.remove(listener);
    print('📎 截屏监听: 移除监听器，当前监听器数量=${_listeners.length}');
  }
  
  /// 通知所有监听器
  void _notifyListeners(String screenshotPath) {
    print('📢 截屏监听: 通知${_listeners.length}个监听器');
    for (var listener in List.from(_listeners)) {
      try {
        listener(screenshotPath);
      } catch (e) {
        print('❌ 截屏监听: 通知监听器异常 $e');
      }
    }
  }
  
  @override
  void onClose() {
    stopListening();
    _listeners.clear();
    _clearPermissionCache();
    super.onClose();
  }
}

