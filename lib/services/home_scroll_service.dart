import 'package:get/get.dart';
import 'package:kissu_app/utils/screen_adaptation.dart';

/// 首页滚动位置服务
/// 用于在跳转到首页前预设背景图片的滚动位置，避免闪烁
class HomeScrollService extends GetxService {
  static HomeScrollService get instance => Get.find<HomeScrollService>();
  
  double? _presetScrollOffset;
  
  /// 预设滚动偏移量
  double? get presetScrollOffset => _presetScrollOffset; 
  
  /// 计算并设置预设滚动位置
  void calculateAndSetPresetPosition() {
    // 使用屏幕适配工具计算预设滚动位置
    _presetScrollOffset = ScreenAdaptation.getPresetScrollOffset();
    
    print('🎯 预设首页背景滚动位置: 屏幕宽度=${ScreenAdaptation.screenWidth}, 动态背景宽度=${ScreenAdaptation.getDynamicContainerSize().width}, 预设偏移=${_presetScrollOffset}');
  }
  
  /// 清除预设位置（使用后清除）
  void clearPresetPosition() {
    _presetScrollOffset = null;
  }
  
  /// 检查是否有预设位置
  bool get hasPresetPosition => _presetScrollOffset != null;
}
