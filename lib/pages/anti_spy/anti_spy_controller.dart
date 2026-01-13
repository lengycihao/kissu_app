import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:ping_discover_network_forked/ping_discover_network_forked.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'widgets/radar_selector.dart';
import '../../utils/permission_helper.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/oktoast_util.dart';

/// 信号量类，用于控制并发数量
class Semaphore {
  final int maxCount;
  int _currentCount;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  Semaphore(this.maxCount) : _currentCount = maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      completer.complete();
    } else {
      _currentCount++;
    }
  }
}

enum ScanState {
  initial,    // 初始状态
  scanning,   // 扫描中
  success,    // 扫描成功
  suspicious, // 发现可疑设备
  failed,     // 扫描失败
}

enum DeviceType {
  phone,        // 手机
  tablet,       // 平板
  laptop,       // 笔记本电脑
  desktop,      // 台式电脑
  router,       // 路由器
  printer,      // 打印机
  camera,       // 摄像头
  tv,           // 智能电视
  speaker,      // 智能音箱
  iot,          // 物联网设备
  server,       // 服务器
  computer,     // 通用计算机
  unknown,      // 未知设备
}

/// 设备识别评分类
class DeviceIdentificationScore {
  double ipPatternScore = 0.0;
  double portSignatureScore = 0.0;
  double macVendorScore = 0.0;
  double httpFingerprintScore = 0.0;
  double upnpScore = 0.0;
  double responseTimeScore = 0.0;
  DeviceType suggestedType = DeviceType.unknown;
  
  double get totalScore => (ipPatternScore + portSignatureScore + macVendorScore + httpFingerprintScore + upnpScore + responseTimeScore) / 6;
}

class DeviceInfo {
  final String ip;
  final String name;
  final String? macAddress;
  final DeviceType type;
  final List<int> openPorts; // 开放的端口列表
  final String? vendor; // 厂商信息
  final String? httpFingerprint; // HTTP指纹
  final String? deviceModel; // 设备型号
  final String? upnpInfo; // UPnP设备信息
  final double confidence; // 识别置信度
  final DateTime discoveredAt; // 发现时间
  final int responseTime; // 响应时间(ms)
  
  DeviceInfo({
    required this.ip, 
    required this.name, 
    this.macAddress,
    this.type = DeviceType.unknown,
    this.openPorts = const [],
    this.vendor,
    this.httpFingerprint,
    this.deviceModel,
    this.upnpInfo,
    this.confidence = 0.5,
    DateTime? discoveredAt,
    this.responseTime = 0,
  }) : discoveredAt = discoveredAt ?? DateTime.now();
  
  // 获取主要端口（用于显示）
  int? get primaryPort => openPorts.isNotEmpty ? openPorts.first : null;
  
  // 判断是否为高风险摄像头
  bool get isHighRiskCamera => type == DeviceType.camera && confidence > 0.8;
  
  // 获取风险等级
  String get riskLevel {
    if (type == DeviceType.camera) {
      if (confidence > 0.9) return '高风险';
      if (confidence > 0.7) return '中风险';
      return '低风险';
    }
    return '正常';
  }
  
  // 重写 == 操作符，基于 IP 地址进行比较
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceInfo && other.ip == ip;
  }
  
  // 重写 hashCode，基于 IP 地址
  @override
  int get hashCode => ip.hashCode;
}

class AntiSpyController extends GetxController with GetTickerProviderStateMixin {
  // 扫描状态
  var scanState = ScanState.initial.obs;
  
  // 当前连接的WiFi信息
  var currentWifiName = "未连接WiFi".obs;
  var currentWifiSSID = "".obs;
  var isWifiConnected = false.obs;
  
  // 扫描到的设备列表
  var discoveredDevices = <DeviceInfo>[].obs;
  var suspiciousDevices = <DeviceInfo>[].obs;
  
  // 扫描进度
  var scanProgress = 0.0.obs;
  
  // 雷达动画类型
  var radarAnimationType = RadarAnimationType.particle.obs;
  
  // 动画控制器
  late AnimationController radarAnimationController;
  late AnimationController pulseAnimationController;
  late Animation<double> radarAnimation;
  late Animation<double> pulseAnimation;
  
  // 扫描流
  StreamSubscription? _scanSubscription;
  
  // 网络信息服务
  final NetworkInfo _networkInfo = NetworkInfo();
  
  // 网络连接监听
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  
  @override
  void onInit() {
    super.onInit();
    _initAnimations();
    _checkWifiConnection();
    _startNetworkListener();
  }
  
  void _initAnimations() {
    // 雷达旋转动画 - 持续旋转
    radarAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    radarAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: radarAnimationController,
      curve: Curves.linear,
    ));
    
    // 脉冲动画 - 用于闪烁点
    pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: pulseAnimationController,
      curve: Curves.easeInOut,
    ));
  }
  
  /// 开始网络连接监听
  void _startNetworkListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _handleConnectivityChange(results);
    });
  }
  
  /// 处理网络连接状态变化
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final hasWifi = results.contains(ConnectivityResult.wifi);
    if (hasWifi) {
      // 连接到WiFi，检查WiFi信息
      _checkWifiConnection();
    } else {
      // 未连接WiFi
      isWifiConnected.value = false;
      currentWifiName.value = "未连接WiFi";
      currentWifiSSID.value = "";
    }
  }
  
  /// 检查WiFi连接状态
  Future<void> _checkWifiConnection() async {
    try {
      final wifiName = await _networkInfo.getWifiName();
      final wifiBSSID = await _networkInfo.getWifiBSSID();
      
      if (wifiName != null && wifiName.isNotEmpty) {
        isWifiConnected.value = true;
        currentWifiName.value = wifiName.replaceAll('"', ''); // 移除引号
        currentWifiSSID.value = wifiBSSID ?? '';
      } else {
        isWifiConnected.value = false;
        currentWifiName.value = "未连接WiFi";
        currentWifiSSID.value = "";
      }
    } catch (e) {
      logError('获取WiFi信息失败: $e', tag: 'AntiSpy', error: e);
      isWifiConnected.value = false;
      currentWifiName.value = "获取WiFi信息失败";
    }
  }
  
  /// 开始扫描
  Future<void> startScan() async {
    if (scanState.value == ScanState.scanning) {
      return;
    }
    
    // 检查WiFi连接
    await _checkWifiConnection();
    if (!isWifiConnected.value) {
      scanState.value = ScanState.failed;
      return;
    }
    
    // 检查位置权限（Android需要位置权限来获取WiFi信息）
    if (Platform.isAndroid) {
      final status = await Permission.location.status;
      if (!status.isGranted) {
        final result = await Permission.location.request();
        if (!result.isGranted) {
          scanState.value = ScanState.failed;
          return;
        }
      }
    }
    
    scanState.value = ScanState.scanning;
    discoveredDevices.clear();
    suspiciousDevices.clear();
    scanProgress.value = 0.0;
    logDebug('🚀 开始扫描，清空设备列表 (当前设备数: ${discoveredDevices.length})', tag: 'AntiSpy');
    
    // 启动动画
    radarAnimationController.repeat();
    pulseAnimationController.repeat(reverse: true);
    
    try {
      await _performNetworkScan();
    } catch (e) {
      logError('扫描失败: $e', tag: 'AntiSpy', error: e);
      scanState.value = ScanState.failed;
      _stopAnimations();
    }
  }
  
  /// 执行网络扫描
  Future<void> _performNetworkScan() async {
    try {
      // 获取当前设备IP
      final wifiIP = await _networkInfo.getWifiIP();
      if (wifiIP == null || wifiIP.isEmpty) {
        throw Exception('无法获取设备IP地址');
      }
      
      // 解析子网
      final ipParts = wifiIP.split('.');
      if (ipParts.length != 4) {
        throw Exception('IP地址格式错误');
      }
      
      final subnet = '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}';
      logDebug('开始扫描子网: $subnet', tag: 'AntiSpy');
      
      // 第一阶段：PING扫描发现在线设备
      await _performPingScan(subnet);
      
      // 第二阶段：端口扫描已发现的设备
      await _performPortScan(subnet);
      
      // 扫描完成
      _finalizeScan();
      
    } catch (e) {
      logError('网络扫描错误: $e', tag: 'AntiSpy', error: e);
      scanState.value = ScanState.failed;
    } finally {
      _stopAnimations();
    }
  }
  
  
  /// 执行PING扫描发现在线设备 - 优化版本
  Future<void> _performPingScan(String subnet) async {
    logDebug('开始快速设备发现...', tag: 'AntiSpy');
    
    // 精简PING端口，只用最有效的几个
    final pingPorts = [80, 443, 22, 5555]; // 减少到4个最有效端口
    int totalPings = 254 * pingPorts.length;
    int completedPings = 0;
    
    for (final port in pingPorts) {
      if (scanState.value != ScanState.scanning) break;
      
      logDebug('快速扫描端口: $port', tag: 'AntiSpy');
      
      _scanSubscription = NetworkAnalyzer.discover2(
        subnet, 
        port,
        timeout: const Duration(milliseconds: 800) // 减少超时时间到800ms
      ).listen((NetworkAddress addr) {
        completedPings++;
        scanProgress.value = (completedPings / totalPings) * 0.25; // PING扫描占25%进度
        
        if (addr.exists) {
          // 发现在线设备，先添加为未知设备
          _addDiscoveredDeviceFromPing(addr.ip);
        }
      });
      
      await _scanSubscription?.asFuture();
    }
    
    // 补充：尝试ARP表扫描（如果可用）
    await _performArpScan(subnet);
  }
  
  /// 执行端口扫描 - 优化版本
  Future<void> _performPortScan(String subnet) async {
    logDebug('开始智能端口扫描...', tag: 'AntiSpy');
    
    // 分层扫描策略：先扫描高价值端口，快速识别设备类型
    final priorityPorts = [
      // 第一优先级：最常见的识别端口（快速扫描）
      80, 443, 22, 8080, 5555, // 通用服务
      3389, 139, 445, 5900,    // 电脑特征端口
      62078, 5037, 4000,       // 手机特征端口
      554, 1935, 8000, 8001,   // 摄像头端口
      631, 9100,               // 打印机端口
    ];
    
    final cameraPorts = [
      // 摄像头专用端口（高优先级）
      554, 1935, 8000, 8001, 8003, 8004, 8005, 8006, 8007, 8010,
      8080, 8443, 8888, 9000, 9001, 9002, 9003, 9004, 9005,
      10000, 10001, 10002, 10003, 10004, 10005,
      37777, 34567, 2000, 2001, 2002, 2003, 2004,
      6667, 7000, 7001, 7002, 7003, 7004, 7005,
      81, 82, 83, 84, 85, 86, 87, 88, 89, 90,
      8081, 8082, 8083, 8084, 8085, 8086, 8087, 8088, 8089, 8090,
    ];
    
    final secondaryPorts = [
      // 第二优先级：补充识别端口
      8443, 8888, 8081, 8082, 8083,
      135, 548, 88, 389, 1433, 3306,
      5901, 5902, 5903, 5904, 5905,
      25565, 27015, 19132, // 游戏端口
      1900, 5353, 8009, 8008, // 智能设备
    ];
    
    // 第一阶段：快速扫描优先级端口
    await _scanPortList(subnet, priorityPorts, 0.25, 0.4, Duration(milliseconds: 300));
    
    // 第二阶段：专门扫描摄像头端口
    await _scanCameraPorts(subnet, cameraPorts, 0.4, 0.7, Duration(milliseconds: 200));
    
    // 第三阶段：补充扫描（仅对已发现设备进行）
    if (discoveredDevices.isNotEmpty) {
      await _scanPortListForKnownDevices(subnet, secondaryPorts, 0.7, 0.85, Duration(milliseconds: 150));
    }
    
    // 第四阶段：HTTP指纹检测
    await _performHttpFingerprintScan(0.85, 1.0);
  }
  
  /// 扫描指定端口列表
  Future<void> _scanPortList(String subnet, List<int> ports, double startProgress, double endProgress, Duration timeout) async {
    int totalChecks = 255 * ports.length;
    int completedChecks = 0;
    
    for (final port in ports) {
      if (scanState.value != ScanState.scanning) break;
      
      _scanSubscription = NetworkAnalyzer.discover2(
        subnet, 
        port,
        timeout: timeout
      ).listen((NetworkAddress addr) {
        completedChecks++;
        double progress = startProgress + (completedChecks / totalChecks) * (endProgress - startProgress);
        scanProgress.value = progress;
        
        if (addr.exists) {
          _addDiscoveredDevice(addr.ip, port);
          update(); // 实时更新UI
        }
      });
      
      await _scanSubscription?.asFuture();
    }
  }
  
  /// 仅对已知设备扫描补充端口
  Future<void> _scanPortListForKnownDevices(String subnet, List<int> ports, double startProgress, double endProgress, Duration timeout) async {
    final knownIPs = discoveredDevices.map((d) => d.ip).toSet();
    int totalChecks = knownIPs.length * ports.length;
    int completedChecks = 0;
    
    for (final port in ports) {
      if (scanState.value != ScanState.scanning) break;
      
      for (final ip in knownIPs) {
        if (scanState.value != ScanState.scanning) break;
        
        try {
          final socket = await Socket.connect(ip, port, timeout: timeout);
          socket.destroy();
          
          // 找到开放端口，更新设备信息
          _addDiscoveredDevice(ip, port);
          update();
        } catch (e) {
          // 端口关闭，忽略
        }
        
        completedChecks++;
        double progress = startProgress + (completedChecks / totalChecks) * (endProgress - startProgress);
        scanProgress.value = progress;
      }
    }
  }
  
  /// ARP表扫描（补充发现方法）
  Future<void> _performArpScan(String subnet) async {
    logDebug('开始ARP表扫描...', tag: 'AntiSpy');
    try {
      // 在Android/Linux上尝试读取ARP表
      if (Platform.isAndroid || Platform.isLinux) {
        final result = await Process.run('cat', ['/proc/net/arp']);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          for (String line in lines) {
            if (line.contains(subnet) && !line.startsWith('IP')) {
              final parts = line.split(RegExp(r'\s+'));
              if (parts.length >= 1) {
                final ip = parts[0];
                if (ip.startsWith(subnet)) {
                  _addDiscoveredDeviceFromPing(ip);
                }
              }
            }
          }
        }
      }
      
      // 在Windows上尝试使用arp命令
      if (Platform.isWindows) {
        final result = await Process.run('arp', ['-a']);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          for (String line in lines) {
            if (line.contains(subnet)) {
              final match = RegExp(r'(\d+\.\d+\.\d+\.\d+)').firstMatch(line);
              if (match != null) {
                final ip = match.group(1)!;
                if (ip.startsWith(subnet)) {
                  _addDiscoveredDeviceFromPing(ip);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      logWarning('ARP扫描失败: $e', tag: 'AntiSpy', error: e);
      // ARP扫描失败不影响主流程
    }
  }

  /// 从PING扫描添加发现的设备
  void _addDiscoveredDeviceFromPing(String ip) {
    // 检查是否已经记录过这个IP
    final existingDevice = discoveredDevices.firstWhereOrNull(
      (device) => device.ip == ip
    );
    
    if (existingDevice == null) {
      // PING发现的设备，先判断基本类型
      final deviceType = _detectDeviceTypeFromIP(ip);
      final deviceName = _generateDeviceName(ip, 0, deviceType);
      final device = DeviceInfo(
        ip: ip,
        name: deviceName, 
        type: deviceType,
        openPorts: [], // PING扫描没有端口信息
      );
      
      // 添加设备并立即更新UI
      discoveredDevices.add(device);
      logDebug('🔍 PING发现新设备: $ip - $deviceName (总数: ${discoveredDevices.length})', tag: 'AntiSpy');
      update(); // 实时更新UI，PING扫描到一个显示一个
      
      // ⚠️ 移除冗余的延迟更新，避免过度刷新UI影响动画
    }
  }
  
  /// 摄像头专用端口扫描 - 优化版本
  Future<void> _scanCameraPorts(String subnet, List<int> ports, double startProgress, double endProgress, Duration timeout) async {
    logDebug('开始摄像头专用端口扫描...', tag: 'AntiSpy');
    
    // 只扫描最常用的摄像头端口，减少扫描时间
    final priorityCameraPorts = [
      554, 1935, 8000, 8001, 8080, 8443, 8888, // 最常见的摄像头端口
      37777, 34567, 2000, 81, 82, 83, 84, 85, // 品牌特定端口
    ];
    
    // 只扫描已发现的设备，而不是整个子网
    final targetIPs = <String>[];
    if (discoveredDevices.isNotEmpty) {
      // 如果已经发现了设备，只扫描这些设备
      targetIPs.addAll(discoveredDevices.map((d) => d.ip));
    } else {
      // 如果没有发现设备，快速扫描常见IP范围
      for (int i = 1; i <= 50; i++) { // 只扫描前50个IP
        targetIPs.add('$subnet.$i');
      }
    }
    
    int totalChecks = targetIPs.length * priorityCameraPorts.length;
    int completedChecks = 0;
    
    // 并发扫描，提高效率
    final futures = <Future>[];
    final semaphore = Semaphore(10); // 限制并发数为10
    
    for (String ip in targetIPs) {
      for (int port in priorityCameraPorts) {
        futures.add(
          semaphore.acquire().then((_) async {
            try {
              final socket = await Socket.connect(ip, port, timeout: Duration(milliseconds: 100)); // 减少超时时间
              await socket.close();
              
              // 发现摄像头端口，进行轻量级检测
              await _lightweightCameraCheck(ip, port);
              
            } catch (e) {
              // 端口关闭或连接失败
            } finally {
              semaphore.release();
              completedChecks++;
              final progress = startProgress + (endProgress - startProgress) * (completedChecks / totalChecks);
              scanProgress.value = progress;
            }
          })
        );
      }
    }
    
    // 等待所有扫描完成，但设置总体超时
    try {
      await Future.wait(futures).timeout(Duration(seconds: 30)); // 30秒总体超时
    } catch (e) {
      logWarning('摄像头扫描超时或出错: $e', tag: 'AntiSpy', error: e);
    }
  }
  
  /// 轻量级摄像头检测 - 快速版本
  Future<void> _lightweightCameraCheck(String ip, int port) async {
    try {
      // 快速判断是否为摄像头端口
      final isCameraPort = _isCameraPort(port);
      if (!isCameraPort) return;
      
      // 创建基础设备信息，不进行HTTP检测以节省时间
      final deviceName = _getBasicDeviceName(ip, port);
      final device = DeviceInfo(
        ip: ip,
        name: deviceName,
        type: DeviceType.camera,
        openPorts: [port],
        httpFingerprint: null, // 跳过HTTP检测以提高速度
        confidence: 0.7, // 基于端口的基础置信度
      );
      
      _addOrUpdateDevice(device);
      
      // 如果是高风险端口，直接标记为可疑
      if (_isHighRiskCameraPort(port)) {
        if (!suspiciousDevices.any((d) => d.ip == ip)) {
          suspiciousDevices.add(device);
          logWarning('🚨 发现可疑摄像头设备: $ip:$port - $deviceName', tag: 'AntiSpy');
        }
      }
      
    } catch (e) {
      logWarning('轻量级摄像头检测失败 $ip:$port - $e', tag: 'AntiSpy', error: e);
    }
  }
  
  /// 判断是否为摄像头端口
  bool _isCameraPort(int port) {
    final cameraPorts = [
      554, 1935, 8000, 8001, 8080, 8443, 8888, // 常见摄像头端口
      37777, 34567, 2000, 81, 82, 83, 84, 85, // 品牌特定端口
      8003, 8004, 8005, 8006, 8007, 8010, // 扩展摄像头端口
      9000, 9001, 9002, 9003, 9004, 9005, // 更多摄像头端口
    ];
    return cameraPorts.contains(port);
  }
  
  /// 判断是否为高风险摄像头端口
  bool _isHighRiskCameraPort(int port) {
    final highRiskPorts = [554, 37777, 34567, 1935, 8000, 8001];
    return highRiskPorts.contains(port);
  }
  
  /// 获取基础设备名称（不进行HTTP检测）
  String _getBasicDeviceName(String ip, int port) {
    switch (port) {
      case 554:
        return 'RTSP摄像头';
      case 37777:
        return '大华摄像头';
      case 34567:
        return '海康威视摄像头';
      case 1935:
        return 'RTMP摄像头';
      case 8000:
      case 8001:
        return '网络摄像头';
      default:
        return '摄像头设备';
    }
  }
  

  
  /// HTTP指纹检测
  Future<String?> _getHttpFingerprint(String ip, int port) async {
    try {
      final client = http.Client();
      
      // 尝试HTTP和HTTPS
      for (String protocol in ['http', 'https']) {
        try {
          final response = await client.get(
            Uri.parse('$protocol://$ip:$port/'),
          ).timeout(Duration(seconds: 3));
          
          // 分析HTTP响应头
          String fingerprint = _analyzeHttpResponse(response);
          client.close();
          return fingerprint;
          
        } catch (e) {
          // 继续尝试下一个协议
        }
      }
      
      client.close();
    } catch (e) {
      logWarning('HTTP指纹检测失败: $ip:$port - $e', tag: 'AntiSpy', error: e);
    }
    return null;
  }
  
  /// 分析HTTP响应
  String _analyzeHttpResponse(http.Response response) {
    List<String> fingerprints = [];
    
    // 检查服务器头
    String? server = response.headers['server'];
    if (server != null) {
      fingerprints.add('Server: $server');
      
      // 常见摄像头服务器标识
      if (server.toLowerCase().contains('hikvision') ||
          server.toLowerCase().contains('dahua') ||
          server.toLowerCase().contains('axis') ||
          server.toLowerCase().contains('vivotek') ||
          server.toLowerCase().contains('foscam') ||
          server.toLowerCase().contains('tp-link') ||
          server.toLowerCase().contains('xiaomi') ||
          server.toLowerCase().contains('camera') ||
          server.toLowerCase().contains('ipcam') ||
          server.toLowerCase().contains('webcam')) {
        fingerprints.add('CameraVendor: ${server}');
      }
    }
    
    // 检查响应体中的摄像头特征
    String body = response.body.toLowerCase();
    if (body.contains('camera') || body.contains('webcam') || 
        body.contains('ipcam') || body.contains('surveillance') ||
        body.contains('video') || body.contains('stream') ||
        body.contains('rtsp') || body.contains('onvif')) {
      fingerprints.add('CameraContent: detected');
    }
    
    // 检查常见摄像头登录页面特征
    if (body.contains('login') && (body.contains('camera') || body.contains('admin'))) {
      fingerprints.add('CameraLogin: detected');
    }
    
    return fingerprints.join('; ');
  }
  
  /// HTTP指纹扫描
  Future<void> _performHttpFingerprintScan(double startProgress, double endProgress) async {
    logDebug('开始HTTP指纹扫描...', tag: 'AntiSpy');
    
    int totalDevices = discoveredDevices.length;
    int completedDevices = 0;
    
    for (var device in discoveredDevices.toList()) {
      if (device.httpFingerprint == null && device.openPorts.isNotEmpty) {
        for (int port in device.openPorts) {
          String? fingerprint = await _getHttpFingerprint(device.ip, port);
          if (fingerprint != null) {
            // 更新设备信息
            final updatedDevice = DeviceInfo(
              ip: device.ip,
              name: device.name,
              type: device.type,
              openPorts: device.openPorts,
              httpFingerprint: fingerprint,
              confidence: device.confidence,
              discoveredAt: device.discoveredAt,
              responseTime: device.responseTime,
            );
            
            final index = discoveredDevices.indexOf(device);
            if (index != -1) {
              discoveredDevices[index] = updatedDevice;
            }
            break; // 找到一个有效指纹就够了
          }
        }
      }
      
      completedDevices++;
      final progress = startProgress + (endProgress - startProgress) * (completedDevices / totalDevices);
      scanProgress.value = progress;
    }
  }
  
  // 批量更新定时器，用于减少UI刷新频率
  int _pendingUpdateCount = 0;
  static const int _batchUpdateThreshold = 5; // 每5个设备批量更新一次
  
  /// 添加发现的设备
  void _addDiscoveredDevice(String ip, int port) {
    // 检查是否已经记录过这个IP
    final existingDevice = discoveredDevices.firstWhereOrNull(
      (device) => device.ip == ip
    );
    
    if (existingDevice == null) {
      final deviceType = _detectDeviceType(ip, port);
      final deviceName = _generateDeviceName(ip, port, deviceType);
      final device = DeviceInfo(
        ip: ip, 
        name: deviceName, 
        type: deviceType,
        openPorts: [port],
      );
      discoveredDevices.add(device);
      logDebug('🔍 端口扫描发现新设备: $ip:$port - $deviceName (总数: ${discoveredDevices.length})', tag: 'AntiSpy');
      
      // 判断是否为可疑设备（摄像头常用端口）
      if (_isSuspiciousDevice(port)) {
        suspiciousDevices.add(device);
        logWarning('⚠️ 发现可疑设备: $ip:$port - $deviceName', tag: 'AntiSpy');
      }
      
      // 🎯 批量更新UI，减少刷新频率，避免影响动画
      _pendingUpdateCount++;
      if (_pendingUpdateCount >= _batchUpdateThreshold) {
        _pendingUpdateCount = 0;
        update(); // 批量更新UI
      }
    } else {
      // 设备已存在，更新端口信息
      if (!existingDevice.openPorts.contains(port)) {
        final updatedPorts = [...existingDevice.openPorts, port];
        final newDeviceType = _detectDeviceType(ip, port);
        
        final updatedDevice = DeviceInfo(
          ip: ip,
          name: existingDevice.name,
          type: newDeviceType != DeviceType.unknown ? newDeviceType : existingDevice.type,
          openPorts: updatedPorts,
          httpFingerprint: existingDevice.httpFingerprint,
          confidence: existingDevice.confidence,
          discoveredAt: existingDevice.discoveredAt,
          responseTime: existingDevice.responseTime,
        );
        
        final index = discoveredDevices.indexOf(existingDevice);
        discoveredDevices[index] = updatedDevice;
        logDebug('🔄 更新设备端口: $ip:$port - ${updatedDevice.name}', tag: 'AntiSpy');
        
        // 重新检查是否为可疑设备
        if (_isSuspiciousDevice(port) && !suspiciousDevices.any((d) => d.ip == ip)) {
          suspiciousDevices.add(updatedDevice);
          logWarning('⚠️ 更新后发现可疑设备: $ip:$port - ${updatedDevice.name}', tag: 'AntiSpy');
        }
      }
    }
  }
  
  /// 添加或更新设备
  void _addOrUpdateDevice(DeviceInfo newDevice) {
    final existingIndex = discoveredDevices.indexWhere((d) => d.ip == newDevice.ip);
    
    if (existingIndex != -1) {
      // 合并端口信息
      final existingDevice = discoveredDevices[existingIndex];
      final mergedPorts = {...existingDevice.openPorts, ...newDevice.openPorts}.toList();
      
      final updatedDevice = DeviceInfo(
        ip: newDevice.ip,
        name: newDevice.name,
        type: newDevice.type,
        openPorts: mergedPorts,
        httpFingerprint: newDevice.httpFingerprint ?? existingDevice.httpFingerprint,
        confidence: newDevice.confidence > existingDevice.confidence ? newDevice.confidence : existingDevice.confidence,
        discoveredAt: existingDevice.discoveredAt,
        responseTime: newDevice.responseTime,
      );
      
      discoveredDevices[existingIndex] = updatedDevice;
    } else {
      discoveredDevices.add(newDevice);
    }
    
    update();
  }
  
  /// 仅根据IP地址检测设备类型（用于PING扫描）
  DeviceType _detectDeviceTypeFromIP(String ip) {
    if (_isRouterIP(ip)) return DeviceType.router;
    if (_isMobileDeviceIP(ip)) return DeviceType.phone;
    return DeviceType.unknown;
  }
  
  /// 检测设备类型 - 使用智能评分系统
  DeviceType _detectDeviceType(String ip, int port) {
    // 使用综合评分系统进行设备识别
    var portScore = _analyzePortSignature(port);
    var ipScore = _analyzeIpPattern(ip);
    
    // 端口特征权重更高，因为更准确
    if (portScore.portSignatureScore >= 0.8) {
      return portScore.suggestedType;
    }
    
    // 如果端口特征不明显，结合IP模式判断
    if (portScore.portSignatureScore >= 0.6 && ipScore.ipPatternScore >= 0.6) {
      // 两个评分都有一定置信度，选择更高的
      return portScore.portSignatureScore >= ipScore.ipPatternScore 
          ? portScore.suggestedType 
          : ipScore.suggestedType;
    }
    
    // 特殊处理通用Web端口 - 但要先检查是否为可疑设备
    if (port == 80 || port == 443 || port == 8080 || port == 8443) {
      // 如果是可疑端口，优先判断为摄像头而不是手机
      if (_isSuspiciousDevice(port)) {
        return DeviceType.camera;
      }
      
      // Web服务端口，结合IP判断
      if (_isRouterIP(ip)) return DeviceType.router;
      if (_isMobileDeviceIP(ip)) return DeviceType.phone;
      return DeviceType.unknown;
    }
    
    // 使用端口评分系统的建议
    return portScore.suggestedType != DeviceType.unknown 
        ? portScore.suggestedType 
        : (ipScore.suggestedType != DeviceType.unknown ? ipScore.suggestedType : DeviceType.unknown);
  }
  
  /// 获取MAC地址厂商信息
  
  /// 获取HTTP指纹信息
  
  
  /// 判断是否为路由器IP
  bool _isRouterIP(String ip) {
    return _isLikelyRouterIP(ip);
  }
  
  /// 更准确的路由器IP判断
  bool _isLikelyRouterIP(String ip) {
    // 常见的网关IP模式
    List<String> commonGateways = [
      '192.168.1.1', '192.168.0.1', '192.168.2.1', '192.168.3.1',
      '10.0.0.1', '10.0.1.1', '10.1.1.1', '10.10.1.1',
      '172.16.0.1', '172.16.1.1', '172.20.10.1',
      '192.168.88.1', // MikroTik默认
      '192.168.100.1', // 一些ISP默认
      '192.168.8.1', // 华为路由器默认
      '192.168.31.1', // 小米路由器默认
    ];
    
    if (commonGateways.contains(ip)) return true;
    
    // 检查是否为网段的第一个IP（通常是网关）
    List<String> parts = ip.split('.');
    if (parts.length == 4) {
      String lastOctet = parts[3];
      // .1 通常是网关，但也检查其他常见模式
      if (lastOctet == '1' || lastOctet == '254') {
        String prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
        // 检查是否为私有网段
        if (prefix.startsWith('192.168.') || 
            prefix.startsWith('10.') ||
            (prefix.startsWith('172.') && 
             int.tryParse(parts[1]) != null &&
             int.parse(parts[1]) >= 16 && int.parse(parts[1]) <= 31)) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// 判断是否可能是服务器IP
  bool _isLikelyServerIP(String ip) {
    List<String> parts = ip.split('.');
    if (parts.length == 4) {
      String lastOctet = parts[3];
      int? last = int.tryParse(lastOctet);
      if (last != null) {
        // 服务器通常使用较小的IP地址（2-50）或特定范围（100-200）
        return (last >= 2 && last <= 50) || (last >= 100 && last <= 200);
      }

    }
    return false;
  }
  
  /// 判断是否为移动设备IP（基于常见的DHCP分配模式）
  bool _isMobileDeviceIP(String ip) {
    final ipParts = ip.split('.');
    if (ipParts.length != 4) return false;
    
    final lastOctet = int.tryParse(ipParts[3]);
    if (lastOctet == null) return false;
    
    // 移动设备通常获得较高的IP地址（DHCP池后段）
    // 大多数路由器DHCP池：100-254
    if (lastOctet >= 100 && lastOctet <= 254) {
      return true;
    }
    
    // 一些路由器使用50-254作为DHCP池
    if (lastOctet >= 50 && lastOctet <= 99) {
      return true;
    }
    
    return false;
  }
  
  /// 判断是否为摄像头端口
  
  /// 生成设备名称
  String _generateDeviceName(String ip, int port, DeviceType type) {
    switch (type) {
      case DeviceType.phone:
        return '手机设备';
      case DeviceType.tablet:
        return '平板设备';
      case DeviceType.laptop:
        return '笔记本电脑';
      case DeviceType.desktop:
        return '台式电脑';
      case DeviceType.router:
        return '路由器';
      case DeviceType.printer:
        return '打印机';
      case DeviceType.camera:
        return '网络摄像头';
      case DeviceType.tv:
        return '智能电视';
      case DeviceType.speaker:
        return '智能音箱';
      case DeviceType.iot:
        return '智能设备';
      case DeviceType.server:
        return '未知设备'; // 简化：服务器也显示为未知设备
      case DeviceType.computer:
        return '未知设备'; // 简化：通用电脑也显示为未知设备
      case DeviceType.unknown:
        return '未知设备';
    }
  }
  
  
  /// 获取设备类型对应的图标
  static IconData getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.phone:
        return Icons.smartphone;
      case DeviceType.tablet:
        return Icons.tablet;
      case DeviceType.laptop:
        return Icons.laptop;
      case DeviceType.desktop:
        return Icons.desktop_windows;
      case DeviceType.router:
        return Icons.router;
      case DeviceType.printer:
        return Icons.print;
      case DeviceType.camera:
        return Icons.videocam;
      case DeviceType.tv:
        return Icons.tv;
      case DeviceType.speaker:
        return Icons.speaker;
      case DeviceType.iot:
        return Icons.devices_other;
      case DeviceType.server:
        return Icons.dns;
      case DeviceType.computer:
        return Icons.computer;
      case DeviceType.unknown:
        return Icons.device_unknown;
    }
  }
  
  
  
  /// 根据端口特征识别设备 - 优化版本
  DeviceIdentificationScore _analyzePortSignature(int port) {
    DeviceIdentificationScore score = DeviceIdentificationScore();
    
    switch (port) {
      // 手机/移动设备特征端口（最高权重）
      case 5555: // Android ADB - 最强手机特征
        score.portSignatureScore = 0.95;
        score.suggestedType = DeviceType.phone;
        break;
      case 62078: case 62079: case 62080: case 62081: // iOS设备端口
      case 5037: case 5038: case 5039: case 5040: // Android调试端口
        score.portSignatureScore = 0.9;
        score.suggestedType = DeviceType.phone;
        break;
      case 4000: case 6000: case 9999: case 1234: // 移动应用常用端口
      case 8081: case 8082: case 8083: case 8084: case 8085: // 移动开发端口
      case 3000: case 3001: case 3002: case 4001: case 4002: case 5001: case 5002:
      case 6001: case 6002: case 8002:
        score.portSignatureScore = 0.85;
        score.suggestedType = DeviceType.phone;
        break;
      
      // 电脑特征端口（高权重，但低于手机特征端口）
      case 3389: // RDP - Windows远程桌面
      case 139: case 445: // SMB文件共享
        score.portSignatureScore = 0.9;
        score.suggestedType = DeviceType.computer;
        break;
      case 5900: case 5901: case 5902: case 5903: case 5904: case 5905: // VNC
      case 135: // Windows RPC
        score.portSignatureScore = 0.85;
        score.suggestedType = DeviceType.computer;
        break;
      case 548: // AFP (macOS)
      case 88: // Kerberos
      case 389: // LDAP
      case 636: // LDAPS
      case 1433: case 1521: case 3306: case 5432: // 数据库
      case 902: case 903: case 912: // VMware
      case 2375: case 2376: // Docker
        score.portSignatureScore = 0.8;
        score.suggestedType = DeviceType.computer;
        break;
      case 22: // SSH
        score.portSignatureScore = 0.75; // 可能是电脑或服务器
        score.suggestedType = DeviceType.computer;
        break;
      case 1024: case 1025: case 1026: case 1027: case 1028: case 1029: case 1030:
      case 2049: case 2121: case 4899:
      case 27015: case 27016: case 25565: case 19132: case 7777: case 7778:
        score.portSignatureScore = 0.7;
        score.suggestedType = DeviceType.computer;
        break;
      
      // 打印机端口
      case 631: // IPP
      case 9100: // JetDirect
      case 515: // LPD
        score.portSignatureScore = 0.95;
        score.suggestedType = DeviceType.printer;
        break;
      
      // 摄像头端口 - 高置信度
      case 554: // RTSP
      case 1935: // RTMP
        score.portSignatureScore = 0.95;
        score.suggestedType = DeviceType.camera;
        break;
      case 37777: // 大华摄像头默认端口
      case 34567: // 海康威视摄像头端口
        score.portSignatureScore = 0.9;
        score.suggestedType = DeviceType.camera;
        break;
      
      // 摄像头端口 - 中等置信度
      case 8003: case 8004: case 8005: case 8006: case 8007: case 8010:
      case 9000: case 9001: case 9002: case 9003: case 9004: case 9005:
      case 10000: case 10001: case 10002: case 10003: case 10004: case 10005:
        score.portSignatureScore = 0.8;
        score.suggestedType = DeviceType.camera;
        break;
      
      // 摄像头端口 - 低置信度（也可能是其他设备）
      case 2000: case 2001: case 2002: case 2003: case 2004:
      case 6667: case 7003: case 7004: case 7005:
      case 81: case 82: case 83: case 84: case 85: case 86: case 87: case 89: case 90:
        score.portSignatureScore = 0.6;
        score.suggestedType = DeviceType.camera;
        break;
      
      // 智能电视端口
      case 8008: case 8009: // Chromecast/智能电视
        score.portSignatureScore = 0.9;
        score.suggestedType = DeviceType.tv;
        break;
      
      // 智能设备端口
      case 1900: // UPnP
      case 5353: // mDNS
        score.portSignatureScore = 0.6;
        score.suggestedType = DeviceType.iot;
        break;
      
      // 通用Web端口（低权重，需要结合其他信息判断）
      case 80: case 443: case 8080: case 8443: case 8888:
        score.portSignatureScore = 0.4; // 降低通用端口权重
        score.suggestedType = DeviceType.unknown;
        // 注意：这些端口可能是摄像头，需要在上层逻辑中特殊处理
        break;
      
      // 服务器端口
      case 23: // Telnet
      case 21: // FTP
      case 25: // SMTP
      case 53: // DNS
      case 110: // POP3
      case 143: // IMAP
      case 993: // IMAPS
      case 995: // POP3S
        score.portSignatureScore = 0.7;
        score.suggestedType = DeviceType.server;
        break;
      
      default:
        score.portSignatureScore = 0.2; // 进一步降低未知端口权重
        score.suggestedType = DeviceType.unknown;
    }
    
    return score;
  }
  
  /// 根据IP模式识别设备
  DeviceIdentificationScore _analyzeIpPattern(String ip) {
    DeviceIdentificationScore score = DeviceIdentificationScore();
    
    if (_isLikelyRouterIP(ip)) {
      score.ipPatternScore = 0.8;
      score.suggestedType = DeviceType.router;
    } else if (_isLikelyServerIP(ip)) {
      score.ipPatternScore = 0.6;
      score.suggestedType = DeviceType.server;
    } else {
      score.ipPatternScore = 0.3;
      score.suggestedType = DeviceType.unknown;
    }
    
    return score;
  }
  
  /// 综合识别设备类型
  
  // /// 综合设备分析
  // DeviceIdentificationScore _comprehensiveDeviceAnalysis(String ip, int port, String? httpFingerprint) {
  //   DeviceIdentificationScore score = DeviceIdentificationScore();
    
  //   // 1. 端口特征分析
  //   var portScore = _analyzePortSignature(port);
  //   score.portSignatureScore = portScore.portSignatureScore;
    
  //   // 2. IP模式分析
  //   var ipScore = _analyzeIpPattern(ip);
  //   score.ipPatternScore = ipScore.ipPatternScore;
    
  //   // 3. HTTP指纹分析
  //   if (httpFingerprint != null) {
  //     score.httpFingerprintScore = _analyzeHttpFingerprint(httpFingerprint);
  //   }
    
  //   // 4. 综合判断设备类型
  //   if (score.httpFingerprintScore > 0.8) {
  //     // HTTP指纹最可靠
  //     score.suggestedType = DeviceType.camera;
  //   } else if (score.portSignatureScore > 0.8) {
  //     // 端口特征次之
  //     score.suggestedType = portScore.suggestedType;
  //   } else if (score.portSignatureScore > 0.6 && score.ipPatternScore > 0.6) {
  //     // 综合判断
  //     score.suggestedType = portScore.suggestedType;
  //   } else {
  //     score.suggestedType = DeviceType.unknown;
  //   }
    
  //   return score;
  // }
  
  // /// 分析HTTP指纹
  // double _analyzeHttpFingerprint(String fingerprint) {
  //   double score = 0.0;
  //   String lowerFingerprint = fingerprint.toLowerCase();
    
  //   // 检查摄像头厂商标识
  //   if (lowerFingerprint.contains('cameravendor:')) {
  //     score += 0.9;
  //   }
    
  //   // 检查摄像头内容特征
  //   if (lowerFingerprint.contains('cameracontent:')) {
  //     score += 0.7;
  //   }
    
  //   // 检查摄像头登录页面
  //   if (lowerFingerprint.contains('cameralogin:')) {
  //     score += 0.8;
  //   }
    
  //   // 检查服务器标识中的摄像头关键词
  //   if (lowerFingerprint.contains('server:')) {
  //     if (lowerFingerprint.contains('hikvision') || 
  //         lowerFingerprint.contains('dahua') ||
  //         lowerFingerprint.contains('axis') ||
  //         lowerFingerprint.contains('vivotek') ||
  //         lowerFingerprint.contains('foscam')) {
  //       score += 0.95;
  //     } else if (lowerFingerprint.contains('camera') ||
  //                lowerFingerprint.contains('ipcam') ||
  //                lowerFingerprint.contains('webcam')) {
  //       score += 0.8;
  //     }
  //   }
    
  //   return score > 1.0 ? 1.0 : score;
  // }
  
   
  
  /// 判断是否为可疑设备
  bool _isSuspiciousDevice(int port) {
    // 摄像头和监控设备常用的端口
    final suspiciousPorts = [
      80, 443, 554, 8080, 8443, 1935, // 基础可疑端口
      8000, 8001, 8003, 8004, 8005, 8006, 8007, 8010, // 扩展摄像头端口
      37777, 34567, 2000, 2001, 2002, 2003, 2004, // 更多摄像头端口
      9000, 9001, 9002, 9003, 9004, 9005, // 高端口范围
    ];
    return suspiciousPorts.contains(port);
  }
  
  /// 完成扫描
  void _finalizeScan() {
    _stopAnimations();
    
    // 🎯 确保最后一批设备也被显示
    if (_pendingUpdateCount > 0) {
      _pendingUpdateCount = 0;
      update();
    }
    
    if (suspiciousDevices.isNotEmpty) {
      scanState.value = ScanState.suspicious;
    } else {
      scanState.value = ScanState.success;
    }
    
    scanProgress.value = 1.0;
  }
  
  /// 停止动画
  void _stopAnimations() {
    radarAnimationController.stop();
    pulseAnimationController.stop();
  }
  
  /// 重新扫描
  void restartScan() {
    _stopAnimations();
    startScan();
  }
  
  /// 返回上一页
  void onBackTap() {
    Get.back();
  }
  
  /// 打开雷达动画选择器
  void openRadarAnimationSelector() async {
    final result = await Get.to(
      () => const RadarAnimationSelectorPage(),
      transition: Transition.rightToLeft,
    );
    if (result != null && result is RadarAnimationType) {
      radarAnimationType.value = result;
    }
  }
  
  /// 测试实时更新功能
 
  /// 打开WiFi设置页面
  void openWifiSettings() async {
    try {
      // 添加小延迟确保 MethodChannel 已初始化
      await Future.delayed(const Duration(milliseconds: 100));
      await PermissionHelper.openWifiSettings();
    } catch (e) {
      logError("打开WiFi设置失败: $e", tag: 'AntiSpy', error: e);
      // 如果原生方法失败，尝试使用 url_launcher 打开设置
      try {
        // 这里可以添加备用方案，比如显示提示信息
        OKToastUtil.show("请手动前往系统设置 > WiFi 连接网络");
      } catch (e2) {
        logError("显示提示信息也失败: $e2", tag: 'AntiSpy', error: e2);
      }
    }
  }

  @override
  void onClose() {
    _scanSubscription?.cancel();
    _connectivitySubscription?.cancel();
    radarAnimationController.dispose();
    pulseAnimationController.dispose();
    super.onClose();
  }
}
 