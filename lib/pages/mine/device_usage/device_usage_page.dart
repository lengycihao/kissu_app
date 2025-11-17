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
        }
      });
    } else {
      _hasInitialized = true;
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
                // 可滚动内容区域
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        // 手机使用记录模块
                        _buildPhoneUsageModule(),
                        const SizedBox(height: 16),
                        // App使用记录模块
                        _buildAppUsageModule(),
                        const SizedBox(height: 16),
                        // 敏感操作记录模块
                        _buildSensitiveRecordModule(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部导航栏
  Widget _buildTopBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                "assets/4.0/kissu4_back.webp",
                width: 24,
                height: 24,
              ),
            ),
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
          // 调试按钮
          GestureDetector(
            onTap: () => controller.toggleDebugMode(),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.bug_report,
                size: 24,
                color: Color(0xFF999999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 手机使用记录模块
  Widget _buildPhoneUsageModule() {
    return GestureDetector(
      onTap: () {
        // 跳转到App使用记录详情页
        Get.toNamed('/kisssu_app/app_usage_detail');
      },
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 模块标题
                  _buildModuleTitle("Ta的手机使用记录"),
                  const SizedBox(height: 12),
                  // 圆环图和统计数据
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 左侧圆环模块 - 174*143比例
                        Expanded(
                          flex: 174,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Obx(() {
                                // 已绑定但未开会员时显示星号
                                if (controller.isUserBound.value &&
                                    !controller.isUserVip.value) {
                                  return _buildCircularProgressWithStars();
                                }
                                return _buildCircularProgress(
                                  controller.screenUsageHours.value,
                                  controller.screenUsageMinutes.value,
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 右侧统计数据 - 131宽度
                        Expanded(
                          flex: 131,
                          child: Column(
                            children: [
                              // 解锁次数
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F9F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Obx(() {
                                    // 已绑定但未开会员时显示星号
                                    final value =
                                        (controller.isUserBound.value &&
                                            !controller.isUserVip.value)
                                        ? "*"
                                        : "${controller.unlockCount.value}";
                                    return _buildStatItem(
                                      "assets/4.0/kissu4_new_use_times_pic.webp",
                                      "解锁手机次数",
                                      value,
                                      "次",
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // 最近使用时长
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F9F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Obx(() {
                                    // 已绑定但未开会员时显示星号
                                    final value =
                                        (controller.isUserBound.value &&
                                            !controller.isUserVip.value)
                                        ? "*"
                                        : "${controller.recentUsageMinutes.value}";
                                    return _buildStatItem(
                                      "assets/4.0/kissu4_new_use_time_pic.webp",
                                      "最近使用时长",
                                      value,
                                      "分钟",
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 毛玻璃蒙版（仅未绑定时显示）
            Obx(() {
              if (!controller.isUserBound.value) {
                return Positioned(
                  top: 40, // 标题高度 + 间距
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildFrostedGlassMask("实时查看Ta的手机使用报告", false),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  /// App使用记录模块
  Widget _buildAppUsageModule() {
    return GestureDetector(
      onTap: () {
        // 跳转到App使用统计页面
        Get.toNamed(KissuRoutePath.appUsage);
      },
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 模块标题
                  _buildModuleTitle("Ta的App使用记录"),
                  const SizedBox(height: 12),
                  // App使用数据
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 左侧：最长使用App模块 - 150宽度
                        Expanded(
                          flex: 130,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // App图标
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFFF5F5F5),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Obx(() {
                                      if (controller
                                          .longestAppLogo
                                          .value
                                          .isNotEmpty) {
                                        return Image.network(
                                          controller.longestAppLogo.value,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Image.asset(
                                                  "assets/4.0/kissu4_use_app_empty.webp",
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                        );
                                      } else {
                                        return Image.asset(
                                          "assets/4.0/kissu4_use_app_empty.webp",
                                          fit: BoxFit.cover,
                                        );
                                      }
                                    }),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // 最长使用APP标题
                                const Text(
                                  "最长使用APP",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // 时长
                                Obx(
                                  () =>
                                      (controller.longestAppHours.value == 0 &&
                                          controller.longestAppMinutes.value ==
                                              0)
                                      ? const Text(
                                          "0小时00分钟",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF999999),
                                          ),
                                        )
                                      : Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text:
                                                    "${controller.longestAppHours.value}",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF333333),
                                                ),
                                              ),
                                              TextSpan(
                                                text: "小时",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xcc333333),
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    "${controller.longestAppMinutes.value}",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF333333),
                                                ),
                                              ),
                                              TextSpan(
                                                text: "分钟",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xcc333333),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 右侧：两个App信息模块 - 155宽度
                        Expanded(
                          flex: 155,
                          child: Column(
                            children: [
                              // 打开次数最多的App
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F9F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Image.asset(
                                            "assets/4.0/kissu4_new_use_times_pic.webp",
                                            width: 16,
                                            height: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          const Expanded(
                                            child: Text(
                                              "打开次数最多的App",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xcc333333),
                                              ),
                                            ),
                                          ),
                                          Image.asset(
                                            "assets/4.0/kissu4_new_use_right.webp",
                                            width: 6,
                                            height: 6,
                                          ),
                                        ],
                                      ),
                                      Obx(
                                        () => Row(
                                          children: [
                                            SizedBox(width: 20),
                                            // App图标或灰色方块
                                            Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                color:
                                                    controller
                                                            .openMostAppCount
                                                            .value >
                                                        0
                                                    ? const Color(0xFF07C160)
                                                    : const Color(0xFFE8E8E8),
                                              ),
                                              child:
                                                  controller
                                                              .openMostAppCount
                                                              .value >
                                                          0 &&
                                                      controller
                                                          .openMostAppLogo
                                                          .value
                                                          .isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                      child: Image.network(
                                                        controller
                                                            .openMostAppLogo
                                                            .value,
                                                        width: 26,
                                                        height: 26,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) {
                                                              return const Center(
                                                                child: Icon(
                                                                  Icons.apps,
                                                                  size: 22,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              );
                                                            },
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 6),
                                            controller.openMostAppCount.value >
                                                    0
                                                ? Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              "${controller.openMostAppCount.value}",
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                  0xFF333333,
                                                                ),
                                                              ),
                                                        ),
                                                        TextSpan(
                                                          text: " 次",
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color: Color(
                                                                  0xff777777,
                                                                ),
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : const Text(
                                                    "0次",
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF999999),
                                                    ),
                                                  ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // 最近使用的App
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F9F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Image.asset(
                                            "assets/4.0/kissu4_new_use_time_pic.webp",
                                            width: 16,
                                            height: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          const Expanded(
                                            child: Text(
                                              "最近使用的App",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xcc333333),
                                              ),
                                            ),
                                          ),
                                          Image.asset(
                                            "assets/4.0/kissu4_new_use_right.webp",
                                            width: 6,
                                            height: 6,
                                          ),
                                        ],
                                      ),
                                      Obx(
                                        () => Row(
                                          children: [
                                            // App图标或灰色方块
                                            SizedBox(width: 20),
                                            Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                color:
                                                    controller
                                                        .lastUseAppTime
                                                        .value
                                                        .isEmpty
                                                    ? const Color(0xFFE8E8E8)
                                                    : const Color(0xFFE6162D),
                                              ),
                                              child:
                                                  controller
                                                          .lastUseAppTime
                                                          .value
                                                          .isNotEmpty &&
                                                      controller
                                                          .lastUseAppLogo
                                                          .value
                                                          .isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                      child: Image.network(
                                                        controller
                                                            .lastUseAppLogo
                                                            .value,
                                                        width: 26,
                                                        height: 26,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) {
                                                              return const Center(
                                                                child: Icon(
                                                                  Icons.apps,
                                                                  size: 22,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              );
                                                            },
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              controller
                                                      .lastUseAppTime
                                                      .value
                                                      .isEmpty
                                                  ? "00:00"
                                                  : controller
                                                        .lastUseAppTime
                                                        .value,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    controller
                                                        .lastUseAppTime
                                                        .value
                                                        .isEmpty
                                                    ? const Color(0xFF999999)
                                                    : const Color(0xFF333333),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 毛玻璃蒙版（未绑定或已绑定未开会员时显示）
            Obx(() {
              if (!controller.isUserBound.value ||
                  (controller.isUserBound.value &&
                      !controller.isUserVip.value)) {
                return Positioned(
                  top: 40, // 标题高度 + 间距
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildFrostedGlassMask(
                    "实时查看Ta的App详细使用记录",
                    controller.isUserBound.value && !controller.isUserVip.value,
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  /// 敏感操作记录模块
  Widget _buildSensitiveRecordModule() {
    return GestureDetector(
      onTap: () {
        // 跳转到敏感操作记录详情页
        Get.to(
          () => const UsageReportPage(),
          binding: UsageReportBinding(),
          transition: Transition.rightToLeft,
        );
      },
      child: Container(
        height: 238,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 模块标题
                  _buildModuleTitle("Ta的敏感操作记录"),
                  const SizedBox(height: 12),
                  // 操作记录列表
                  Expanded(
                    child: Obx(() {
                      if (controller.sensitiveRecords.isEmpty ||
                          controller.isDebugEmptyMode.value) {
                        return _buildEmptySensitiveRecords();
                      }
                      return Column(
                        children: List.generate(
                          math.min(3, controller.sensitiveRecords.length),
                          (index) => _buildSensitiveRecordItem(
                            controller.sensitiveRecords[index],
                            index <
                                math.min(
                                  2,
                                  controller.sensitiveRecords.length - 1,
                                ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // 毛玻璃蒙版（未绑定或已绑定未开会员时显示）
            Obx(() {
              if (!controller.isUserBound.value ||
                  (controller.isUserBound.value &&
                      !controller.isUserVip.value)) {
                return Positioned(
                  top: 40, // 标题高度 + 间距
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildFrostedGlassMask(
                    "实时查看Ta的敏感记录",
                    controller.isUserBound.value && !controller.isUserVip.value,
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  /// 构建毛玻璃蒙版
  Widget _buildFrostedGlassMask(String text, bool isVipButton) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: GestureDetector(
          onTap: () {
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 第一行：图标 + 文字
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/kissu4_vip_hat.webp',
                        width: 16,
                        height: 14,
                      ),
                      const SizedBox(width: 6),
                      Stack(
                        children: [
                          Positioned(
                            bottom: 2,
                            right: 0,
                            child: Image.asset(
                              'assets/kissu4_vip_line.webp',
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
                  // 第二行：按钮（根据状态显示不同的按钮）
                  Image.asset(
                    isVipButton
                        ? 'assets/kissu3_go_vip.webp'
                        : 'assets/kissu3_go_bind.webp',
                    width: isVipButton ? 129 : 109,
                    height: 35,
                  ),
                ],
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

  /// 圆环进度（双层圆环）
  Widget _buildCircularProgress(int hours, int minutes) {
    // 使用 totalUseDuration.minute 对比今天当前时间的分钟数据
    final progress = controller.getCircularProgress();

    return Stack(
      alignment: Alignment.center,
      children: [
        // 虚线圆环（内侧）
        CustomPaint(
          size: const Size(92, 92),
          painter: DashedCirclePainter(
            color: const Color(0xFFFFE2F4),
            strokeWidth: 2,
          ),
        ),
        // 实线进度圆环（外侧）- 带渐变和终点白色圆
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: GradientCircularProgressPainter(
              progress: progress,
              strokeWidth: 9,
              backgroundColor: const Color(0xFFFFE2F4),
              gradientColors: const [Color(0xFFFFA4DC), Color(0xFFFFA0DB)],
            ),
          ),
        ),
        // 中间文字
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  "$hours",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const Text(
                  "小时",
                  style: TextStyle(fontSize: 11, color: Color(0xcc333333)),
                ),
                Text(
                  "$minutes",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const Text(
                  "分",
                  style: TextStyle(fontSize: 11, color: Color(0xcc333333)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              "屏幕使用时长",
              style: TextStyle(fontSize: 11, color: Color(0xcc333333)),
            ),
          ],
        ),
      ],
    );
  }

  /// 圆环进度（显示星号版本）
  Widget _buildCircularProgressWithStars() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 虚线圆环（内侧）
        CustomPaint(
          size: const Size(92, 92),
          painter: DashedCirclePainter(
            color: const Color(0xFFFFE2F4),
            strokeWidth: 2,
          ),
        ),
        // 实线进度圆环（外侧）- 不显示进度，只显示背景
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: GradientCircularProgressPainter(
              progress: 0, // 不显示进度
              strokeWidth: 9,
              backgroundColor: const Color(0xFFFFE2F4),
              gradientColors: const [Color(0xFFFFA4DC), Color(0xFFFFA0DB)],
            ),
          ),
        ),
        // 中间文字（星号）
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: const [
                Text(
                  "*",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  "小时",
                  style: TextStyle(fontSize: 11, color: Color(0xcc333333)),
                ),
                Text(
                  "*",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  "分",
                  style: TextStyle(fontSize: 11, color: Color(0xcc333333)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              "屏幕使用时长",
              style: TextStyle(fontSize: 11, color: Color(0xcc333333)),
            ),
          ],
        ),
      ],
    );
  }

  /// 统计项
  Widget _buildStatItem(
    String iconPath,
    String label,
    String value,
    String unit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Image.asset(iconPath, width: 16, height: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xcc333333),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Image.asset(
              "assets/4.0/kissu4_new_use_right.webp",
              width: 6,
              height: 6,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 空的敏感操作记录
  Widget _buildEmptySensitiveRecords() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            "assets/4.0/kissu4_use_app_empty.webp",
            width: 80,
            height: 80,
          ),
          const SizedBox(height: 8),
          const Text(
            "暂无使用数据",
            style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  /// 敏感操作记录项
  Widget _buildSensitiveRecordItem(SensitiveRecord record, bool showDivider) {
    return Column(
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // 图标
              Image.asset(record.iconPath, width: 18, height: 18),
              const SizedBox(width: 4),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      record.content,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF333333),
                      ),
                    ),
                    if (record.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        record.subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // 时间
              Text(
                record.time,
                style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
              ),
            ],
          ),
        ),
        if (showDivider) const SizedBox(height: 10),
      ],
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
