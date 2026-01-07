import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'location_sheet_manager.dart';
import 'location_map_widget.dart';
import 'location_overlay_manager.dart';
import 'location_toolbar_widget.dart';
import '../location_v2_controller.dart';
import 'package:kissu_app/services/analytics/analytics_manager.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/services/analytics/analytics_params.dart';

/// 定位页面主布局组件
/// 负责整体页面的布局结构和管理各个子组件
class LocationPageLayout extends StatefulWidget {
  final LocationV2Controller controller;

  const LocationPageLayout({super.key, required this.controller});

  @override
  State<LocationPageLayout> createState() => _LocationPageLayoutState();
}

class _LocationPageLayoutState extends State<LocationPageLayout>
    with WidgetsBindingObserver {
  late final LocationSheetManager _sheetManager;
  late final LocationOverlayManager _overlayManager;
  late final LocationToolbarWidget _toolbarWidget;
  
  // 埋点相关
  int? _pageEnterTime;
  int _exitType = ExitTypeValue.back;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 埋点：记录页面进入时间
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch;

    _sheetManager = LocationSheetManager(controller: widget.controller);
    _overlayManager = LocationOverlayManager(controller: widget.controller);
    _toolbarWidget = LocationToolbarWidget(controller: widget.controller);
  }

  @override
  void dispose() {
    // 埋点：记录页面离开事件
    if (_pageEnterTime != null) {
      final exitTime = DateTime.now().millisecondsSinceEpoch;
      final durationMs = exitTime - _pageEnterTime!;
      final enterTimeStr = _formatEnterTime(DateTime.fromMillisecondsSinceEpoch(_pageEnterTime!));
      final durationStr = _formatDuration(durationMs);
      
      AnalyticsManager.instance.trackPageView(
        pageId: LocationEvents.pageId,
        eventId: LocationEvents.page,
        enterTime: enterTimeStr,
        duration: durationStr,
        sourcePage: Get.arguments != null && Get.arguments is Map && Get.arguments.containsKey('source_page')
            ? (Get.arguments['source_page'] as int).toString()
            : null,
        exitType: _exitType,
      );
    }
    
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  /// 格式化页面进入时间为 "年-月-日 时:分:秒" 格式
  String _formatEnterTime(DateTime dateTime) {
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }
  
  /// 格式化停留时长为 "分:秒" 格式
  String _formatDuration(int durationMs) {
    final totalSeconds = (durationMs / 1000).floor();
    final minutes = (totalSeconds / 60).floor();
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      widget.controller.tipsManager.onAppResumed();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sheetManager.updateDimensions(context);
  }

  @override
  Widget build(BuildContext context) {
    widget.controller.pageContext = context;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFFFF6EF)),
        child: Stack(
          children: [
            // 地图Widget
            Positioned.fill(
              child: LocationMapWidget(controller: widget.controller),
            ),

            // 渐变背景遮罩（在背景图片上方）
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 160,
              child: Obx(() {
                // 计算透明度：从底部吸顶到顶部吸顶时，从0x00ffffff变成0x99ffffff
                final currentPercent = widget.controller.sheetPercent.value;
                final minPercent = 600.0 / MediaQuery.of(context).size.height; // 使用固定的最小高度
                final maxPercent = _sheetManager.maxHeight / MediaQuery.of(context).size.height;

                double opacity = 0.0;
                if (currentPercent > minPercent) {
                  if (currentPercent >= maxPercent) {
                    opacity = 0.7; // 0x99ffffff 的 alpha 值是 0.6
                  } else {
                    // 在中间位置时线性插值
                    opacity = 0.7 * ((currentPercent - minPercent) / (maxPercent - minPercent));
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
              height: 160, // 背景图片高度设为屏幕高度的25%
              child: Image.asset(
                'assets/4.0/kissu_location_bar_bg.webp',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
        
            // 切换视图时的过渡动画
            _overlayManager.buildSwitchTransition(),

            // // 全屏渐变背景
            // _overlayManager.buildGradientBackground(),

            // 浮动操作按钮
            _toolbarWidget.buildFloatingActionButtons(),

            // 左侧浮动按钮
            _toolbarWidget.buildLeftFloatingButtons(),

            // 浮动提示组件
            _overlayManager.buildFloatingTips(),

            // 离线提示覆盖层暂时注释不要删
            // _overlayManager.buildOfflineTipOverlay(),

            // 可拖拽下半屏
            _sheetManager.buildDraggableSheet(),

            // 底部吸底图片
            _overlayManager.buildBottomImage(),

            // 地图logo
            _overlayManager.buildMapLogo(),

            // 返回按钮
            _toolbarWidget.buildBackButton(
              context,
              _sheetManager.scrollController,
            ),
          ],
        ),
      ),
    );
  }
}
