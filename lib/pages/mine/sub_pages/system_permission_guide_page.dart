import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/dialogs/system_permission_complete_dialog.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/services/analytics/analytics_params.dart';
import 'system_permission_controller.dart';

class SystemPermissionGuidePage extends StatefulWidget {
  final SystemPermissionGuideType guideType;
  final String title;

  const SystemPermissionGuidePage({
    super.key,
    required this.guideType,
    required this.title,
  });

  @override
  State<SystemPermissionGuidePage> createState() => _SystemPermissionGuidePageState();
}

class _SystemPermissionGuidePageState extends State<SystemPermissionGuidePage> with WidgetsBindingObserver {
  SystemPermissionController get controller => Get.find<SystemPermissionController>();
  
  SystemPermissionGuideType get guideType => widget.guideType;
  String get title => widget.title;

  /// 判断是否为权限类型的指引（不需要完成确认弹窗）
  bool get _isPermissionType =>
      guideType == SystemPermissionGuideType.location ||
      guideType == SystemPermissionGuideType.notification ||
      guideType == SystemPermissionGuideType.appUsage ||
      guideType == SystemPermissionGuideType.overlayWindow;

  // 埋点相关
  int? _pageEnterTime;
  int _exitType = ExitTypeValue.back;
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
    switch (state) {
      case AppLifecycleState.paused:
        _exitType = ExitTypeValue.toBackground;
        _recordPageExit();
        break;
      case AppLifecycleState.resumed:
        if (_hasTrackedPageExit) {
          _recordPageEnter();
        }
        break;
      case AppLifecycleState.detached:
        _exitType = ExitTypeValue.toBackground;
        _recordPageExit();
        break;
      default:
        break;
    }
  }

  void _recordPageEnter() {
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _hasTrackedPageExit = false;
    _exitType = ExitTypeValue.back;
  }

  void _recordPageExit() {
    if (_hasTrackedPageExit || _pageEnterTime == null) return;
    _hasTrackedPageExit = true;

    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final duration = currentTime - _pageEnterTime!;

    // 获取事件ID和状态
    final eventId = _getEventId();
    final status = _getPermissionStatus();

    AnalyticsHelper.trackPermissionSetGuidePage(
      eventId: eventId,
      enterTime: _pageEnterTime!,
      duration: duration,
      exitType: _exitType,
      status: status,
    );
  }

  /// 获取当前页面对应的事件ID
  String _getEventId() {
    switch (guideType) {
      case SystemPermissionGuideType.location:
        return PermissionSetEvents.locationPage;
      case SystemPermissionGuideType.allowBackgroundRun:
        return PermissionSetEvents.backstagePage;
      case SystemPermissionGuideType.notification:
        return PermissionSetEvents.notificationPage;
      case SystemPermissionGuideType.appUsage:
        return PermissionSetEvents.screenPage;
      case SystemPermissionGuideType.preventSleep:
        return PermissionSetEvents.sleepPage;
      case SystemPermissionGuideType.lockInBackground:
        return PermissionSetEvents.lockBackgroundPage;
      case SystemPermissionGuideType.battery:
        return PermissionSetEvents.sleepPage; // 电池权限复用防休眠事件ID
      case SystemPermissionGuideType.overlayWindow:
        return PermissionSetEvents.sleepPage; // 悬浮窗权限复用防休眠事件ID
    }
  }

  /// 获取权限开启状态
  /// 0=未开启，1=已开启定位（未开启始终），2=开启始终
  int _getPermissionStatus() {
    switch (guideType) {
      case SystemPermissionGuideType.location:
        // 定位权限特殊处理
        if (controller.isLocationAlwaysGranted.value) {
          return 2; // 开启始终
        } else if (controller.isLocationGranted.value) {
          return 1; // 已开启定位（未开启始终）
        } else {
          return 0; // 未开启
        }
      case SystemPermissionGuideType.notification:
        return controller.isNotificationGranted.value ? 1 : 0;
      case SystemPermissionGuideType.appUsage:
        return controller.isUsageAccessGranted.value ? 1 : 0;
      case SystemPermissionGuideType.preventSleep:
        return controller.isGuideCompleted(guideType) ? 1 : 0;
      case SystemPermissionGuideType.allowBackgroundRun:
        return controller.isGuideCompleted(guideType) ? 1 : 0;
      case SystemPermissionGuideType.lockInBackground:
        return controller.isGuideCompleted(guideType) ? 1 : 0;
      case SystemPermissionGuideType.battery:
        return controller.isBatteryOptimized.value ? 1 : 0;
      case SystemPermissionGuideType.overlayWindow:
        return controller.isOverlayGranted.value ? 1 : 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isPermissionType, // 权限类型可以直接返回，其他类型由完成弹窗控制返回
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isPermissionType) {
          // 权限类型直接返回
          Get.back();
        } else {
          // 其他类型显示完成确认弹窗
          await _showCompleteConfirmDialog(context);
        }
      },
      child: Obx(() {
        final imageAsset = controller.getGuideAsset(guideType);

        return Scaffold(
          backgroundColor: const Color(0xFFffffff),
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  "assets/4.0/kissu4_new_use_bg.webp",
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 25),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: ClipRRect(
                          child: Container(
                            padding: const EdgeInsets.only(top: 16),
                            decoration:
                                const BoxDecoration(color: Colors.white),
                            child: Scrollbar(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Image.asset(
                                  imageAsset,
                                  fit: BoxFit.fitWidth,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// 底部按钮区域：根据不同指引类型和完成状态切换文案
  Widget _buildActionButtons(BuildContext context) {
    // "让程序锁在后台"：根据完成状态显示不同按钮
    if (guideType == SystemPermissionGuideType.lockInBackground) {
      final bool hasCompleted = controller.isGuideCompleted(guideType);
      
      if (hasCompleted) {
        // 已完成：显示"再次设置"和"完成"两个按钮
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          child: Row(
            children: [
              Expanded(
                child: _buildBottomButton(
                  text: '再次设置',
                  color: const Color(0xffFF83C4),
                  onTap: () => _showCompleteConfirmDialog(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBottomButton(
                  text: '完成',
                  color: Colors.black,
                  onTap: () => Get.back(),
                ),
              ),
            ],
          ),
        );
      } else {
        // 未完成：只显示"去设置"按钮
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          child: _buildBottomButton(
            text: '去设置',
            color: Colors.black,
            onTap: () => _showCompleteConfirmDialog(context),
          ),
        );
      }
    }

    // 权限类型的指引：根据权限状态显示不同按钮
    final bool isPermissionType = guideType == SystemPermissionGuideType.location ||
        guideType == SystemPermissionGuideType.notification ||
        guideType == SystemPermissionGuideType.appUsage ||
        guideType == SystemPermissionGuideType.overlayWindow;
    
    if (isPermissionType) {
      // 检查权限是否已开启
      final bool isPermissionGranted = controller.isGuideCompleted(guideType);
      
      if (isPermissionGranted) {
        // 权限已开启：显示"再次设置"和"完成"两个按钮
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          child: Row(
            children: [
              Expanded(
                child: _buildBottomButton(
                  text: '再次设置',
                  color: const Color(0xffFF83C4),
                  onTap: _handleGoSettings,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBottomButton(
                  text: '完成',
                  color: Colors.black,
                  onTap: () => Get.back(),
                ),
              ),
            ],
          ),
        );
      } else {
        // 权限未开启：只显示"去设置"按钮
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          child: _buildBottomButton(
            text: '去设置',
            color: Colors.black,
            onTap: _handleGoSettings,
          ),
        );
      }
    }

    final bool hasCompleted = controller.isGuideCompleted(guideType);
    final bool openedThisSession =
        controller.isGuideOpenedThisSession(guideType);
    final bool showTwoButtons = hasCompleted || openedThisSession;

    // 首次进入且未完成：只显示"去设置"
    if (!showTwoButtons) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
        child: _buildBottomButton(
          text: '去设置',
          color: Colors.black,
          onTap: _handleGoSettings,
        ),
      );
    }

    // 返回后或已完成：显示"再次设置 / 完成"
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
      child: Row(
        children: [
          Expanded(
            child: _buildBottomButton(
              text: '再次设置',
              color: const Color(0xffFF83C4),
              onTap: _handleGoSettings,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildBottomButton(
              text: '完成',
              color: Colors.black,
              onTap: () => _showCompleteConfirmDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Widget _buildTopBar(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
  //     child: Row(
  //       children: [
  //         CommonBackButton(
  //           onTap: () {
  //             if (_isPermissionType) {
  //               // 权限类型直接返回
  //               Get.back();
  //             } else {
  //               // 其他类型显示完成确认弹窗
  //               _showCompleteConfirmDialog(context);
  //             }
  //           },
  //           assetPath: "assets/images/kissu_mine_back.webp",
  //           iconSize: 22,
  //         ),
  //         Expanded(
  //           child: Center(
  //             child: Text(
  //               title,
  //               style: const TextStyle(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.w500,
  //                 color: Color(0xFF333333),
  //               ),
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 22),
  //       ],
  //     ),
  //   );
  // }
  
  /// 顶部导航栏
  Widget _buildTopBar(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          // 返回按钮
          Positioned(
            left: 5,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                if (_isPermissionType) {
                // 权限类型直接返回
                Get.back();
              } else {
                // 其他类型显示完成确认弹窗
                _showCompleteConfirmDialog(context);
              }
              },
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Image.asset(
                  "assets/images/kissu_mine_back.webp",
                  width: 22,
                  height: 22,
                ),
              ),
            ),
          ),
          // 标题 - 绝对居中
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16, // 用户特别要求改为16
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleGoSettings() {
    controller.markGuideOpenedThisSession(guideType);
    controller.openGuideSetting(guideType);
  }

  Future<void> _showCompleteConfirmDialog(BuildContext context) async {
    await SystemPermissionCompleteDialog.show(
      onConfirm: () async {
        await controller.markGuideCompleted(guideType);
        Get.back();
      },
      onCancel: () {
        // 点错了：关闭弹窗并返回上一页
        Get.back();
      },
    );
  }
}
