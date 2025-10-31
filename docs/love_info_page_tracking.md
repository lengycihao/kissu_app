# 恋爱信息页面埋点集成文档

## 📋 概述
本文档记录了**恋爱信息页面**（`LoveInfoPage`）的友盟埋点集成实现。恋爱信息页面用于展示和编辑用户及伴侣的个人信息，包括头像、昵称、性别、生日等。

---

## 🎯 埋点事件列表

### 1. 个人信息_性别点击埋点
**事件名称**: `my_personal_info_gender`  
**事件类型**: 点击事件  
**触发时机**: 用户选择性别并成功更新后

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `click_time` | String | 点击时间（年/月/日 时:分:秒） | "2025/10/30 14:30:25" |
| `gender` | String | 性别状态 | "男", "女" |

#### 实现位置
- **Service**: `TrackingService.trackPersonalInfoGender()`
- **Controller**: `LoveInfoController._updateUserGender()`
- **上报时机**: 性别更新成功后

### 2. 个人信息_头像点击埋点
**事件名称**: `my_personal_info_avatar`  
**事件类型**: 点击事件  
**触发时机**: 用户更换头像并上传成功后

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `click_time` | String | 点击时间（年/月/日 时:分:秒） | "2025/10/30 14:30:25" |
| `is_avatar` | String | 头像是否更换 | "是", "否" |

#### 实现位置
- **Service**: `TrackingService.trackPersonalInfoAvatar()`
- **Controller**: `LoveInfoController._uploadAvatar()`
- **上报时机**: 头像上传并更新成功后

### 3. 个人信息_年龄点击埋点
**事件名称**: `my_personal_info_birth`  
**事件类型**: 点击事件  
**触发时机**: 用户选择生日并成功更新后

#### 参数说明
| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `device_id` | String | 虚拟用户ID | "abc123..." |
| `user_id` | String | 用户ID | "12345" |
| `click_time` | String | 点击时间（年/月/日 时:分:秒） | "2025/10/30 14:30:25" |
| `birth` | String | 年龄日期 | "2000-01-15" |

#### 实现位置
- **Service**: `TrackingService.trackPersonalInfoBirth()`
- **Controller**: `LoveInfoController._updateUserBirthday()`
- **上报时机**: 生日更新成功后

---

## 🔧 实现细节

### 1. TrackingService 中的埋点方法

在 `lib/services/tracking_service.dart` 中添加了3个埋点方法：

#### 1.1 性别选择埋点
```dart
/// 埋点：个人信息_性别 - 点击事件
static Future<void> trackPersonalInfoGender({
  required String gender,
}) async {
  final params = await _buildBaseParams();
  params['gender'] = gender;
  await _trackEvent('my_personal_info_gender', params, '个人信息-性别点击');
}
```

#### 1.2 头像更换埋点
```dart
/// 埋点：个人信息_头像 - 点击事件
static Future<void> trackPersonalInfoAvatar({
  required bool isAvatarChanged,
}) async {
  final params = await _buildBaseParams();
  params['is_avatar'] = isAvatarChanged ? '是' : '否';
  await _trackEvent('my_personal_info_avatar', params, '个人信息-头像点击');
}
```

#### 1.3 生日选择埋点
```dart
/// 埋点：个人信息_年龄 - 点击事件
static Future<void> trackPersonalInfoBirth({
  required String birth,
}) async {
  final params = await _buildBaseParams();
  params['birth'] = birth;
  await _trackEvent('my_personal_info_birth', params, '个人信息-年龄点击');
}
```

### 2. LoveInfoController 中的集成

在 `lib/pages/mine/love_info/love_info_controller.dart` 中集成了埋点调用：

#### 2.1 性别选择流程
```dart
/// 更新用户性别
Future<void> _updateUserGender(String genderText) async {
  try {
    // 转换性别文本为数字
    int genderValue = genderText == '男' ? 1 : genderText == '女' ? 2 : 0;
    
    final authApi = AuthApi();
    final result = await authApi.updateUserInfo(gender: genderValue);
    
    if (result.isSuccess) {
      // 更新本地数据
      myGender.value = genderText;
      
      // 上报性别选择埋点
      await TrackingService.trackPersonalInfoGender(gender: genderText);
      
      // 更新用户缓存和刷新页面...
      CustomToast.show(Get.context!, '性别更新成功');
    }
  } catch (e) {
    CustomToast.show(Get.context!, '性别更新失败：$e');
  }
}
```

#### 2.2 头像更换流程
```dart
/// 上传头像
Future<void> _uploadAvatar(File imageFile) async {
  try {
    // 上传图片
    final fileUploadApi = FileUploadApi();
    final result = await fileUploadApi.uploadFile(imageFile);
    
    if (result.isSuccess && result.data != null) {
      // 直接更新头像URL
      myAvatar.value = result.data!;
      // 更新用户信息
      await _updateUserAvatar(result.data!);
      
      // 上报头像更换埋点（更换成功）
      await TrackingService.trackPersonalInfoAvatar(isAvatarChanged: true);
      
      CustomToast.show(Get.context!, '头像更新成功');
    }
  } catch (e) {
    CustomToast.show(Get.context!, '上传头像失败：$e');
  }
}
```

#### 2.3 生日选择流程
```dart
/// 更新用户生日
Future<void> _updateUserBirthday(DateTime birthday) async {
  try {
    final birthdayStr = _formatDate(birthday);
    final authApi = AuthApi();
    final result = await authApi.updateUserInfo(birthday: birthdayStr);
    
    if (result.isSuccess) {
      // 更新本地数据
      myBirthday.value = birthdayStr;
      
      // 上报生日选择埋点
      await TrackingService.trackPersonalInfoBirth(birth: birthdayStr);
      
      // 更新用户缓存和刷新页面...
      CustomToast.show(Get.context!, '生日更新成功');
    }
  } catch (e) {
    CustomToast.show(Get.context!, '生日更新失败：$e');
  }
}
```

---

## 🎬 触发流程

### 性别选择流程
1. **用户点击性别字段** → `onGenderTap()`
2. **弹出性别选择弹窗** → `DialogManager.showGenderSelect()`
3. **用户选择性别** → 回调 `onGenderSelected`
4. **调用更新接口** → `_updateUserGender()`
5. **更新成功后上报埋点** → `TrackingService.trackPersonalInfoGender()`

### 头像更换流程
1. **用户点击头像** → `onAvatarTap()`
2. **选择图片来源** → 相册/拍照
3. **选择图片并裁剪** → `ImageCropPage`
4. **上传图片** → `_uploadAvatar()`
5. **上传成功后上报埋点** → `TrackingService.trackPersonalInfoAvatar(isAvatarChanged: true)`

### 生日选择流程
1. **用户点击生日字段** → `onBirthdayTap()`
2. **弹出日期选择器** → `_showBirthdayPicker()`
3. **用户选择日期** → 确认选择
4. **调用更新接口** → `_updateUserBirthday()`
5. **更新成功后上报埋点** → `TrackingService.trackPersonalInfoBirth()`

---

## ✅ 验证要点

### 性别选择埋点
1. **触发时机正确**：只在性别更新成功后上报
2. **性别值正确**：gender 为 "男" 或 "女"
3. **参数完整**：device_id、user_id、click_time、gender 都正确上报

### 头像更换埋点
1. **触发时机正确**：只在头像上传成功后上报
2. **更换状态正确**：is_avatar 为 "是"（表示成功更换）
3. **参数完整**：device_id、user_id、click_time、is_avatar 都正确上报
4. **支持多种来源**：相册、拍照、系统头像都能正确上报

### 生日选择埋点
1. **触发时机正确**：只在生日更新成功后上报
2. **日期格式正确**：birth 格式为 yyyy-MM-dd（如：2000-01-15）
3. **参数完整**：device_id、user_id、click_time、birth 都正确上报

---

## 📝 注意事项

1. **只在成功时上报**：所有埋点都在 API 调用成功且本地数据更新后才上报，避免记录失败操作

2. **头像状态固定**：头像埋点的 `is_avatar` 参数固定为 "是"，因为只有成功更换才会上报

3. **日期格式统一**：生日日期格式统一使用 `_formatDate()` 方法格式化，确保格式一致

4. **异步处理**：所有埋点调用都使用 `await`，确保在页面跳转或关闭前完成上报

---

## 📝 变更日期

2025-10-30

---

## 🔗 相关文件

- `lib/services/tracking_service.dart` - 埋点服务类
- `lib/pages/mine/love_info/love_info_controller.dart` - 恋爱信息页面控制器
- `lib/pages/mine/love_info/love_info_page.dart` - 恋爱信息页面UI组件
- `api_type.md` - 埋点事件定义文档

---

## 🎯 页面功能说明

恋爱信息页面主要包含以下功能：
- **用户信息编辑**：头像、昵称、性别、生日、手机号
- **伴侣信息展示**：查看伴侣的头像、昵称、性别、生日等
- **恋爱信息展示**：在一起天数、相恋时间等
- **绑定管理**：未绑定时显示绑定入口，已绑定时显示解绑按钮

所有个人信息的修改操作都会被准确记录和上报。

