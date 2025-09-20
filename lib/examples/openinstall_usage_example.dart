import 'package:flutter/material.dart';
import '../services/openinstall_service.dart';

/// OpenInstall 使用示例
/// 展示如何在应用中使用 OpenInstall 服务
class OpenInstallUsageExample {
  
  /// 示例1: 基本初始化
  static Future<void> basicInitialization() async {
    try {
      // 初始化 OpenInstall 服务
      await OpenInstallService.init();
      print('OpenInstall 初始化成功');
    } catch (e) {
      print('OpenInstall 初始化失败: $e');
    }
  }

  /// 示例2: 获取安装参数
  static Future<void> getInstallParams() async {
    try {
      // 获取安装参数（带超时）
      final params = await OpenInstallService.getInstallParamsWithTimeout(
        timeoutSeconds: 10,
      );
      
      if (params != null) {
        final channelCode = params['channelCode'] as String?;
        final bindData = params['bindData'] as String?;
        final shouldRetry = params['shouldRetry'] as bool?;
        
        print('渠道代码: $channelCode');
        print('携带参数: $bindData');
        print('是否需要重试: $shouldRetry');
        
        // 根据参数处理业务逻辑
        if (channelCode != null) {
          _handleChannelCode(channelCode);
        }
        
        if (bindData != null) {
          _handleBindData(bindData);
        }
      } else {
        print('未获取到安装参数');
      }
    } catch (e) {
      print('获取安装参数失败: $e');
    }
  }

  /// 示例3: 注册唤醒监听器
  static void registerWakeupHandler() {
    OpenInstallService.registerWakeupHandler((params) {
      print('应用被唤醒，收到参数: $params');
      
      final channelCode = params['channelCode'] as String?;
      final bindData = params['bindData'] as String?;
      
      // 处理唤醒参数
      if (channelCode != null) {
        _handleChannelCode(channelCode);
      }
      
      if (bindData != null) {
        _handleBindData(bindData);
      }
    });
  }

  /// 示例4: 上报注册事件
  static Future<void> reportUserRegister() async {
    try {
      await OpenInstallService.reportRegister();
      print('用户注册事件上报成功');
    } catch (e) {
      print('用户注册事件上报失败: $e');
    }
  }

  /// 示例5: 上报效果点
  static Future<void> reportUserAction() async {
    try {
      // 上报用户点击事件
      await OpenInstallService.reportEffectPoint(
        pointId: 'user_click_button',
        pointValue: 1,
      );
      print('用户点击事件上报成功');
    } catch (e) {
      print('用户点击事件上报失败: $e');
    }
  }

  /// 示例6: 上报带参数的效果点
  static Future<void> reportUserActionWithExtra() async {
    try {
      // 上报带额外参数的效果点
      await OpenInstallService.reportEffectPoint(
        pointId: 'user_purchase',
        pointValue: 1,
        extraMap: {
          'product_id': '12345',
          'price': '99.99',
          'currency': 'CNY',
        },
      );
      print('用户购买事件上报成功');
    } catch (e) {
      print('用户购买事件上报失败: $e');
    }
  }

  /// 示例7: 上报分享事件
  static Future<void> reportShareEvent() async {
    try {
      final result = await OpenInstallService.reportShare(
        shareCode: 'user_12345',
        platform: 'WechatSession',
      );
      
      final shouldRetry = result['shouldRetry'] as bool?;
      final message = result['message'] as String?;
      
      if (shouldRetry == true) {
        print('分享上报失败，需要重试: $message');
        // 可以在这里实现重试逻辑
      } else {
        print('分享上报成功');
      }
    } catch (e) {
      print('分享上报失败: $e');
    }
  }

  /// 示例8: 获取渠道信息
  static Future<void> getChannelInfo() async {
    try {
      final channelCode = await OpenInstallService.getChannelCode();
      if (channelCode != null) {
        print('当前渠道: $channelCode');
        _handleChannelCode(channelCode);
      } else {
        print('未获取到渠道信息');
      }
    } catch (e) {
      print('获取渠道信息失败: $e');
    }
  }

  /// 示例9: 检查是否通过 OpenInstall 安装
  static Future<void> checkInstallSource() async {
    try {
      final isFromOpenInstall = await OpenInstallService.isFromOpenInstall();
      if (isFromOpenInstall) {
        print('应用通过 OpenInstall 安装');
        // 可以在这里处理特殊的业务逻辑
      } else {
        print('应用通过其他方式安装');
      }
    } catch (e) {
      print('检查安装来源失败: $e');
    }
  }

  /// 示例10: 完整的应用启动流程
  static Future<void> completeAppStartup() async {
    try {
      // 1. 初始化 OpenInstall
      await OpenInstallService.init();
      print('OpenInstall 初始化完成');

      // 2. 注册唤醒监听器
      registerWakeupHandler();
      print('唤醒监听器注册完成');

      // 3. 获取安装参数
      final params = await OpenInstallService.getInstallParams();
      if (params != null) {
        print('获取到安装参数: $params');
        // 处理安装参数
        _processInstallParams(params);
      }

      // 4. 检查安装来源
      final isFromOpenInstall = await OpenInstallService.isFromOpenInstall();
      if (isFromOpenInstall) {
        print('应用通过 OpenInstall 安装，执行特殊逻辑');
        _handleOpenInstallInstallation();
      }

    } catch (e) {
      print('应用启动流程执行失败: $e');
    }
  }

  /// 处理渠道代码
  static void _handleChannelCode(String channelCode) {
    print('处理渠道代码: $channelCode');
    
    // 根据不同的渠道代码执行不同的逻辑
    switch (channelCode) {
      case 'wechat':
        print('来自微信渠道');
        break;
      case 'qq':
        print('来自QQ渠道');
        break;
      case 'weibo':
        print('来自微博渠道');
        break;
      default:
        print('来自其他渠道: $channelCode');
        break;
    }
  }

  /// 处理携带参数
  static void _handleBindData(String bindData) {
    print('处理携带参数: $bindData');
    
    try {
      // 假设 bindData 是 JSON 格式
      // 在实际项目中，您可能需要解析 JSON
      print('解析携带参数: $bindData');
      
      // 根据参数内容执行相应的业务逻辑
      if (bindData.contains('invite_code')) {
        print('检测到邀请码参数');
        // 处理邀请码逻辑
      }
      
      if (bindData.contains('room_id')) {
        print('检测到房间ID参数');
        // 处理房间ID逻辑
      }
    } catch (e) {
      print('处理携带参数失败: $e');
    }
  }

  /// 处理安装参数
  static void _processInstallParams(Map<String, dynamic> params) {
    final channelCode = params['channelCode'] as String?;
    final bindData = params['bindData'] as String?;
    
    if (channelCode != null) {
      _handleChannelCode(channelCode);
    }
    
    if (bindData != null) {
      _handleBindData(bindData);
    }
  }

  /// 处理通过 OpenInstall 安装的特殊逻辑
  static void _handleOpenInstallInstallation() {
    print('执行 OpenInstall 安装的特殊逻辑');
    
    // 例如：显示欢迎页面、给予特殊奖励等
    // 这里可以添加您的业务逻辑
  }
}

/// 在 Widget 中使用 OpenInstall 的示例
class OpenInstallExampleWidget extends StatefulWidget {
  @override
  _OpenInstallExampleWidgetState createState() => _OpenInstallExampleWidgetState();
}

class _OpenInstallExampleWidgetState extends State<OpenInstallExampleWidget> {
  String _installInfo = '正在获取安装信息...';
  String _channelCode = '';
  String _bindData = '';

  @override
  void initState() {
    super.initState();
    _initOpenInstall();
  }

  Future<void> _initOpenInstall() async {
    try {
      // 注册唤醒监听器
      OpenInstallService.registerWakeupHandler((params) {
        setState(() {
          _installInfo = '应用被唤醒，收到参数: $params';
          _channelCode = params['channelCode'] as String? ?? '';
          _bindData = params['bindData'] as String? ?? '';
        });
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
    } catch (e) {
      setState(() {
        _installInfo = '获取安装参数失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OpenInstall 示例'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '安装信息:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(_installInfo),
            SizedBox(height: 16),
            if (_channelCode.isNotEmpty) ...[
              Text('渠道代码: $_channelCode'),
              SizedBox(height: 8),
            ],
            if (_bindData.isNotEmpty) ...[
              Text('携带参数: $_bindData'),
              SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: () async {
                await OpenInstallService.reportRegister();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('注册事件上报成功')),
                );
              },
              child: Text('上报注册事件'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                await OpenInstallService.reportEffectPoint(
                  pointId: 'button_click',
                  pointValue: 1,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('效果点上报成功')),
                );
              },
              child: Text('上报效果点'),
            ),
          ],
        ),
      ),
    );
  }
}
