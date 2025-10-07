# 表情状态接口更新说明 - face_expire 字段

## 📅 更新时间
2025-01-07

## 🔄 更新内容

### 1. API 接口变更

#### `/get/face` - 获取表情列表（响应变更）
**新增字段：** `now_face.face_expire`

```json
{
  "now_face": {
    "class_id": 1,
    "face_expire": 1,  // ✨ 新增：有效期（小时）
    "id": 1,
    "face_url": "https://...",
    "class_name": "心情想法",
    "face_text": "亲亲",
    "create_time": 1759866624
  }
}
```

**字段说明：**
- `face_expire`：状态有效期（小时数）
- 可能的值：1, 2, 4, 6, 8, 12
- 分别对应：1小时、2小时、4小时、6小时、8小时、12小时

---

#### `/save/face` - 设置表情状态（参数变更）
**接口路径变更：** `/set/face` → `/save/face`  
**参数变更：** `hours` → `face_expire`

```json
{
  "face_id": 1,
  "face_expire": 2  // ✨ 参数名改为 face_expire（之前是 hours）
}
```

**参数说明：**
- `face_id`：表情 ID
- `face_expire`：有效期（小时），可选值：1, 2, 4, 6, 8, 12

---

## 📝 代码修改列表

### 1. 数据模型更新
**文件：** `lib/model/face_status_model.dart`

✅ `CurrentFaceStatus` 类添加 `faceExpire` 字段
```dart
class CurrentFaceStatus {
  final int faceExpire; // 新增字段
  
  CurrentFaceStatus({
    required this.faceExpire,
    // ...其他字段
  });
  
  factory CurrentFaceStatus.fromJson(Map<String, dynamic> json) {
    return CurrentFaceStatus(
      faceExpire: json['face_expire'] as int? ?? 1,
      // ...
    );
  }
}
```

---

### 2. API 接口更新
**文件：** `lib/network/public/face_status_api.dart`

✅ 参数名从 `hours` 改为 `faceExpire`
```dart
Future<HttpResultN<void>> setFaceStatus({
  required int faceId,
  required int faceExpire, // 参数名变更
}) async {
  final result = await HttpManagerN.instance.executePost(
    ApiRequest.setFaceStatus,
    jsonParam: {
      'face_id': faceId,
      'face_expire': faceExpire, // JSON 键名变更
    },
    paramEncrypt: false,
  );
  // ...
}
```

**文件：** `lib/network/public/api_request.dart`

✅ 接口路径从 `/set/face` 改为 `/save/face`
```dart
static const setFaceStatus = '/save/face'; // 路径变更
```

---

### 3. 控制器逻辑更新
**文件：** `lib/pages/location/location_state_controller.dart`

✅ 加载状态时读取 `faceExpire` 字段
```dart
if (data.nowFace != null) {
  final nowFace = data.nowFace!;
  selectedExpireHours.value = nowFace.faceExpire; // 读取 face_expire
  DebugUtil.info('✅ 当前状态: ${nowFace.faceText}, 有效期: ${nowFace.faceExpire}小时');
} else {
  selectedExpireHours.value = 1; // 无状态时重置为默认值
}
```

✅ 调用 API 时使用 `faceExpire` 参数
```dart
// 设置状态
final result = await _api.setFaceStatus(
  faceId: selectedEmoji.value!.id,
  faceExpire: selectedExpireHours.value, // 使用新参数名
);

// 更新有效期
final result = await _api.setFaceStatus(
  faceId: currentStatusId.value,
  faceExpire: hours, // 使用新参数名
);
```

---

### 4. 页面显示逻辑更新
**文件：** `lib/pages/location/location_state_page.dart`

✅ 增强状态显示判断，防止 `now_face` 为空时显示不完整的状态
```dart
Obx(() {
  // 当没有状态或状态数据不完整时，不显示
  if (!controller.hasStatus.value || 
      controller.currentStatusEmoji.value.isEmpty ||
      controller.currentStatusText.value.isEmpty) {
    return const SizedBox.shrink();
  }
  // ...显示状态区域
})
```

---

### 5. 文档更新
**文件：** `状态表情功能对接说明.md`

✅ 更新接口说明
- 接口路径：`/set/face` → `/save/face`
- 请求参数：`hours` → `face_expire`
- 响应字段：添加 `now_face.face_expire` 说明

**文件：** `api.md`

✅ 示例数据已包含 `face_expire` 字段

---

## 🎯 功能说明

### 有效期选项对应关系
| 页面显示 | face_expire 值 |
|---------|---------------|
| 1小时   | 1             |
| 2小时   | 2             |
| 4小时   | 4             |
| 6小时   | 6             |
| 8小时   | 8             |
| 12小时  | 12            |

### 业务流程
1. **获取当前状态**
   - 调用 `/get/face` 获取 `now_face`
   - 读取 `face_expire` 字段
   - 页面高亮显示对应的有效期选项

2. **设置新状态**
   - 用户选择表情和有效期
   - 调用 `/save/face`，传入 `face_expire` (1/2/4/6/8/12)
   - 保存到服务器

3. **修改有效期**
   - 用户在顶部状态区域点击新的有效期
   - 调用 `/save/face`，传入当前 `face_id` 和新的 `face_expire`
   - 更新状态有效期

---

## ✅ 测试建议

1. **获取状态测试**
   - 有状态时，检查页面是否正确高亮显示对应的有效期选项
   - 无状态时，检查是否不显示状态区域

2. **设置状态测试**
   - 选择不同的有效期选项（1/2/4/6/8/12小时）
   - 验证请求参数中的 `face_expire` 值正确

3. **修改有效期测试**
   - 在顶部状态区域修改有效期
   - 验证立即调用接口并更新

4. **边界情况测试**
   - `now_face` 为 `null` 时不显示状态区域
   - `face_expire` 字段缺失时使用默认值 1

---

## 📌 注意事项

1. ✅ 所有接口调用的参数已从 `hours` 改为 `face_expire`
2. ✅ 接口路径已从 `/set/face` 改为 `/save/face`
3. ✅ 模型已支持解析 `face_expire` 字段
4. ✅ 页面逻辑已支持显示和选择有效期
5. ✅ 边界情况已处理（空状态、字段缺失）

---

**修改完成时间：** 2025-01-07  
**涉及文件：** 5 个代码文件 + 2 个文档文件  
**测试状态：** ✅ 无 lint 错误

