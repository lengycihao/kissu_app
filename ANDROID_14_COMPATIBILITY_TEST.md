# Android 14 兼容性测试指南

## 修复内容总结

### 1. API级别调整
- ✅ `compileSdk` 从 36 降级到 34（稳定的Android 14 API）
- ✅ `targetSdk` 从 36 降级到 34（稳定的Android 14 API）
- ✅ `minSdk` 明确设置为 23

### 2. 权限优化
- ✅ 移除 `READ_PHONE_STATE` 的 `maxSdkVersion="28"` 限制
- ✅ 添加 `FOREGROUND_SERVICE_DATA_SYNC` 权限（Android 14必需）
- ✅ 添加 `SCHEDULE_EXACT_ALARM` 权限（后台任务优化）
- ✅ 添加 `READ_MEDIA_IMAGES` 和 `READ_MEDIA_VIDEO` 权限（Android 13+）

### 3. 服务配置
- ✅ 前台服务添加 `android:permission="android.permission.BIND_JOB_SERVICE"`
- ✅ 明确指定前台服务类型：`dataSync` 和 `location`

### 4. 应用配置
- ✅ 添加 `android:dataExtractionRules` 和 `android:fullBackupContent`
- ✅ 创建数据提取和备份规则文件

## 测试步骤

### 预备条件
1. 确保开发环境配置正确：
   ```bash
   flutter doctor -v
   ```

2. 清理项目缓存：
   ```bash
   flutter clean
   flutter pub get
   cd android && ./gradlew clean
   ```

### 在Android 14设备上的测试

#### 步骤1：构建Debug版本
```bash
flutter build apk --debug
```

#### 步骤2：安装到Android 14设备
```bash
flutter install
```

#### 步骤3：启动测试
1. **冷启动测试**
   - 确保应用完全关闭
   - 点击应用图标启动
   - ✅ 应用能正常启动，显示启动页
   - ✅ 隐私政策弹窗正常显示

2. **隐私合规测试**
   - ✅ 用户未同意前不收集敏感信息
   - ✅ 用户点击"同意并继续"后功能正常
   - ✅ 第三方SDK正常初始化

3. **权限申请测试**
   - ✅ 定位权限申请正常
   - ✅ 通知权限申请正常（Android 13+）
   - ✅ 存储权限申请正常
   - ✅ 前台服务权限正常

4. **核心功能测试**
   - ✅ 用户登录/注册功能
   - ✅ 定位功能
   - ✅ 推送功能
   - ✅ 分享功能
   - ✅ 支付功能

#### 步骤4：后台/前台切换测试
1. 将应用切换到后台
2. 等待5分钟后切换回前台
3. ✅ 应用状态保持正常
4. ✅ 后台服务未被意外终止

#### 步骤5：权限撤销测试
1. 进入系统设置撤销定位权限
2. 返回应用使用定位功能
3. ✅ 应用正确处理权限被撤销的情况
4. ✅ 重新申请权限流程正常

### 构建Release版本测试

#### 步骤1：构建Release APK
```bash
flutter build apk --release
```

#### 步骤2：安装Release版本
```bash
# 卸载debug版本
adb uninstall com.yuluo.kissu
# 安装release版本
adb install build/app/outputs/flutter-apk/app-release.apk
```

#### 步骤3：完整功能测试
重复上述所有测试步骤，确保Release版本功能正常。

## 常见问题排查

### 问题1：应用无法启动
**可能原因：**
- API级别不兼容
- 权限配置错误
- 服务配置错误

**排查方法：**
```bash
adb logcat | grep -E "(FATAL|ERROR|AndroidRuntime)"
```

### 问题2：权限申请失败
**可能原因：**
- 权限声明缺失
- 权限申请逻辑错误
- Android 14新限制

**排查方法：**
```bash
adb logcat | grep -i permission
```

### 问题3：后台服务被杀死
**可能原因：**
- 前台服务类型未正确配置
- 缺少必要的权限声明

**排查方法：**
```bash
adb logcat | grep -E "(Service|Foreground)"
```

## 提交前检查清单

- [ ] 应用在Android 14设备上正常启动
- [ ] 隐私政策弹窗正常显示和处理
- [ ] 所有权限申请正常工作
- [ ] 核心功能（登录、定位、推送、分享、支付）正常
- [ ] 后台/前台切换正常
- [ ] Release版本测试通过
- [ ] 日志中无致命错误
- [ ] 应用符合小米市场审核要求

## 成功标准

1. **启动成功率：100%**
2. **功能完整性：100%**
3. **权限合规性：100%**
4. **性能稳定性：无崩溃**

完成以上所有测试后，应用应该能在Android 14上稳定运行，并通过小米市场的兼容性审核。
