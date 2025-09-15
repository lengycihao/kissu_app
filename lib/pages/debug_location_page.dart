import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:kissu_app/services/location_permission_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// 定位调试页面
/// 提供详细的定位调试信息和高级功能测试
class DebugLocationPage extends StatefulWidget {
  const DebugLocationPage({super.key});

  @override
  State<DebugLocationPage> createState() => _DebugLocationPageState();
}

class _DebugLocationPageState extends State<DebugLocationPage> {
  late SimpleLocationService _locationService;
  
  String _debugInfo = "等待调试信息...";
  String _lastError = "暂无错误";
  bool _isLoading = false;
  List<String> _locationHistory = [];
  
  @override
  void initState() {
    super.initState();
    _locationService = Get.find<SimpleLocationService>();
    _setupDebugListeners();
    _loadInitialDebugInfo();
  }

  /// 设置调试监听器
  void _setupDebugListeners() {
    // 监听位置更新
    _locationService.locationStream.listen((location) {
      if (mounted && location != null) {
        _addLocationToHistory(location);
      }
    });

    // 监听定位服务状态变化
    _locationService.isLocationEnabled.listen((isEnabled) {
      if (mounted) {
        _updateDebugInfo();
      }
    });
  }

  /// 添加位置到历史记录
  void _addLocationToHistory(Map<String, Object> location) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final latitude = location['latitude']?.toString() ?? 'N/A';
    final longitude = location['longitude']?.toString() ?? 'N/A';
    final accuracy = location['accuracy']?.toString() ?? 'N/A';
    final locationType = location['locationType'] as int?;
    final address = location['formattedAddress']?.toString() ?? 'N/A';
    final locationText = """
[$timestamp] 📍 
位置: $latitude, $longitude
精度: ${accuracy}m
类型: ${_getLocationTypeText(locationType)}
地址: ${address.length > 30 ? address.substring(0, 30) + '...' : address}
    """.trim();
    
    setState(() {
      _locationHistory.insert(0, locationText);
      if (_locationHistory.length > 10) {
        _locationHistory = _locationHistory.take(10).toList();
      }
    });
  }

  /// 获取定位类型文本
  String _getLocationTypeText(int? locationType) {
    switch (locationType) {
      case 1: return "GPS";
      case 2: return "前次";
      case 4: return "网络";
      case 5: return "WiFi";
      case 6: return "基站";
      case 8: return "离线";
      default: return "未知($locationType)";
    }
  }

  /// 加载初始调试信息
  void _loadInitialDebugInfo() async {
    await _updateDebugInfo();
  }

  /// 更新调试信息
  Future<void> _updateDebugInfo() async {
    try {
      final isRunning = _locationService.isServiceRunning;
      final locationStatus = await Permission.location.status;
      final hasPermission = locationStatus == PermissionStatus.granted;
      
      setState(() {
        _debugInfo = """
🔧 定位服务调试信息:

📊 服务状态:
• 定位服务运行: ${isRunning ? '✅ 是' : '❌ 否'}
• 权限状态: ${hasPermission ? '✅ 已授权' : '❌ 未授权'}
⚙️ 配置信息:
• 定位模式: 高精度模式
• 是否返回地址: 是
• 是否允许模拟位置: 否

🌐 网络状态:
• API Key: 已配置
• 隐私合规: 已设置
• 插件版本: AMap Flutter Location

📱 设备信息:
• 平台: ${GetPlatform.isAndroid ? 'Android' : GetPlatform.isIOS ? 'iOS' : '其他'}
• 调试模式: ${kDebugMode ? '是' : '否'}
        """.trim();
      });
    } catch (e) {
      setState(() {
        _debugInfo = "获取调试信息失败: $e";
      });
    }
  }

  /// 获取定位状态文本
  String _getLocationStateText(bool isRunning) {
    return isRunning ? "🟢 运行中" : "🔴 已停止";
  }

  /// 检查插件状态
  void _checkPluginStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _locationService.checkAMapPluginStatus();
      await _updateDebugInfo();
      _showMessage("插件状态检查完成，请查看控制台输出");
    } catch (e) {
      setState(() {
        _lastError = "插件状态检查失败: $e";
      });
      _showMessage("插件状态检查失败");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 强制重新初始化定位
  void _forceReinitialize() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 停止当前定位
      _locationService.stop();
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 重新启动定位
      await _locationService.startLocation();
      
      await _updateDebugInfo();
      _showMessage("定位服务强制重新初始化完成");
    } catch (e) {
      setState(() {
        _lastError = "强制重新初始化失败: $e";
      });
      _showMessage("强制重新初始化失败");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 测试网络连接
  void _testNetworkConnectivity() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 这里可以添加网络连接测试逻辑
      _showMessage("网络连接测试功能待实现");
    } catch (e) {
      setState(() {
        _lastError = "网络连接测试失败: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 清除定位缓存
  void _clearLocationCache() async {
    setState(() {
      _isLoading = true;
    });

    try {
      setState(() {
        _locationHistory.clear();
        _lastError = "暂无错误";
      });
      _showMessage("定位历史记录已清除");
    } catch (e) {
      setState(() {
        _lastError = "清除缓存失败: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 导出调试日志
  void _exportDebugLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final debugData = """
=== 定位调试报告 ===
生成时间: ${DateTime.now()}

$_debugInfo

📜 位置历史记录:
${_locationHistory.join('\n---\n')}

❌ 最后错误:
$_lastError

=== 报告结束 ===
      """;
      
      // 这里可以添加导出到文件的逻辑
      print("调试报告:");
      print(debugData);
      
      _showMessage("调试日志已输出到控制台");
    } catch (e) {
      setState(() {
        _lastError = "导出调试日志失败: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 显示消息
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("定位调试工具"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateDebugInfo,
            tooltip: "刷新调试信息",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 调试信息显示
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "🔧 系统调试信息",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[800],
                        ),
                      ),
                      const Spacer(),
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _debugInfo,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 位置历史记录
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
                    "📜 位置历史记录 (最近10条)",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _locationHistory.isEmpty
                    ? const Text("暂无位置历史记录")
                    : Column(
                        children: _locationHistory.map((location) => 
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Text(
                              location,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          )
                        ).toList(),
                      ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 错误信息显示
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "❌ 最后错误信息",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastError,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 高级调试功能
            Text(
              "🛠️ 高级调试功能",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              ),
            ),
            const SizedBox(height: 12),

            // 检查插件状态
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkPluginStatus,
              icon: const Icon(Icons.extension),
              label: const Text("检查插件状态"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 8),

            // 强制重新初始化
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _forceReinitialize,
              icon: const Icon(Icons.restart_alt),
              label: const Text("强制重新初始化"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 8),

            // 测试网络连接
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testNetworkConnectivity,
              icon: const Icon(Icons.network_check),
              label: const Text("测试网络连接"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 8),

            // 实用工具按钮组
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _clearLocationCache,
                    icon: const Icon(Icons.clear_all),
                    label: const Text("清除记录"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _exportDebugLogs,
                    icon: const Icon(Icons.download),
                    label: const Text("导出日志"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 调试说明
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🔍 调试说明",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "• 此页面提供定位服务的详细调试信息\n"
                      "• 位置历史记录实时更新，最多显示10条\n"
                      "• 使用'检查插件状态'诊断插件问题\n"
                      "• 如果定位完全失效，尝试'强制重新初始化'\n"
                      "• '导出日志'会将调试信息输出到控制台\n"
                      "• 所有操作都会在控制台输出详细日志",
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
