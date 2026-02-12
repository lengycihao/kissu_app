import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/network/utils/sp_util.dart';
import 'package:kissu_app/pages/chat/chat_controller.dart';
import 'package:kissu_app/utils/media_picker_util.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';

/// 背景数据模型
class ChatBackgroundItem {
  final String path;
  final bool requiresVip;
  final String name;

  const ChatBackgroundItem({
    required this.path,
    this.requiresVip = false,
    this.name = '',
  });
}

class ChatBackgroundController extends GetxController {
  // 获取聊天控制器实例
  late ChatController chatController;

  // 默认背景列表（带VIP属性）
  static const List<ChatBackgroundItem> defaultBackgrounds = [
    ChatBackgroundItem(
      path: 'assets/chat/kissu_chat_bg1.webp',
      requiresVip: false,
      name: '纯白背景',
    ),
    ChatBackgroundItem(
      path: 'assets/chat/kissu_chat_bg2.webp',
      requiresVip: true,
      name: '水滴布袋心满屏背景',
    ),
    ChatBackgroundItem(
      path: 'assets/chat/kissu_chat_bg3.webp',
      requiresVip: true,
      name: '闭眼假寐格子衫背景',
    ),
    ChatBackgroundItem(
      path: 'assets/chat/kissu_chat_bg4.webp',
      requiresVip: true,
      name: '五个憨憨深蓝色背景',
    ),
    ChatBackgroundItem(
      path: 'assets/chat/kissu_chat_bg5.webp',
      requiresVip: true,
      name: '两个憨憨双黄蛋背景',
    ),
    ChatBackgroundItem(
      path: 'assets/chat/kissu_chat_bg6.webp',
      requiresVip: true,
      name: '两个憨憨水边耍背景',
    ),

    ChatBackgroundItem(
      path: 'assets/chat/kissu_chat_bg7.webp',
      requiresVip: false,
      name: '小熊左右背景',
    ),
    ChatBackgroundItem(
      path: 'assets/chat/kissu_chat_bg8.webp',
      requiresVip: false,
      name: '小熊上下背景',
    ),
    ChatBackgroundItem(
      path: 'assets/chat/kissu_chat_bg9.webp',
      requiresVip: false,
      name: '小狗平铺背景',
    ),
    ChatBackgroundItem(
      path: 'assets/chat/kissu_chat_bg10.webp',
      requiresVip: false,
      name: '蓝色原点背景',
    ),
    ChatBackgroundItem(
      path: 'assets/chat/kissu_chat_bg11.webp',
      requiresVip: false,
      name: 'kissu文字平铺背景',
    ),
  ];

  // 缓存key
  static const String _backgroundCacheKey = 'chat_background_path';

  // 当前选中的背景路径
  final RxString selectedBackground = 'assets/chat/kissu_chat_bg1.webp'.obs;

  // 预览背景路径（用于页面顶部预览）
  final RxString previewBackground = 'assets/chat/kissu_chat_bg1.webp'.obs;

  // 所有背景列表（只包含默认背景，不包含本地添加的图片）
  final RxList<ChatBackgroundItem> allBackgrounds = <ChatBackgroundItem>[].obs;

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

  /// 根据路径查找背景项
  ChatBackgroundItem? findBackgroundItem(String path) {
    try {
      return allBackgrounds.firstWhere((item) => item.path == path);
    } catch (e) {
      return null;
    }
  }

  /// 检查背景是否需要VIP
  bool isBackgroundRequiresVip(String path) {
    final item = findBackgroundItem(path);
    return item?.requiresVip ?? false;
  }

  // 加载已保存的背景
  Future<void> _loadSelectedBackground() async {
    final savedBackground = await SpUtil.getString(_backgroundCacheKey);
    if (savedBackground.isNotEmpty) {
      selectedBackground.value = savedBackground;
      previewBackground.value = savedBackground;
    } else {
      // 如果没有保存的背景，使用默认背景
      selectedBackground.value = defaultBackgrounds[0].path;
      previewBackground.value = defaultBackgrounds[0].path;
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

      logDebug('💬 添加本地背景（不显示在列表中）: ${imageFile.path}');
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

    logDebug('💬 应用聊天背景: ${selectedBackground.value}');
  }

  /// 根据背景路径获取对应的ID
  String _getBackgroundId(String backgroundPath) {
    final item = findBackgroundItem(backgroundPath);
    if (item != null) {
      return item.name;
    }
    // 如果是自定义背景（从相册添加的），返回特殊ID
    return '自定义背景';
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
