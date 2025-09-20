import 'dart:io';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
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
  
  // 缓存网络和电池信息
  static String? _cachedNetworkName;
  static String? _cachedPower;

  BusinessHeaderInterceptor(this._authService);

  /// 获取当前设置的渠道
  /// 返回当前渠道标识，用于判断是否需要显示特定功能
  static String? getCurrentChannel() {
    return _cachedChannel;
  }

  /// 手动设置渠道（用于打包时配置）
  /// [channel] 渠道标识
  static void setChannel(String channel) {
    _cachedChannel = channel;
  }

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
      await _addNetworkHeaders(options);

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
            _cachedMobileModel = iosInfo.model;
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
          options.headers[HttpHeaderKey.brand] = _cachedBrand;  //具体渠道
        }
      } catch (e) {
        print('获取设备信息失败: $e');
      }
    }
  }

  /// 添加网络相关请求头
  Future<void> _addNetworkHeaders(RequestOptions options) async {
    // 设置默认渠道（可以根据实际需求修改）
    // 打包时请修改这里的渠道值：
    // kissu_xiaomi   <小米>  kissu_huawei  <华为>  kissu_rongyao  <荣耀>  kissu_vivo  <vivo>  kissu_oppo  <oppo>  
    if (_cachedChannel == null) {
      _cachedChannel = Platform.isAndroid ? 'kissu_oppo' : 'Android';  // 荣耀渠道
    }
    options.headers[HttpHeaderKey.channel] = _cachedChannel;

    // 获取真实的网络状态
    await _getNetworkInfo(options);
    
    // 获取真实的电池电量
    await _getBatteryInfo(options);
  }

  /// 获取网络信息
  Future<void> _getNetworkInfo(RequestOptions options) async {
    try {
      if (_cachedNetworkName == null) {
        final connectivity = Connectivity();
        final connectivityResults = await connectivity.checkConnectivity();
        
        String networkType = 'unknown';
        
        // 处理多个连接结果，优先选择主要连接类型
        if (connectivityResults.contains(ConnectivityResult.wifi)) {
          networkType = 'wifi';
          // 尝试获取WiFi SSID
          try {
            final networkInfo = NetworkInfo();
            final wifiName = await networkInfo.getWifiName();
            if (wifiName != null && wifiName.isNotEmpty) {
              networkType = 'wifi_${wifiName.replaceAll('"', '')}';
            }
          } catch (e) {
            // 如果获取WiFi名称失败，使用默认的wifi
            networkType = 'wifi';
          }
        } else if (connectivityResults.contains(ConnectivityResult.mobile)) {
          networkType = 'mobile';
        } else if (connectivityResults.contains(ConnectivityResult.ethernet)) {
          networkType = 'ethernet';
        } else if (connectivityResults.contains(ConnectivityResult.bluetooth)) {
          networkType = 'bluetooth';
        } else if (connectivityResults.contains(ConnectivityResult.vpn)) {
          networkType = 'vpn';
        } else if (connectivityResults.contains(ConnectivityResult.other)) {
          networkType = 'other';
        } else if (connectivityResults.contains(ConnectivityResult.none)) {
          networkType = 'none';
        }
        
        _cachedNetworkName = networkType;
      }
      
      options.headers[HttpHeaderKey.networkName] = _cachedNetworkName;
    } catch (e) {
      print('获取网络信息失败: $e');
      // 使用默认值
      options.headers[HttpHeaderKey.networkName] = 'unknown';
    }
  }

  /// 获取电池信息
  Future<void> _getBatteryInfo(RequestOptions options) async {
    try {
      if (_cachedPower == null) {
        final battery = Battery();
        final batteryLevel = await battery.batteryLevel;
        _cachedPower = batteryLevel.toString();
      }
      
      options.headers[HttpHeaderKey.power] = _cachedPower;
    } catch (e) {
      print('获取电池信息失败: $e');
      // 使用默认值
      options.headers[HttpHeaderKey.power] = '100';
    }
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
    _cachedNetworkName = null;
    _cachedPower = null;
    _packageInfo = null;
  }
}
