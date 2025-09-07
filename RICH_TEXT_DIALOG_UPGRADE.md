# ToastDialog 富文本功能升级

## 🎯 功能概述

升级了`ToastDialog.showDialogWithCloseButton`方法，支持富文本内容和可点击链接功能。

## ✨ 新增功能

### 1. 富文本支持
- 自动识别文本中的`《协议名称》`格式
- 将协议名称设置为可点击链接
- 链接颜色：#FF7C98（粉色）
- 支持下划线装饰

### 2. 灵活的内容类型
- **String**: 普通文本或包含协议的文本
- **Widget**: 自定义富文本组件
- 自动识别并适配不同类型

### 3. 点击回调处理
- 提供`onLinkTap`回调函数
- 传递被点击的协议名称
- 支持自定义跳转逻辑

## 🔧 API 变更

### 方法签名
```dart
static Future<void> showDialogWithCloseButton(
  BuildContext context,
  String title,
  dynamic content,        // ✨ 新：支持String或Widget
  VoidCallback onConfirm,
  {
    double height = 300.0,
    Function(String)? onLinkTap,  // ✨ 新：链接点击回调
  }
)
```

### 参数说明
| 参数 | 类型 | 说明 |
|------|------|------|
| `content` | `dynamic` | 支持String或Widget，String会自动解析富文本 |
| `onLinkTap` | `Function(String)?` | 链接点击回调，参数为协议名称 |

## 💡 使用示例

### 1. 基本富文本使用
```dart
ToastDialog.showDialogWithCloseButton(
  context,
  '温馨提示',
  '为了更好的保障你的权益，请阅读并同意《用户协议》和《隐私协议》后进行登录',
  () {
    // 确认回调
  },
  onLinkTap: (linkName) {
    // 处理链接点击
    switch (linkName) {
      case '用户协议':
        // 跳转到用户协议页面
        break;
      case '隐私协议':
        // 跳转到隐私协议页面
        break;
    }
  },
);
```

### 2. 普通文本使用
```dart
ToastDialog.showDialogWithCloseButton(
  context,
  '提示',
  '这是普通文本，没有链接',
  () {
    // 确认回调
  },
);
```

### 3. 自定义Widget使用
```dart
ToastDialog.showDialogWithCloseButton(
  context,
  '自定义内容',
  RichText(
    text: TextSpan(
      children: [
        TextSpan(text: '自定义的'),
        TextSpan(
          text: '富文本内容',
          style: TextStyle(color: Colors.red),
        ),
      ],
    ),
  ),
  () {
    // 确认回调
  },
);
```

## 🎨 样式规范

### 链接样式
- **颜色**: #FF7C98（粉色）
- **装饰**: 下划线
- **字体大小**: 14px
- **点击效果**: 自定义回调处理

### 普通文本样式
- **颜色**: #333333（深灰）
- **字体大小**: 14px
- **对齐**: 居中

## 🔍 实现原理

### 1. 文本解析
```dart
// 使用正则表达式分割文本
final parts = content.split(RegExp(r'《([^》]+)》'));
```

### 2. TextSpan构建
```dart
// 为每个部分创建对应的TextSpan
for (int i = 0; i < parts.length; i++) {
  if (i % 2 == 0) {
    // 普通文本
    spans.add(TextSpan(text: parts[i], style: normalStyle));
  } else {
    // 链接文本
    spans.add(TextSpan(
      text: '《${parts[i]}》',
      style: linkStyle,
      recognizer: TapGestureRecognizer()..onTap = () => onLinkTap(parts[i]),
    ));
  }
}
```

### 3. 手势识别
使用`TapGestureRecognizer`为链接添加点击事件处理。

## 📋 修改文件清单

1. ✅ `lib/utils/toast_toalog.dart`
   - 添加富文本支持
   - 新增链接点击处理
   - 添加gestures导入

2. ✅ `lib/pages/login/login_controller.dart`
   - 更新弹窗调用
   - 添加链接处理方法
   - 支持协议页面跳转

## 🔄 向前兼容性

### ✅ 完全兼容
- 原有的普通文本调用无需修改
- 新参数都是可选的
- 保持原有的视觉效果

### 📈 扩展性
- 支持更多协议格式
- 可扩展自定义样式
- 易于添加新的链接类型

## 🧪 测试建议

1. **普通文本**: 验证原有功能正常
2. **富文本**: 验证协议链接可点击
3. **样式**: 验证颜色和下划线正确
4. **回调**: 验证点击事件正确触发

现在您的弹窗支持富文本和可点击链接了！🎉
