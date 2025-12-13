import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/utils/sp_util.dart';
import 'package:kissu_app/pages/chat/chat_controller.dart';
import 'package:kissu_app/utils/media_picker_util.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';

class ChatBackgroundController extends GetxController {
  // 获取聊天控制器实例
  late ChatController chatController;

  // 默认背景列表
  static const List<String> defaultBackgrounds = [
    'assets/chat/kissu_chat_bg1.webp',
    'assets/chat/kissu_chat_bg2.webp',
    'assets/chat/kissu_chat_bg3.webp',
  ];

  // 缓存key
  static const String _backgroundCacheKey = 'chat_background_path';
  static const String _customBackgroundsKey = 'chat_custom_backgrounds';

  // 当前选中的背景路径
  final RxString selectedBackground = 'assets/chat/kissu_chat_bg1.webp'.obs;

  // 预览背景路径（用于页面顶部预览）
  final RxString previewBackground = 'assets/chat/kissu_chat_bg1.webp'.obs;

  // 自定义背景列表（从相册添加的）
  final RxList<String> customBackgrounds = <String>[].obs;

  // 所有背景列表（默认 + 自定义）
  final RxList<String> allBackgrounds = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    // 获取聊天控制器实例
    chatController = Get.find<ChatController>();
    _loadBackgrounds();
    _loadSelectedBackground();
  }

  // 加载背景列表
  Future<void> _loadBackgrounds() async {
    // 加载自定义背景
    final customList = await SpUtil.getStringList(_customBackgroundsKey);
    customBackgrounds.value = customList;
    
    // 合并背景列表：自定义背景在前（最新的在最前），默认背景在后
    allBackgrounds.value = [...customBackgrounds.reversed, ...defaultBackgrounds];
    
    // 设置预览背景为当前选中的背景
    previewBackground.value = selectedBackground.value;
  }

  // 加载已保存的背景
  Future<void> _loadSelectedBackground() async {
    final savedBackground = await SpUtil.getString(_backgroundCacheKey);
    if (savedBackground.isNotEmpty) {
      selectedBackground.value = savedBackground;
      previewBackground.value = savedBackground;
    } else {
      // 如果没有保存的背景，使用默认背景
      selectedBackground.value = defaultBackgrounds[0];
      previewBackground.value = defaultBackgrounds[0];
    }
  }

  // 选择背景
  void selectBackground(String backgroundPath) {
    selectedBackground.value = backgroundPath;
    previewBackground.value = backgroundPath;
  }

  // 从相册添加背景
  Future<void> addBackgroundFromGallery() async {
    final imageFile = await MediaPickerUtil.pickImageFromGallery(
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (imageFile != null) {
      // 添加到自定义背景列表的最前面（最新的在最前）
      final newCustomList = [imageFile.path, ...customBackgrounds];
      customBackgrounds.value = newCustomList;
      
      // 更新所有背景列表：自定义背景在前（最新的在最前），默认背景在后
      allBackgrounds.value = [...customBackgrounds.reversed, ...defaultBackgrounds];
      
      // 保存自定义背景列表
      await SpUtil.putStringList(_customBackgroundsKey, customBackgrounds);
      
      // 自动选中新添加的背景
      selectBackground(imageFile.path);
      
      debugPrint('💬 添加自定义背景: ${imageFile.path}');
      debugPrint('💬 当前自定义背景数量: ${customBackgrounds.length}');
      debugPrint('💬 当前所有背景数量: ${allBackgrounds.length}');
    }
  }

  // 使用选中的背景
  Future<void> applyBackground() async {
    // 更新聊天控制器的背景
    chatController.backgroundImage.value = selectedBackground.value;
    
    // 保存到缓存
    await SpUtil.putString(_backgroundCacheKey, selectedBackground.value);
    
    // 直接返回到聊天页面，跳过设置页面
    Get.until((route) => route.settings.name == KissuRoutePath.chat);
    
    // 延迟显示提示，确保页面已经返回
    Future.delayed(const Duration(milliseconds: 300), () {
      OKToastUtil.showSuccess('背景已更换');
    });
    
    debugPrint('💬 应用聊天背景: ${selectedBackground.value}');
  }

  // 获取背景图片提供器（支持资产图片和文件图片）
  ImageProvider getBackgroundImageProvider(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else {
      return FileImage(File(path));
    }
  }
}

