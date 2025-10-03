# 企业微信客服集成 - 参数化调用方式

## 📋 概述

本文档说明如何使用 **参数化方式**（corpId、agentId、kfId）调用企业微信客服，而不是使用完整的链接。

## 🔑 参数说明

### 必需参数

| 参数名 | 说明 | 示例 | 获取方式 |
|--------|------|------|----------|
| `corpId` | 企业微信 CorpID (企业ID) | `wxca15128b8c388c13` | 企业微信后台 → 我的企业 → 企业信息 |
| `kfId` | 客服 ID | `kfcf77b8b4a2a2a61d9` | 企业微信后台 → 客服 → 客服账号 |

### 可选参数

| 参数名 | 说明 | 示例 | 获取方式 |
|--------|------|------|----------|
| `agentId` | 应用 AgentID | `1000002` | 企业微信后台 → 应用管理 → 应用详情 |
| `secret` | 应用密钥 Secret | `xxx...` | **仅用于服务端**，客户端不使用 |

> ⚠️ **安全提示**：`secret` 仅用于服务端获取 access_token，**绝不应**在客户端代码中使用！

## 📱 使用方法

### 1. Flutter 端调用

在你的 Flutter 代码中使用参数化方式：

```dart
import 'package:kissu_app/utils/permission_helper.dart';

void openCustomerService() {
  // 企业微信配置信息（请从企业微信后台获取）
  const String corpId = 'wxca15128b8c388c13';  // 企业微信 CorpID
  const String kfId = 'kfcf77b8b4a2a2a61d9';  // 客服 ID
  const String? agentId = null;  // 应用 AgentID (可选)

  try {
    // 使用参数化方式调用
    PermissionHelper.openWeComKfWithParams(
      corpId: corpId,
      kfId: kfId,
      agentId: agentId,
    );
  } catch (e) {
    print('无法打开企业微信客服: $e');
  }
}
```

### 2. 当前项目使用位置

**文件：** `lib/pages/mine/mine_controller.dart`

**方法：** `openContact()`

**代码：**
```dart
void openContact() {
  // 企业微信配置信息
  const String corpId = 'wxca15128b8c388c13';  // 企业微信 CorpID
  const String kfId = 'kfcf77b8b4a2a2a61d9';  // 客服 ID
  const String? agentId = null;  // 应用 AgentID (可选)

  try {
    PermissionHelper.openWeComKfWithParams(
      corpId: corpId,
      kfId: kfId,
      agentId: agentId,
    );
  } catch (e) {
     OKToastUtil.show('无法打开微信/企业微信: $e');
  }
}
```

## 🔧 原理说明

### Android 端实现

在 `MainActivity.kt` 中，参数化调用会：

1. **接收参数**：接收 `corpId`、`kfId`、`agentId`
2. **构建 URL**：内部自动构建客服链接 `https://work.weixin.qq.com/kfid/{kfId}`
3. **调用 SDK**：
   - 如果安装了企业微信 → 使用 `corpId` 注册 SDK 并打开客服
   - 如果安装了微信 → 使用微信深链接打开
   - 否则 → 降级到浏览器

**关键代码：**
```kotlin
private fun openWeComKfWithParams(corpId: String, agentId: String?, kfId: String) {
    // 构建客服URL
    val kfidUrl = "https://work.weixin.qq.com/kfid/$kfId"
    
    // 使用企业微信SDK
    val wwApi = WWAPIFactory.createWWAPI(this)
    wwApi.registerApp(corpId)  // 使用 corpId 注册
    wwApi.openUrl(kfidUrl)     // 打开客服
}
```

## 🆚 对比：参数方式 vs 链接方式

### 参数方式（推荐）

**优点：**
- ✅ 配置清晰，参数分离
- ✅ 易于维护和修改
- ✅ 符合企业微信官方推荐做法
- ✅ 支持动态切换不同客服

**调用示例：**
```dart
PermissionHelper.openWeComKfWithParams(
  corpId: 'wxca15128b8c388c13',
  kfId: 'kfcf77b8b4a2a2a61d9',
);
```

### 链接方式（仍然支持）

**优点：**
- ✅ 简单直接
- ✅ 兼容旧代码

**调用示例：**
```dart
PermissionHelper.openWeComKf(
  'https://work.weixin.qq.com/kfid/kfcf77b8b4a2a2a61d9'
);
```

## 📝 如何获取这些参数

### 1. 获取 CorpID (企业ID)

1. 登录企业微信管理后台：https://work.weixin.qq.com/
2. 进入 **我的企业** → **企业信息**
3. 找到 **企业ID** 字段，复制（格式：`wx...`）

### 2. 获取客服 ID (kfId)

1. 在企业微信管理后台
2. 进入 **客服** → **接待人员**
3. 选择或创建客服账号
4. 客服链接格式：`https://work.weixin.qq.com/kfid/XXXXX`
5. 提取最后的 `XXXXX` 部分作为 `kfId`

### 3. 获取 AgentID（可选）

1. 在企业微信管理后台
2. 进入 **应用管理**
3. 选择你的应用
4. 查看 **AgentId** 字段

### 4. 关于 Secret（仅服务端使用）

- **用途**：获取 access_token，调用企业微信服务端 API
- **获取**：企业微信后台 → 应用管理 → 应用详情 → Secret
- ⚠️ **重要**：`Secret` **绝不能**写在客户端代码中！仅在服务端使用

## 🧪 测试

### 测试参数配置

当前项目使用的测试参数：

```dart
corpId: 'wxca15128b8c388c13'
kfId: 'kfcf77b8b4a2a2a61d9'
agentId: null  // 可选，不使用
```

### 测试步骤

1. **编译运行**
   ```bash
   flutter run
   ```

2. **打开"联系我们"页面**
   - 在APP中：我的 → 联系我们

3. **点击联系客服**
   - 已安装企业微信 → 直接拉起企业微信客服
   - 已安装微信 → 通过微信深链接打开
   - 未安装 → 浏览器打开

4. **查看日志**
   ```bash
   adb logcat | grep "MainActivity"
   ```

## 🔍 常见问题

### Q1: corpId 和微信 AppID 是什么关系？

**A:** 在企业微信中，`corpId` 就是企业ID，格式类似微信的 AppID（`wx...`开头）。如果你的企业微信绑定了微信公众号/小程序，它们可能共享相同的 AppID。

### Q2: 我没有 agentId，可以不填吗？

**A:** 可以！`agentId` 是可选参数。如果不需要特定应用授权，传 `null` 即可。

### Q3: Secret 应该填在哪里？

**A:** **绝对不要**在客户端代码中使用 Secret！Secret 仅用于服务端获取 access_token。如果需要调用企业微信服务端 API，应该在后端服务器中使用。

### Q4: 如何切换不同的客服？

**A:** 只需修改 `kfId` 参数：

```dart
// 客服A
PermissionHelper.openWeComKfWithParams(
  corpId: 'wxca15128b8c388c13',
  kfId: 'kfAAAAAAAA',
);

// 客服B
PermissionHelper.openWeComKfWithParams(
  corpId: 'wxca15128b8c388c13',
  kfId: 'kfBBBBBBBB',
);
```

## 📚 相关文档

- [企业微信SDK集成总览](./wework_sdk_integration.md)
- [企业微信官方文档](https://work.weixin.qq.com/api/doc)
- [企业微信客服API文档](https://developer.work.weixin.qq.com/document/path/94670)

## ✅ 总结

使用参数化方式调用企业微信客服：

1. **获取参数**：corpId、kfId（从企业微信后台）
2. **调用方法**：`PermissionHelper.openWeComKfWithParams()`
3. **不使用链接**：无需拼接完整URL
4. **自动降级**：自动选择最佳打开方式

**代码示例：**
```dart
PermissionHelper.openWeComKfWithParams(
  corpId: 'wxca15128b8c388c13',
  kfId: 'kfcf77b8b4a2a2a61d9',
);
```

就这么简单！🎉

