import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/utils/sp_util.dart';
import 'package:kissu_app/pages/chat/chat_controller.dart';
import 'package:kissu_app/utils/media_picker_util.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';

class ChatBackgroundController extends GetxController {
  // 获取聊天控制器实例
  late ChatController chatController;

  // 默认背景列表
  static const List<String> defaultBackgrounds = [
    'assets/chat/kissu_chat_bg1.webp',
    'assets/chat/kissu_chat_bg2.webp',
    'assets/chat/kissu_chat_bg3.webp',
    'assets/chat/kissu_chat_bg4.webp',
    'assets/chat/kissu_chat_bg5.webp',
    'assets/chat/kissu_chat_bg6.webp', 
  ];

  // 缓存key
  static const String _backgroundCacheKey = 'chat_background_path';

  // 当前选中的背景路径
  final RxString selectedBackground = 'assets/chat/kissu_chat_bg1.webp'.obs;

  // 预览背景路径（用于页面顶部预览）
  final RxString previewBackground = 'assets/chat/kissu_chat_bg1.webp'.obs;

  // 所有背景列表（只包含默认背景，不包含本地添加的图片）
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
    // 只加载默认背景列表，不显示自定义背景
    allBackgrounds.value = [...defaultBackgrounds];
    
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
      // 只设置为当前选中的背景，不添加到列表中
      // 直接保存到缓存，替换之前添加的本地图片
      await SpUtil.putString(_backgroundCacheKey, imageFile.path);
      
      // 自动选中新添加的背景
      selectBackground(imageFile.path);
      
      debugPrint('💬 添加本地背景（不显示在列表中）: ${imageFile.path}');
    }
  }

  // 使用选中的背景
  Future<void> applyBackground() async {
    // 埋点：记录背景选择
    final bgName = _getBackgroundId(selectedBackground.value);
    AnalyticsHelper.trackChatBgBtn(bgName: bgName);
    
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
  
  /// 根据背景路径获取对应的ID
  String _getBackgroundId(String backgroundPath) {
     
    final index = defaultBackgrounds.indexOf(backgroundPath);
    if (index >= 0 && index < 6) {
      const bgIds = ['纯白背景', '小熊左右背景', '小熊上下背景', '小狗平铺背景', '蓝色原点背景', 'kissu文字平铺背景'];
      return bgIds[index];
    }
    // 如果是自定义背景（从相册添加的），返回特殊ID
    return '自定义背景'; // 自定义背景
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

