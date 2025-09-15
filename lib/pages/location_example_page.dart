import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kissu_app/services/simple_location_service.dart';

/// 定位服务使用示例页面
/// 展示如何正确使用改进后的SimpleLocationService
class LocationExamplePage extends StatefulWidget {
  const LocationExamplePage({super.key});

  @override
  State<LocationExamplePage> createState() => _LocationExamplePageState();
}

class _LocationExamplePageState extends State<LocationExamplePage> {
  late StreamSubscription<Map<String, Object>> _locationSubscription;
  String _locationText = "等待定位...";
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initLocationService();
  }

  /// 初始化定位服务
  void _initLocationService() {
    // 初始化定位服务
    SimpleLocationService.instance.init();
    
    // 监听定位流 - 只监听一次，避免重复监听
    _locationSubscription = SimpleLocationService.instance.locationStream.listen(
      (locationData) {
        _handleLocationData(locationData);
      },
      onError: (error) {
        setState(() {
          _locationText = "定位出错: $error";
        });
        debugPrint('❌ 定位流出错: $error');
      },
    );
  }

  /// 处理定位数据
  void _handleLocationData(Map<String, Object> locationData) {
    try {
      final lat = locationData["latitude"] ?? 0;
      final lon = locationData["longitude"] ?? 0;
      final accuracy = locationData["accuracy"] ?? 0;
      final address = locationData["address"] ?? "未知地址";
      final timestamp = locationData["timestamp"] ?? 0;

      setState(() {
        _locationText = """
📍 定位信息:
纬度: $lat
经度: $lon  
精度: ${accuracy}米
地址: $address
时间: ${DateTime.fromMillisecondsSinceEpoch(int.tryParse(timestamp.toString()) ?? 0)}
        """.trim();
      });

      debugPrint('✅ 收到定位数据: 纬度=$lat, 经度=$lon, 精度=${accuracy}米');
    } catch (e) {
      debugPrint('❌ 解析定位数据失败: $e');
      setState(() {
        _locationText = "解析定位数据失败: $e";
      });
    }
  }

  /// 开始定位
  void _startLocation() {
    if (!_isListening) {
      SimpleLocationService.instance.start();
      setState(() {
        _isListening = true;
        _locationText = "正在定位...";
      });
      debugPrint('🚀 开始定位');
    }
  }

  /// 停止定位
  void _stopLocation() {
    if (_isListening) {
      SimpleLocationService.instance.stop();
      setState(() {
        _isListening = false;
        _locationText = "定位已停止";
      });
      debugPrint('⏹️ 停止定位');
    }
  }

  @override
  void dispose() {
    // 停止监听
    _locationSubscription.cancel();
    // 停止定位
    SimpleLocationService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("定位服务示例"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 定位信息显示
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _locationText,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 控制按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isListening ? null : _startLocation,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("开始定位"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isListening ? _stopLocation : null,
                    icon: const Icon(Icons.stop),
                    label: const Text("停止定位"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 状态指示器
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: _isListening ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: _isListening ? Colors.green : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isListening ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: _isListening ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isListening ? "定位服务运行中" : "定位服务已停止",
                    style: TextStyle(
                      color: _isListening ? Colors.green[800] : Colors.red[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 使用说明
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📋 使用说明",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "1. 点击'开始定位'启动定位服务\n"
                      "2. 服务会每2秒获取一次位置信息\n"
                      "3. 定位信息会实时显示在上方区域\n"
                      "4. 点击'停止定位'结束定位服务\n"
                      "5. 离开页面时会自动停止定位",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
