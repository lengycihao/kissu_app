import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/source_page_utils.dart';
import 'device_usage_controller.dart';
import 'package:kissu_app/pages/usage_report/usage_report_page.dart';
import 'package:kissu_app/pages/usage_report/usage_report_binding.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'widgets/device_phone_usage_card.dart';
import 'widgets/device_app_usage_card.dart';
import 'widgets/device_sensitive_usage_card.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';

// 导出模型和painter供其他文件使用
export 'models/sensitive_record.dart';
export 'widgets/circular_progress_painters.dart';

/// 新的用机记录页面
class DeviceUsagePage extends StatefulWidget {
  const DeviceUsagePage({super.key});

  @override
  State<DeviceUsagePage> createState() => _DeviceUsagePageState();
}

class _DeviceUsagePageState extends State<DeviceUsagePage>
    with WidgetsBindingObserver {
  late DeviceUsageController controller;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // 安全地获取控制器，避免重复初始化问题
    if (!Get.isRegistered<DeviceUsageController>()) {
      Get.lazyPut<DeviceUsageController>(() => DeviceUsageController());
    }
    controller = Get.find<DeviceUsageController>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App进入后台
        controller.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        // App从后台恢复
        controller.onAppResumed();
        break;
      default:
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 首次构建时不刷新，后续页面恢复时刷新
    if (_hasInitialized) {
      // 页面恢复时刷新状态和数据（延迟一下确保路由已完成）
      Future.microtask(() {
        if (mounted) {
          controller.updateBindStatus();
          // 🎯 每次进入页面时，如果未绑定则自动弹出绑定弹窗
          _checkAndShowBindingDialog();
        }
      });
    } else {
      _hasInitialized = true;
      // 🎯 首次进入时，如果未绑定则自动弹出绑定弹窗
      Future.microtask(() {
        if (mounted) {
          _checkAndShowBindingDialog();
        }
      });
    }
  }

  /// 检查绑定状态并自动弹出绑定弹窗
  void _checkAndShowBindingDialog() {
    if (!controller.isUserBound.value && context.mounted) {
      CustomBottomDialog.show(
        context: context,
        caller: SourcePageUtilsCaller.deviceUsage,
        onClose: () {
          // 绑定弹窗关闭后，刷新状态并重新加载数据
          controller.updateBindStatus();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          // 背景图片（与顶部对齐）
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
                // 顶部导航栏
                _buildTopBar(),
                // 可滚动内容区域（支持下拉刷新）
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => controller.refreshData(),
                    color: const Color(0xFFFF839E),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          // 权限提示横幅（只有在尚未授权使用情况访问权限时显示）
                          Obx(() => controller.hasUsagePermission.value
                              ? const SizedBox.shrink()
                              : _buildPermissionBanner(controller)),
                          // 手机使用记录模块
                          DevicePhoneUsageCard(
                            controller: controller,
                            onTap: () {
                              // 埋点：手机使用记录模块点击（不管是否会员都记录）
                              final btnName = !controller.isUserBound.value ? 'bind' : (!controller.isUserVip.value ? 'vip' : '');
                              AnalyticsHelper.trackPhoneUseModule(btnName: btnName);
                              
                              _handleVipFeatureTap(
                                onVipUserNavigate: () {
                                  // 埋点：页面离开（进入下一页）
                                  controller.onNavigateToNextPage?.call();
                                  // 埋点：手机使用记录模块点击（不管是否会员都记录）
                              final btnName = !controller.isUserBound.value ? 'bind' : (!controller.isUserVip.value ? 'vip' : '');
                              if (btnName.isNotEmpty) {
                                AnalyticsHelper.trackPhoneUseModule(btnName: btnName);
                              }
                                  Get.toNamed(
                                    KissuRoutePath.appUsageInfo,
                                  );
                                },
                              );
                            },
                            onVipTap: () {
                              // 埋点：页面离开（进入下一页）
                              controller.onNavigateToNextPage?.call();
                               final btnName = !controller.isUserBound.value ? 'bind' : (!controller.isUserVip.value ? 'vip' : '');
                              if (btnName.isNotEmpty) {
                                AnalyticsHelper.trackPhoneUseModule(btnName: btnName);
                              }
                              // 未开通会员时点击跳转开通会员页面
                              Get.toNamed(
                                KissuRoutePath.vip,
                               arguments: {'source_page': SourcePageUtilsCaller.deviceUsage, },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // App使用记录模块
                          DeviceAppUsageCard(
                            controller: controller,
                            onTap: () {
                              // 埋点：App使用记录模块点击（不管是否会员都记录）
                              final btnName = !controller.isUserBound.value ? 'bind' : (!controller.isUserVip.value ? 'vip' : '');
                               AnalyticsHelper.trackAppUseModule(btnName: btnName);
                              
                              _handleVipFeatureTap(
                                onVipUserNavigate: () {
                                  // 埋点：页面离开（进入下一页）
                                  controller.onNavigateToNextPage?.call();
                                  
                                  Get.toNamed(KissuRoutePath.appUsage);
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // 敏感操作记录模块
                          DeviceSensitiveUsageCard(
                            controller: controller,
                            onTap: () {
                              // 埋点：敏感操作记录模块点击（不管是否会员都记录）
                              final btnName = !controller.isUserBound.value ? 'bind' : (!controller.isUserVip.value ? 'vip' : '');
                                AnalyticsHelper.trackSensitiveOperationModule(btnName: btnName);
                              
                              if (!controller.isUserBound.value) {
                                _checkAndShowBindingDialog();
                                return;
                              }
                              // 埋点：页面离开（进入下一页）
                              controller.onNavigateToNextPage?.call();
                              
                              Get.to(
                                () => const UsageReportPage(),
                                binding: UsageReportBinding(),
                                transition: Transition.rightToLeft,
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 用机记录引导图覆盖层（全屏，包含状态栏区域）- 放在最后以覆盖所有内容
          Obx(() => _buildGuideOverlay()),
        ],
      ),
    );
  }

  /// 顶部导航栏
  Widget _buildTopBar() {
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
                // 埋点：返回按钮点击
                AnalyticsHelper.trackPhoneHistoryBack();
                // 使用 Navigator 返回，避免 GetX Snackbar 初始化错误
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
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
                "用机记录",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          // 右侧设置按钮
          Positioned(
            right: 5,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                // 埋点：设置按钮点击
                AnalyticsHelper.trackPhoneHistorySetting();
                
                // 埋点：页面离开（进入下一页）
                controller.onNavigateToNextPage?.call();
                
                // 复用用机记录设置入口，跳转到通知设置页面
                Get.toNamed(KissuRoutePath.notificationSettings);
              },
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/phone_history/kissu_phone_setting.webp',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 统一处理"需要绑定 + 需要会员"的模块点击逻辑
  /// [onVipUserNavigate] 在“已绑定且是会员”时执行的跳转逻辑
  void _handleVipFeatureTap({
    required VoidCallback onVipUserNavigate,
  }) {
    // 未绑定时优先弹出绑定弹窗
    if (!controller.isUserBound.value) {
      _checkAndShowBindingDialog();
      return;
    }

    // 已绑定但未开会员：跳转到VIP页面
    if (!controller.isUserVip.value) {
      // 埋点：页面离开（进入下一页）
      controller.onNavigateToNextPage?.call();
      
      Get.toNamed(
        KissuRoutePath.vip,
        arguments: {'source_page': SourcePageUtilsCaller.deviceUsage, },
      )?.then((_) {
        // 从VIP页面返回后，刷新绑定状态
        controller.updateBindStatus();
      });
      return;
    }

    // 已绑定且是会员：执行对应模块的跳转
    onVipUserNavigate();
  }
 
 
  /// 构建用机记录引导图覆盖层
  Widget _buildGuideOverlay() {
    if (!controller.showGuideOverlay.value) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => controller.hideGuideOverlay(),
          child: Stack(
            children: [
              Positioned(
                top: 35,
                right: 10,
                child: Image.asset(
                  'assets/setting/kissu_guide_setting.webp',
                  width: 32,
                  height: 52,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 82,
                right: 44,
                child: // 竖线
                Image.asset(
                  'assets/setting/kissu_guide_line.webp',
                  width: 44,
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ),
               Positioned(
                top: 120,
                right: 240,
                child: // 竖线
                Image.asset(
                  'assets/setting/kissu_guide_laba.webp',
                  width: 14,
                  height: 14,
                  fit: BoxFit.contain,
                ),
              ),
              // 引导图：参考系统权限引导的样式，放在右上角区域
              Positioned(
                top: 125, // 适配头部和筛选区域高度
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    // 气泡 + 提示文字
                    Text(
                      '敏感信息接收设置都在这里哦~',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'AlimamaShuHeiTi',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Image.asset(
                          'assets/setting/kissu_guide_tips.webp',
                          width: 53,
                          height: 18,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 8),
                        const Text(
                          '可以手动设置提示的类型',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                   
                  ],
                ),
               const SizedBox(height: 20),
                 GestureDetector(
                      onTap: () => controller.hideGuideOverlay(),
                      child: Image.asset(
                        'assets/setting/kissu_guide_know.webp',
                        width: 90,
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 权限提示横幅
  Widget _buildPermissionBanner(DeviceUsageController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE1F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: Color(0xFFFF839E),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '目前必要权限还未开启，会造成数据显示错误',
                style: TextStyle(color: const Color(0xb3000000), fontSize: 12),
                maxLines: 1,
              ),
            ),
          ),
          SizedBox(width: 5),
          GestureDetector(
            onTap: () {
              // 埋点：权限引导按钮点击
              AnalyticsHelper.trackPermissionGuideBtn();
              controller.openUsageSettings();
            },
            child: Row(
              children: const [
                Text(
                  '去开启',
                  style: TextStyle(
                    color: Color(0xe6000000),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xe6000000),
                  size: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
