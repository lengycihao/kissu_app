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
  
  /// 是否需要来源页参数（默认false，只有绑定页面和会员页面需要设为true）
  bool get needSourcePage => false;
  
  /// 来源页面（只有needSourcePage为true时才会传递）
  String? get analyticsSourcePage => null;
  
  /// 额外的页面参数（可选，子类可覆盖）
  Map<String, dynamic>? get analyticsExtraParams => null;

  /// 页面进入时间（十位时间戳）
  int? _pageEnterTime;
  
  /// 离开方式（默认为返回）
  int _exitType = ExitTypeValue.back;
  
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
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _hasTrackedPageExit = false;
    _exitType = ExitTypeValue.back; // 重置离开方式
    debugPrint('📊 页面进入: $analyticsEventId');
  }

  /// 记录页面离开
  void _recordPageExit() {
    if (_hasTrackedPageExit || _pageEnterTime == null) return;
    _hasTrackedPageExit = true;

    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final duration = currentTime - _pageEnterTime!;

    try {
      AnalyticsManager.instance.trackPageView(
        pageId: analyticsPageId,
        eventId: analyticsEventId,
        enterTime: _pageEnterTime!,
        duration: duration,
        // 只有需要来源页的页面才传递sourcePage
        sourcePage: needSourcePage ? analyticsSourcePage : null,
        exitType: _exitType,
        params: analyticsExtraParams,
      );
      debugPrint('📊 页面离开: $analyticsEventId, 停留: ${duration}秒, 离开方式: $_exitType');
    } catch (e) {
      debugPrint('❌ 记录页面离开失败: $e');
    }
  }

  /// 设置离开方式
  /// 
  /// 在页面跳转前调用此方法设置离开方式
  /// [exitType] 离开方式，使用 [ExitTypeValue] 中的常量
  /// - 1: 返回
  /// - 2: 关闭APP
  /// - 3: 切换到后台
  /// - 4: 进入下一页
  void setExitType(int exitType) {
    _exitType = exitType;
  }

  /// 标记进入下一页（在跳转到下一页前调用）
  void markNavigateToNextPage() {
    _exitType = ExitTypeValue.nextPage;
  }

  /// 标记返回上一页（在返回上一页前调用）
  void markNavigateBack() {
    _exitType = ExitTypeValue.back;
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
  
  /// 是否需要来源页参数（默认false，只有绑定页面和会员页面需要设为true）
  bool get needSourcePage => false;
  
  /// 来源页面（只有needSourcePage为true时才会传递）
  String? get analyticsSourcePage => null;
  
  /// 额外的页面参数（可选，子类可覆盖）
  Map<String, dynamic>? get analyticsExtraParams => null;

  /// 页面进入时间（十位时间戳）
  int? _pageEnterTime;
  
  /// 离开方式（默认为返回）
  int _exitType = ExitTypeValue.back;
  
  /// 是否已记录页面离开事件
  bool _hasTrackedPageExit = false;
  
  /// 是否是从后台恢复
  bool _isResumedFromBackground = false;

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
    switch (state) {
      case AppLifecycleState.paused:
        // App进入后台
        _exitType = ExitTypeValue.toBackground;
        _recordPageExit();
        break;
      case AppLifecycleState.resumed:
        // App从后台恢复，重新记录页面进入
        if (_hasTrackedPageExit) {
          _isResumedFromBackground = true;
          _recordPageEnter();
        }
        break;
      case AppLifecycleState.detached:
        // App被关闭
        _exitType = ExitTypeValue.closeApp;
        _recordPageExit();
        break;
      default:
        break;
    }
  }

  /// 记录页面进入
  void _recordPageEnter() {
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _hasTrackedPageExit = false;
    _exitType = ExitTypeValue.back; // 重置离开方式
    debugPrint('📊 页面进入: $analyticsEventId${_isResumedFromBackground ? " (从后台恢复)" : ""}');
    _isResumedFromBackground = false;
  }

  /// 记录页面离开
  void _recordPageExit() {
    if (_hasTrackedPageExit || _pageEnterTime == null) return;
    _hasTrackedPageExit = true;

    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final duration = currentTime - _pageEnterTime!;

    try {
      AnalyticsManager.instance.trackPageView(
        pageId: analyticsPageId,
        eventId: analyticsEventId,
        enterTime: _pageEnterTime!,
        duration: duration,
        // 只有需要来源页的页面才传递sourcePage
        sourcePage: needSourcePage ? analyticsSourcePage : null,
        exitType: _exitType,
        params: analyticsExtraParams,
      );
      debugPrint('📊 页面离开: $analyticsEventId, 停留: ${duration}秒, 离开方式: $_exitType');
    } catch (e) {
      debugPrint('❌ 记录页面离开失败: $e');
    }
  }

  /// 设置离开方式
  /// 
  /// 在页面跳转前调用此方法设置离开方式
  /// [exitType] 离开方式，使用 [ExitTypeValue] 中的常量
  /// - 1: 返回
  /// - 2: 关闭APP
  /// - 3: 切换到后台
  /// - 4: 进入下一页
  void setExitType(int exitType) {
    _exitType = exitType;
  }

  /// 标记进入下一页（在跳转到下一页前调用）
  void markNavigateToNextPage() {
    _exitType = ExitTypeValue.nextPage;
  }

  /// 标记返回上一页（在返回上一页前调用）
  void markNavigateBack() {
    _exitType = ExitTypeValue.back;
  }
}
