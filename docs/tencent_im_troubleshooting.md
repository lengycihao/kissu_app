# 腾讯IM 故障排查指南

## 问题：收不到消息

### 症状
- 对方发送了消息，但我这边收不到
- `_setupMessageListener` 方法没有被调用
- 日志中看不到 "收到新消息" 的记录

### 原因分析

#### 1. 应用重启或热重载导致监听器丢失
**问题描述：**
之前的版本中，如果用户已经登录过IM，再次调用`loginIM`时会直接返回，不会重新设置消息监听器。这导致应用重启或热重载后，监听器丢失，收不到消息。

**已修复：**
现在即使用户已经登录，也会确保消息监听器被正确设置。

#### 2. IM未正确登录
**检查方法：**
```dart
TencentIMService.instance.checkIMStatus();
```

查看日志输出，确认：
- `SDK已初始化: true`
- `已登录: true`
- `当前用户ID: xxx`

#### 3. 监听器未设置
**检查方法：**
查看日志中是否有：
```
✅ 消息监听器已成功设置
```

如果没有，说明监听器设置失败。

### 解决方案

#### 方案1: 手动强制设置监听器
```dart
import 'package:kissu_app/services/tencent_im_service.dart';

// 在你的页面初始化时调用
@override
void initState() {
  super.initState();
  
  // 强制设置消息监听器
  TencentIMService.instance.forceSetupMessageListener();
  
  // 设置消息接收回调
  TencentIMService.instance.setOnReceiveNewMessage((messages) {
    print('收到消息: ${messages.length}条');
  });
}
```

#### 方案2: 检查并重新登录
```dart
final imService = TencentIMService.instance;

// 检查IM状态
imService.checkIMStatus();

// 如果未登录，重新触发登录
if (!imService.isLoggedIn) {
  // 重新获取用户信息并登录
  final authService = getIt<AuthService>();
  if (authService.currentUser != null) {
    await imService.loginIM(authService.currentUser!);
  }
}
```

#### 方案3: 完全重启IM
```dart
final imService = TencentIMService.instance;

// 1. 退出登录
await imService.logoutIM();

// 2. 卸载SDK
await imService.unInitIM();

// 3. 重新登录（会自动初始化SDK和设置监听器）
final authService = getIt<AuthService>();
if (authService.currentUser != null) {
  await imService.loginIM(authService.currentUser!);
}
```

### 调试步骤

#### 第1步：检查IM状态
```dart
TencentIMService.instance.checkIMStatus();
```

期望输出：
```
====== IM状态检查 ======
SDK已初始化: true
已登录: true
当前用户ID: 你的unique_id
新消息回调已设置: true
消息撤回回调已设置: false  // 如果你没设置撤回回调，这里是false正常
========================
```

#### 第2步：手动设置监听器
```dart
TencentIMService.instance.forceSetupMessageListener();
```

查看日志，应该看到：
```
🔄 手动强制设置消息监听器
✅ 消息监听器已成功设置
```

#### 第3步：设置回调并测试
```dart
TencentIMService.instance.setOnReceiveNewMessage((messages) {
  print('========== 收到消息 ==========');
  for (var msg in messages) {
    print('消息ID: ${msg.msgID}');
    print('发送者: ${msg.sender}');
    print('内容: ${msg.textElem?.text}');
  }
  print('============================');
});
```

让对方发送一条测试消息，查看是否能收到。

#### 第4步：查看完整日志
使用标签过滤查看IM相关的所有日志：
```bash
flutter logs | grep "TencentIMService"
```

或在代码中：
```dart
// 开启详细日志
import 'package:kissu_app/network/tools/logging/log_manager.dart';

// 查看所有IM日志
logger.info('开始监听IM消息', tag: 'TencentIMService');
```

### 常见错误及解决

#### 错误1: "IM SDK未初始化，无法添加监听器"
**原因：** SDK初始化失败或未完成

**解决：**
```dart
// 检查初始化状态
if (!TencentIMService.instance.isInitialized) {
  print('SDK未初始化，等待初始化完成');
  // 等待一段时间后再试，或重新登录
}
```

#### 错误2: 日志中看到 "IM已登录该用户" 但收不到消息
**原因：** 之前版本的bug，已经修复

**解决：** 更新到最新代码后，调用：
```dart
TencentIMService.instance.forceSetupMessageListener();
```

#### 错误3: 回调函数没有被触发
**检查：**
```dart
// 确认回调已设置
TencentIMService.instance.checkIMStatus();
// 查看 "新消息回调已设置" 是否为 true

// 如果为 false，重新设置
TencentIMService.instance.setOnReceiveNewMessage((messages) {
  // 你的处理逻辑
});
```

### 完整的初始化示例

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/services/tencent_im_service.dart';

class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _imService = TencentIMService.instance;
  
  @override
  void initState() {
    super.initState();
    _initIMListener();
  }
  
  Future<void> _initIMListener() async {
    // 1. 检查IM状态
    _imService.checkIMStatus();
    
    // 2. 等待一小段时间确保初始化完成
    await Future.delayed(Duration(milliseconds: 100));
    
    // 3. 强制设置监听器（确保一定会设置）
    _imService.forceSetupMessageListener();
    
    // 4. 设置消息接收回调
    _imService.setOnReceiveNewMessage((messages) {
      setState(() {
        for (var msg in messages) {
          print('✅ 收到新消息: ${msg.textElem?.text}');
          // 更新UI...
        }
      });
    });
    
    print('✅ IM监听器初始化完成');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('聊天'),
        actions: [
          // 添加一个调试按钮
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: () {
              _imService.checkIMStatus();
            },
          ),
        ],
      ),
      body: Container(
        // 你的聊天界面
      ),
    );
  }
}
```

### 预防措施

为了避免以后再出现收不到消息的问题：

1. **在关键页面都调用 `forceSetupMessageListener()`**
   ```dart
   @override
   void initState() {
     super.initState();
     TencentIMService.instance.forceSetupMessageListener();
   }
   ```

2. **定期检查IM状态**
   ```dart
   // 每隔一段时间检查一次
   Timer.periodic(Duration(minutes: 5), (timer) {
     TencentIMService.instance.checkIMStatus();
   });
   ```

3. **监听网络变化，重新设置监听器**
   ```dart
   // 当网络恢复时
   void onNetworkRestored() {
     TencentIMService.instance.forceSetupMessageListener();
   }
   ```

### 需要帮助？

如果按照以上步骤仍然无法解决问题：

1. 收集完整的日志（包括TencentIMService标签的所有日志）
2. 记录问题复现步骤
3. 检查对方是否真的发送成功了消息
4. 使用腾讯IM控制台查看消息记录

## 更新日志

- **2024-10-30 v1.1**: 修复了重复登录时不设置监听器的问题，添加了手动设置监听器的方法
- **2024-10-30 v1.0**: 初始版本

