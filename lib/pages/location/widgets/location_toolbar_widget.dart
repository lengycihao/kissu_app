import 'package:flutter/material.dart';
import '../location_v2_controller.dart';
import 'floating_action_buttons.dart';
import 'left_floating_buttons.dart';

/// 定位页面工具栏组件管理器
/// 负责管理所有悬浮按钮和工具栏组件
class LocationToolbarWidget {
  final LocationV2Controller controller;

  LocationToolbarWidget({required this.controller});

  /// 构建浮动操作按钮
  Widget buildFloatingActionButtons() {
    return Builder(
      builder: (context) => FloatingActionButtons(
        screenHeight: MediaQuery.of(context).size.height,
        controller: controller,
      ),
    );
  }

  /// 构建左侧浮动按钮
  Widget buildLeftFloatingButtons() {
    return Builder(
      builder: (context) => LeftFloatingButtons(
        screenHeight: MediaQuery.of(context).size.height,
        controller: controller,
      ),
    );
  }

  /// 构建返回按钮
  Widget buildBackButton(BuildContext context, ScrollController? scrollController) {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 5,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => controller.handleBackButtonTap(scrollController),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/kissu_mine_back.webp',
            width: 22,
            height: 22,
          ),
        ),
      ),
    );
  }
}
