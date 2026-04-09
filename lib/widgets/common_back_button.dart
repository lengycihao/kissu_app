import 'package:flutter/material.dart';

/// 通用导航栏组件
///
/// 功能特性：
/// 1. **背景图片支持**：可传入背景图片
/// 2. **高度可调**：可设置导航栏高度
/// 3. **返回按钮**：触摸区域大，图标16*16，边界距离屏幕16px
/// 4. **右侧按钮**：可选的右侧按钮
/// 5. **居中标题**：必须居中的标题文本
class CommonNavigationBar extends StatelessWidget {
  /// 导航栏高度（默认44）
  final double height;

  /// 背景图片路径
  final String? backgroundImage;

  /// 返回按钮点击回调
  final VoidCallback? onBackPressed;

  /// 返回按钮图标路径
  final String backIconPath;

  /// 返回按钮图标大小（默认16*16）
  final double backIconSize;

  /// 标题文本
  final String title;

  /// 标题样式
  final TextStyle? titleStyle;

  /// 右侧按钮Widget（可选）
  final Widget? rightWidget;

  /// 背景颜色（当没有背景图片时使用）
  final Color? backgroundColor;

  const CommonNavigationBar({
    super.key,
    this.height = 44,
    this.backgroundImage,
    this.onBackPressed,
    this.backIconPath = 'assets/images/kissu_mine_back.webp',
    this.backIconSize = 16,
    required this.title,
    this.titleStyle,
    this.rightWidget,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        image: backgroundImage != null
            ? DecorationImage(
                image: AssetImage(backgroundImage!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          // 返回按钮（左边，边界距离屏幕16px）
          if (onBackPressed != null)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: onBackPressed,
                child: SizedBox(
                  width: 44, // 触摸区域宽度
                  height: height, // 触摸区域高度
                  child: Center(
                    child: Image.asset(
                      backIconPath,
                      width: backIconSize,
                      height: backIconSize,
                    ),
                  ),
                ),
              ),
            ),

          // 标题（居中）
          Positioned(
            left: onBackPressed != null ? 60 : 16, // 如果有返回按钮，左侧预留空间
            right: rightWidget != null ? 60 : 16, // 如果有右侧按钮，右侧预留空间
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                title,
                style: titleStyle ??
                    const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // 右侧按钮（可选）
          if (rightWidget != null)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: rightWidget,
              ),
            ),
        ],
      ),
    );
  }
}

/// 通用返回按钮（保持向后兼容）
///
/// 已废弃：建议使用 CommonNavigationBar
/// 这个类保留是为了向后兼容，未来会移除
@Deprecated('Use CommonNavigationBar instead')
class CommonBackButton extends StatelessWidget {
  /// 点击回调
  final VoidCallback? onTap;

  /// 图标资源路径（默认使用"我的"页面的返回图标）
  final String assetPath;

  /// 图标实际显示大小
  final double iconSize;

  /// 命中区域尺寸
  final double hitSize;

  const CommonBackButton({
    super.key,
    this.onTap,
    this.assetPath = 'assets/images/kissu_mine_back.webp',
    this.iconSize = 22,
    this.hitSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: SizedBox(
        width: hitSize,
        height: hitSize,
        child: Center(
          child: Image.asset(
            assetPath,
            width: iconSize,
            height: iconSize,
          ),
        ),
      ),
    );
  }
}

