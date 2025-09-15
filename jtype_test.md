
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';
import 'package:kissu_app/services/simple_location_service.dart';

/// 定位测试页面 - 用于调试定位问题
class LocationTestPage extends StatefulWidget {
  const LocationTestPage({super.key});

  @override
  State<LocationTestPage> createState() => _LocationTestPageState();
}

class _LocationTestPageState extends State<LocationTestPage> {
  final AMapFlutterLocation _locationPlugin = AMapFlutterLocation();
  final SimpleLocationService _locationService = SimpleLocationService.instance;
  
  final List<String> _logs = [];
  Map<String, Object>? _currentLocation;
  bool _isLocationRunning = false;
  StreamSubscription<Map<String, Object>>? _testLocationSub;

  @override
  void initState() {
    super.initState();
    _addLog('页面初始化完成');
  }

  @override
  void dispose() {
    _testLocationSub?.cancel();
    _locationPlugin.stopLocation();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_logs.length > 50) {
        _logs.removeLast();
      }
    });
    debugPrint('LocationTest: $message');
  }

  /// 检查权限状态
  Future<void> _checkPermissions() async {
    _addLog('=== 开始检查权限 ===');
    
    try {
      final locationStatus = await Permission.location.status;
      _addLog('基础定位权限: ${locationStatus.name}');
      
      final backgroundLocationStatus = await Permission.locationAlways.status;
      _addLog('后台定位权限: ${backgroundLocationStatus.name}');
      
      final notificationStatus = await Permission.notification.status;
      _addLog('通知权限: ${notificationStatus.name}');
      
    } catch (e) {
      _addLog('检查权限失败: $e');
    }
  }

  /// 请求权限
  Future<void> _requestPermissions() async {
    _addLog('=== 开始请求权限 ===');
    
    try {
      // 请求基础定位权限
      var locationStatus = await Permission.location.request();
      _addLog('基础定位权限请求结果: ${locationStatus.name}');
      
      if (locationStatus.isGranted) {
        // 请求后台定位权限
        var backgroundStatus = await Permission.locationAlways.request();
        _addLog('后台定位权限请求结果: ${backgroundStatus.name}');
      }
      
    } catch (e) {
      _addLog('请求权限失败: $e');
    }
  }

  /// 初始化高德定位
  Future<void> _initAMapLocation() async {
    _addLog('=== 初始化高德定位 ===');
    
    try {
      // 设置隐私合规
      AMapFlutterLocation.updatePrivacyShow(true, true);
      AMapFlutterLocation.updatePrivacyAgree(true);
      _addLog('隐私合规设置完成');
      
      // 设置API密钥
      AMapFlutterLocation.setApiKey('38edb925a25f22e3aae2f86ce7f2ff3b', '');
      _addLog('API密钥设置完成');
      
      // 设置定位参数
      AMapLocationOption locationOption = AMapLocationOption();
      locationOption.locationMode = AMapLocationMode.Hight_Accuracy;
      locationOption.needAddress = true;
      locationOption.onceLocation = false;
      locationOption.locationInterval = 2000;
      locationOption.distanceFilter = 10;
      
      _locationPlugin.setLocationOption(locationOption);
      _addLog('定位参数设置完成');
      
    } catch (e) {
      _addLog('初始化高德定位失败: $e');
    }
  }

  /// 开始单次定位测试
  Future<void> _startSingleLocationTest() async {
    _addLog('=== 开始单次定位测试 ===');
    
    try {
      // 检查权限
      final locationStatus = await Permission.location.status;
      if (!locationStatus.isGranted) {
        _addLog('定位权限未授予，无法进行定位测试');
        return;
      }
      
      // 先停止定位服务以避免Stream冲突
      if (_locationService.isLocationEnabled.value) {
        _addLog('⚠️ 检测到定位服务正在运行，先停止以避免冲突');
        _locationService.stopLocation();
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      await _initAMapLocation();
      
      // 取消之前的监听器
      await _testLocationSub?.cancel();
      
      // 监听定位结果
      _testLocationSub = _locationPlugin.onLocationChanged().listen((result) {
        _addLog('收到定位结果:');
        result.forEach((key, value) {
          _addLog('  $key: $value');
        });
        
        setState(() {
          _currentLocation = result;
        });
      }, onError: (error) {
        _addLog('定位错误: $error');
      });
      
      // 开始定位
      _locationPlugin.startLocation();
      _addLog('定位已启动，等待结果...');
      
      // 10秒后停止
      Future.delayed(const Duration(seconds: 10), () {
        _locationPlugin.stopLocation();
        _testLocationSub?.cancel();
        _testLocationSub = null;
        _addLog('单次定位测试结束');
      });
      
    } catch (e) {
      _addLog('单次定位测试失败: $e');
    }
  }

  /// 测试定位服务
  Future<void> _testLocationService() async {
    _addLog('=== 测试定位服务 ===');
    
    try {
      if (_isLocationRunning) {
        _locationService.stopLocation();
        _addLog('定位服务已停止');
        setState(() {
          _isLocationRunning = false;
        });
      } else {
        final success = await _locationService.startLocation();
        _addLog('定位服务启动结果: $success');
        setState(() {
          _isLocationRunning = success;
        });
        
        // 监听定位变化
        _locationService.currentLocation.listen((location) {
          if (location != null) {
            _addLog('定位服务收到位置: lat=${location.latitude}, lng=${location.longitude}');
          }
        });
      }
      
    } catch (e) {
      _addLog('测试定位服务失败: $e');
    }
  }

  /// 清空日志
  void _clearLogs() {
    setState(() {
      _logs.clear();
      _currentLocation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('定位测试'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 控制按钮区域
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _checkPermissions,
                  child: const Text('检查权限'),
                ),
                ElevatedButton(
                  onPressed: _requestPermissions,
                  child: const Text('请求权限'),
                ),
                ElevatedButton(
                  onPressed: _startSingleLocationTest,
                  child: const Text('单次定位测试'),
                ),
                ElevatedButton(
                  onPressed: _testLocationService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLocationRunning ? Colors.red : Colors.green,
                  ),
                  child: Text(_isLocationRunning ? '停止定位服务' : '启动定位服务'),
                ),
                ElevatedButton(
                  onPressed: _clearLogs,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('清空日志'),
                ),
              ],
            ),
          ),
          
          // 当前位置信息
          if (_currentLocation != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('当前位置信息:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('纬度: ${_currentLocation!['latitude'] ?? 'N/A'}'),
                  Text('经度: ${_currentLocation!['longitude'] ?? 'N/A'}'),
                  Text('精度: ${_currentLocation!['accuracy'] ?? 'N/A'}m'),
                  Text('地址: ${_currentLocation!['address'] ?? 'N/A'}'),
                  Text('时间: ${_currentLocation!['callbackTime'] ?? 'N/A'}'),
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          
          // 日志区域
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '调试日志:',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            _logs[index],
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

```