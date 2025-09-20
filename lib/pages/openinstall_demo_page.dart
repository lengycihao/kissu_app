import 'package:flutter/material.dart';
import '../services/openinstall_service.dart';

/// OpenInstall 功能演示页面
class OpenInstallDemoPage extends StatefulWidget {
  const OpenInstallDemoPage({super.key});

  @override
  State<OpenInstallDemoPage> createState() => _OpenInstallDemoPageState();
}

class _OpenInstallDemoPageState extends State<OpenInstallDemoPage> {
  Map<String, dynamic>? _installParams;
  String? _channelCode;
  String? _bindData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInstallParams();
    _registerWakeupHandler();
  }

  /// 加载安装参数
  Future<void> _loadInstallParams() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取安装参数
      final params = await OpenInstallService.getInstallParamsWithTimeout(
        timeoutSeconds: 10,
      );
      
      if (params != null) {
        setState(() {
          _installParams = params;
          _channelCode = params['channelCode'] as String?;
          _bindData = params['bindData'] as String?;
        });
      } else {
        setState(() {
          _installParams = null;
          _channelCode = null;
          _bindData = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取安装参数失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 注册唤醒监听器
  void _registerWakeupHandler() {
    OpenInstallService.registerWakeupHandler((params) {
      if (mounted) {
        setState(() {
          _installParams = params;
          _channelCode = params['channelCode'] as String?;
          _bindData = params['bindData'] as String?;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('应用被唤醒，收到新参数'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  /// 上报注册事件
  Future<void> _reportRegister() async {
    await OpenInstallService.reportRegister();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('注册事件上报成功'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// 上报效果点
  Future<void> _reportEffectPoint() async {
    await OpenInstallService.reportEffectPoint(
      pointId: 'demo_click',
      pointValue: 1,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('效果点上报成功'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenInstall 演示'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            const Text(
              'OpenInstall 功能演示',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // 安装参数信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '安装参数信息',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else ...[
                      _buildInfoRow('渠道代码', _channelCode ?? '无'),
                      _buildInfoRow('携带参数', _bindData ?? '无'),
                      _buildInfoRow('完整参数', _installParams?.toString() ?? '无'),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 功能按钮
            const Text(
              '功能测试',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loadInstallParams,
                    child: const Text('重新获取参数'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _reportRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('上报注册'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _reportEffectPoint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('上报效果点'),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 说明文字
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '使用说明',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. 渠道代码：用于统计不同渠道的安装量\n'
                      '2. 携带参数：可以携带自定义参数进行安装\n'
                      '3. 注册事件：用户注册时调用，用于统计转化率\n'
                      '4. 效果点：用于统计用户行为，如点击、购买等',
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
