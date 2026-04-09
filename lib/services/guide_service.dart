import 'package:shared_preferences/shared_preferences.dart';

/// 引导页服务
/// 管理App首次启动引导页的显示状态
class GuideService {
  static const String _keyGuideShown = 'guide_shown';
  
  static GuideService? _instance;
  static GuideService get instance {
    _instance ??= GuideService._();
    return _instance!;
  }
  
  GuideService._();
  
  /// 检查是否需要显示引导页
  /// 返回true表示需要显示（首次启动）
  Future<bool> shouldShowGuide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShown = prefs.getBool(_keyGuideShown) ?? false;
      return !hasShown; // 未显示过则返回true
    } catch (e) {
      // 出错时默认不显示引导页
      return false;
    }
  }
  
  /// 标记引导页已显示
  Future<void> markGuideShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyGuideShown, true);
    } catch (e) {
      // 忽略错误
    }
  }
  
  /// 重置引导页状态（用于测试）
  Future<void> resetGuideStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyGuideShown);
    } catch (e) {
      // 忽略错误
    }
  }
}
