import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'analytics_manager.dart';
import 'analytics_params.dart';

/// 页面埋点Mixin
/// 用于自动记录页面进入时间、停留时长等信息
/// 
/// 使用方式：
/// ```dart
/// class MyController extends GetxController with AnalyticsPageMixin {
///   @override
///   String get analyticsPageId => HomeEvents.pageId;
///   
///   @override
///   String get analyticsEventId => HomeEvents.page;
/// }
/// ```
mixin AnalyticsPageMixin on GetxController {
  /// 页面ID（子类必须实现）
  String get analyticsPageId;
  
  /// 事件ID（子类必须实现）
  String get analyticsEventId;
  
  /// 来源页面（可选，子类可覆盖）
  String? get analyticsSourcePage => null;
  
  /// 额外的页面参数（可选，子类可覆盖）
  Map<String, dynamic>? get analyticsExtraParams => null;

  /// 页面进入时间
  DateTime? _pageEnterTime;
  
  /// 离开方式
  String _exitType = ExitTypeValue.back;
  
  /// 是否已记录页面离开事件
  bool _hasTrackedPageExit = false;

  @override
  void onInit() {
    super.onInit();
    _recordPageEnter();
  }

  @override
  void onClose() {
    _recordPageExit();
    super.onClose();
  }

  /// 记录页面进入
  void _recordPageEnter() {
    _pageEnterTime = DateTime.now();
    _hasTrackedPageExit = false;
    debugPrint('📊 页面进入: $analyticsEventId');
  }

  /// 记录页面离开
  void _recordPageExit() {
    if (_hasTrackedPageExit || _pageEnterTime == null) return;
    _hasTrackedPageExit = true;

    final enterTime = _formatEnterTime(_pageEnterTime!);
    final duration = _calculateDuration(_pageEnterTime!);

    try {
      AnalyticsManager.instance.trackPageView(
        pageId: analyticsPageId,
        eventId: analyticsEventId,
        enterTime: enterTime,
        duration: duration,
        sourcePage: analyticsSourcePage,
        exitType: _exitType,
        params: analyticsExtraParams,
      );
      debugPrint('📊 页面离开: $analyticsEventId, 停留: $duration');
    } catch (e) {
      debugPrint('❌ 记录页面离开失败: $e');
    }
  }

  /// 设置离开方式
  /// 
  /// 在页面跳转前调用此方法设置离开方式
  /// [exitType] 离开方式，使用 [ExitTypeValue] 中的常量
  void setExitType(String exitType) {
    _exitType = exitType;
  }

  /// 标记进入下一页
  /// 
  /// 在跳转到下一页前调用
  void markNavigateToNextPage() {
    _exitType = ExitTypeValue.nextPage;
  }

  /// 标记返回上一页
  /// 
  /// 在返回上一页前调用
  void markNavigateBack() {
    _exitType = ExitTypeValue.back;
  }

  /// 格式化进入时间（格式：年-月-日 时:分:秒）
  String _formatEnterTime(DateTime dateTime) {
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }

  /// 计算停留时长（格式：mm:ss）
  String _calculateDuration(DateTime enterTime) {
    final now = DateTime.now();
    final diff = now.difference(enterTime);
    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// 页面埋点Mixin（用于StatefulWidget）
/// 
/// 使用方式：
/// ```dart
/// class _MyPageState extends State<MyPage> with AnalyticsPageStateMixin {
///   @override
///   String get analyticsPageId => HomeEvents.pageId;
///   
///   @override
///   String get analyticsEventId => HomeEvents.page;
/// }
/// ```
mixin AnalyticsPageStateMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  /// 页面ID（子类必须实现）
  String get analyticsPageId;
  
  /// 事件ID（子类必须实现）
  String get analyticsEventId;
  
  /// 来源页面（可选，子类可覆盖）
  String? get analyticsSourcePage => null;
  
  /// 额外的页面参数（可选，子类可覆盖）
  Map<String, dynamic>? get analyticsExtraParams => null;

  /// 页面进入时间
  DateTime? _pageEnterTime;
  
  /// 离开方式
  String _exitType = ExitTypeValue.back;
  
  /// 是否已记录页面离开事件
  bool _hasTrackedPageExit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recordPageEnter();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordPageExit();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // App进入后台，记录离开方式
      _exitType = ExitTypeValue.toBackground;
    } else if (state == AppLifecycleState.detached) {
      // App被关闭
      _exitType = ExitTypeValue.closeApp;
      _recordPageExit();
    }
  }

  /// 记录页面进入
  void _recordPageEnter() {
    _pageEnterTime = DateTime.now();
    _hasTrackedPageExit = false;
    debugPrint('📊 页面进入: $analyticsEventId');
  }

  /// 记录页面离开
  void _recordPageExit() {
    if (_hasTrackedPageExit || _pageEnterTime == null) return;
    _hasTrackedPageExit = true;

    final enterTime = _formatEnterTime(_pageEnterTime!);
    final duration = _calculateDuration(_pageEnterTime!);

    try {
      AnalyticsManager.instance.trackPageView(
        pageId: analyticsPageId,
        eventId: analyticsEventId,
        enterTime: enterTime,
        duration: duration,
        sourcePage: analyticsSourcePage,
        exitType: _exitType,
        params: analyticsExtraParams,
      );
      debugPrint('📊 页面离开: $analyticsEventId, 停留: $duration');
    } catch (e) {
      debugPrint('❌ 记录页面离开失败: $e');
    }
  }

  /// 设置离开方式
  void setExitType(String exitType) {
    _exitType = exitType;
  }

  /// 标记进入下一页
  void markNavigateToNextPage() {
    _exitType = ExitTypeValue.nextPage;
  }

  /// 标记返回上一页
  void markNavigateBack() {
    _exitType = ExitTypeValue.back;
  }

  /// 格式化进入时间
  String _formatEnterTime(DateTime dateTime) {
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }

  /// 计算停留时长
  String _calculateDuration(DateTime enterTime) {
    final now = DateTime.now();
    final diff = now.difference(enterTime);
    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
