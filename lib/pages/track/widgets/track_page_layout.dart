import 'package:flutter/material.dart';
import 'track_sheet_manager.dart';
import 'track_map_widget.dart';
import 'track_overlay_manager.dart';
import 'track_toolbar_widget.dart';
import '../track_controller.dart';
import '../track_page_config.dart';

/// 轨迹页面主布局组件
/// 负责整体页面的布局结构和管理各个子组件
class TrackPageLayout extends StatefulWidget {
  final TrackController controller;

  const TrackPageLayout({
    super.key,
    required this.controller,
  });

  @override
  State<TrackPageLayout> createState() => _TrackPageLayoutState();
}

class _TrackPageLayoutState extends State<TrackPageLayout>
    with WidgetsBindingObserver {
  late final TrackSheetManager _sheetManager;
  late final TrackOverlayManager _overlayManager;
  late final TrackToolbarWidget _toolbarWidget;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _sheetManager = TrackSheetManager(controller: widget.controller);
    _overlayManager = TrackOverlayManager(controller: widget.controller);
    _toolbarWidget = TrackToolbarWidget(controller: widget.controller);

    // 页面初始化时刷新轨迹数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.refreshCurrentUserData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 更新屏幕尺寸参数
    _sheetManager.updateDimensions(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 生命周期管理逻辑可以在这里处理
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrackPageConfig.backgroundWhite,
      body: Stack(
        children: [
          // 地图组件
          TrackMapWidget(controller: widget.controller),

          // 背景遮罩层
          _overlayManager.buildBackgroundOverlay(),

          // 全屏渐变背景
          _overlayManager.buildGradientBackground(),

          // 左侧浮动按钮组
          _toolbarWidget.buildLeftFloatingButtons(),

          // 右侧轨迹播放浮动按钮
          _toolbarWidget.buildRightReplayButton(),

          // 下半屏滑动面板
          _sheetManager.buildDraggableSheet(),

          // 底部吸底图片
          _overlayManager.buildBottomImage(),

          // 地图logo
          _overlayManager.buildMapLogo(),

          // 顶部返回按钮
          _toolbarWidget.buildBackButton(),

          // 顶部头像行
          _toolbarWidget.buildAvatarRow(),
        ],
      ),
    );
  }
}
