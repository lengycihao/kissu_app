import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceUtil {
  static DeviceUtil? _instance;
  static DeviceUtil get instance => _instance ??= DeviceUtil._();

  DeviceUtil._();

  String? _deviceId;
  String? _appVersion;
  String? _deviceType;
  bool _isInitialized = false;

  /// Initialize device information
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeDeviceInfo();
      await _initializeAppInfo();
      _isInitialized = true;

      logger.info(
        'Device utility initialized',
        tag: 'DeviceUtil',
        extra: {
          'deviceId': _deviceId,
          'appVersion': _appVersion,
          'deviceType': _deviceType,
          'platform': Platform.operatingSystem,
        },
      );
    } catch (e) {
      logger.error(
        'Failed to initialize device utility',
        tag: 'DeviceUtil',
        error: e,
      );
      // Set default values on error
      _deviceId = _generateFallbackDeviceId();
      _appVersion = '1.0.0';
      _deviceType = Platform.operatingSystem;
      _isInitialized = true;
    }
  }

  Future<void> _initializeDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      _deviceId = androidInfo.id;
      _deviceType = 'android';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      _deviceId = iosInfo.identifierForVendor;
      _deviceType = 'ios';
    } else if (kIsWeb) {
      final webInfo = await deviceInfo.webBrowserInfo;
      _deviceId = _generateWebDeviceId(webInfo);
      _deviceType = 'web';
    } else {
      _deviceId = _generateFallbackDeviceId();
      _deviceType = Platform.operatingSystem;
    }
  }

  Future<void> _initializeAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
    } catch (e) {
      logger.warning('Failed to get package info', tag: 'DeviceUtil', error: e);
      _appVersion = '1.0.0';
    }
  }

  String _generateWebDeviceId(WebBrowserInfo webInfo) {
    // Generate a stable device ID for web based on browser info
    final browserData =
        '${webInfo.browserName}-${webInfo.platform}-${webInfo.userAgent?.hashCode}';
    return browserData.hashCode.abs().toString();
  }

  String _generateFallbackDeviceId() {
    // Generate a fallback device ID based on timestamp and platform
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final platform = Platform.operatingSystem;
    return '$platform-$timestamp';
  }

  /// Get device ID
  String get deviceId {
    if (!_isInitialized) {
      logger.warning(
        'DeviceUtil not initialized, using fallback deviceId',
        tag: 'DeviceUtil',
      );
      return _generateFallbackDeviceId();
    }
    return _deviceId ?? _generateFallbackDeviceId();
  }

  /// Get app version
  String get appVersion {
    if (!_isInitialized) {
      logger.warning(
        'DeviceUtil not initialized, using default appVersion',
        tag: 'DeviceUtil',
      );
      return '1.0.0';
    }
    return _appVersion ?? '1.0.0';
  }

  /// Get device type/platform
  String get deviceType {
    if (!_isInitialized) {
      return Platform.operatingSystem;
    }
    return _deviceType ?? Platform.operatingSystem;
  }

  /// Get OS name for API headers
  String get osName {
    return Platform.operatingSystem.toLowerCase();
  }

  /// Check if device info is available
  bool get isInitialized => _isInitialized;

  /// Update device ID manually (for testing or special cases)
  void updateDeviceId(String newDeviceId) {
    _deviceId = newDeviceId;
    logger.info(
      'Device ID updated manually',
      tag: 'DeviceUtil',
      extra: {'newDeviceId': newDeviceId},
    );
  }
}
