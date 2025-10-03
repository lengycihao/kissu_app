import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kissu_app/pages/chat/widgets/chat_message_item.dart';
import 'package:kissu_app/pages/chat/widgets/chat_extension_panel.dart';
import 'package:kissu_app/pages/chat/widgets/chat_more_menu.dart';
import 'package:kissu_app/pages/chat/widgets/chat_emoji_panel.dart';
import 'package:kissu_app/pages/chat/widgets/location_picker_page.dart';
import 'package:kissu_app/utils/media_picker_util.dart';
import 'package:kissu_app/services/simple_location_service.dart';

class ChatController extends GetxController {
  // 滚动控制器
  final ScrollController scrollController = ScrollController();
  
  // 输入框焦点控制器
  final FocusNode inputFocusNode = FocusNode();

  // 面板显示状态
  final RxBool showEmojiPanel = false.obs;
  final RxBool showExtensionPanel = false.obs;
  final RxBool isVoiceRecording = false.obs;
  final RxBool isVoiceCanceling = false.obs;

  // 录音相关
  final _audioRecorder = AudioRecorder();
  String? _recordingPath;
  DateTime? _recordStartTime;

  // 聊天消息列表
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;

  // 聊天背景图片路径
  final RxString backgroundImage = ''.obs;

  // 对方昵称/备注
  final RxString chatName = '聊天对象'.obs;

  // 用户会员状态（用于表情面板）
  final RxBool isVip = false.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('💬 ChatController 初始化');
    _loadMockMessages();
  }

  @override
  void onClose() {
    scrollController.dispose();
    inputFocusNode.dispose();
    _audioRecorder.dispose();
    debugPrint('💬 ChatController 销毁');
    super.onClose();
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

    messages.add(message);
    _scrollToBottom();

    // 隐藏面板
    hideAllPanels();

    // TODO: 发送到服务器
    debugPrint('💬 发送消息: $text');
  }

  // 发送表情
  void sendEmoji(String emoji) {
    sendTextMessage(emoji);
  }

  // 发送会员表情
  void sendVipEmoji(VipEmoji vipEmoji) {
    // TODO: 发送动态表情到服务器
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: vipEmoji.name,
      type: MessageType.image,
      isSent: true,
      time: DateTime.now(),
      avatarUrl: null,
      imageUrl: vipEmoji.url, // 会员表情的GIF URL
    );

    messages.add(message);
    _scrollToBottom();
    hideAllPanels();

    debugPrint('💬 发送会员表情: ${vipEmoji.name}');
  }

  // 切换表情面板
  void toggleEmojiPanel() {
    showEmojiPanel.value = !showEmojiPanel.value;
    if (showEmojiPanel.value) {
      showExtensionPanel.value = false;
    }
  }

  // 切换扩展功能面板
  void toggleExtensionPanel() {
    showExtensionPanel.value = !showExtensionPanel.value;
    if (showExtensionPanel.value) {
      showEmojiPanel.value = false;
    }
  }

  // 隐藏所有面板
  void hideAllPanels() {
    showEmojiPanel.value = false;
    showExtensionPanel.value = false;
    // 收起键盘
    inputFocusNode.unfocus();
  }

  // 开始录音
  void startVoiceRecording() async {
    try {
      // 先检查权限状态
      var status = await Permission.microphone.status;
      
      // 如果权限未授予，请求权限
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        
        // 权限被拒绝，不进入录音状态
        if (!status.isGranted) {
          Get.snackbar(
            '权限不足',
            '需要麦克风权限才能录音',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
          );
          // 重要：确保UI状态重置
          isVoiceRecording.value = false;
          isVoiceCanceling.value = false;
          return;
        }
        
        // 权限刚被授予，但用户可能已经松手了
        // 不自动开始录音，让用户再次按下
        debugPrint('💬 权限已授予，请再次按住说话按钮');
        isVoiceRecording.value = false;
        isVoiceCanceling.value = false;
        return;
      }

      // 权限已存在，立即开始录音
      // 生成录音文件路径
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${dir.path}/voice_$timestamp.m4a';

      // 开始录音
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );

      isVoiceRecording.value = true;
      isVoiceCanceling.value = false;
      _recordStartTime = DateTime.now();
      
      debugPrint('💬 开始录音: $_recordingPath');
    } catch (e) {
      debugPrint('录音失败: $e');
      // 确保异常时重置状态
      isVoiceRecording.value = false;
      isVoiceCanceling.value = false;
      Get.snackbar(
        '错误',
        '录音失败，请重试',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // 更新取消状态
  void updateVoiceCancelState(bool isCanceling) {
    isVoiceCanceling.value = isCanceling;
  }

  // 结束录音（发送）
  void stopVoiceRecording() async {
    if (!isVoiceRecording.value) return;

    try {
      // 停止录音
      final path = await _audioRecorder.stop();
      
      isVoiceRecording.value = false;
      isVoiceCanceling.value = false;

      if (path == null || path.isEmpty) {
        debugPrint('录音失败：路径为空');
        return;
      }

      // 计算录音时长
      final duration = _recordStartTime != null
          ? DateTime.now().difference(_recordStartTime!).inSeconds
          : 0;

      // 录音时长太短（小于1秒）
      if (duration < 1) {
        Get.snackbar(
          '提示',
          '录音时间太短',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        // 删除录音文件
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
        return;
      }

      debugPrint('💬 录音完成: $path, 时长: $duration秒');

      // TODO: 上传录音文件到服务器
      // final voiceUrl = await _uploadVoiceFile(File(path));

      // 发送语音消息
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '语音消息',
        type: MessageType.voice,
        isSent: true,
        time: DateTime.now(),
        avatarUrl: null,
        voiceDuration: duration,
        voiceUrl: path, // 实际应该是服务器返回的URL
      );
      
      messages.add(message);
      _scrollToBottom();

    } catch (e) {
      debugPrint('停止录音失败: $e');
    } finally {
      _recordStartTime = null;
      _recordingPath = null;
    }
  }

  // 取消录音
  void cancelVoiceRecording() async {
    if (!isVoiceRecording.value) return;

    try {
      // 停止录音
      final path = await _audioRecorder.stop();
      
      isVoiceRecording.value = false;
      isVoiceCanceling.value = false;

      debugPrint('💬 取消录音');

      // 删除录音文件
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          debugPrint('已删除录音文件: $path');
        }
      }
    } catch (e) {
      debugPrint('取消录音失败: $e');
    } finally {
      _recordStartTime = null;
      _recordingPath = null;
    }
  }

  // 处理扩展功能点击
  void handleExtensionAction(ExtensionType type) async {
    debugPrint('💬 扩展功能: ${type.name}');
    hideAllPanels();

    switch (type) {
      case ExtensionType.album:
        await _pickImageFromGallery();
        break;
      case ExtensionType.camera:
        await _takePhoto();
        break;
      case ExtensionType.location:
        await _pickAndSendLocation();
        break;
    }
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

      messages.add(message);
      _scrollToBottom();

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

  // 更换背景对话框
  void _showChangeBackgroundDialog() async {
    // 预设背景图列表
    final List<String> backgroundOptions = [
      '', // 无背景
      'assets/chat/kissu3_chat_bg.webp',
      'assets/3.0/kissu3_picture_wall.webp',
    ];

    // 显示背景选择对话框
    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择聊天背景',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              // 背景选项列表
              ...backgroundOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final bgPath = entry.value;
                return _buildBackgroundOption(
                  bgPath,
                  label: index == 0 
                      ? '无背景' 
                      : '背景 $index',
                  isSelected: backgroundImage.value == bgPath,
                );
              }),
              const SizedBox(height: 10),
              // 从相册选择
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xffBA92FD)),
                title: const Text('从相册选择'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onTap: () {
                  Get.back();
                  _pickBackgroundFromGallery();
                },
              ),
              const SizedBox(height: 10),
              // 关闭按钮
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('取消'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建背景选项
  Widget _buildBackgroundOption(String bgPath, {required String label, required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        backgroundImage.value = bgPath;
        Get.back();
        Get.snackbar(
          '成功',
          '背景已更换',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xffBA92FD),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 1),
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
            // 背景预览
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
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? const Color(0xffBA92FD) : Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            // 选中标记
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xffBA92FD),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 获取背景图片提供器（支持资产图片和文件图片）
  ImageProvider _getBackgroundImageProvider(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else {
      return FileImage(File(path));
    }
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
}
