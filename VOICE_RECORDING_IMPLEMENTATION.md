# 语音录制功能实现说明

## 概述
本文档说明了聊天页面中语音录制功能的完整实现。

## 功能特性

### 1. 录音控制
- ✅ 按住录音按钮开始录音
- ✅ 松开按钮发送语音消息
- ✅ 上滑取消录音功能
- ✅ 录音时长限制（最短1秒）

### 2. 视觉反馈
- ✅ 录音中显示半透明黑色遮罩
- ✅ 录音图标动画效果
- ✅ 录音提示文字
- ✅ 取消录音时的红色警告状态

### 3. 权限管理
- ✅ 自动请求麦克风权限
- ✅ 权限拒绝时的友好提示

### 4. 文件管理
- ✅ 录音文件保存到临时目录
- ✅ 取消录音时自动删除文件
- ✅ 录音时长太短时自动删除文件

## 技术实现

### 核心组件

#### 1. ChatInputBar (输入栏)
**文件**: `lib/pages/chat/widgets/chat_input_bar.dart`

**关键功能**:
- 语音按钮的手势识别（按下、移动、抬起）
- 上滑取消检测（超过60像素触发取消状态）
- 松手时根据位置决定发送或取消

**关键代码**:
```dart
GestureDetector(
  onTapDown: (details) {
    _pressStartPosition = details.globalPosition;
    widget.onVoicePressed?.call();
  },
  onTapUp: (details) {
    if (_isCanceling) {
      widget.onVoiceCancelled?.call();
    } else {
      widget.onVoiceReleased?.call();
    }
  },
  // ... 手势处理
)
```

#### 2. ChatVoiceRecorder (录音浮层)
**文件**: `lib/pages/chat/widgets/chat_voice_recorder.dart`

**关键功能**:
- 录音中的视觉反馈（遮罩、动画、提示文字）
- 取消状态的颜色变化（白色 → 红色）
- 录音图标的缩放动画

**UI 状态**:
- 正常录音：白色图标 + "松开发送，上滑取消"
- 取消状态：红色图标 + "松开取消发送"

#### 3. ChatController (控制器)
**文件**: `lib/pages/chat/chat_controller.dart`

**核心方法**:

1. **startVoiceRecording()** - 开始录音
   - 请求麦克风权限
   - 生成临时文件路径
   - 配置录音参数（AAC编码，44.1kHz采样率）
   - 更新录音状态

2. **stopVoiceRecording()** - 结束录音并发送
   - 停止录音并获取文件路径
   - 计算录音时长
   - 验证时长（>1秒）
   - 创建语音消息并添加到消息列表

3. **cancelVoiceRecording()** - 取消录音
   - 停止录音
   - 删除录音文件
   - 重置状态

4. **updateVoiceCancelState(bool)** - 更新取消状态
   - 响应手指上滑动作
   - 更新UI显示

### 数据模型

#### ChatMessage 扩展
**文件**: `lib/pages/chat/widgets/chat_message_item.dart`

新增字段:
```dart
final int? voiceDuration;  // 语音时长(秒)
final String? voiceUrl;    // 语音文件URL/路径
```

## 依赖项

### 必需依赖
```yaml
dependencies:
  record: ^5.1.2              # 录音功能
  permission_handler: ^11.4.0  # 权限管理
  path_provider: ^2.1.5        # 文件路径
```

## 使用流程

### 用户操作流程
1. 用户点击语音图标切换到语音模式
2. 按住"按住说话"按钮开始录音
3. 说话过程中：
   - 保持按住：继续录音
   - 上滑手指：进入取消状态（UI变红）
4. 松开手指：
   - 在正常位置松开：发送语音
   - 在取消区域松开：取消录音

### 技术流程

```
按下按钮
  ↓
请求权限 → 权限被拒 → 显示提示
  ↓
权限通过
  ↓
创建录音文件 → 开始录音 → 更新UI
  ↓
用户上滑?
  ↓ Yes                ↓ No
更新为取消状态      保持正常状态
  ↓                    ↓
松开手指              松开手指
  ↓                    ↓
停止录音              停止录音
  ↓                    ↓
删除文件              检查时长
  ↓                    ↓
重置状态         时长<1秒? → 删除文件
                      ↓ No
                 创建消息 → 添加到列表
                      ↓
                  滚动到底部
```

## 待实现功能

### 服务器集成
- [ ] 录音文件上传到服务器
- [ ] 获取服务器返回的URL
- [ ] 语音消息发送API对接

### 播放功能
- [ ] 语音消息播放器
- [ ] 播放进度显示
- [ ] 播放状态管理

### 增强功能
- [ ] 录音时的音量波形显示
- [ ] 最大录音时长限制（如60秒）
- [ ] 录音倒计时提示
- [ ] 自动转文字功能

## 测试要点

### 功能测试
- [x] 录音功能是否正常
- [x] 权限请求是否正确
- [x] 取消功能是否正常
- [x] 时长限制是否生效
- [x] 文件是否正确删除

### UI测试
- [x] 录音状态UI是否正确
- [x] 取消状态UI是否正确
- [x] 动画是否流畅
- [x] 提示文字是否清晰

### 边界测试
- [ ] 录音中切到后台
- [ ] 录音中来电话
- [ ] 录音中关闭页面
- [ ] 存储空间不足
- [ ] 权限在录音中被撤销

## 注意事项

1. **权限处理**: 首次使用需要请求麦克风权限
2. **文件清理**: 取消录音和时长不足时会自动删除文件
3. **临时文件**: 录音文件保存在临时目录，后续需上传到服务器
4. **跨平台**: 使用 `record` 插件支持 iOS 和 Android
5. **性能**: 录音动画使用 `AnimationController` 确保流畅

## 文件结构

```
lib/pages/chat/
├── chat_controller.dart              # 录音逻辑控制
├── chat_page.dart                   # 页面集成
└── widgets/
    ├── chat_input_bar.dart          # 录音按钮和手势
    ├── chat_voice_recorder.dart     # 录音浮层UI
    └── chat_message_item.dart       # 消息模型（包含语音字段）
```

## 更新日志

### 2025-10-03
- ✅ 实现基础录音功能
- ✅ 实现上滑取消功能
- ✅ 添加权限管理
- ✅ 添加文件管理
- ✅ 添加时长验证
- ✅ 实现完整的UI反馈

