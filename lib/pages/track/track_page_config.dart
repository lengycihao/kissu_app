import 'package:flutter/material.dart';

/// 轨迹页面UI配置类
/// 统一管理所有UI常量、颜色、尺寸和布局参数
class TrackPageConfig {
  // ===== 颜色常量 =====
  static const Color primaryPink = Color(0xFFFF9AD9);
  static const Color secondaryPink = Color(0xFFFF88AA);
  static const Color backgroundWhite = Colors.white;
  static const Color backgroundGray = Color(0xfff6f6f6);
  static const Color overlayBlack = Colors.black;
  static const Color borderGray = Color(0xFFD9D9D9);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0x99000000);
  static const Color gradientStart = Color(0xffFFF1FD);
  static const Color gradientEnd = Color(0xfff6f6f6);

  // ===== 尺寸常量 =====
  // 头像尺寸
  static const double avatarSizeSelected = 38.0;
  static const double avatarSizeUnselected = 34.0;

  // 指示条尺寸
  static const double indicatorWidth = 46.0;
  static const double indicatorHeight = 7.0;
  static const double indicatorBorderRadius = 3.5;

  // 按钮尺寸
  static const double buttonSize = 24.0;
  static const double buttonBorderRadius = 22.0;

  // 面板圆角
  static const double panelBorderRadius = 20.0;
  static const double panelTopBorderRadius = 18.0;

  // 地图logo尺寸
  static const double mapLogoWidth = 68.0;
  static const double mapLogoHeight = 22.0;

  // 底部背景图片高度
  static const double bottomImageHeight = 115.0;

  // ===== 布局参数 =====
  // 面板高度计算参数
  static const double bindPartnerPanelHeight = 310.0; // 未绑定或未开通会员
  static const double vipPanelHeight = 190.0; // 已绑定且是会员
  static const double maxPanelOffset = 100.0;

  // 面板滑动相关
  static const double mapEnableThreshold = 0.3; // 地图手势启用阈值
  static const double middleSnapBase = 0.5; // 中间吸顶基准值
  static const double bindPartnerSnapOffset = 21.0; // 已绑定偏移量
  static const double unbindPartnerSnapOffset = 57.0; // 未绑定偏移量

  // 透明度计算参数
  static const double maxOverlayOpacity = 0.4;
  static const double maxGradientOpacity = 0.8;

  // ===== 动画时长 =====
  static const Duration shortAnimation = Duration(milliseconds: 100);
  static const Duration normalAnimation = Duration(milliseconds: 150);
  static const Duration longAnimation = Duration(milliseconds: 300);
  static const Duration sheetSnapAnimation = Duration(milliseconds: 200);

  // ===== 边距和间距 =====
  static const double defaultPadding = 16.0;
  static const double smallPadding = 10.0;
  static const double tinyPadding = 5.0;
  static const double horizontalMargin = 14.0;

  // ===== 阴影配置 =====
  static const BoxShadow backButtonShadow = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxShadow avatarShadow = BoxShadow(
    color: Color(0x4DFF88AA),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  // ===== 渐变配置 =====
  static const LinearGradient panelGradient = LinearGradient(
    colors: [gradientStart, backgroundGray, backgroundGray],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.3, 1.0],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundGray, backgroundWhite, backgroundGray],
  );

  // ===== 边框配置 =====
  static BorderRadius get defaultBorderRadius =>
      BorderRadius.circular(panelBorderRadius);

  static BorderRadius get panelTopBorderRadiusObject =>
      BorderRadius.vertical(top: Radius.circular(panelTopBorderRadius));

  static BorderRadiusGeometry get panelTopBorderRadiusGeometry =>
      BorderRadius.vertical(top: Radius.circular(panelTopBorderRadius));

  static double get panelTopBorderRadiusValue => panelTopBorderRadius;

  // ===== 工具方法 =====
  /// 根据绑定状态计算面板初始高度
  static double getInitialHeight({
    required bool isBindPartner,
    required bool isVip,
  }) {
    return (!isBindPartner || !isVip)
        ? bindPartnerPanelHeight
        : vipPanelHeight;
  }

  /// 根据绑定状态计算面板最小高度
  static double getMinHeight({
    required bool isBindPartner,
    required bool isVip,
  }) {
    return (!isBindPartner || !isVip)
        ? bindPartnerPanelHeight
        : vipPanelHeight;
  }

  /// 计算中间吸顶位置
  static double getMiddleSnapSize({
    required bool isBindPartner,
    required double screenHeight,
  }) {
    final offset = isBindPartner
        ? bindPartnerSnapOffset
        : unbindPartnerSnapOffset;
    return middleSnapBase + (offset / screenHeight);
  }
}
