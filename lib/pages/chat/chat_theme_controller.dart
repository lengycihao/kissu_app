 import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/network/utils/sp_util.dart';
import 'package:kissu_app/pages/chat/chat_controller.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';

class ChatThemeController extends GetxController {
  // 获取聊天控制器实例
  late ChatController chatController;

  // 主题列表（1-4）
  static const List<int> themes = [1, 2, 3, 4];

  // 缓存key
  static const String _themeCacheKey = 'chat_theme';
  static const String _themeBackgroundCacheKey = 'chat_theme_background';
  static const String _themeBubbleCacheKey = 'chat_theme_bubble';

  // 当前选中的主题（1-4）
  final RxInt selectedTheme = 1.obs;

  // 预览主题（用于页面顶部预览）
  final RxInt previewTheme = 1.obs;

  @override
  void onInit() {
    super.onInit();
    // 获取聊天控制器实例
    chatController = Get.find<ChatController>();
    _loadSelectedTheme();
  }

  // 加载已保存的主题
  Future<void> _loadSelectedTheme() async {
    final savedTheme = await SpUtil.getInteger(_themeCacheKey);
    if (savedTheme > 0 && savedTheme <= 4) {
      selectedTheme.value = savedTheme;
      previewTheme.value = savedTheme;
    } else {
      // 如果没有保存的主题，使用默认主题1
      selectedTheme.value = 1;
      previewTheme.value = 1;
    }
  }

  // 选择主题
  void selectTheme(int theme) {
    if (theme >= 1 && theme <= 4) {
      selectedTheme.value = theme;
      previewTheme.value = theme;
    }
  }

  // 获取主题对应的背景路径
  String getThemeBackgroundPath(int theme) {
    return 'assets/chat/kissu_chat_theme_bg$theme.webp';
  }

  // 获取主题对应的气泡预览路径（用于缩略图）
  String getThemeBubblePreviewPath(int theme) {
    return 'assets/chat/kissu_chat_bubble_show$theme.webp';
  }

  // 获取主题对应的气泡样式（用于实际应用）
  int getThemeBubbleStyle(int theme) {
    return theme; // 主题1对应气泡1，主题2对应气泡2，以此类推
  }

  /// 应用选中的主题
  /// 同时更新背景和气泡，但保持三者独立存储
  /// 注意：设置主题时，会同时更新背景和气泡的缓存，但它们是独立的
  /// 用户后续单独设置背景或气泡时，不会影响主题设置
  Future<void> applyTheme() async {
    try {
      final theme = selectedTheme.value;
      
      // 埋点：记录主题选择
      final themeName = _getThemeId(theme);
      AnalyticsHelper.trackChatThemeBtn(themeName: themeName);
      
      // 获取主题对应的背景和气泡
      final backgroundPath = getThemeBackgroundPath(theme);
      final bubbleStyle = getThemeBubbleStyle(theme);
      
      // 保存主题到缓存
      await SpUtil.putInteger(_themeCacheKey, theme);
      
      // 保存主题对应的背景和气泡到独立的缓存key（用于记录主题设置）
      await SpUtil.putString(_themeBackgroundCacheKey, backgroundPath);
      await SpUtil.putInteger(_themeBubbleCacheKey, bubbleStyle);
      
      // 同时更新背景和气泡的独立缓存（这样它们能正常工作）
      // 这样当用户单独设置背景或气泡时，会覆盖这些值，实现独立设置
      await SpUtil.putString('chat_background_path', backgroundPath);
      await SpUtil.putInteger('chat_bubble_style', bubbleStyle);
      
      // 更新聊天控制器的背景、气泡样式和主题
      chatController.backgroundImage.value = backgroundPath;
      chatController.updateBubbleStyle(bubbleStyle);
      chatController.updateTheme(theme);
      
      logDebug('💬 应用聊天主题: $theme');
      logDebug('💬 主题背景: $backgroundPath');
      logDebug('💬 主题气泡: $bubbleStyle');
      
      // 直接返回到聊天页面，跳过设置页面
      Get.until((route) => route.settings.name == KissuRoutePath.chat);
      
      // 延迟显示提示，确保页面已经返回
      Future.delayed(const Duration(milliseconds: 300), () {
        OKToastUtil.showSuccess('主题已更换');
      });
    } catch (e) {
      logError('💬 应用主题失败: $e');
      // 出错时也直接返回到聊天页面
      Get.until((route) => route.settings.name == KissuRoutePath.chat);
    }
  }
  
  /// 根据主题获取对应的ID
  String _getThemeId(int theme) {
    // 主题ID映射：200011=第一套, 200012=第二套, 200013=第三套, 200014=第四套
    const themeIds = ['棕色主题', '星星主题', '蓝色主题', '粉色主题'];
    if (theme >= 1 && theme <= 4) {
      return themeIds[theme - 1];
    }
    return '棕色主题'; // 默认返回第一套
  }
}

