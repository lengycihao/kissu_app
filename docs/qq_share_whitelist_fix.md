# QQ分享错误901309解决方案

## 问题描述
QQ分享时出现错误：**"分享链接不在官网配置的分享链接范围内 901309"**

## 问题原因
QQ开放平台要求所有分享的链接域名必须在**白名单**中配置，否则会拒绝分享请求。
错误码 `901309` 表示您分享的URL域名未在QQ互联官网的白名单中。

## 解决步骤

### 1. 登录QQ互联管理中心
访问：https://connect.qq.com/manage.html

### 2. 找到您的应用
- AppID: `102797447`
- AppKey: `c5KJ2VipiMRMCpJf`

### 3. 配置白名单域名

进入应用管理后台，找到以下配置项之一：
- **网站回调域**
- **分享域名白名单**
- **授权回调域**（移动应用中）

### 4. 添加域名到白名单

根据代码中使用的分享链接，需要添加以下域名：

```
www.ikissu.cn
ikissu.cn
```

**注意事项：**
- 只需要填写域名，不需要 `https://` 前缀
- 如果有子域名，建议同时添加带 www 和不带 www 的版本
- 保存后等待 5-10 分钟生效

### 5. 验证配置

配置生效后，运行应用测试QQ分享功能。查看日志输出：

```
🔗 QQ分享链接: https://www.ikissu.cn/share/matchingcode.html?bindCode=xxx
🔗 分享链接域名需要在QQ开放平台配置白名单
```

确认分享的域名已在白名单中。

## 当前代码中的分享链接

### 1. 匹配码分享
```dart
// lib/widgets/share_bottom_sheet.dart
'https://www.ikissu.cn/share/matchingcode.html?bindCode=$matchCode'
```

### 2. APP分享
```dart
// lib/widgets/share_bottom_sheet.dart
"${shareConfig?.sharePage}?bindCode=${user?.friendCode ?? '1000000'}"
```
服务器返回的 `sharePage` 域名也需要在白名单中。

## 常见问题

### Q: 配置后还是报错怎么办？
A: 
1. 确认已等待 5-10 分钟让配置生效
2. 检查域名拼写是否正确（不要有多余空格）
3. 尝试重启应用
4. 查看调试日志确认分享的实际URL

### Q: 需要配置其他内容吗？
A: 
除了白名单域名，还需要确保：
- QQ AppID 和 AppKey 配置正确
- AndroidManifest.xml 中的回调Activity配置正确（已配置）
- 应用签名与QQ开放平台后台一致

### Q: 如何查看服务器返回的分享链接？
A: 
运行应用后查看控制台日志，搜索 "🔗 QQ分享链接" 即可看到实际分享的URL。

## 相关文件

- `lib/services/share_service.dart` - 分享服务配置
- `lib/widgets/share_bottom_sheet.dart` - 分享弹窗组件
- `android/app/src/main/AndroidManifest.xml` - QQ回调配置
- `android/app/src/main/kotlin/com/yuluo/kissu/MainActivity.kt` - QQ SDK初始化

## 参考资料

- [QQ互联官方文档](https://wiki.connect.qq.com/)
- [友盟分享文档](https://developer.umeng.com/docs/128606/detail/193653)

