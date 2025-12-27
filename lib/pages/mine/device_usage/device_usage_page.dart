import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'device_usage_controller.dart';
import 'dart:math' as math;
import 'package:kissu_app/pages/usage_report/usage_report_page.dart';
import 'package:kissu_app/pages/usage_report/usage_report_binding.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog_controller.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'widgets/device_phone_usage_card.dart';
import 'widgets/device_app_usage_card.dart';
import 'widgets/device_sensitive_usage_card.dart';

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
        caller: BindingDialogCaller.deviceUsage,
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
                              _handleVipFeatureTap(
                                onVipUserNavigate: () => Get.toNamed(
                                  KissuRoutePath.appUsageInfo,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // App使用记录模块
                          DeviceAppUsageCard(
                            controller: controller,
                            onTap: () {
                              _handleVipFeatureTap(
                                onVipUserNavigate: () =>
                                    Get.toNamed(KissuRoutePath.appUsage),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // 敏感操作记录模块
                          DeviceSensitiveUsageCard(
                            controller: controller,
                            onTap: () {
                              if (!controller.isUserBound.value) {
                                _checkAndShowBindingDialog();
                                return;
                              }
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

  // 手机 / App / 敏感操作模块已拆分为独立组件（见 widgets/）
  // 保留旧实现作为参考，但当前未被调用
  // ignore: unused_element
  /// App使用记录模块（旧实现，已由 DeviceAppUsageCard 替代）
  // Widget _buildAppUsageModule() {
  //   return GestureDetector(
  //     onTap: () {
  //       _handleVipFeatureTap(
  //         onVipUserNavigate: () => Get.toNamed(KissuRoutePath.appUsage),
  //       );
  //     },
  //     child: Container(
  //       height: 190,
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       child: Stack(
  //         children: [
  //           Padding(
  //             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 // 模块标题
  //                 _buildModuleTitle("Ta的App使用记录"),
  //                 const SizedBox(height: 12),
  //                 // App使用数据
  //                 Expanded(
  //                   child: Row(
  //                     crossAxisAlignment: CrossAxisAlignment.stretch,
  //                     children: [
  //                       // 左侧：最长使用App模块 - 150宽度
  //                       Expanded(
  //                         flex: 130,
  //                         child: Container(
  //                           decoration: BoxDecoration(
  //                             color: const Color(0xFFF9F9F9),
  //                             borderRadius: BorderRadius.circular(12),
  //                           ),
  //                           child: Column(
  //                             mainAxisAlignment: MainAxisAlignment.center,
  //                             children: [
  //                               // App图标
  //                               Container(
  //                                 width: 60,
  //                                 height: 60,
  //                                 decoration: BoxDecoration(
  //                                   borderRadius: BorderRadius.circular(12),
  //                                   color: const Color(0xFFF9f9f9),
  //                                 ),
  //                                 child: ClipRRect(
  //                                   borderRadius: BorderRadius.circular(12),
  //                                   child: Obx(() {
  //                                     if (controller
  //                                         .longestAppLogo
  //                                         .value
  //                                         .isNotEmpty) {
  //                                       return NetworkImageHelper.loadImage(
  //                                         imageUrl: controller.longestAppLogo.value,
  //                                         fit: BoxFit.cover,
  //                                         errorWidget: Image.asset(
  //                                           "assets/phone_history/kissu4_phone_icon_empty.webp",
  //                                           fit: BoxFit.cover,
  //                                         ),
  //                                       );
  //                                     } else {
  //                                       return Image.asset(
  //                                         "assets/phone_history/kissu4_phone_icon_empty.webp",
  //                                         fit: BoxFit.cover,
  //                                       );
  //                                     }
  //                                   }),
  //                                 ),
  //                               ),
  //                               const SizedBox(height: 8),
  //                               // 最长使用APP标题
  //                               const Text(
  //                                 "最长使用APP",
  //                                 style: TextStyle(
  //                                   fontSize: 12,
  //                                   color: Color(0xFF333333),
  //                                 ),
  //                               ),
  //                               const SizedBox(height: 2),
  //                               // 时长
  //                               Obx(
  //                                 () =>
  //                                      Text.rich(
  //                                         TextSpan(
  //                                           children: [
  //                                             TextSpan(
  //                                               text:
  //                                                   "${controller.longestAppHours.value}",
  //                                               style: const TextStyle(
  //                                                 fontSize: 16,
  //                                                 fontWeight: FontWeight.bold,
  //                                                 color: Color(0xFF333333),
  //                                               ),
  //                                             ),
  //                                             TextSpan(
  //                                               text: "小时",
  //                                               style: const TextStyle(
  //                                                 fontSize: 13,
  //                                                 color: Color(0xcc333333),
  //                                               ),
  //                                             ),
  //                                             TextSpan(
  //                                               text:
  //                                                   "${controller.longestAppMinutes.value}",
  //                                               style: const TextStyle(
  //                                                 fontSize: 16,
  //                                                 fontWeight: FontWeight.bold,
  //                                                 color: Color(0xFF333333),
  //                                               ),
  //                                             ),
  //                                             TextSpan(
  //                                               text: "分钟",
  //                                               style: const TextStyle(
  //                                                 fontSize: 13,
  //                                                 color: Color(0xcc333333),
  //                                               ),
  //                                             ),
  //                                           ],
  //                                         ),
  //                                       ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ),
  //                       const SizedBox(width: 10),
  //                       // 右侧：两个App信息模块 - 155宽度
  //                       Expanded(
  //                         flex: 155,
  //                         child: Column(
  //                           children: [
  //                             // 打开次数最多的App
  //                             Expanded(
  //                               child: Container(
  //                                 decoration: BoxDecoration(
  //                                   color: const Color(0xFFF9F9F9),
  //                                   borderRadius: BorderRadius.circular(12),
  //                                 ),
  //                                 padding: const EdgeInsets.symmetric(
  //                                   horizontal: 10,
  //                                   vertical: 8,
  //                                 ),
  //                                 child: Column(
  //                                   crossAxisAlignment:
  //                                       CrossAxisAlignment.start,
  //                                   mainAxisAlignment:
  //                                       MainAxisAlignment.spaceBetween,
  //                                   children: [
  //                                     Row(
  //                                       children: [
  //                                         Image.asset(
  //                                           "assets/4.0/kissu4_new_use_times_pic.webp",
  //                                           width: 16,
  //                                           height: 16,
  //                                         ),
  //                                         const SizedBox(width: 4),
  //                                         const Expanded(
  //                                           child: Text(
  //                                             "打开次数最多的App",
  //                                             style: TextStyle(
  //                                               fontSize: 12,
  //                                               color: Color(0xcc333333),
  //                                             ),
  //                                           ),
  //                                         ),
  //                                         Image.asset(
  //                                           "assets/4.0/kissu4_new_use_right.webp",
  //                                           width: 6,
  //                                           height: 6,
  //                                         ),
  //                                       ],
  //                                     ),
  //                                     Obx(
  //                                       () => Row(
  //                                         children: [
  //                                           SizedBox(width: 20),
  //                                           // App图标
  //                                           Container(
  //                                             width: 26,
  //                                             height: 26,
  //                                             decoration: BoxDecoration(
  //                                               borderRadius:
  //                                                   BorderRadius.circular(4),
  //                                             ),
  //                                             child:
  //                                                 controller
  //                                                             .openMostAppCount
  //                                                             .value >
  //                                                         0 &&
  //                                                     controller
  //                                                         .openMostAppLogo
  //                                                         .value
  //                                                         .isNotEmpty
  //                                                 ? ClipRRect(
  //                                                     borderRadius:
  //                                                         BorderRadius.circular(
  //                                                           4,
  //                                                         ),
  //                                                     child: NetworkImageHelper.loadImage(
  //                                                       imageUrl: controller
  //                                                           .openMostAppLogo
  //                                                           .value,
  //                                                       width: 26,
  //                                                       height: 26,
  //                                                       fit: BoxFit.cover,
  //                                                       errorWidget: ClipRRect(
  //                                                         borderRadius:
  //                                                             BorderRadius.circular(4),
  //                                                         child: Image.asset(
  //                                                           "assets/phone_history/kissu4_phone_icon_empty.webp",
  //                                                           width: 26,
  //                                                           height: 26,
  //                                                           fit: BoxFit.cover,
  //                                                         ),
  //                                                       ),
  //                                                     ),
  //                                                   )
  //                                                 : ClipRRect(
  //                                                     borderRadius:
  //                                                         BorderRadius.circular(4),
  //                                                     child: Image.asset(
  //                                                       "assets/phone_history/kissu4_phone_icon_empty.webp",
  //                                                       width: 26,
  //                                                       height: 26,
  //                                                       fit: BoxFit.cover,
  //                                                     ),
  //                                                   ),
  //                                           ),
  //                                           const SizedBox(width: 6),
  //                                           Text.rich(
  //                                                   TextSpan(
  //                                                     children: [
  //                                                       TextSpan(
  //                                                         text:
  //                                                             "${controller.openMostAppCount.value}",
  //                                                         style:
  //                                                             const TextStyle(
  //                                                               fontSize: 14,
  //                                                               fontWeight:
  //                                                                   FontWeight
  //                                                                       .bold,
  //                                                               color: Color(
  //                                                                 0xFF333333,
  //                                                               ),
  //                                                             ),
  //                                                       ),
  //                                                       TextSpan(
  //                                                         text: " 次",
  //                                                         style:
  //                                                             const TextStyle(
  //                                                               fontSize: 12,
  //                                                               color: Color(
  //                                                                 0xff777777,
  //                                                               ),
  //                                                             ),
  //                                                       ),
  //                                                     ],
  //                                                   ),
  //                                                 )
  //                                         ],
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ),
  //                             const SizedBox(height: 10),
  //                             // 最近使用的App
  //                             Expanded(
  //                               child: Container(
  //                                 decoration: BoxDecoration(
  //                                   color: const Color(0xFFF9F9F9),
  //                                   borderRadius: BorderRadius.circular(12),
  //                                 ),
  //                                 padding: const EdgeInsets.symmetric(
  //                                   horizontal: 10,
  //                                   vertical: 8,
  //                                 ),
  //                                 child: Column(
  //                                   crossAxisAlignment:
  //                                       CrossAxisAlignment.start,
  //                                   mainAxisAlignment:
  //                                       MainAxisAlignment.spaceBetween,
  //                                   children: [
  //                                     Row(
  //                                       children: [
  //                                         Image.asset(
  //                                           "assets/4.0/kissu4_new_use_time_pic.webp",
  //                                           width: 16,
  //                                           height: 16,
  //                                         ),
  //                                         const SizedBox(width: 4),
  //                                         const Expanded(
  //                                           child: Text(
  //                                             "最近使用的App",
  //                                             style: TextStyle(
  //                                               fontSize: 12,
  //                                               color: Color(0xcc333333),
  //                                             ),
  //                                           ),
  //                                         ),
  //                                         Image.asset(
  //                                           "assets/4.0/kissu4_new_use_right.webp",
  //                                           width: 6,
  //                                           height: 6,
  //                                         ),
  //                                       ],
  //                                     ),
  //                                     Obx(
  //                                       () => Row(
  //                                         children: [
  //                                           // App图标
  //                                           SizedBox(width: 20),
  //                                           Container(
  //                                             width: 26,
  //                                             height: 26,
  //                                             decoration: BoxDecoration(
  //                                               borderRadius:
  //                                                   BorderRadius.circular(4),
  //                                             ),
  //                                             child:
  //                                                 controller
  //                                                         .lastUseAppTime
  //                                                         .value
  //                                                         .isNotEmpty &&
  //                                                     controller
  //                                                         .lastUseAppLogo
  //                                                         .value
  //                                                         .isNotEmpty
  //                                                 ? ClipRRect(
  //                                                     borderRadius:
  //                                                         BorderRadius.circular(
  //                                                           4,
  //                                                         ),
  //                                                     child: NetworkImageHelper.loadImage(
  //                                                       imageUrl: controller
  //                                                           .lastUseAppLogo
  //                                                           .value,
  //                                                       width: 26,
  //                                                       height: 26,
  //                                                       fit: BoxFit.cover,
  //                                                       errorWidget: ClipRRect(
  //                                                         borderRadius:
  //                                                             BorderRadius.circular(4),
  //                                                         child: Image.asset(
  //                                                           "assets/phone_history/kissu4_phone_icon_empty.webp",
  //                                                           width: 26,
  //                                                           height: 26,
  //                                                           fit: BoxFit.cover,
  //                                                         ),
  //                                                       ),
  //                                                     ),
  //                                                   )
  //                                                 : ClipRRect(
  //                                                     borderRadius:
  //                                                         BorderRadius.circular(4),
  //                                                     child: Image.asset(
  //                                                       "assets/phone_history/kissu4_phone_icon_empty.webp",
  //                                                       width: 26,
  //                                                       height: 26,
  //                                                       fit: BoxFit.cover,
  //                                                     ),
  //                                                   ),
  //                                           ),
  //                                           const SizedBox(width: 6),
  //                                           Text(
  //                                             controller
  //                                                     .lastUseAppTime
  //                                                     .value
  //                                                     .isEmpty
  //                                                 ? "00:00"
  //                                                 : controller
  //                                                       .lastUseAppTime
  //                                                       .value,
  //                                             style: TextStyle(
  //                                               fontSize: 14,
  //                                               fontWeight: FontWeight.w600,
  //                                               color:
  //                                                   controller
  //                                                       .lastUseAppTime
  //                                                       .value
  //                                                       .isEmpty
  //                                                   ? const Color(0xFF333333)
  //                                                   : const Color(0xFF333333),
  //                                             ),
  //                                           ),
  //                                         ],
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           // 毛玻璃蒙版（未绑定、已绑定未开会员、或对方是iPhone且已绑定已开会员时显示）
  //           Obx(() {
  //             final isBound = controller.isUserBound.value;
  //             final isVip = controller.isUserVip.value;
  //             // 未绑定或已绑定未开会员：显示原有蒙版
  //             if (!isBound || (isBound && !isVip)) {
  //               return Positioned(
  //                 top: 40, // 标题高度 + 间距
  //                 left: 0,
  //                 right: 0,
  //                 bottom: 0,
  //                 child: _buildFrostedGlassMask(
  //                   "实时查看Ta的App详细使用记录",
  //                   isBound && !isVip,
  //                 ),
  //               );
  //             }
              
  //             // // 已绑定已开会员，但对方是iPhone：显示iPhone内测提示
  //             // if (isBound && isVip && isIOS) {
  //             //   return Positioned(
  //             //     top: 40, // 标题高度 + 间距
  //             //     left: 0,
  //             //     right: 0,
  //             //     bottom: 0,
  //             //     child: _buildFrostedGlassMask(
  //             //       "iPhone处于内测阶段，您的对象为\niPhone用户。\"App使用记录\"暂时\n无法查看，我们将逐步开放，感谢\n您的理解！",
  //             //       false, // 不显示VIP按钮
  //             //     ),
  //             //   );
  //             // }
              
  //             return const SizedBox.shrink();
  //           }),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // ignore: unused_element
  /// 敏感操作记录模块（旧实现，已由 DeviceSensitiveUsageCard 替代）
  // Widget _buildSensitiveRecordModule() => const SizedBox.shrink();

  /// 统一处理“需要绑定 + 需要会员”的模块点击逻辑
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
      Get.toNamed(
        KissuRoutePath.vip,
        arguments: const {
          'previousPageName': '用机记录页面',
          'previousPageId': 'device_usage',
        },
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
            onTap: () => controller.openUsageSettings(),
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

/// 虚线圆环绘制器
class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedCirclePainter({
    required this.color,
    this.strokeWidth = 2,
    this.dashWidth = 6,
    this.dashSpace = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    double startAngle = -math.pi / 2;
    final totalDashSpace = dashWidth + dashSpace;
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / totalDashSpace).floor();

    for (int i = 0; i < dashCount; i++) {
      final sweepAngle = dashWidth / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += totalDashSpace / radius;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 敏感操作记录数据类
class SensitiveRecord {
  final String iconPath;
  final String content;
  final String time;
  final String subtitle;

  SensitiveRecord({
    required this.iconPath,
    required this.content,
    required this.time,
    this.subtitle = "",
  });
}

/// 渐变圆形进度条绘制器（带白色终点圆）
class GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final List<Color> gradientColors;

  GradientCircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 绘制背景圆环
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 绘制渐变进度
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final sweepAngle = 2 * math.pi * progress;

      final gradient = SweepGradient(
        colors: gradientColors,
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweepAngle,
        transform: const GradientRotation(0),
      );

      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);

      // 绘制终点白色圆
      final endAngle = -math.pi / 2 + sweepAngle;
      final endX = center.dx + radius * math.cos(endAngle);
      final endY = center.dy + radius * math.sin(endAngle);
      final endPoint = Offset(endX, endY);

      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(endPoint, strokeWidth / 2 - 1, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
