# 聊天页面更多功能菜单优化

## 📋 需求说明

1. **更多菜单展示方式**：从原来的弹出菜单改为抽屉式展示，显示在右上角按钮下方
2. **视觉设计**：
   - 背景图：`kissu3_chat_more_bg.webp` (88×58)
   - 修改备注图标：`kissu3_chat_remark.webp` (13×13)
   - 更换背景图标：`kissu3_chat_picture.webp` (13×13)
   - 文字颜色：12pt `#6D383E`
3. **功能实现**：完整实现更换背景功能

---

## ✅ 实现内容

### 1️⃣ **更多菜单组件重构** (`chat_more_menu.dart`)

#### 原设计
- 使用系统 `showMenu` 弹出菜单
- 使用 Material Icons
- 白色背景，标准列表样式

#### 新设计（抽屉式）
```dart
class ChatMoreMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 58,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/chat/kissu3_chat_more_bg.webp'),
          fit: BoxFit.fill,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _menuItems.map((item) => _buildMenuItem(item)).toList(),
      ),
    );
  }
}
```

#### 菜单项设计
```dart
Widget _buildMenuItem(MoreMenuItem item) {
  return GestureDetector(
    onTap: () => onItemTap?.call(item.type),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          item.iconAsset,  // 使用自定义图标
          width: 13,
          height: 13,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 4),
        Text(
          item.label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xff6D383E),  // 设计稿颜色
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ),
  );
}
```

#### 显示方式（Overlay）
```dart
static void show(BuildContext context, {
  required Offset position,
  Function(MoreMenuType)? onItemTap,
}) {
  final overlay = Overlay.of(context);
  OverlayEntry? overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        // 点击外部区域关闭
        GestureDetector(
          onTap: () => overlayEntry?.remove(),
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // 菜单内容（显示在按钮下方）
        Positioned(
          left: position.dx - 88,  // 右对齐到按钮
          top: position.dy,
          child: Material(
            color: Colors.transparent,
            child: ChatMoreMenu(onItemTap: (type) {
              overlayEntry?.remove();
              onItemTap?.call(type);
            }),
          ),
        ),
      ],
    ),
  );

  overlay.insert(overlayEntry);
}
```

---

### 2️⃣ **更新菜单显示位置** (`chat_page.dart`)

```dart
void _showMoreMenu(BuildContext context) {
  // 获取按钮位置
  final RenderBox button = context.findRenderObject() as RenderBox;
  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  
  // 获取按钮在屏幕上的位置
  final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
  final buttonSize = button.size;
  
  // 计算菜单显示位置：在按钮右下方
  ChatMoreMenu.show(
    context,
    position: Offset(
      buttonPosition.dx + buttonSize.width,  // 右对齐到按钮右边
      buttonPosition.dy + buttonSize.height + 4,  // 按钮下方，留4像素间隙
    ),
    onItemTap: controller.handleMoreMenuAction,
  );
}
```

**效果**：
- ✅ 菜单显示在右上角"更多"按钮正下方
- ✅ 右边缘对齐到按钮右边缘
- ✅ 与按钮保持4像素间距
- ✅ 点击外部区域自动关闭

---

### 3️⃣ **实现更换背景功能** (`chat_controller.dart`)

#### 预设背景列表
```dart
final List<String> backgroundOptions = [
  '',  // 无背景
  'assets/chat/kissu3_chat_bg.webp',
  'assets/3.0/kissu3_picture_wall.webp',
];
```

#### 背景选择对话框
```dart
void _showChangeBackgroundDialog() async {
  await Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择聊天背景', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            // 预设背景选项
            ...backgroundOptions.asMap().entries.map((entry) {
              return _buildBackgroundOption(entry.value, 
                label: entry.key == 0 ? '无背景' : '背景 ${entry.key}',
                isSelected: backgroundImage.value == entry.value,
              );
            }),
            // 从相册选择
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xffBA92FD)),
              title: const Text('从相册选择'),
              onTap: () {
                Get.back();
                _pickBackgroundFromGallery();
              },
            ),
            // 取消按钮
            TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          ],
        ),
      ),
    ),
  );
}
```

#### 背景选项预览
```dart
Widget _buildBackgroundOption(String bgPath, {
  required String label, 
  required bool isSelected
}) {
  return GestureDetector(
    onTap: () {
      backgroundImage.value = bgPath;
      Get.back();
      Get.snackbar('成功', '背景已更换', 
        backgroundColor: const Color(0xffBA92FD),
        colorText: Colors.white,
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? const Color(0xffBA92FD) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 背景预览（80×60）
          Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              color: bgPath.isEmpty ? const Color(0xffFDF6F1) : null,
              image: bgPath.isNotEmpty
                  ? DecorationImage(
                      image: _getBackgroundImageProvider(bgPath),
                      fit: BoxFit.cover,
                    )
                  : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 标签
          Expanded(
            child: Text(label, style: TextStyle(
              fontSize: 14,
              color: isSelected ? const Color(0xffBA92FD) : Colors.grey[800],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            )),
          ),
          // 选中标记
          if (isSelected)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.check_circle, color: Color(0xffBA92FD), size: 20),
            ),
        ],
      ),
    ),
  );
}
```

#### 从相册选择背景
```dart
Future<void> _pickBackgroundFromGallery() async {
  final imageFile = await MediaPickerUtil.pickImageFromGallery(
    imageQuality: 85,
    maxWidth: 1920,
    maxHeight: 1920,
  );

  if (imageFile != null) {
    // 使用本地图片路径作为背景
    backgroundImage.value = imageFile.path;
    Get.snackbar('成功', '背景已更换', 
      backgroundColor: const Color(0xffBA92FD),
      colorText: Colors.white,
    );
    
    // TODO: 上传背景图到服务器，保存用户偏好设置
  }
}
```

---

### 4️⃣ **支持资产和文件图片** (`chat_page.dart` & `chat_controller.dart`)

#### 图片提供器
```dart
ImageProvider _getBackgroundImageProvider(String path) {
  if (path.startsWith('assets/')) {
    return AssetImage(path);  // 资产图片
  } else {
    return FileImage(File(path));  // 文件图片（相册选择）
  }
}
```

#### 应用背景
```dart
Container(
  decoration: controller.backgroundImage.value.isNotEmpty
      ? BoxDecoration(
          image: DecorationImage(
            image: _getBackgroundImageProvider(controller.backgroundImage.value),
            fit: BoxFit.cover,
          ),
        )
      : null,
  child: ListView.builder(
    // 消息列表
  ),
)
```

---

## 🎨 视觉效果

### 更多菜单
```
┌─────────────────────────────┐
│     ChatPage AppBar         │
│  ┌──────────┐  [···]       │  ← 点击这里
│  │          │    ↓          │
│  │          │ ┌──────────┐  │  ← 菜单显示在这里
│  │          │ │ 🏷️  🖼️  │  │     (抽屉式，88×58)
│  │          │ │修改 更换│  │
│  │   消息   │ │备注 背景│  │
│  │   列表   │ └──────────┘  │
│  │          │               │
│  └──────────┘               │
└─────────────────────────────┘
```

### 背景选择对话框
```
┌─────────────────────────────┐
│     选择聊天背景            │
├─────────────────────────────┤
│ ┌────┐                      │
│ │预览│ 无背景            ✓  │  ← 当前选中
│ └────┘                      │
│ ┌────┐                      │
│ │预览│ 背景 1               │
│ └────┘                      │
│ ┌────┐                      │
│ │预览│ 背景 2               │
│ └────┘                      │
│ 📷  从相册选择              │
│                             │
│         [ 取消 ]            │
└─────────────────────────────┘
```

---

## 📁 修改的文件

1. ✅ `lib/pages/chat/widgets/chat_more_menu.dart` - 抽屉式菜单组件
2. ✅ `lib/pages/chat/chat_page.dart` - 菜单显示位置调整
3. ✅ `lib/pages/chat/chat_controller.dart` - 更换背景功能实现

---

## 🔧 使用的资源

- ✅ `assets/chat/kissu3_chat_more_bg.webp` - 菜单背景 (88×58)
- ✅ `assets/chat/kissu3_chat_remark.webp` - 修改备注图标 (13×13)
- ✅ `assets/chat/kissu3_chat_picture.webp` - 更换背景图标 (13×13)
- ✅ `assets/chat/kissu3_chat_bg.webp` - 预设背景1
- ✅ `assets/3.0/kissu3_picture_wall.webp` - 预设背景2

---

## 🎯 功能特性

### 更多菜单
- ✅ 抽屉式展示，显示在按钮正下方
- ✅ 使用自定义背景图和图标
- ✅ 文字颜色符合设计稿 (#6D383E)
- ✅ 点击外部区域自动关闭
- ✅ 点击菜单项后自动关闭

### 更换背景功能
- ✅ 支持无背景（默认底色）
- ✅ 支持2个预设背景
- ✅ 支持从相册选择自定义背景
- ✅ 背景预览缩略图（80×60）
- ✅ 实时更新背景显示
- ✅ 选中状态高亮显示（紫色边框+对勾）
- ✅ 成功提示（紫色 Snackbar）

### 图片加载
- ✅ 智能区分资产图片和文件图片
- ✅ 使用 `AssetImage` 加载预设背景
- ✅ 使用 `FileImage` 加载相册图片
- ✅ 预览和消息列表背景使用相同加载逻辑

---

## 🚀 后续优化建议

1. **背景持久化**：将用户选择的背景保存到本地存储（SharedPreferences）
2. **背景同步**：上传自定义背景到服务器，实现多端同步
3. **更多预设背景**：添加更多精美的预设背景供用户选择
4. **背景分类**：纯色、渐变、图案、照片等分类
5. **背景透明度**：允许调整背景透明度，确保消息可读性

---

## 🎬 测试场景

### ✅ 场景1：打开更多菜单
1. 进入聊天页面
2. 点击右上角"···"按钮
3. **期望**：菜单显示在按钮正下方，使用自定义背景和图标

### ✅ 场景2：选择预设背景
1. 打开更多菜单 → 点击"更换背景"
2. 选择任一预设背景
3. **期望**：消息列表背景立即更换，显示成功提示

### ✅ 场景3：从相册选择背景
1. 打开更换背景对话框
2. 点击"从相册选择"
3. 选择一张图片
4. **期望**：图片作为聊天背景显示，支持文件图片加载

### ✅ 场景4：取消背景
1. 打开更换背景对话框
2. 选择"无背景"
3. **期望**：恢复默认底色 (#FDF6F1)

### ✅ 场景5：点击外部关闭菜单
1. 打开更多菜单
2. 点击菜单外部区域
3. **期望**：菜单自动关闭

---

完成！🎉

