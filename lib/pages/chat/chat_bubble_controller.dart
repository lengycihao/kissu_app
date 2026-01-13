import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/utils/sp_util.dart';
import 'package:kissu_app/pages/chat/chat_controller.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';

class ChatBubbleController extends GetxController {
  // 获取聊天控制器实例
  late ChatController chatController;

  // 气泡样式列表（1-4）
  static const List<int> bubbleStyles = [1, 2, 3, 4];

  // 缓存key
  static const String _bubbleStyleCacheKey = 'chat_bubble_style';

  // 当前选中的气泡样式（1-4）
  final RxInt selectedBubbleStyle = 1.obs;

  @override
  void onInit() {
    super.onInit();
    // 获取聊天控制器实例
    chatController = Get.find<ChatController>();
    _loadSelectedBubbleStyle();
  }

  // 加载已保存的气泡样式
  Future<void> _loadSelectedBubbleStyle() async {
    final savedStyle = await SpUtil.getInteger(_bubbleStyleCacheKey);
    if (savedStyle > 0 && savedStyle <= 4) {
      selectedBubbleStyle.value = savedStyle;
    } else {
      // 如果没有保存的样式，使用默认样式1
      selectedBubbleStyle.value = 1;
    }
  }

  // 选择气泡样式
  void selectBubbleStyle(int style) {
    if (style >= 1 && style <= 4) {
      selectedBubbleStyle.value = style;
    }
  }

  // 获取自己的气泡图片路径
  String getSelfBubblePath(int style) {
    return 'assets/chat/kissu_chat_bubble_self_$style.webp';
  }

  // 获取对方的气泡图片路径
  String getOtherBubblePath(int style) {
    return 'assets/chat/kissu_chat_bubble_other_$style.webp';
  }

  /// 应用选中的气泡样式
  /// 保存样式到缓存，更新聊天控制器，然后返回聊天页面
  Future<void> applyBubbleStyle() async {
    try {
      // 埋点：记录气泡选择
      final buddleName = _getBubbleId(selectedBubbleStyle.value);
      AnalyticsHelper.trackChatBuddleBtn(buddleName: buddleName);
      
      // 保存到缓存（设备绑定，不是账号绑定）
      await SpUtil.putInteger(_bubbleStyleCacheKey, selectedBubbleStyle.value);
      
      // 更新聊天控制器的气泡样式（这会触发消息列表自动更新）
      chatController.updateBubbleStyle(selectedBubbleStyle.value);
      
      debugPrint('💬 应用聊天气泡样式: ${selectedBubbleStyle.value}');
      
      // 直接返回到聊天页面，跳过设置页面
      Get.until((route) => route.settings.name == KissuRoutePath.chat);
    } catch (e) {
      debugPrint('💬 应用气泡样式失败: $e');
      // 即使出错也直接返回到聊天页面
      Get.until((route) => route.settings.name == KissuRoutePath.chat);
    }
  }
  
  /// 根据气泡样式获取对应的ID
  String _getBubbleId(int bubbleStyle) {
    // 气泡ID映射：300011=第一套, 300012=第二套, 300013=第三套, 300014=第四套
    const bubbleIds = ['棕色气泡', '纯粉色气泡', '蓝色星星气泡', '粉色兔子气泡'];
    if (bubbleStyle >= 1 && bubbleStyle <= 4) {
      return bubbleIds[bubbleStyle - 1];
    }
    return '棕色气泡'; // 默认返回第一套
  }
}

