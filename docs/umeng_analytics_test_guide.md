# 友盟统计测试指南

## 🧪 测试目的

验证友盟统计集成是否正常工作，包括：
1. 初始化是否成功
2. 事件埋点是否正常上报
3. 用户ID设置是否生效
4. 页面统计是否准确

## 🚀 测试步骤

### 1. 启动应用并同意隐私政策

**操作**：
1. 启动应用
2. 在隐私政策弹窗中点击"同意"

**预期日志**：
```
D/UmengAnalytics: 友盟统计初始化成功 - AppKey: 674f7f5f7e09ea12cb5e4d1e, Channel: default
I/DebugUtil: 友盟统计已初始化
```

**检查点**：
- ✅ 看到"友盟统计初始化成功"日志
- ✅ 没有报错信息
- ✅ 初始化发生在用户同意隐私政策之后

---

### 2. 测试登录埋点

**操作**：
1. 进入登录页面
2. 输入手机号和验证码
3. 点击登录

**预期日志**：
```
D/UmengAnalytics: 记录事件: user_login_success, 参数: {login_method=sms_code, user_id=12345, user_type=normal}
D/UmengAnalytics: 设置用户ID: 12345
I/DebugUtil: 友盟统计-记录事件: user_login_success, 参数: {login_method: sms_code, user_id: 12345}
I/DebugUtil: 友盟统计-设置用户ID: 12345
```

**检查点**：
- ✅ 登录成功后记录了 `user_login_success` 事件
- ✅ 事件参数包含 `login_method`、`user_id`、`user_type`
- ✅ 用户ID被正确设置

---

### 3. 测试退出登录埋点

**操作**：
1. 进入"我的"页面
2. 点击"退出登录"按钮
3. 确认退出

**预期日志**：
```
D/UmengAnalytics: 记录事件: user_logout, 参数: {user_id=12345, logout_source=mine_page}
D/UmengAnalytics: 清除用户ID
I/DebugUtil: 友盟统计-记录事件: user_logout
I/DebugUtil: 友盟统计-清除用户ID
```

**检查点**：
- ✅ 退出登录时记录了 `user_logout` 事件
- ✅ 用户ID被清除

---

### 4. 测试页面统计（如果已实现）

**操作**：
1. 进入某个页面（如首页）
2. 停留几秒
3. 退出页面

**预期日志**：
```
D/UmengAnalytics: 页面访问开始: HomePage
D/UmengAnalytics: 页面访问结束: HomePage
```

**检查点**：
- ✅ 进入页面时记录 `onPageStart`
- ✅ 退出页面时记录 `onPageEnd`

---

## 📊 友盟后台验证

### 1. 登录友盟后台

访问：https://www.umeng.com/
- 使用注册的账号登录
- 进入"统计分析" > "自定义事件"

### 2. 查看数据

**实时数据**：
- 友盟后台一般有 **1-2 小时延迟**
- 实时数据可能需要等待一段时间才能看到

**关键指标**：
1. **自定义事件** - 查看 `user_login_success`、`user_logout` 等事件
2. **活跃用户** - 查看今日活跃用户数
3. **事件参数** - 查看事件的详细参数

### 3. 调试模式

如果需要实时查看数据上报，可以：
1. 在 Android Logcat 中过滤友盟日志
2. 使用友盟的测试设备功能（需在友盟后台配置）

---

## 🔍 常见问题排查

### 问题 1: 看不到初始化日志

**原因**：友盟统计未初始化

**排查步骤**：
1. 检查是否同意了隐私政策
2. 查看 `PrivacyComplianceManager` 的日志
3. 确认 `_enableUmengAnalytics()` 被调用

**解决方法**：
```dart
// 在隐私政策同意后，手动验证
final manager = Get.find<PrivacyComplianceManager>();
print('隐私政策状态: ${manager.isPrivacyAgreed}');
print('SDK初始化状态: ${manager.isSdkInitialized}');
```

---

### 问题 2: 事件埋点没有日志

**原因**：
1. 友盟统计未初始化
2. 代码中没有调用埋点方法

**排查步骤**：
1. 检查 `UmengAnalytics._isInitialized` 状态
2. 确认埋点代码被执行

**解决方法**：
```dart
// 添加调试日志
print('友盟是否初始化: ${UmengAnalytics._isInitialized}');
UmengAnalytics.onEvent('test_event', {'test_key': 'test_value'});
```

---

### 问题 3: 友盟后台看不到数据

**原因**：
1. 数据延迟（1-2小时）
2. AppKey 配置错误
3. 应用未上架（测试环境）

**排查步骤**：
1. 确认 AppKey 是否正确：`674f7f5f7e09ea12cb5e4d1e`
2. 等待 2 小时后再查看
3. 检查友盟后台的"测试设备"设置

---

### 问题 4: Android 编译错误

**错误信息**：
```
Unresolved reference: setUserProfile
```

**原因**：友盟 SDK 不支持 `setUserProfile` 方法

**解决方法**：
已在 `MainActivity.kt` 中处理，该方法不会实际调用友盟 API，仅做占位。

---

## ✅ 测试检查清单

- [ ] 应用启动后同意隐私政策
- [ ] 看到"友盟统计初始化成功"日志
- [ ] 登录后看到 `user_login_success` 事件日志
- [ ] 登录后看到"设置用户ID"日志
- [ ] 退出登录后看到 `user_logout` 事件日志
- [ ] 退出登录后看到"清除用户ID"日志
- [ ] Logcat 中没有友盟相关的错误日志
- [ ] 2小时后在友盟后台看到数据（可选）

---

## 📝 Logcat 过滤命令

### 查看所有友盟日志

```bash
adb logcat | grep -E "UmengAnalytics|Umeng"
```

### 查看友盟统计相关的所有日志

```bash
adb logcat -s UmengAnalytics:D DebugUtil:I
```

### 实时监控埋点

```bash
adb logcat | grep -E "记录事件|设置用户ID|清除用户ID"
```

---

## 🎯 测试用例

| 测试项 | 操作 | 预期结果 |
|--------|------|----------|
| 初始化 | 同意隐私政策 | 看到初始化成功日志 |
| 登录埋点 | 手机号登录 | 记录 login_success 事件 |
| 设置用户ID | 登录成功 | 设置用户ID成功 |
| 退出埋点 | 点击退出登录 | 记录 logout 事件 |
| 清除用户ID | 退出登录 | 清除用户ID成功 |
| 自定义事件 | 触发业务操作 | 记录对应事件 |

---

## 📞 技术支持

如果遇到问题：

1. **查看日志**：先检查 Logcat 中的友盟日志
2. **查看文档**：参考 `umeng_analytics_integration.md`
3. **友盟官方文档**：https://developer.umeng.com/docs/119267/detail/118584
4. **友盟技术支持**：在友盟后台提交工单

---

## 🔄 持续验证

建议在以下情况重新测试：

1. 更新友盟 SDK 版本后
2. 修改初始化配置后
3. 添加新的埋点后
4. 发布新版本前

---

**最后更新**: 2025-10-24

