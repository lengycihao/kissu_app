# 🚨 快速修复：腾讯IM插件错误

## 错误
```
MissingPluginException: No implementation found for method getNetworkInfo
```

## 快速解决（5步）

### 1️⃣ 停止应用
完全关闭应用（不是热重启！）

### 2️⃣ 清理缓存
```bash
flutter clean
```

### 3️⃣ 重新获取依赖
```bash
flutter pub get
```

### 4️⃣ 完全重新运行
```bash
flutter run
```
⚠️ **重要**: 不要使用热重载/热重启！必须完全重新启动应用！

### 5️⃣ 验证
查看日志，应该看到：
```
✅ 腾讯IM SDK初始化成功
```

## 还是不行？

### 强力修复
```bash
# 清理所有缓存
flutter clean

# 清理Android构建
cd android
./gradlew clean
cd ..

# 重新获取依赖
flutter pub get

# 完全重新运行
flutter run
```

### 最终方案
1. 关闭IDE
2. 删除以下文件夹：
   - `build/`
   - `.dart_tool/`
   - `android/build/`
   - `android/app/build/`
3. 重新打开项目
4. 运行：
   ```bash
   flutter pub get
   flutter run
   ```

## 为什么会这样？

❌ **不会触发插件重新注册的操作：**
- 热重载 (Hot Reload)
- 热重启 (Hot Restart)
- 只修改Dart代码

✅ **会触发插件重新注册的操作：**
- 完全重新构建应用
- `flutter run`（完全启动）
- 构建APK/IPA

## 记住

**添加新插件后 = 必须完全重新构建！**

---
详细文档: `docs/tencent_im_plugin_error_fix.md`

