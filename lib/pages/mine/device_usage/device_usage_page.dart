import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'device_usage_controller.dart';
import 'dart:math' as math;
import 'package:kissu_app/pages/usage_report/usage_report_page.dart';
import 'package:kissu_app/pages/usage_report/usage_report_binding.dart';
import 'package:kissu_app/widgets/common_back_button.dart';
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
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          // 返回按钮（统一封装，点击区域更大且更灵敏）
          CommonBackButton(
            onTap: () {
              // 使用 Navigator 返回，避免 GetX Snackbar 初始化错误
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            assetPath: "assets/4.0/kissu4_back.webp",
            iconSize: 22,
          ),
          // 标题
          const Expanded(
            child: Center(
              child: Text(
                "用机记录",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          // 右侧设置按钮：从“敏感操作记录”页面迁移到这里
          GestureDetector(
            onTap: () {
              // 复用用机记录设置入口，跳转到通知设置页面
              Get.toNamed(KissuRoutePath.notificationSettings);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
              'assets/phone_history/kissu_phone_setting.webp',
              width: 24,
              height: 24,
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

  // 构建毛玻璃蒙版
  Widget _buildFrostedGlassMask(String text, bool isVipButton) {
    // 判断是否是iPhone内测提示（文本较长且不显示按钮）
    // final isIPhoneHint = text.contains('iPhone处于内测阶段');
    
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: GestureDetector(
          onTap: () {
            // // iPhone提示不响应点击
            // if (isIPhoneHint) return;
            
            final currentContext = Get.context;
            if (currentContext != null) {
              if (isVipButton) {
                // 已绑定未开会员：跳转到VIP页面
                Get.toNamed(
                  KissuRoutePath.vip,
                  arguments: {
                    'previousPageName': '用机记录页面',
                    'previousPageId': 'device_usage',
                  },
                )?.then((_) {
                  // 从VIP页面返回后，刷新状态并重新加载数据
                  controller.updateBindStatus();
                });
              } else {
                // 未绑定：显示绑定弹窗
                CustomBottomDialog.show(
                  context: currentContext,
                  caller: BindingDialogCaller.deviceUsage,
                  onClose: () {
                    // 绑定弹窗关闭后，刷新状态并重新加载数据
                    // 注意：绑定成功时，_refreshCurrentPageData() 会自动刷新，这里作为备用
                    controller.updateBindStatus();
                  },
                );
              }
            }
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFFFFFF).withOpacity(0.2), // #FFFFFF 半透明
                  const Color(0xFFFDE4FF).withOpacity(0.8), // #FDE4FF 半透明
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 第一行：图标 + 文字
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Image.asset(
                            'assets/images/kissu4_vip_hat.webp',
                            width: 16,
                            height: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                         Stack(
                                  children: [
                                    Positioned(
                                      bottom: 2,
                                      right: 0,
                                      child: Image.asset(
                                        'assets/images/kissu4_vip_line.webp',
                                        width: 68,
                                        height: 12,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Text(
                                      text,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                  ],
                                ),
                      ],
                    ),
                    const SizedBox(height: 12),
                      Image.asset(
                        isVipButton
                            ? 'assets/images/kissu3_go_vip.webp'
                            : 'assets/images/kissu3_go_bind.webp',
                        width: isVipButton ? 129 : 109,
                        height: 35,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 模块标题（带背景和tip图标）
  Widget _buildModuleTitle(String title) {
    return Row(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // 背景图
            Image.asset(
              "assets/4.0/kissu4_new_use_label_bg.webp",
              height: 15,
              width: 140,
              fit: BoxFit.fitWidth,
            ),
            // 标题和tip
            SizedBox(
              height: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'AlimamaShuHeiTi',
                      color: Color(0xFF333333),
                    ),
                  ),
                  Image.asset(
                    "assets/4.0/kissu4_app_use_tip.webp",
                    width: 13,
                    height: 17,
                  ),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),
        // 箭头
        Image.asset("assets/4.0/kissu4_next_go.webp", width: 16, height: 16),
      ],
    );
  }

  // ignore: unused_element
  /// 圆环进度（双层圆环）（旧实现，已在 DevicePhoneUsageCard 中重写）
  // Widget _buildCircularProgress(int hours, int minutes) {
  //   // 使用屏幕使用时长对比24小时（1440分钟）计算进度
  //   final progress = controller.getCircularProgress();

  //   return Stack(
  //     alignment: Alignment.center,
  //     children: [
  //       // 虚线圆环（内侧）
  //       CustomPaint(
  //         size: const Size(92, 92),
  //         painter: DashedCirclePainter(
  //           color: const Color(0xFFFFE2F4),
  //           strokeWidth: 2,
  //         ),
  //       ),
  //       // 实线进度圆环（外侧）- 带渐变和终点白色圆
  //       SizedBox(
  //         width: 120,
  //         height: 120,
  //         child: CustomPaint(
  //           painter: GradientCircularProgressPainter(
  //             progress: progress,
  //             strokeWidth: 9,
  //             backgroundColor: const Color(0xFFFFE2F4),
  //             gradientColors: const [Color(0xFFFFA4DC), Color(0xFFFFA0DB)],
  //           ),
  //         ),
  //       ),
  //       // 中间文字
  //       Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             crossAxisAlignment: CrossAxisAlignment.baseline,
  //             textBaseline: TextBaseline.alphabetic,
  //             children: [
  //               Text(
  //                 "$hours",
  //                 style: const TextStyle(
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.bold,
  //                   color: Color(0xFF333333),
  //                 ),
  //               ),
  //               const Text(
  //                 "小时",
  //                 style: TextStyle(fontSize: 11, color: Color(0xcc333333)),
  //               ),
  //               Text(
  //                 "$minutes",
  //                 style: const TextStyle(
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.bold,
  //                   color: Color(0xFF333333),
  //                 ),
  //               ),
  //               const Text(
  //                 "分",
  //                 style: TextStyle(fontSize: 11, color: Color(0xcc333333)),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 2),
  //           const Text(
  //             "屏幕使用时长",
  //             style: TextStyle(fontSize: 11, color: Color(0xcc333333)),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  // ignore: unused_element
  /// 圆环进度（显示星号版本）（旧实现，已在 DevicePhoneUsageCard 中重写）
  // Widget _buildCircularProgressWithStars() {
  //   return Stack(
  //     alignment: Alignment.center,
  //     children: [
  //       // 虚线圆环（内侧）
  //       CustomPaint(
  //         size: const Size(92, 92),
  //         painter: DashedCirclePainter(
  //           color: const Color(0xFFFFE2F4),
  //           strokeWidth: 2,
  //         ),
  //       ),
  //       // 实线进度圆环（外侧）- 不显示进度，只显示背景
  //       SizedBox(
  //         width: 120,
  //         height: 120,
  //         child: CustomPaint(
  //           painter: GradientCircularProgressPainter(
  //             progress: 0, // 不显示进度
  //             strokeWidth: 9,
  //             backgroundColor: const Color(0xFFFFE2F4),
  //             gradientColors: const [Color(0xFFFFA4DC), Color(0xFFFFA0DB)],
  //           ),
  //         ),
  //       ),
  //       // 中间文字（星号）
  //       Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             crossAxisAlignment: CrossAxisAlignment.baseline,
  //             textBaseline: TextBaseline.alphabetic,
  //             children: const [
  //               Text(
  //                 "*",
  //                 style: TextStyle(
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.bold,
  //                   color: Color(0xFF333333),
  //                 ),
  //               ),
  //               Text(
  //                 "小时",
  //                 style: TextStyle(fontSize: 11, color: Color(0xcc333333)),
  //               ),
  //               Text(
  //                 "*",
  //                 style: TextStyle(
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.bold,
  //                   color: Color(0xFF333333),
  //                 ),
  //               ),
  //               Text(
  //                 "分",
  //                 style: TextStyle(fontSize: 11, color: Color(0xcc333333)),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 2),
  //           const Text(
  //             "屏幕使用时长",
  //             style: TextStyle(fontSize: 11, color: Color(0xcc333333)),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  // ignore: unused_element
  /// 统计项（旧实现，已在 DevicePhoneUsageCard 中重写）
  // Widget _buildStatItem(
  //   String iconPath,
  //   String label,
  //   String value,
  //   String unit,
  // ) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       Row(
  //         children: [
  //           Image.asset(iconPath, width: 16, height: 16),
  //           const SizedBox(width: 4),
  //           Text(
  //             label,
  //             style: const TextStyle(
  //               fontSize: 12,
  //               color: Color(0xcc333333),
  //               fontWeight: FontWeight.w500,
  //             ),
  //           ),
  //           const SizedBox(width: 4),
  //           Image.asset(
  //             "assets/4.0/kissu4_new_use_right.webp",
  //             width: 6,
  //             height: 6,
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 4),
  //       Row(
  //         children: [
  //           Text(
  //             value,
  //             style: const TextStyle(
  //               fontSize: 16,
  //               fontWeight: FontWeight.bold,
  //               color: Color(0xFF333333),
  //             ),
  //           ),
  //           Text(
  //             unit,
  //             style: const TextStyle(
  //               fontSize: 12,
  //               fontWeight: FontWeight.w400,
  //               color: Color(0xFF333333),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  // ignore: unused_element
  /// 空的敏感操作记录（旧实现，已在 DeviceSensitiveUsageCard 中重写）
  // Widget _buildEmptySensitiveRecords() {
  //   return Center(
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Image.asset(
  //           "assets/4.0/kissu4_use_app_empty.webp",
  //           width: 80,
  //           height: 80,
  //         ),
  //         const SizedBox(height: 8),
  //         const Text(
  //           "暂无使用数据",
  //           style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ignore: unused_element
  /// 敏感操作记录项（旧实现，已在 DeviceSensitiveUsageCard 中重写）
  // Widget _buildSensitiveRecordItem(SensitiveRecord record, bool showDivider) {
  //   // 根据是否有subtitle判断高度：单行52，双行68
  //   final itemHeight = record.subtitle.isNotEmpty ? 68.0 : 52.0;
    
  //   return Column(
  //     children: [
  //       Container(
  //         height: itemHeight,
  //         decoration: BoxDecoration(
  //           color: const Color(0xFFF9F9F9),
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //         padding: const EdgeInsets.symmetric(horizontal: 12),
  //         child: Row(
  //           crossAxisAlignment: record.subtitle.isNotEmpty 
  //               ? CrossAxisAlignment.center 
  //               : CrossAxisAlignment.center,
  //           children: [
  //             // 图标
  //             SizedBox(
  //               width: 18,
  //               height: 18,
  //               child: NetworkImageHelper.loadImage(
  //                 imageUrl: record.iconPath,
  //                 fit: BoxFit.contain,
  //               ),
  //             ),
  //             const SizedBox(width: 4),
  //             // 内容
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Text(
  //                     record.content,
  //                     style: const TextStyle(
  //                       fontSize: 13,
  //                       color: Color(0xFF333333),
  //                     ),
  //                   ),
  //                   if (record.subtitle.isNotEmpty) ...[
  //                     const SizedBox(height: 2),
  //                     Text(
  //                       record.subtitle,
  //                       style: const TextStyle(
  //                         fontSize: 11,
  //                         color: Color(0xcc333333),
  //                       ),
  //                     ),
  //                   ],
  //                 ],
  //               ),
  //             ),
  //             // 时间
  //             Text(
  //               record.time,
  //               style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
  //             ),
  //           ],
  //         ),
  //       ),
  //       if (showDivider) const SizedBox(height: 10),
  //     ],
  //   );
  // }

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
