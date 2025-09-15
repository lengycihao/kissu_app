import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// 定位功能测试页面
/// 综合测试定位服务的各种功能
class LocationTestPage extends StatefulWidget {
  const LocationTestPage({super.key});

  @override
  State<LocationTestPage> createState() => _LocationTestPageState();
}

class _LocationTestPageState extends State<LocationTestPage> {
  late SimpleLocationService _locationService;
  
  String _statusText = "等待开始测试...";
  String _locationInfo = "暂无位置信息";
  bool _isLoading = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _locationService = Get.find<SimpleLocationService>();
    _initializeLocationListener();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 初始化定位监听
  void _initializeLocationListener() {
    // 监听位置信息变化
    _locationService.locationStream.listen((location) {
      if (mounted) {
        setState(() {
          _locationInfo = """
📍 位置信息:
• 纬度: ${location['latitude']?.toString() ?? 'N/A'}
• 经度: ${location['longitude']?.toString() ?? 'N/A'}
• 精度: ${location['accuracy']?.toString() ?? 'N/A'}米
• 地址: ${location['formattedAddress']?.toString() ?? 'N/A'}
• 时间: ${DateTime.fromMillisecondsSinceEpoch(location['locTime'] as int? ?? 0)}
• 定位类型: ${_getLocationTypeText(location['locationType'] as int?)}
          """.trim();
        });
      }
    });
  }


  /// 获取定位类型文本
  String _getLocationTypeText(int? locationType) {
    switch (locationType) {
      case 1:
        return "GPS定位";
      case 2:
        return "前次定位";
      case 4:
        return "网络定位";
      case 5:
        return "WiFi定位";
      case 6:
        return "手机基站定位";
      case 8:
        return "离线定位";
      default:
        return "未知类型($locationType)";
    }
  }

  /// 开始基础定位测试
  void _startBasicLocationTest() async {
    setState(() {
      _isLoading = true;
      _statusText = "正在启动基础定位测试...";
    });

    try {
      final result = await _locationService.startLocation();
      final isSuccess = result;
      setState(() {
        _statusText = isSuccess ? "✅ 基础定位启动成功" : "❌ 基础定位启动失败";
        _isListening = isSuccess;
      });
    } catch (e) {
      setState(() {
        _statusText = "基础定位测试出错: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 停止定位服务
  void _stopLocationService() async {
    setState(() {
      _isLoading = true;
      _statusText = "正在停止定位服务...";
    });

    try {
      _locationService.stop();
      setState(() {
        _statusText = "✅ 定位服务已停止";
        _isListening = false;
        _locationInfo = "暂无位置信息";
      });
    } catch (e) {
      setState(() {
        _statusText = "停止定位服务出错: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 单次定位测试 - 使用独立插件实例避免Stream冲突
  void _singleLocationTest() async {
    setState(() {
      _isLoading = true;
      _statusText = "正在进行单次定位测试...";
    });

    try {
      // 使用新的testSingleLocation方法，避免Stream冲突
      final result = await _locationService.testSingleLocation();
      
      if (result != null) {
        // 解析定位结果
        double? latitude = double.tryParse(result['latitude']?.toString() ?? '');
        double? longitude = double.tryParse(result['longitude']?.toString() ?? '');
        double? accuracy = double.tryParse(result['accuracy']?.toString() ?? '');
        String? address = result['address']?.toString();
        int? locationType = int.tryParse(result['locationType']?.toString() ?? '');
        
        setState(() {
          _statusText = "✅ 单次定位成功";
          _locationInfo = """
📍 单次定位结果:
• 纬度: ${latitude?.toStringAsFixed(6) ?? 'N/A'}
• 经度: ${longitude?.toStringAsFixed(6) ?? 'N/A'}
• 精度: ${accuracy?.toStringAsFixed(2) ?? 'N/A'}米
• 定位类型: ${_getLocationTypeText(locationType)}
• 地址: ${address ?? '未获取到地址'}
• 时间: ${DateTime.now().toString().substring(0, 19)}
          """.trim();
        });
      } else {
        setState(() {
          _statusText = "❌ 单次定位失败，未获取到位置信息";
          _locationInfo = "请检查定位权限和网络连接";
        });
      }
    } catch (e) {
      setState(() {
        _statusText = "单次定位测试出错: $e";
        _locationInfo = "测试过程中发生异常";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 网络定位测试
  void _networkLocationTest() async {
    setState(() {
      _isLoading = true;
      _statusText = "正在进行网络定位测试...";
    });

    try {
      await _locationService.tryNetworkLocationOnly();
      setState(() {
        _statusText = "✅ 网络定位测试完成，请查看位置信息";
      });
    } catch (e) {
      setState(() {
        _statusText = "网络定位测试出错: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 定位诊断测试
  void _locationDiagnosticTest() async {
    setState(() {
      _isLoading = true;
      _statusText = "正在进行定位诊断...";
    });

    try {
      await _locationService.runLocationDiagnosticAndFix();
      setState(() {
        _statusText = "✅ 定位诊断完成，检查控制台输出";
      });
    } catch (e) {
      setState(() {
        _statusText = "定位诊断出错: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 重启定位服务
  void _restartLocationService() async {
    setState(() {
      _isLoading = true;
      _statusText = "正在重启定位服务...";
    });

    try {
      await _locationService.forceRestartLocation();
      setState(() {
        _statusText = "✅ 定位服务重启完成";
      });
    } catch (e) {
      setState(() {
        _statusText = "重启定位服务出错: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 权限检查测试
  void _checkPermissions() async {
    setState(() {
      _isLoading = true;
      _statusText = "正在检查权限状态...";
    });

    try {
      final locationStatus = await Permission.location.status;
      final hasPermission = locationStatus == PermissionStatus.granted;
      setState(() {
        _statusText = hasPermission 
          ? "✅ 权限检查通过，定位权限充足"
          : "❌ 权限检查失败，定位权限不足";
      });
    } catch (e) {
      setState(() {
        _statusText = "权限检查出错: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("定位功能测试"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 服务状态显示
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📊 服务状态",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                    "定位服务: ${_locationService.isServiceRunning ? '🟢 运行中' : '🔴 已停止'}",
                    style: const TextStyle(fontSize: 14),
                  )),
                  const SizedBox(height: 4),
                  FutureBuilder<PermissionStatus>(
                    future: Permission.location.status,
                    builder: (context, snapshot) {
                      final hasPermission = snapshot.data == PermissionStatus.granted;
                      return Text(
                        "权限状态: ${hasPermission ? '✅ 已授权' : '❌ 未授权'}",
                        style: const TextStyle(fontSize: 14),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "监听状态: ${_isListening ? '🔊 监听中' : '🔇 未监听'}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 状态信息显示
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📝 测试状态",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _isLoading 
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text("处理中..."),
                        ],
                      )
                    : Text(
                        _statusText,
                        style: const TextStyle(fontSize: 14),
                      ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 位置信息显示
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📍 位置信息",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _locationInfo,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 测试按钮区域
            Text(
              "🧪 测试功能",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              ),
            ),
            const SizedBox(height: 12),

            // 权限检查按钮
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkPermissions,
              icon: const Icon(Icons.security),
              label: const Text("检查定位权限"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 8),

            // 开始/停止定位按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _startBasicLocationTest,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("开始定位"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _stopLocationService,
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

            const SizedBox(height: 8),

            // 单次定位按钮
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _singleLocationTest,
              icon: const Icon(Icons.my_location),
              label: const Text("单次定位测试"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 8),

            // 网络定位按钮
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _networkLocationTest,
              icon: const Icon(Icons.wifi),
              label: const Text("网络定位测试"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 8),

            // 重启定位按钮
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _restartLocationService,
              icon: const Icon(Icons.refresh),
              label: const Text("重启定位服务"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 8),

            // 诊断按钮
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _locationDiagnosticTest,
              icon: const Icon(Icons.build),
              label: const Text("定位诊断测试"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "1. 首先点击'检查定位权限'确保权限充足\n"
                      "2. 使用'开始定位'启动持续定位监听\n"
                      "3. 使用'单次定位测试'进行一次性定位\n"
                      "4. 如果定位有问题，使用'定位诊断测试'\n"
                      "5. 必要时使用'重启定位服务'重新初始化\n"
                      "6. 查看控制台输出获取详细信息",
                      style: TextStyle(fontSize: 13),
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
