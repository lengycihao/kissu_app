# 分享功能使用文档

## 概述

本应用集成了友盟+分享SDK，支持分享到微信好友、微信朋友圈、QQ等平台。

## 功能特性

- ✅ 微信好友分享
- ✅ 微信朋友圈分享  
- ✅ QQ分享
- ✅ 支持文字、图片、链接等多种内容类型
- ✅ 自动检测目标应用是否已安装
- ✅ 符合友盟+合规要求

## 快速开始

### 1. 获取ShareService实例

```dart
final shareService = Get.find<ShareService>();
```

### 2. 基础分享方法

#### 分享纯文本
```dart
// 分享纯文本到微信好友
await shareService.shareTextToWeChat("要分享的文本内容");

// 分享纯文本到QQ
await shareService.shareTextToQQ("要分享的文本内容");
```

#### 分享图片
```dart
// 分享本地图片到微信
await shareService.shareImageToWeChat("/path/to/image.jpg");

// 分享本地图片到QQ  
await shareService.shareImageToQQ("/path/to/image.jpg");
```

### 3. 高级分享（推荐）

#### 分享链接卡片到微信
```dart
await shareService.shareToWeChat(
  title: "Kissu - 你的专属社交应用",        // 卡片标题
  text: "发现更多有趣的人和事，开启精彩社交生活", // 卡片描述
  img: "https://kissu.app/logo.png",    // 缩略图URL
  weburl: "https://kissu.app",          // 点击跳转链接
  sharemedia: 0  // 0=微信好友, 1=微信朋友圈
);
```

#### 分享链接卡片到QQ
```dart
await shareService.shareToQQ(
  title: "Kissu - 你的专属社交应用",
  text: "发现更多有趣的人和事，开启精彩社交生活", 
  img: "https://kissu.app/logo.png",
  weburl: "https://kissu.app"
);
```

## 参数说明

### shareToWeChat 参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| title | String | 是 | 分享卡片的标题 |
| text | String | 是 | 分享卡片的描述文字 |
| img | String | 否 | 缩略图URL（网络图片链接） |
| weburl | String | 是 | 点击卡片后跳转的网页链接 |
| sharemedia | int | 是 | 分享目标：0=微信好友，1=微信朋友圈 |

### shareToQQ 参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| title | String | 是 | 分享卡片的标题 |
| text | String | 是 | 分享卡片的描述文字 |
| img | String | 否 | 缩略图URL（网络图片链接） |
| weburl | String | 是 | 点击卡片后跳转的网页链接 |

## 实际使用示例

### 1. 分享用户动态
```dart
class PostController extends GetxController {
  final shareService = Get.find<ShareService>();
  
  // 分享动态到微信朋友圈
  Future<void> sharePostToMoments(Post post) async {
    await shareService.shareToWeChat(
      title: "来自${post.author}的精彩动态",
      text: post.content.length > 50 
        ? "${post.content.substring(0, 50)}..." 
        : post.content,
      img: post.images.isNotEmpty ? post.images.first : null,
      weburl: "https://kissu.app/post/${post.id}",
      sharemedia: 1  // 朋友圈
    );
  }
}
```

### 2. 分享应用邀请
```dart
class InviteController extends GetxController {
  final shareService = Get.find<ShareService>();
  
  // 邀请好友下载应用
  Future<void> inviteFriend() async {
    await shareService.shareToWeChat(
      title: "Kissu邀请你一起玩",
      text: "我在用Kissu，超好玩的社交应用，快来一起玩吧！",
      img: "https://kissu.app/invite_banner.png",
      weburl: "https://kissu.app/download?invite=${user.inviteCode}",
      sharemedia: 0  // 微信好友
    );
  }
}
```

### 3. 检查应用安装状态
```dart
// 检查微信是否安装
bool isWeChatInstalled = await shareService.checkWeChatInstalled();
if (!isWeChatInstalled) {
  Get.snackbar("提示", "请先安装微信应用");
  return;
}

// 检查QQ是否安装  
bool isQQInstalled = await shareService.checkQQInstalled();
if (!isQQInstalled) {
  Get.snackbar("提示", "请先安装QQ应用");
  return;
}
```

## 注意事项

### 1. 图片要求
- 缩略图必须使用网络图片URL，不支持本地图片路径
- 建议图片尺寸：200x200 ~ 500x500像素
- 支持格式：JPG、PNG、GIF
- 图片大小建议控制在1MB以内

### 2. 文本限制
- 标题建议控制在30字以内
- 描述文字建议控制在100字以内
- 过长的文本可能会被截断

### 3. URL要求
- weburl必须是完整的HTTP/HTTPS链接
- 建议使用HTTPS协议
- 确保链接可正常访问

### 4. 权限配置
应用已配置好相关权限和Activity，无需额外设置：
- 微信分享回调：`WXEntryActivity`
- 微信支付回调：`WXPayEntryActivity`  
- QQ分享回调：`QQEntryActivity`

## 错误处理

### 常见错误及解决方案

1. **应用未安装**
   ```dart
   // 分享前检查应用是否安装
   if (!await shareService.checkWeChatInstalled()) {
     Get.snackbar("错误", "微信未安装");
     return;
   }
   ```

2. **网络图片加载失败**
   ```dart
   // 使用默认图片作为备选
   String imageUrl = post.image ?? "https://kissu.app/default_share.png";
   ```

3. **分享被取消**
   ```dart
   try {
     await shareService.shareToWeChat(...);
     Get.snackbar("成功", "分享成功");
   } catch (e) {
     Get.snackbar("提示", "分享被取消");
   }
   ```

## 最佳实践

### 1. 用户体验优化
```dart
// 显示分享选项底部弹窗
void showShareBottomSheet(Post post) {
  Get.bottomSheet(
    Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("分享到", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareOption(
                icon: Icons.wechat,
                label: "微信好友",
                onTap: () => _shareToWeChatFriend(post),
              ),
              _buildShareOption(
                icon: Icons.moments,
                label: "朋友圈", 
                onTap: () => _shareToWeChatMoments(post),
              ),
              _buildShareOption(
                icon: Icons.qq,
                label: "QQ",
                onTap: () => _shareToQQ(post),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
```

### 2. 分析和统计
```dart
// 记录分享行为
Future<void> shareWithAnalytics(String platform, String contentType) async {
  // 执行分享
  await shareService.shareToWeChat(...);
  
  // 记录分析数据
  Analytics.track('share_content', {
    'platform': platform,
    'content_type': contentType,
    'timestamp': DateTime.now().toIso8601String(),
  });
}
```

## 技术支持

如遇到问题，请检查：
1. 友盟+控制台配置是否正确
2. Android Manifest权限配置
3. 第三方应用签名配置
4. 网络连接状态

更多技术细节请参考 [友盟+官方文档](https://developer.umeng.com/docs/128606/detail/193653)
