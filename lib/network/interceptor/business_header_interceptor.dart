import 'dart:io';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:kissu_app/network/interceptor/http_header_key.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/utils/signature_utils.dart';

/// 业务请求头拦截器
/// 自动添加 token、sign、version、channel 等业务相关的请求头
class BusinessHeaderInterceptor extends Interceptor {
  final AuthService _authService;

  // 缓存设备信息，避免重复获取
  static DeviceInfoPlugin? _deviceInfo;
  static PackageInfo? _packageInfo;
  static String? _cachedDeviceId;
  static String? _cachedMobileModel;
  static String? _cachedBrand;
  static String? _cachedVersion;
  static String? _cachedChannel;
  static String? _cachedPkg;

  BusinessHeaderInterceptor(this._authService);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // 确保设备信息已初始化
      await _initializeDeviceInfo();

      // 添加 token（如果用户已登录）
      await _addTokenHeader(options);

      // 添加版本信息
      _addVersionHeaders(options);

      // 添加设备信息
      await _addDeviceHeaders(options);

      // 添加网络信息
      _addNetworkHeaders(options);

      // 添加签名（如果需要）
      _addSignHeader(options);
    } catch (e) {
      // 如果获取信息失败，不影响请求继续
      print('BusinessHeaderInterceptor error: $e');
    }

    handler.next(options);
  }

  /// 初始化设备信息
  Future<void> _initializeDeviceInfo() async {
    if (_deviceInfo == null) {
      _deviceInfo = DeviceInfoPlugin();
    }

    if (_packageInfo == null) {
      _packageInfo = await PackageInfo.fromPlatform();
    }
  }

  /// 添加 token 请求头
  Future<void> _addTokenHeader(RequestOptions options) async {
    // 确保用户信息已加载
    if (_authService.currentUser == null) {
      await _authService.loadCurrentUser();
    }

    // 如果用户已登录且有 token，则添加到请求头
    if (_authService.isLoggedIn && _authService.currentUser?.token != null) {
      options.headers[HttpHeaderKey.token] = _authService.currentUser!.token!;
    }
  }

  /// 添加版本相关请求头
  void _addVersionHeaders(RequestOptions options) {
    if (_packageInfo != null) {
      if (_cachedVersion == null) {
        _cachedVersion = _packageInfo!.version;
      }
      if (_cachedPkg == null) {
        _cachedPkg = _packageInfo!.packageName;
      }

      options.headers[HttpHeaderKey.version] = _cachedVersion;
      options.headers[HttpHeaderKey.pkg] = _cachedPkg;
    }
  }

  /// 添加设备相关请求头
  Future<void> _addDeviceHeaders(RequestOptions options) async {
    if (_deviceInfo != null) {
      try {
        if (Platform.isAndroid) {
          if (_cachedDeviceId == null ||
              _cachedMobileModel == null ||
              _cachedBrand == null) {
            final androidInfo = await _deviceInfo!.androidInfo;
            _cachedDeviceId = androidInfo.id;
            _cachedMobileModel = '${androidInfo.brand} ${androidInfo.model}';
            _cachedBrand = androidInfo.brand;
          }
        } else if (Platform.isIOS) {
          if (_cachedDeviceId == null ||
              _cachedMobileModel == null ||
              _cachedBrand == null) {
            final iosInfo = await _deviceInfo!.iosInfo;
            _cachedDeviceId = iosInfo.identifierForVendor ?? 'unknown';
            _cachedMobileModel = '${iosInfo.name} ${iosInfo.model}';
            _cachedBrand = 'Apple';
          }
        }

        if (_cachedDeviceId != null) {
          options.headers[HttpHeaderKey.deviceId] = _cachedDeviceId;
        }
        if (_cachedMobileModel != null) {
          options.headers[HttpHeaderKey.mobileModel] = _cachedMobileModel;
        }
        if (_cachedBrand != null) {
          options.headers[HttpHeaderKey.brand] = _cachedBrand;
        }
      } catch (e) {
        print('获取设备信息失败: $e');
      }
    }
  }

  /// 添加网络相关请求头
  void _addNetworkHeaders(RequestOptions options) {
    // 设置默认渠道（可以根据实际需求修改）
    if (_cachedChannel == null) {
      _cachedChannel = Platform.isAndroid ? 'android' : 'ios';
    }
    options.headers[HttpHeaderKey.channel] = _cachedChannel;

    // 网络名称（这里可以根据实际需求获取网络状态）
    options.headers[HttpHeaderKey.networkName] = 'wifi'; // 或者通过网络状态插件获取

    // 电量信息（这里设置默认值，可以通过电量插件获取实际值）
    options.headers[HttpHeaderKey.power] = '100'; // 可以通过 battery_plus 插件获取
  }

  /// 添加签名请求头
  void _addSignHeader(RequestOptions options) {
    // 添加时间戳
    SignatureUtils.addTimestamp(options);

    // 生成签名
    final sign = SignatureUtils.generateSignature(options: options);
    options.headers[HttpHeaderKey.sign] = sign;
  }

  /// 清除缓存的设备信息（在需要时调用）
  static void clearCache() {
    _cachedDeviceId = null;
    _cachedMobileModel = null;
    _cachedBrand = null;
    _cachedVersion = null;
    _cachedChannel = null;
    _cachedPkg = null;
    _packageInfo = null;
  }
}
