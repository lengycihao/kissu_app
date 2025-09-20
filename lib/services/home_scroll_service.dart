import 'package:get/get.dart';

/// 首页滚动位置服务
/// 用于在跳转到首页前预设背景图片的滚动位置，避免闪烁
class HomeScrollService extends GetxService {
  static HomeScrollService get instance => Get.find<HomeScrollService>();
  
  double? _presetScrollOffset;
  
  /// 预设滚动偏移量
  double? get presetScrollOffset => _presetScrollOffset;
  
  /// 计算并设置预设滚动位置
  void calculateAndSetPresetPosition() {
    // 背景图片宽度是1500px，屏幕宽度通过Get.width获取
    final screenWidth = Get.width;
    final backgroundWidth = 1500.0;
    
    // 计算需要滚动的距离，让图片中心对准屏幕中心，然后再向左偏移190px
    final centerOffset = (backgroundWidth - screenWidth) / 2;
    final scrollOffset = centerOffset - 190; // 向左偏移190px
    
    // 确保滚动距离不会小于0
    _presetScrollOffset = scrollOffset.clamp(0.0, double.infinity);
    
    print('🎯 预设首页背景滚动位置: 屏幕宽度=${screenWidth}, 背景宽度=${backgroundWidth}, 预设偏移=${_presetScrollOffset}');
  }
  
  /// 清除预设位置（使用后清除）
  void clearPresetPosition() {
    _presetScrollOffset = null;
  }
  
  /// 检查是否有预设位置
  bool get hasPresetPosition => _presetScrollOffset != null;
}
