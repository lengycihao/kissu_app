# OpenInstall Deep Link 测试指南

## 一、准备工作

### 1. 确认配置
- ✅ AndroidManifest.xml 中已配置 OpenInstall scheme: `eb24o3`
- ✅ OpenInstall 服务已在隐私政策同意后初始化
- ✅ 唤醒处理器已注册

### 2. 编译安装应用
```bash
# 清理构建
flutter clean

# 重新构建
flutter build apk --debug
# 或
flutter build apk --release

# 安装到设备
flutter install
# 或使用 adb
adb install build/app/outputs/flutter-apk/app-debug.apk
```

## 二、测试方法

### 方法1：使用 adb 命令测试（推荐）

#### 1. 基础测试（测试 scheme 是否配置正确）
```bash
# 测试基本的 scheme 唤醒
adb shell am start -a android.intent.action.VIEW -d "eb24o3://test"

# 测试带路径的 scheme
adb shell am start -a android.intent.action.VIEW -d "eb24o3://home"
adb shell am start -a android.intent.action.VIEW -d "eb24o3://login"
adb shell am start -a android.intent.action.VIEW -d "eb24o3://vip"
```

#### 2. 测试带参数的链接
```bash
# 测试带查询参数的链接
adb shell am start -a android.intent.action.VIEW -d "eb24o3://home?param1=value1&param2=value2"

# 测试带路径和参数的链接
adb shell am start -a android.intent.action.VIEW -d "eb24o3://login?friendCode=123456"
```

### 方法2：使用 OpenInstall 控制台生成测试链接

1. **登录 OpenInstall 控制台**
   - 访问 https://www.openinstall.io/
   - 登录你的账号

2. **创建测试渠道**
   - 进入"渠道管理"或"H5渠道统计"
   - 创建新渠道，设置渠道名称（如：测试渠道）
   - 配置携带参数（可选）：
     - `path`: 要跳转的页面路径（如：`home`, `login`, `vip`）
     - `friendCode`: 邀请码（如：`123456`）

3. **获取测试链接**
   - 保存渠道后，会生成一个短链接
   - 复制这个链接

4. **测试链接**
   - 在手机浏览器中打开链接
   - 或在电脑浏览器中打开，然后用手机扫描二维码

### 方法3：在代码中直接测试

在应用启动后，可以在 Flutter 代码中手动触发测试：

```dart
// 在某个页面的按钮点击事件中
void testOpenInstall() async {
  // 模拟 OpenInstall 唤醒参数
  final testData = {
    'path': 'home',
    'friendCode': '123456',
    'channelCode': 'test_channel',
  };
  
  // 调用唤醒处理器
  final privacyManager = Get.find<PrivacyComplianceManager>();
  // 注意：这是私有方法，需要改为公开方法才能测试
  // privacyManager._handleOpenInstallWakeup(testData);
}
```

## 三、查看日志

### 1. 实时查看日志（推荐）

```bash
# 查看所有日志（包含 OpenInstall 相关）
adb logcat | grep -i "openinstall\|OpenInstall\|MainActivity\|GETX\|GOING TO ROUTE"

# 只看 OpenInstall 相关日志
adb logcat | grep -i "openinstall\|OpenInstall"

# 只看 MainActivity 日志
adb logcat | grep "MainActivity"

# 只看 Flutter/Dart 日志（需要应用中有 print 或 DebugUtil）
adb logcat | grep "flutter\|Dart"
```

### 2. 查看特定标签的日志

```bash
# 查看 MainActivity 的日志
adb logcat -s MainActivity

# 查看 OpenInstall 相关日志
adb logcat -s "MainActivity:*" "*:S" | grep -i "openinstall\|eb24o3"
```

### 3. 保存日志到文件

```bash
# 保存所有日志到文件
adb logcat > openinstall_test.log

# 只保存 OpenInstall 相关日志
adb logcat | grep -i "openinstall\|OpenInstall\|MainActivity\|GETX" > openinstall_test.log
```

## 四、预期日志输出

### 正常情况下的日志顺序：

1. **MainActivity 日志**（Android 原生层）
```
D/MainActivity: MainActivity onCreate
D/MainActivity: 🔔 检测到OpenInstall Intent
D/MainActivity:   - Scheme: eb24o3
D/MainActivity:   - Host: null (或具体host)
D/MainActivity:   - Path: /home (或具体path)
D/MainActivity:   - Query: param1=value1 (如果有查询参数)
D/MainActivity:   - Full URI: eb24o3://home?param1=value1
```

2. **OpenInstall 服务日志**（Flutter 层）
```
I/flutter: 🔔 OpenInstall唤醒回调被触发（应用可能还在启动中）
I/flutter: 🔔 OpenInstall唤醒参数: {path: home, friendCode: 123456, ...}
I/flutter:   - path: home
I/flutter:   - friendCode: 123456
I/flutter: 📋 从OpenInstall唤醒参数中提取到路径: home
I/flutter: 🔄 准备跳转到路由: /kisssu_app/home (原始路径: home)
I/flutter: ✅ 路由存在: /kisssu_app/home
I/flutter: ✅ OpenInstall唤醒跳转成功: /kisssu_app/home
```

3. **路由跳转日志**（GetX）
```
[GETX] GOING TO ROUTE /kisssu_app/home
```

### 异常情况下的日志：

1. **如果路由不存在**
```
I/flutter: ⚠️ 路由不存在: /kisssu_app/unknown
I/flutter: 可用路由列表:
I/flutter:   - /kisssu_app/splash
I/flutter:   - /kisssu_app/home
I/flutter:   - /kisssu_app/login
...
I/flutter: ⚠️ 路由不存在: /kisssu_app/unknown，应用正常启动到首页
```

2. **如果跳转到 /notfound**
```
[GETX] GOING TO ROUTE /notfound
```
此时应该会自动跳转到启动页，不会显示"页面不存在"。

## 五、测试检查清单

### ✅ 基础功能测试

- [ ] 应用可以通过 `eb24o3://` scheme 打开
- [ ] MainActivity 能正确接收 Intent
- [ ] OpenInstall 服务能正确初始化
- [ ] 唤醒回调能被正确触发

### ✅ 路由跳转测试

- [ ] 无路径参数时，应用正常启动到首页
- [ ] 有路径参数时，能正确跳转到对应页面
- [ ] 路径不存在时，不会显示"页面不存在"，而是跳转到启动页
- [ ] 路径映射正确（如 `home` -> `/kisssu_app/home`）

### ✅ 参数传递测试

- [ ] 邀请码（friendCode）能正确获取
- [ ] 渠道代码（channelCode）能正确获取
- [ ] 其他自定义参数能正确获取

### ✅ 边界情况测试

- [ ] 应用未安装时，链接能正常打开（跳转到应用商店或下载页）
- [ ] 应用已安装但未启动时，能正常打开并跳转
- [ ] 应用已在后台运行时，能正常打开并跳转
- [ ] 应用正在前台运行时，能正常处理唤醒

## 六、常见问题排查

### 问题1：点击链接没有反应

**可能原因：**
- scheme 配置不正确
- 应用未安装
- Intent Filter 配置错误

**解决方法：**
1. 检查 AndroidManifest.xml 中的 scheme 是否为 `eb24o3`
2. 确认应用已正确安装
3. 使用 `adb shell am start` 命令测试

### 问题2：应用打开了但显示"页面不存在"

**可能原因：**
- 路由不存在
- 路径映射不正确
- 唤醒回调未正确触发

**解决方法：**
1. 查看日志，确认唤醒参数中的路径
2. 检查路径映射逻辑是否正确
3. 确认路由表中是否存在对应路由

### 问题3：日志中没有 OpenInstall 相关输出

**可能原因：**
- OpenInstall 服务未初始化
- 隐私政策未同意
- 唤醒回调未注册

**解决方法：**
1. 确认隐私政策已同意
2. 检查 OpenInstall 服务是否已初始化
3. 查看 `PrivacyComplianceManager` 的初始化日志

### 问题4：路由跳转失败

**可能原因：**
- 应用未完全启动
- 路由系统未初始化
- 路径转换错误

**解决方法：**
1. 增加延迟时间（当前是2秒）
2. 检查路由转换逻辑
3. 查看路由存在性检查日志

## 七、快速测试脚本

创建一个测试脚本 `test_openinstall.sh`：

```bash
#!/bin/bash

echo "=== OpenInstall Deep Link 测试 ==="
echo ""

echo "1. 测试基础 scheme..."
adb shell am start -a android.intent.action.VIEW -d "eb24o3://test"
sleep 2

echo ""
echo "2. 测试跳转到首页..."
adb shell am start -a android.intent.action.VIEW -d "eb24o3://home"
sleep 2

echo ""
echo "3. 测试跳转到登录页..."
adb shell am start -a android.intent.action.VIEW -d "eb24o3://login"
sleep 2

echo ""
echo "4. 测试带邀请码的链接..."
adb shell am start -a android.intent.action.VIEW -d "eb24o3://home?friendCode=123456"
sleep 2

echo ""
echo "=== 测试完成 ==="
echo "请查看日志输出确认结果"
```

使用方法：
```bash
chmod +x test_openinstall.sh
./test_openinstall.sh
```

## 八、注意事项

1. **测试前确保应用已安装**：使用 `adb install` 或 `flutter install` 安装应用

2. **测试时查看日志**：建议在另一个终端窗口实时查看日志

3. **测试不同场景**：
   - 应用未启动时点击链接
   - 应用在后台时点击链接
   - 应用在前台时点击链接

4. **清理应用数据**：如果测试邀请码等功能，可能需要清理应用数据重新测试

```bash
adb shell pm clear com.yuluo.kissu
```

5. **检查 OpenInstall 控制台**：确认控制台中的配置是否正确

