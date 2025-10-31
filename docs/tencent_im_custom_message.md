# 腾讯IM自定义消息处理

## 消息结构

腾讯IM的消息对象 `V2TimMessage` 包含以下字段：

### 基本字段
- `msgID` - 消息ID
- `sender` - 发送者ID
- `elemType` - 消息元素类型

### 消息内容字段
- `textElem` - 文本消息（普通文本）
- `elemList` - 消息元素列表（**自定义消息在这里**）

## 自定义消息位置

自定义消息存储在 `message.elemList` 数组中，每个元素包含：

```dart
// 消息元素
V2TimElem {
  elemType,        // 元素类型
  textElem,        // 文本元素
  customElem,      // 自定义元素 ⭐
  imageElem,       // 图片元素
  soundElem,       // 语音元素
  videoElem,       // 视频元素
  fileElem,        // 文件元素
  // ... 其他类型
}

// 自定义元素
V2TimCustomElem {
  data,            // 自定义数据（二进制数据）
  desc,            // 自定义描述
  extension,       // 自定义扩展字段
}
```

## 消息监听示例

已更新的监听器会打印详细的自定义消息信息：

```
📨 收到新消息
消息基本信息 - ID: xxx, 发送者: xxx, 类型: xxx
📋 消息包含 1 个元素
  元素[0] - 类型: custom, 自定义数据: {...}, 扩展: {...}
  🎯 自定义消息 - data: {...}, desc: xxx, extension: {...}
```

## 处理自定义消息

### 方法1: 在回调中处理

```dart
TencentIMService.instance.setOnReceiveNewMessage((messages) {
  for (var msg in messages) {
    // 检查是否有elemList
    if (msg.elemList != null && msg.elemList!.isNotEmpty) {
      for (var elem in msg.elemList!) {
        // 检查是否是自定义消息
        if (elem.customElem != null) {
          final customData = elem.customElem!.data;
          final customDesc = elem.customElem!.desc;
          final customExt = elem.customElem!.extension;
          
          print('收到自定义消息:');
          print('  数据: $customData');
          print('  描述: $customDesc');
          print('  扩展: $customExt');
          
          // 处理自定义消息...
          _handleCustomMessage(customData, customDesc, customExt);
        }
      }
    }
  }
});
```

### 方法2: 解析JSON数据

如果自定义数据是JSON格式：

```dart
import 'dart:convert';

void _handleCustomMessage(String? data, String? desc, String? extension) {
  if (data == null) return;
  
  try {
    // 解析JSON数据
    final jsonData = jsonDecode(data);
    
    // 根据不同的消息类型处理
    final messageType = jsonData['type'];
    
    switch (messageType) {
      case 'notification':
        _handleNotification(jsonData);
        break;
      case 'custom_action':
        _handleCustomAction(jsonData);
        break;
      default:
        print('未知的自定义消息类型: $messageType');
    }
  } catch (e) {
    print('解析自定义消息失败: $e');
  }
}
```

## 发送自定义消息

```dart
// 创建自定义消息
final createResult = await TencentImSDKPlugin.v2TIMManager
    .getMessageManager()
    .createCustomMessage(
      data: '{"type": "notification", "content": "你好"}',
      desc: '通知消息',
      extension: '{"priority": "high"}',
    );

if (createResult.code == 0) {
  // 发送自定义消息
  final sendResult = await TencentImSDKPlugin.v2TIMManager
      .getMessageManager()
      .sendMessage(
        receiver: '对方的unique_id',
        groupID: '',
      );
  
  if (sendResult.code == 0) {
    print('自定义消息发送成功');
  }
}
```

## 完整示例：聊天页面处理自定义消息

```dart
import 'package:flutter/material.dart';
import 'package:kissu_app/services/tencent_im_service.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'dart:convert';

class ChatPageWithCustomMessage extends StatefulWidget {
  @override
  State<ChatPageWithCustomMessage> createState() => _ChatPageWithCustomMessageState();
}

class _ChatPageWithCustomMessageState extends State<ChatPageWithCustomMessage> {
  final List<Map<String, dynamic>> _messages = [];
  
  @override
  void initState() {
    super.initState();
    _setupMessageListener();
  }
  
  void _setupMessageListener() {
    TencentIMService.instance.setOnReceiveNewMessage((messages) {
      for (var msg in messages) {
        setState(() {
          // 处理文本消息
          if (msg.textElem != null && msg.textElem!.text != null) {
            _messages.add({
              'type': 'text',
              'content': msg.textElem!.text,
              'sender': msg.sender,
              'time': DateTime.now(),
            });
          }
          
          // 处理自定义消息
          if (msg.elemList != null && msg.elemList!.isNotEmpty) {
            for (var elem in msg.elemList!) {
              if (elem.customElem != null) {
                _handleCustomMessage(elem.customElem!, msg.sender);
              }
            }
          }
        });
      }
    });
  }
  
  void _handleCustomMessage(V2TimCustomElem customElem, String? sender) {
    try {
      // 尝试解析JSON数据
      final jsonData = jsonDecode(customElem.data ?? '{}');
      
      _messages.add({
        'type': 'custom',
        'customType': jsonData['type'],
        'content': jsonData['content'],
        'sender': sender,
        'time': DateTime.now(),
        'rawData': customElem.data,
        'desc': customElem.desc,
        'extension': customElem.extension,
      });
    } catch (e) {
      print('解析自定义消息失败: $e');
      // 如果不是JSON，直接存储原始数据
      _messages.add({
        'type': 'custom',
        'content': customElem.data,
        'sender': sender,
        'time': DateTime.now(),
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('聊天')),
      body: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msg = _messages[index];
          
          if (msg['type'] == 'text') {
            return ListTile(
              title: Text(msg['sender'] ?? ''),
              subtitle: Text(msg['content'] ?? ''),
            );
          } else if (msg['type'] == 'custom') {
            return Card(
              color: Colors.blue[50],
              child: ListTile(
                leading: Icon(Icons.star),
                title: Text('自定义消息'),
                subtitle: Text(msg['content']?.toString() ?? ''),
              ),
            );
          }
          
          return Container();
        },
      ),
    );
  }
}
```

## 调试技巧

### 1. 查看日志
当收到消息时，查看日志中的详细信息：

```
📨 收到新消息
消息基本信息 - ID: xxx, 发送者: xxx, 类型: xxx
📋 消息包含 1 个元素
  元素[0] - 类型: custom, 自定义数据: {...}, 扩展: {...}
  🎯 自定义消息 - data: {...}, desc: xxx, extension: {...}
```

### 2. 打印完整消息对象
```dart
TencentIMService.instance.setOnReceiveNewMessage((messages) {
  for (var msg in messages) {
    print('完整消息对象: ${msg.toJson()}');
    
    if (msg.elemList != null) {
      for (int i = 0; i < msg.elemList!.length; i++) {
        print('元素[$i]: ${msg.elemList![i].toJson()}');
      }
    }
  }
});
```

## 常见问题

### Q: 为什么收到消息但 elemList 为空？
A: 可能是普通文本消息，检查 `textElem` 字段。

### Q: customElem.data 是什么格式？
A: 通常是字符串，可能是JSON格式，也可能是普通文本。需要根据实际情况解析。

### Q: 如何区分不同类型的自定义消息？
A: 在 data 中定义一个 `type` 字段来区分不同类型：
```json
{
  "type": "notification",
  "content": "..."
}
```

## 更新日志

- 2024-10-30: 添加自定义消息详细日志输出
- 2024-10-30: 支持 elemList 解析

