import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/utils/sp_util.dart';
import 'package:kissu_app/pages/chat/widgets/chat_message_item.dart';
import 'package:kissu_app/pages/chat/widgets/chat_more_menu.dart';
import 'package:kissu_app/pages/chat/widgets/location_picker_page.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:kissu_app/utils/media_picker_util.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';

class ChatController extends GetxController {
  // 滚动控制器
  final ScrollController scrollController = ScrollController();
  
  // 输入框焦点控制器
  final FocusNode inputFocusNode = FocusNode();

  // 面板显示状态
  final RxBool showEmojiPanel = false.obs;

  // 聊天消息列表
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;

  // 聊天背景图片路径
  final RxString backgroundImage = ''.obs;

  // 聊天气泡样式（1-4）
  final RxInt bubbleStyle = 1.obs;

  // 聊天主题（1-4，默认1）
  final RxInt chatTheme = 1.obs;

  // 对方昵称/备注
  final RxString chatName = '聊天对象'.obs;

  // 对方头像URL
  final RxString avatarUrl = ''.obs;

  // 用户会员状态（用于表情面板）
  final RxBool isVip = false.obs;

  // 设备信息展开状态：null表示未展开，其他值表示当前展开的项类型
  final selectedDeviceInfoType = Rxn<String>(); // 'distance', 'mobileModel', 'network', 'power'

  // 设备信息悬浮提示的自动隐藏定时器
  Timer? _deviceInfoTooltipTimer;

  @override
  void onInit() {
    super.onInit();
    debugPrint('💬 ChatController 初始化');
    _loadMockMessages();
    _setupFocusListener();
    _loadBackgroundFromCache();
    _loadBubbleStyleFromCache();
    _loadThemeFromCache();
  }

  // 从缓存加载背景
  Future<void> _loadBackgroundFromCache() async {
    final savedBackground = await SpUtil.getString('chat_background_path');
    if (savedBackground.isNotEmpty) {
      backgroundImage.value = savedBackground;
      debugPrint('💬 加载缓存的聊天背景: $savedBackground');
    }
  }

  // 从缓存加载气泡样式
  Future<void> _loadBubbleStyleFromCache() async {
    final savedStyle = await SpUtil.getInteger('chat_bubble_style', 1);
    if (savedStyle > 0 && savedStyle <= 4) {
      bubbleStyle.value = savedStyle;
      debugPrint('💬 加载缓存的气泡样式: $savedStyle');
    } else {
      // 如果缓存中没有或值无效，使用默认样式1
      bubbleStyle.value = 1;
      // 同时保存默认值到缓存
      await SpUtil.putInteger('chat_bubble_style', 1);
      debugPrint('💬 使用默认气泡样式: 1');
    }
  }

  // 从缓存加载主题
  Future<void> _loadThemeFromCache() async {
    final savedTheme = await SpUtil.getInteger('chat_theme', 1);
    if (savedTheme > 0 && savedTheme <= 4) {
      chatTheme.value = savedTheme;
      debugPrint('💬 加载缓存的主题: $savedTheme');
    } else {
      chatTheme.value = 1;
      await SpUtil.putInteger('chat_theme', 1);
      debugPrint('💬 使用默认主题: 1');
    }
  }

  // 更新气泡样式（由 ChatBubbleController 调用）
  void updateBubbleStyle(int style) {
    if (style >= 1 && style <= 4) {
      bubbleStyle.value = style;
      debugPrint('💬 更新气泡样式: $style');
    }
  }

  // 更新主题（由 ChatThemeController 调用）
  void updateTheme(int theme) {
    if (theme >= 1 && theme <= 4) {
      chatTheme.value = theme;
      debugPrint('💬 更新主题: $theme');
    }
  }

  // 获取主题对应的按钮颜色
  Color getThemeButtonColor() {
    switch (chatTheme.value) {
      case 1:
      case 2:
        return const Color(0xffFF90CA);
      case 3:
        return const Color(0xffA6D7FF);
      case 4:
        return const Color(0xffAD7D63);
      default:
        return const Color(0xffFF90CA);
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    inputFocusNode.dispose();
    _deviceInfoTooltipTimer?.cancel();
    debugPrint('💬 ChatController 销毁');
    super.onClose();
  }

  /// 清除设备信息提示（手动关闭 tip）
  void clearSelectedDeviceInfo() {
    _deviceInfoTooltipTimer?.cancel();
    selectedDeviceInfoType.value = null;
  }

  /// 切换设备信息展开状态（并启动 2 秒自动隐藏计时）
  void toggleDeviceInfo(String? type) {
    // 先取消之前的定时器
    _deviceInfoTooltipTimer?.cancel();

    // 如果点击的是当前已展开的项，则收起并直接返回
    if (selectedDeviceInfoType.value == type) {
      selectedDeviceInfoType.value = null;
      return;
    }

    // 切换到新的类型
    selectedDeviceInfoType.value = type;

    // 启动 2 秒自动隐藏
    if (type != null) {
      _deviceInfoTooltipTimer = Timer(const Duration(seconds: 2), () {
        // 只在当前仍然是同一个类型时才隐藏，避免抢掉后续点击
        if (selectedDeviceInfoType.value == type) {
          selectedDeviceInfoType.value = null;
        }
      });
    }
  }

  // 设置输入框焦点监听器
  void _setupFocusListener() {
    inputFocusNode.addListener(() {
      // 当输入框获得焦点时（键盘抬起），关闭所有面板
      if (inputFocusNode.hasFocus) {
        showEmojiPanel.value = false;
        debugPrint('💬 键盘抬起，关闭所有面板');
        // 键盘抬起时，延迟滚动到底部
        _scrollToBottomWithDelay();
      }
    });
  }

  // 加载模拟消息
  void _loadMockMessages() {
    messages.addAll([
      ChatMessage(
        id: '1',
        content: '你好！',
        type: MessageType.text,
        isSent: false,
        time: DateTime.now().subtract(const Duration(minutes: 5)),
        avatarUrl: null,
      ),
      ChatMessage(
        id: '2',
        content: '嗨，在干嘛呢？',
        type: MessageType.text,
        isSent: true,
        time: DateTime.now().subtract(const Duration(minutes: 4)),
        avatarUrl: null,
        isRead: true, // 已读
      ),
      ChatMessage(
        id: '3',
        content: '刚吃完饭，准备出去散步',
        type: MessageType.text,
        isSent: false,
        time: DateTime.now().subtract(const Duration(minutes: 3)),
        avatarUrl: null,
      ),
    ]);
  }

  // 发送文字消息
  void sendTextMessage(String text) {
    if (text.trim().isEmpty) return;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      type: MessageType.text,
      isSent: true,
      time: DateTime.now(),
      avatarUrl: null,
    );

    // 添加消息到列表
    messages.add(message);
    
    // 强制刷新UI（确保 RxList 触发更新）
    messages.refresh();
    
    // 延迟滚动到底部，确保UI更新完成
    Future.microtask(() => _scrollToBottom());

    // 隐藏面板
    hideAllPanels();

    // TODO: 发送到服务器
    debugPrint('💬 发送消息: $text');
  }

  // 插入表情到输入框（不直接发送）
  void insertEmojiToInput(String emoji) {
    // 这个方法会被 ChatPage 中的 GlobalKey 调用
    // 实际实现在 ChatPage 中
  }

  // 切换表情面板
  void toggleEmojiPanel() {
    showEmojiPanel.value = !showEmojiPanel.value;
    if (showEmojiPanel.value) {
      // 展开表情面板时，收起键盘
      inputFocusNode.unfocus();
      debugPrint('💬 表情面板展开，收起键盘');
      // 延迟滚动到底部，确保面板完全展开后再滚动
      _scrollToBottomWithDelay();
    }
  }

  // 隐藏所有面板
  void hideAllPanels() {
    showEmojiPanel.value = false;
    // 收起键盘
    inputFocusNode.unfocus();
  }

  /// 功能区：相册
  Future<void> onAlbumTap() async {
    hideAllPanels();
    await _pickImageFromGallery();
  }

  /// 功能区：拍照
  Future<void> onCameraTap() async {
    hideAllPanels();
    await _takePhoto();
  }

  /// 功能区：位置 - 跳转到定位页面
  Future<void> onLocationTap() async {
    hideAllPanels();
    Get.toNamed(KissuRoutePath.location);
  }

  // 从相册选择图片
  Future<void> _pickImageFromGallery() async {
    final imageFile = await MediaPickerUtil.pickImageFromGallery(
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (imageFile != null) {
      await _sendImageMessage(imageFile);
    }
  }

  // 拍照
  Future<void> _takePhoto() async {
    final imageFile = await MediaPickerUtil.takePhoto(
      imageQuality: 85,
    );

    if (imageFile != null) {
      await _sendImageMessage(imageFile);
    }
  }

  // 发送图片消息
  Future<void> _sendImageMessage(File imageFile) async {
    try {
      // TODO: 上传图片到服务器获取URL
      // 这里先使用本地路径模拟
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '[图片]',
        type: MessageType.image,
        isSent: true,
        time: DateTime.now(),
        avatarUrl: null,
        imageUrl: imageFile.path, // 实际应该是服务器返回的URL
      );

      // 添加消息到列表
      messages.add(message);
      
      // 强制刷新UI（确保 RxList 触发更新）
      messages.refresh();
      
      // 延迟滚动到底部，确保UI更新完成
      Future.microtask(() => _scrollToBottom());

      debugPrint('💬 发送图片消息: ${imageFile.path}');

      // TODO: 上传图片到服务器
      // final uploadedUrl = await _uploadImage(imageFile);
      // 更新消息中的图片URL
    } catch (e) {
      debugPrint('发送图片失败: $e');
      Get.snackbar(
        '错误',
        '发送图片失败',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // 选择并发送位置 - 打开位置选择页面
  Future<void> _pickAndSendLocation() async {
    try {
      // 直接从全局定位服务获取当前位置
      final locationService = SimpleLocationService.instance;
      final currentLoc = locationService.currentLocation.value;

      if (currentLoc == null) {
        Get.snackbar(
          '提示',
          '正在获取位置信息，请稍后再试',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        return;
      }

      // 打开位置选择页面
      final selectedLocation = await Get.to<LocationInfo>(
        () => LocationPickerPage(
          initialLatitude: double.tryParse(currentLoc.latitude),
          initialLongitude: double.tryParse(currentLoc.longitude),
          initialLocationName: currentLoc.locationName.isNotEmpty 
              ? currentLoc.locationName 
              : '当前位置',
          avatarUrl: null, // 可以传入对方的头像
        ),
        transition: Transition.downToUp,
      );

      if (selectedLocation == null) return;

      // 发送位置消息
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: selectedLocation.name,
        type: MessageType.location,
        isSent: true,
        time: DateTime.now(),
        avatarUrl: null,
        locationName: selectedLocation.name,
        latitude: selectedLocation.latitude,
        longitude: selectedLocation.longitude,
      );

      messages.add(message);
      _scrollToBottom();

      debugPrint('💬 发送位置: ${message.locationName} (${message.latitude}, ${message.longitude})');
      // TODO: 发送位置到服务器
    } catch (e) {
      debugPrint('发送位置失败: $e');
      Get.snackbar(
        '错误',
        '发送位置失败',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // 处理更多菜单点击
  void handleMoreMenuAction(MoreMenuType type) {
    debugPrint('💬 更多菜单: ${type.name}');

    switch (type) {
      case MoreMenuType.editRemark:
        _showEditRemarkDialog();
        break;
      case MoreMenuType.changeBackground:
        _showChangeBackgroundDialog();
        break;
    }
  }

  // 修改备注对话框
  void _showEditRemarkDialog() {
    final TextEditingController controller = TextEditingController(text: chatName.value);

    Get.dialog(
      AlertDialog(
        title: const Text('修改备注'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入备注名',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                chatName.value = newName;
              }
              Get.back();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 更换背景 - 直接调起相册
  void _showChangeBackgroundDialog() async {
    // 直接从相册选择背景图
    _pickBackgroundFromGallery();
  }

  // 从相册选择背景
  Future<void> _pickBackgroundFromGallery() async {
    final imageFile = await MediaPickerUtil.pickImageFromGallery(
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (imageFile != null) {
      // 使用本地图片路径作为背景
      backgroundImage.value = imageFile.path;
      Get.snackbar(
        '成功',
        '背景已更换',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xffBA92FD),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 1),
      );
      
      debugPrint('💬 更换聊天背景: ${imageFile.path}');
      // TODO: 上传背景图到服务器，保存用户偏好设置
    }
  }


  // 滚动到底部
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 延迟滚动到底部（用于面板展开时）
  void _scrollToBottomWithDelay() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
