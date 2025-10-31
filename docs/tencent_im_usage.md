# 腾讯IM集成使用说明

## 概述

本项目已集成腾讯云IM SDK，用于实现即时通讯功能。

### SDK配置信息
- **SDKAppID**: `1600095370`
- **UserID**: 登录后返回的 `unique_id`
- **UserSig**: 登录后返回的 `im_sign`

## 自动集成

IM服务已经集成到登录流程中，无需手动初始化和登录。

### 登录时自动处理
当用户登录成功时，系统会自动：
1. 初始化IM SDK
2. 使用 `unique_id` 和 `im_sign` 登录IM
3. 设置用户资料（昵称和头像）
4. 设置消息监听器

### 退出时自动处理
当用户退出登录或注销账号时，系统会自动：
1. 移除消息监听器
2. 清除所有回调
3. 退出IM登录
4. 清理相关资源

## 使用方法

### 1. 监听新消息

在你的页面或Controller中设置消息接收回调：

```dart
import 'package:kissu_app/services/tencent_im_service.dart';

class ChatController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    
    // 设置新消息接收回调
    TencentIMService.instance.setOnReceiveNewMessage((messages) {
      for (var msg in messages) {
        print('收到新消息:');
        print('  消息ID: ${msg.msgID}');
        print('  发送者: ${msg.sender}');
        print('  文本内容: ${msg.textElem?.text}');
        print('  消息类型: ${msg.elemType}');
        
        // 处理消息...
        _handleNewMessage(msg);
      }
    });
  }
  
  void _handleNewMessage(V2TimMessage message) {
    // 你的消息处理逻辑
    // 例如：更新UI、显示通知等
  }
  
  @override
  void onClose() {
    // 页面关闭时清除回调（可选）
    // TencentIMService.instance.clearCallbacks();
    super.onClose();
  }
}
```

### 2. 监听消息撤回

```dart
TencentIMService.instance.setOnRecvMessageRevoked((msgID) {
  print('消息被撤回: $msgID');
  
  // 处理消息撤回
  // 例如：从列表中移除该消息或显示"消息已撤回"
});
```

### 3. 发送文本消息

#### 发送单聊消息

```dart
final imService = TencentIMService.instance;

// 发送给对方（使用对方的unique_id）
final result = await imService.sendTextMessage(
  receiverID: '对方的unique_id',
  text: '你好，这是一条测试消息',
  isGroup: false, // 单聊
);

if (result?.code == 0) {
  print('消息发送成功');
  print('消息ID: ${result?.data?.msgID}');
} else {
  print('消息发送失败: ${result?.desc}');
}
```

#### 发送群聊消息

```dart
final result = await imService.sendTextMessage(
  receiverID: '群组ID',
  text: '大家好',
  isGroup: true, // 群聊
);
```

### 4. 检查IM状态

```dart
final imService = TencentIMService.instance;

// 检查是否已初始化
if (imService.isInitialized) {
  print('IM SDK已初始化');
}

// 检查是否已登录
if (imService.isLoggedIn) {
  print('IM已登录');
  print('当前用户ID: ${imService.currentUserID}');
}
```

### 5. 完整示例：聊天页面

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/services/tencent_im_service.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';

class ChatPage extends StatefulWidget {
  final String receiverID; // 对方的unique_id
  final String receiverName; // 对方的昵称

  const ChatPage({
    Key? key,
    required this.receiverID,
    required this.receiverName,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final List<V2TimMessage> _messages = [];
  final _imService = TencentIMService.instance;

  @override
  void initState() {
    super.initState();
    _setupMessageListener();
  }

  void _setupMessageListener() {
    // 设置新消息监听
    _imService.setOnReceiveNewMessage((messages) {
      setState(() {
        _messages.addAll(messages);
      });
      
      // 滚动到底部
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    // 滚动逻辑...
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // 发送消息
    final result = await _imService.sendTextMessage(
      receiverID: widget.receiverID,
      text: text,
    );

    if (result?.code == 0) {
      // 发送成功，添加到列表
      setState(() {
        _messages.add(result!.data!);
      });
      
      // 清空输入框
      _textController.clear();
      
      // 滚动到底部
      _scrollToBottom();
    } else {
      // 发送失败，显示错误
      Get.snackbar('发送失败', result?.desc ?? '未知错误');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ListTile(
                  title: Text(msg.sender ?? ''),
                  subtitle: Text(msg.textElem?.text ?? ''),
                );
              },
            ),
          ),
          
          // 输入框
          Container(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: '输入消息...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: Text('发送'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    // 注意：不要在这里清除全局回调，因为其他页面可能还在使用
    super.dispose();
  }
}
```

## 注意事项

### 1. 消息监听器的生命周期
- 消息监听器在IM登录成功后自动设置
- 在IM退出登录时自动移除
- 不建议手动移除全局监听器，除非你确定不再需要接收消息

### 2. 回调函数的管理
- 使用 `setOnReceiveNewMessage` 设置的回调是全局的
- 如果多个页面都设置了回调，最后设置的会覆盖之前的
- 建议在一个统一的地方（如ChatService）管理消息回调

### 3. UserID 和 UserSig
- UserID 使用登录后返回的 `unique_id`
- UserSig 使用登录后返回的 `im_sign`
- 这两个值由后端生成，前端无需处理

### 4. 错误处理
- 所有IM操作都有完善的错误日志
- 可以通过查看日志（tag: 'TencentIMService'）来排查问题
- 发送消息等操作会返回结果，需要检查 `code` 是否为 0

## 高级功能

如需实现更多功能（如图片消息、语音消息、会话列表等），请参考腾讯云IM官方文档：
https://cloud.tencent.com/document/product/269/96059

## 常见问题

### Q: IM登录失败怎么办？
A: 检查以下几点：
1. 确保已经成功登录应用（获得了 unique_id 和 im_sign）
2. 检查网络连接
3. 查看日志确认错误原因

### Q: 收不到消息怎么办？
A: 检查以下几点：
1. 确保已设置消息接收回调
2. 确认IM已成功登录（`isLoggedIn` 为 true）
3. 检查对方是否成功发送了消息

### Q: 如何获取历史消息？
A: 可以使用 `TencentImSDKPlugin.v2TIMManager.getMessageManager().getHistoryMessageList()` 方法获取历史消息。

## 更新日志

- 2024-10-30: 初始集成，支持基本的消息收发功能

