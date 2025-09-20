import 'package:flutter/material.dart';
import '../services/openinstall_service.dart';

/// OpenInstall 测试页面
/// 用于测试 OpenInstall 功能是否正常工作
class OpenInstallTestPage extends StatefulWidget {
  const OpenInstallTestPage({Key? key}) : super(key: key);

  @override
  State<OpenInstallTestPage> createState() => _OpenInstallTestPageState();
}

class _OpenInstallTestPageState extends State<OpenInstallTestPage> {
  String _installInfo = '正在获取安装信息...';
  String _channelCode = '';
  String _bindData = '';
  String _opid = '';
  bool _isFromOpenInstall = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initOpenInstall();
  }

  Future<void> _initOpenInstall() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 注册唤醒监听器
      OpenInstallService.registerWakeupHandler((params) {
        setState(() {
          _installInfo = '应用被唤醒，收到参数: $params';
          _channelCode = params['channelCode'] as String? ?? '';
          _bindData = params['bindData'] as String? ?? '';
        });
        _showSnackBar('应用被唤醒，收到参数: $params');
      });

      // 获取安装参数
      final params = await OpenInstallService.getInstallParams();
      if (params != null) {
        setState(() {
          _installInfo = '获取到安装参数: $params';
          _channelCode = params['channelCode'] as String? ?? '';
          _bindData = params['bindData'] as String? ?? '';
        });
      } else {
        setState(() {
          _installInfo = '未获取到安装参数';
        });
      }

      // 获取 OPID
      final opid = await OpenInstallService.getOpid();
      setState(() {
        _opid = opid ?? '未获取到OPID';
      });

      // 检查是否通过 OpenInstall 安装
      final isFromOpenInstall = await OpenInstallService.isFromOpenInstall();
      setState(() {
        _isFromOpenInstall = isFromOpenInstall;
      });

    } catch (e) {
      setState(() {
        _installInfo = '获取安装参数失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _reportRegister() async {
    try {
      await OpenInstallService.reportRegister();
      _showSnackBar('用户注册事件上报成功');
    } catch (e) {
      _showSnackBar('用户注册事件上报失败: $e');
    }
  }

  Future<void> _reportEffectPoint() async {
    try {
      await OpenInstallService.reportEffectPoint(
        pointId: 'test_button_click',
        pointValue: 1,
        extraMap: {
          'test_time': DateTime.now().toIso8601String(),
          'test_page': 'OpenInstallTestPage',
        },
      );
      _showSnackBar('效果点上报成功');
    } catch (e) {
      _showSnackBar('效果点上报失败: $e');
    }
  }

  Future<void> _reportShare() async {
    try {
      final result = await OpenInstallService.reportShare(
        shareCode: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        platform: 'WechatSession',
      );
      
      final shouldRetry = result['shouldRetry'] as bool?;
      final message = result['message'] as String?;
      
      if (shouldRetry == true) {
        _showSnackBar('分享上报失败，需要重试: $message');
      } else {
        _showSnackBar('分享上报成功');
      }
    } catch (e) {
      _showSnackBar('分享上报失败: $e');
    }
  }

  Future<void> _getChannelCode() async {
    try {
      final channelCode = await OpenInstallService.getChannelCode();
      if (channelCode != null) {
        setState(() {
          _channelCode = channelCode;
        });
        _showSnackBar('获取渠道代码成功: $channelCode');
      } else {
        _showSnackBar('未获取到渠道代码');
      }
    } catch (e) {
      _showSnackBar('获取渠道代码失败: $e');
    }
  }

  Future<void> _getBindData() async {
    try {
      final bindData = await OpenInstallService.getBindData();
      if (bindData != null) {
        setState(() {
          _bindData = bindData;
        });
        _showSnackBar('获取携带参数成功: $bindData');
      } else {
        _showSnackBar('未获取到携带参数');
      }
    } catch (e) {
      _showSnackBar('获取携带参数失败: $e');
    }
  }

  Future<void> _refreshData() async {
    await _initOpenInstall();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenInstall 测试'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 安装信息卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '安装信息',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_installInfo),
                          const SizedBox(height: 8),
                          if (_channelCode.isNotEmpty) ...[
                            Text('渠道代码: $_channelCode'),
                            const SizedBox(height: 4),
                          ],
                          if (_bindData.isNotEmpty) ...[
                            Text('携带参数: $_bindData'),
                            const SizedBox(height: 4),
                          ],
                          Text('OPID: $_opid'),
                          const SizedBox(height: 4),
                          Text('是否通过OpenInstall安装: $_isFromOpenInstall'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 功能测试按钮
                  const Text(
                    '功能测试',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 按钮网格
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.5,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _reportRegister,
                        icon: const Icon(Icons.person_add),
                        label: const Text('上报注册'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _reportEffectPoint,
                        icon: const Icon(Icons.touch_app),
                        label: const Text('上报效果点'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _reportShare,
                        icon: const Icon(Icons.share),
                        label: const Text('上报分享'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _getChannelCode,
                        icon: const Icon(Icons.tag),
                        label: const Text('获取渠道'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _getBindData,
                        icon: const Icon(Icons.data_object),
                        label: const Text('获取参数'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _refreshData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('刷新数据'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 使用说明
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
                            '1. 点击"刷新数据"按钮获取最新的安装参数\n'
                            '2. 测试各种事件上报功能\n'
                            '3. 通过OpenInstall生成的测试链接安装应用\n'
                            '4. 检查是否能正确获取渠道代码和携带参数\n'
                            '5. 测试应用唤醒功能',
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
