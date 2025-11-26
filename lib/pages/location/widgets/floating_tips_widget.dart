import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../location_v2_controller.dart';
import 'location_tips_manager.dart';

/// 浮动提示组件
/// 支持三种不同的提示样式
class FloatingTipsWidget extends StatelessWidget {
  final LocationV2Controller controller; // 控制器，用于获取滑动状态
  final LocationTipsManager tipsManager; // 提示管理器
  final double screenHeight; // 屏幕高度

  const FloatingTipsWidget({
    super.key,
    required this.controller,
    required this.tipsManager,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 检查是否有提示需要显示
      if (!tipsManager.hasAnyTip) return const SizedBox.shrink();

      // 计算头像底部位置：状态栏高度 + 16px + 头像最大高度(38.4px) + 26px间距
      final avatarTop = MediaQuery.of(context).padding.top + 16;
      final avatarMaxHeight = 32.0 * 1.2; // 头像选中时的最大高度
      final tipTop = avatarTop + avatarMaxHeight + 26;

      // 获取当前滑动进度
      final sheetPercent = controller.sheetPercent.value;

      // 🔧 动态计算中间吸顶位置（与DraggableScrollableSheet的snapSize保持一致）
      final isBindPartner = controller.isBindPartner.value;
      final middleSnapSize = isBindPartner
          ? 0.5 +
                (21 / screenHeight) // 已绑定：屏幕中间 + 21px偏移
          : 0.5 + (57 / screenHeight); // 未绑定：屏幕中间 + 57px偏移

      // 计算顶部吸顶位置的百分比
      final maxPercent = (screenHeight - 100) / screenHeight;

      // 计算透明度：从中间吸顶位置滑向顶部吸顶位置时逐渐消失
      double opacity = 1.0;
      if (sheetPercent > middleSnapSize) {
        // 从中间到顶部的进度：1 到 0（逐渐消失）
        final progress =
            (sheetPercent - middleSnapSize) / (maxPercent - middleSnapSize);
        opacity = (1.0 - progress).clamp(0.0, 1.0);
      }

      return Positioned(
        top: tipTop, // 距离顶部头像底部26px的间距
        left: 16, // 距离屏幕左侧间距
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: opacity,
          child: _buildCurrentTip(),
        ),
      );
    });
  }

  /// 构建当前应该显示的提示
  /// 🔧 修改：支持同时显示多个提示，使用Column垂直排列
  Widget _buildCurrentTip() {
    List<Widget> tips = [];

    // 按优先级顺序添加提示
    if (tipsManager.showPermissionTip.value) {
      tips.add(
        GestureDetector(
          onTap: tipsManager.onPermissionTipTap,
          child: _buildBasicTip(
            text: '请开启实时定位，更好体验',
            richText: 'KissU',
            hasCloseButton: false,
          ),
        ),
      );
    }

    if (tipsManager.showPartnerLocationTip.value) {
      tips.add(
        _buildBasicTip(
          text: '对方未开启定位，赶快提醒对方哦~',
          richText: '',
          hasCloseButton: true,
          onClose: tipsManager.onPartnerLocationTipClose,
          hasArrow: false, // 这个提示不显示箭头
        ),
      );
    }

    if (tipsManager.showVipExpiryTip.value) {
      tips.add(
        GestureDetector(
          onTap: tipsManager.onVipExpiryTipTap,
          child: _buildMembershipTip(),
        ),
      );
    }

    if (tips.isEmpty) return const SizedBox.shrink();

    // 如果只有一个提示，直接返回
    if (tips.length == 1) return tips.first;

    // 多个提示时使用Column垂直排列
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tips
          .map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8), // 提示之间的间距
              child: tip,
            ),
          )
          .toList(),
    );
  }

  Widget _buildBasicTip({
    required String text,
    required String richText,
    required bool hasCloseButton,
    VoidCallback? onClose,
    bool hasArrow = true, // 默认显示箭头
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 240,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFf000000), // #FFFCE8
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Image(
                image: AssetImage('assets/4.0/kissu4_location_white.webp'),
                width: 14,
                height: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: text,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFffffff), // #333333
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: richText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFF8FBD ), // #333333
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Text(
                  //   text,
                  //   style: const TextStyle(
                  //     fontSize: 12,
                  //     color: Color(0xFFffffff), // #333333
                  //     fontWeight: FontWeight.w400,
                  //   ),
                  //   maxLines: 1,
                  // ),
                ),
              ),
              // 箭头图标（可控显示）
              if (hasArrow) ...[
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFFffffff), // #AD6D48
                ),
                const SizedBox(width: 11),
              ] else
                const SizedBox(width: 16), // 没有箭头时保持右边距
            ],
          ),
        ),
        // 关闭按钮（样式2和3才有）
        if (hasCloseButton)
          Positioned(
            top: -10, // 🔧 扩大点击区域：越界出去上边10px
            right: -5, // 🔧 扩大点击区域：越界出去右边10px
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                width: 24, // 🔧 扩大点击区域：从14增加到24
                height: 24, // 🔧 扩大点击区域：从14增加到24
                alignment: Alignment.center, // 🔧 确保图标居中
                child: Container(
                  width: 14, // 保持视觉大小不变
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Image(
                    image: AssetImage('assets/4.0/kissu4_close_black.webp'),
                    width: 16,
                    height: 16,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMembershipTip() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 240,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFf000000), // #FFFCE8
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Image(
                image: AssetImage('assets/4.0/kissu4_location_white.webp'),
                width: 14,
                height: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Obx(
                  () => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '你的会员还有${tipsManager.vipExpiryText.value}到期！',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFffffff), // #333333
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
              // 去续费按钮
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '去续费',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF408D), // #FF408D
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFFffffff), // #AD6D48
                  ),
                ],
              ),
              const SizedBox(width: 11),
            ],
          ),
        ),
         
        Positioned(
            top: -10, // 🔧 扩大点击区域：越界出去上边10px
            right: -5, // 🔧 扩大点击区域：越界出去右边10px
            child: GestureDetector(
              onTap: () => tipsManager.showVipExpiryTip.value = false,
              child: Container(
                width: 24, // 🔧 扩大点击区域：从14增加到24
                height: 24, // 🔧 扩大点击区域：从14增加到24
                alignment: Alignment.center, // 🔧 确保图标居中
                child: Container(
                  width: 14, // 保持视觉大小不变
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Image(
                    image: AssetImage('assets/4.0/kissu4_close_black.webp'),
                    width: 16,
                    height: 16,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
