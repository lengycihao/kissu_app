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
import 'package:kissu_app/network/utils/device_util.dart';
import 'package:get/get.dart';
import 'package:kissu_app/services/privacy_compliance_manager.dart';
import 'package:kissu_app/utils/debug_util.dart';

/// 业务请求头拦截器
/// 自动添加 token、sign、version、channel 等业务相关的请求头
class BusinessHeaderInterceptor extends Interceptor {
  final AuthService _authService;

  // 缓存设备信息，避免重复获取
  static DeviceInfoPlugin? _deviceInfo;
  static PackageInfo? _packageInfo;
  static String? _cachedMobileModel;
  static String? _cachedBrand;  
  static String? _cachedVersion;
  static String? _cachedChannel;
  static String? _cachedPkg;
  
  // 缓存网络和电池信息
  static String? _cachedNetworkName;
  static String? _cachedPower;

  BusinessHeaderInterceptor(this._authService);

  /// 🔧 新增：安全处理HTTP头部值，确保符合HTTP标准
  /// 对包含非ASCII字符的值进行URL编码
  String _safeHeaderValue(String value) {
    try {
      // 检查是否包含非ASCII字符
      if (value.runes.any((rune) => rune > 127)) {
        // 包含非ASCII字符，进行URL编码
        final encoded = Uri.encodeComponent(value);
        DebugUtil.info('HTTP头部值已编码: $value -> $encoded');
        return encoded;
      }
      return value;
    } catch (e) {
      DebugUtil.error('编码HTTP头部值失败: $e');
      // 如果编码失败，返回安全的默认值
      return 'unknown';
    }
  }

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
      DebugUtil.error('BusinessHeaderInterceptor error: $e');
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

  /// 添加设备相关请求头（隐私合规版本）
  Future<void> _addDeviceHeaders(RequestOptions options) async {
    try {
      // 使用隐私合规的DeviceUtil获取设备信息
      final deviceUtil = DeviceUtil.instance;
      
      // DeviceUtil内部已经处理了隐私合规检查
      options.headers[HttpHeaderKey.deviceId] = deviceUtil.deviceId;
      
      // 设备型号和品牌信息相对不那么敏感，但也要检查隐私状态
      if (_canCollectSensitiveData()) {
        if (_deviceInfo != null) {
          if (Platform.isAndroid) {
            if (_cachedMobileModel == null || _cachedBrand == null) {
              final androidInfo = await _deviceInfo!.androidInfo;
              _cachedMobileModel = '${androidInfo.brand} ${androidInfo.model}';
              _cachedBrand = androidInfo.brand;
            }
          } else if (Platform.isIOS) {
            if (_cachedMobileModel == null || _cachedBrand == null) {
              final iosInfo = await _deviceInfo!.iosInfo;
              _cachedMobileModel = iosInfo.model;
              _cachedBrand = 'Apple';
            }
          }
        }
      } else {
        // 隐私政策未同意时使用通用信息
        _cachedMobileModel = Platform.operatingSystem;
        _cachedBrand = Platform.operatingSystem;
      }

      if (_cachedMobileModel != null) {
        // 🔧 修复：使用安全处理函数确保设备型号符合HTTP标准
        options.headers[HttpHeaderKey.mobileModel] = _safeHeaderValue(_cachedMobileModel!);
      }
      if (_cachedBrand != null) {
        // 🔧 修复：使用安全处理函数确保品牌名称符合HTTP标准
        options.headers[HttpHeaderKey.brand] = _safeHeaderValue(_cachedBrand!);
      }
    } catch (e) {
      DebugUtil.error('获取设备信息失败: $e');
      // 使用默认值
      options.headers[HttpHeaderKey.deviceId] = 'unknown';
      options.headers[HttpHeaderKey.mobileModel] = Platform.operatingSystem;
      options.headers[HttpHeaderKey.brand] = Platform.operatingSystem;
    }
  }

  /// 添加网络相关请求头
  Future<void> _addNetworkHeaders(RequestOptions options) async {
    // 设置默认渠道（可以根据实际需求修改）
    // 打包时请修改这里的渠道值：
    // kissu_xiaomi   <小米>  kissu_huawei  <华为>  kissu_rongyao  <荣耀>  kissu_vivo  <vivo>  kissu_oppo  <oppo>  kissu_meizu  <魅族>  kissu_yyb  <应用宝>
    _cachedChannel ??= Platform.isAndroid ? 'kissu_rongyao' : 'kissu_default';
    options.headers[HttpHeaderKey.channel] = _cachedChannel;


    // 获取真实的网络状态
    await _getNetworkInfo(options);
    
    // 获取真实的电池电量
    await _getBatteryInfo(options);
  }

  /// 获取网络信息（隐私合规版本）
  Future<void> _getNetworkInfo(RequestOptions options) async {
    try {
      // 🔒 隐私合规检查：如果用户未同意隐私政策，直接使用默认值
      if (!_canCollectSensitiveData()) {
        options.headers[HttpHeaderKey.networkName] = 'unknown';
        return;
      }
      
      if (_cachedNetworkName == null) {
        final connectivity = Connectivity();
        final connectivityResults = await connectivity.checkConnectivity();
        
        String networkType = 'unknown';
        
        // 处理多个连接结果，优先选择主要连接类型
        if (connectivityResults.contains(ConnectivityResult.wifi)) {
          networkType = 'wifi';
          
          // 🔒 WiFi SSID是敏感信息，只在隐私合规后才获取
          // 🔧 修复：添加超时控制，避免热点时获取SSID超时导致请求阻塞
          try {
            final networkInfo = NetworkInfo();
            final wifiName = await networkInfo.getWifiName()
                .timeout(
                  const Duration(seconds: 2),
                  onTimeout: () {
                    DebugUtil.warning('获取WiFi SSID超时（2秒），使用默认值');
                    return null;
                  },
                );
            if (wifiName != null && wifiName.isNotEmpty) {
              // 🔧 修复：对WiFi名称进行安全处理，避免中文字符导致HTTP头部格式错误
              final cleanWifiName = wifiName.replaceAll('"', '');
              networkType = 'wifi_$cleanWifiName';
            }
          } catch (e) {
            // 如果获取WiFi名称失败，使用默认的wifi
            DebugUtil.warning('获取WiFi SSID失败: $e，使用默认值');
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
      
      // 🔧 修复：使用安全处理函数确保HTTP头部值符合标准
      options.headers[HttpHeaderKey.networkName] = _safeHeaderValue(_cachedNetworkName ?? 'unknown');
    } catch (e) {
      DebugUtil.error('获取网络信息失败: $e');
      // 使用默认值
      options.headers[HttpHeaderKey.networkName] = 'unknown';
    }
  }

  /// 获取电池信息（隐私合规版本）
  Future<void> _getBatteryInfo(RequestOptions options) async {
    try {
      // 🔒 电池电量是敏感信息，需要隐私合规检查
      if (_canCollectSensitiveData()) {
        if (_cachedPower == null) {
          final battery = Battery();
          final batteryLevel = await battery.batteryLevel;
          _cachedPower = batteryLevel.toString();
        }
        options.headers[HttpHeaderKey.power] = _cachedPower;
      } else {
        // 隐私政策未同意时使用默认值
        options.headers[HttpHeaderKey.power] = '100';
      }
    } catch (e) {
      DebugUtil.error('获取电池信息失败: $e');
      // 使用默认值
      options.headers[HttpHeaderKey.power] = '100';
    }
  }
  
  /// 检查是否可以收集敏感数据
  bool _canCollectSensitiveData() {
    try {
      if (Get.isRegistered<PrivacyComplianceManager>()) {
        final privacyManager = Get.find<PrivacyComplianceManager>();
        return privacyManager.canCollectSensitiveData;
      }
    } catch (e) {
      DebugUtil.error('检查隐私合规状态失败: $e');
    }
    // 如果无法检查隐私状态，默认不允许收集
    return false;
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
    _cachedMobileModel = null;
    _cachedBrand = null;
    _cachedVersion = null;
    _cachedChannel = null;
    _cachedPkg = null;
    _cachedNetworkName = null;
    _cachedPower = null;
    _packageInfo = null;
  }
  
  /// 🔧 新增：仅清除网络信息缓存（用于网络状态变化时）
  static void clearNetworkCache() {
    _cachedNetworkName = null;
    DebugUtil.info('网络信息缓存已清除');
  }
  
  /// 🔧 新增：仅清除电池信息缓存
  static void clearBatteryCache() {
    _cachedPower = null;
  }
}
