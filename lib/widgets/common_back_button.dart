import 'package:flutter/material.dart';

/// 通用返回按钮
///
/// 设计目标：
/// 1. **点击区域更大**：通过放大命中区域提升可点击性；
/// 2. **不影响现有 UI 布局**：图标尺寸和对齐方式保持不变；
/// 3. **点击灵敏**：使用 `HitTestBehavior.translucent` 捕获空白区域点击。
class CommonBackButton extends StatelessWidget {
  /// 点击回调
  final VoidCallback? onTap;

  /// 图标资源路径（默认使用“我的”页面的返回图标）
  final String assetPath;

  /// 图标实际显示大小（不改变原有视觉效果）
  final double iconSize;

  /// 命中区域尺寸（越大越好点，但尽量控制在不明显改变布局的范围内）
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
        // 命中区域略大于图标，但不会夸张放大，避免破坏原有布局观感
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


