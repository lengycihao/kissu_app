import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

          // 渐变背景遮罩（在背景图片上方）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Obx(() {
              // 计算透明度：从中间吸顶位置到顶部吸顶时，从0x00ffffff变成0x99ffffff
              final currentPercent = widget.controller.sheetPercent.value;
              final screenHeight = MediaQuery.of(Get.context!).size.height;
              
              // 计算中间吸顶位置
              final actualBindStatus = widget.controller.getActualBindStatus();
              final middleSnapSize = actualBindStatus
                  ? 0.5 + (21 / screenHeight)
                  : 0.5 + (57 / screenHeight);
              
              // 顶部吸顶位置
              final maxPercent = _sheetManager.maxHeight / screenHeight;

              double opacity = 0.0;
              if (currentPercent > middleSnapSize) {
                if (currentPercent >= maxPercent) {
                  opacity = 0.7; // 0xb3ffffff 的 alpha 值是 0.7
                } else {
                  // 从中间吸顶到顶部吸顶时线性插值
                  opacity = 0.7 * ((currentPercent - middleSnapSize) / (maxPercent - middleSnapSize));
                }
              }

              return Container(
                color: Color(0xFFFFFFFF).withValues(alpha: opacity),
              );
            }),
          ),

          // 顶部背景图片
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160, // 背景图片高度设为固定值
            child: Image.asset(
              'assets/4.0/kissu_location_bar_bg.webp', // 暂时使用定位页面的背景图片
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          // // 背景遮罩层
          // _overlayManager.buildBackgroundOverlay(),

          // // 全屏渐变背景
          // _overlayManager.buildGradientBackground(),


          // 右侧轨迹播放浮动按钮
          _toolbarWidget.buildRightReplayButton(),

          // 下半屏滑动面板
          _sheetManager.buildDraggableSheet(),

          // 底部吸底图片
          _overlayManager.buildBottomImage(),

          // 地图logo
          _overlayManager.buildMapLogo(),

          // 顶部返回按钮
          _toolbarWidget.buildBackButton(context, _sheetManager.scrollController),

          // 顶部头像行
          _toolbarWidget.buildAvatarRow(),
        ],
      ),
    );
  }
}
