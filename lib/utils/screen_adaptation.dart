import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 屏幕适配工具类
/// 用于将基于1500*812设计稿的坐标和尺寸适配到不同屏幕尺寸
class ScreenAdaptation {
  // 设计稿基准尺寸
  static const double designWidth = 1500.0;
  static const double designHeight = 812.0;
  
  /// 获取屏幕宽度
  static double get screenWidth => Get.width;
  
  /// 获取屏幕高度  
  static double get screenHeight => Get.height;
  
  /// 计算宽度缩放比例
  static double get widthScale => screenWidth / designWidth;
  
  /// 计算高度缩放比例
  static double get heightScale => screenHeight / designHeight;
  
  /// 计算动态背景宽度（基于屏幕高度：屏幕高度/812*1500）
  static double get dynamicBackgroundWidth => screenHeight / designHeight * designWidth;
  
  /// 使用宽度比例缩放（保持宽高比）
  static double scaleWidth(double value) => value * widthScale;
  
  /// 使用高度比例缩放
  static double scaleHeight(double value) => value * heightScale;
  
  /// 使用宽度比例缩放坐标（推荐用于水平布局）
  static double scaleX(double value) => value * widthScale;
  
  /// 使用高度比例缩放坐标（推荐用于垂直布局）
  static double scaleY(double value) => value * heightScale;
  
  /// 基于动态背景宽度缩放X坐标
  static double scaleXByDynamicWidth(double value) => value * (dynamicBackgroundWidth / designWidth);
  
  /// 基于高度比例缩放大小（用于PAG文件等元素）
  static double scaleSizeByHeight(double value) => value * heightScale;
  
  /// 缩放尺寸（使用宽度比例保持宽高比）
  static Size scaleSize(Size size) => Size(
    scaleWidth(size.width),
    scaleWidth(size.height), // 使用宽度比例保持宽高比
  );
  
  /// 缩放位置（使用宽度比例）
  static Offset scalePosition(Offset position) => Offset(
    scaleX(position.dx),
    scaleY(position.dy),
  );
  
  /// 获取适配后的背景图尺寸
  static Size getAdaptedBackgroundSize() {
    // 根据屏幕宽度适配，保持宽高比
    final adaptedWidth = screenWidth;
    final adaptedHeight = adaptedWidth * (designHeight / designWidth);
    return Size(adaptedWidth, adaptedHeight);
  }
  
  /// 获取适配后的背景图容器尺寸
  static Size getAdaptedContainerSize() {
    final backgroundSize = getAdaptedBackgroundSize();
    return Size(
      backgroundSize.width,
      screenHeight - 10, // 保持原有的高度逻辑
    );
  }

  /// 获取动态容器尺寸（用于保持滑动效果）
  static Size getDynamicContainerSize() {
    return Size(
      dynamicBackgroundWidth, // 使用动态背景宽度
      screenHeight - 10, // 高度仍然需要适配
    );
  }

  /// 获取动态背景图片尺寸（用于保持滑动效果）
  static Size getDynamicBackgroundSize() {
    return Size(
      dynamicBackgroundWidth, // 使用动态背景宽度
      screenHeight, // 使用屏幕高度
    );
  }
  
  /// 计算背景图居中偏移量
  static double getBackgroundCenterOffset() {
    final containerWidth = getAdaptedContainerSize().width;
    final screenWidth = ScreenAdaptation.screenWidth;
    return (containerWidth - screenWidth) / 2;
  }

  /// 计算动态背景图居中偏移量（用于滑动效果）
  static double getDynamicBackgroundCenterOffset() {
    final containerWidth = getDynamicContainerSize().width;
    final screenWidth = ScreenAdaptation.screenWidth;
    return (containerWidth - screenWidth) / 2;
  }
  
  /// 计算预设滚动位置（向左偏移190px的逻辑）
  static double getPresetScrollOffset() {
    final centerOffset = getDynamicBackgroundCenterOffset(); // 使用动态偏移量
    final scrollOffset = centerOffset - scaleXByDynamicWidth(190); // 向左偏移190px，使用动态宽度缩放
    return scrollOffset.clamp(0.0, double.infinity);
  }
}

