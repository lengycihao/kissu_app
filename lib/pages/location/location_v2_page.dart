import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:kissu_app/widgets/device_info_item.dart';
import 'package:kissu_app/widgets/safe_amap_widget.dart';
import 'package:kissu_app/widgets/smooth_avatar_widget.dart';
import 'package:kissu_app/pages/track/track_page.dart';
import 'package:kissu_app/pages/track/track_binding.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'location_v2_controller.dart';

class LocationV2Page extends StatelessWidget {
  LocationV2Page({super.key});

  final controller = Get.put(LocationV2Controller());

  @override
  Widget build(BuildContext context) {
    return _LocationPageContent(controller: controller);
  }
}

// 将主要内容提取为单独的StatefulWidget以优化性能
class _LocationPageContent extends StatefulWidget {
  final LocationV2Controller controller;

  const _LocationPageContent({required this.controller});

  @override
  State<_LocationPageContent> createState() => _LocationPageContentState();
}

class _LocationPageContentState extends State<_LocationPageContent>
    with WidgetsBindingObserver {
  late double screenHeight;
  late double initialHeight;
  late double minHeight;
  late double maxHeight;
  late double mapHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // 应用进入后台，暂停地图更新（释放资源）
      print('📍 LocationV2Page: 应用进入后台，暂停地图更新');
    } else if (state == AppLifecycleState.resumed) {
      // 应用恢复前台，恢复地图更新
      print('📍 LocationV2Page: 应用恢复前台，恢复地图更新');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里计算屏幕尺寸相关参数
    screenHeight = MediaQuery.of(context).size.height;
    // 起始位置：下半屏高度为190px（顶部距离屏幕底部190px）
    initialHeight = 190;
    // 最小位置：不允许往下滑，最小就是初始位置190px
    minHeight = 190;
    // 最大位置：顶部距离屏幕顶部100px
    maxHeight = screenHeight - 100;
    mapHeight = screenHeight - initialHeight + 90;
  }

  @override
  Widget build(BuildContext context) {
    widget.controller.pageContext = context; // 保存 Scaffold 的 context
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Color(0xFFFFF6EF)),
        child: Stack(
          children: [
            // 固定的地图模块 - 使用缓存优化
            Positioned.fill(
              child: _CachedMapWidget(controller: widget.controller),
            ),


            // 全屏渐变背景 - 从中间滑到顶部时显示
            _GradientBackgroundOverlay(
              controller: widget.controller,
              screenHeight: screenHeight,
              initialHeight: initialHeight,
              maxHeight: maxHeight,
            ),

            // 未绑定提示 - 放置在下半屏上方
            // Positioned(
            //   bottom: screenHeight * 0.3 + 20,
            //   left: 20,
            //   right: 20,
            //   child: _FloatingUnbindNotification(
            //     controller: widget.controller,
            //     screenHeight: screenHeight,
            //     initialHeight: initialHeight,
            //   ),
            // ),

            // 右侧浮动按钮组 - 位于地图和下半屏之间
            _FloatingActionButtons(
              screenHeight: screenHeight,
              controller: widget.controller,
            ),

            // 左侧浮动按钮组 - 刷新和切换地图类型
            _LeftFloatingButtons(
              screenHeight: screenHeight,
              controller: widget.controller,
            ),

            // 下半屏 DraggableScrollableSheet，扩大可拖动区域
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                widget.controller.sheetPercent.value = notification.extent;
                return true;
              },
              child: Builder(
                builder: (context) {
                  // 🔧 修改：只有已绑定、查看另一半头像时且非会员时才禁用拖动
                  return Obx(() {
                    final isVip = widget
                        .controller
                        .isVip
                        .value; // 🔧 使用controller的响应式isVip
                    final isViewingPartner =
                        widget.controller.isOneself.value == 0;
                    final isBindPartner = widget.controller.isBindPartner.value;
                    final shouldLimitDrag =
                        !isVip && isViewingPartner && isBindPartner;

                    // 🔧 根据绑定状态动态计算中间吸顶位置
                    // 未绑定时设备信息模块高度134px，已绑定时92px，差42px
                    // 为了让视觉上的吸顶位置一致，需要调整snapSize
                    final middleSnapSize = isBindPartner
                        ? 0.5 +
                              (21 / screenHeight) // 已绑定：屏幕中间
                        : 0.5 +
                              (57 /
                                  screenHeight); // 未绑定：稍微往上偏移42px（设备模块高度差）+ 35

                    return DraggableScrollableSheet(
                      initialChildSize: initialHeight / screenHeight,
                      minChildSize: shouldLimitDrag
                          ? initialHeight / screenHeight
                          : minHeight / screenHeight,
                      maxChildSize: shouldLimitDrag
                          ? initialHeight / screenHeight
                          : maxHeight / screenHeight,
                      snap: true, // 启用吸附效果
                      snapSizes: shouldLimitDrag
                          ? null
                          : [
                              middleSnapSize, // 🔧 动态中间位置（根据绑定状态调整）
                              (screenHeight - 100) /
                                  screenHeight, // 距离屏幕顶部100px
                            ],
                      snapAnimationDuration: const Duration(milliseconds: 200), // 🎯 优化滑动体验：缩短吸附动画时间
                      builder: (context, scrollController) {
                        return Column(
                          children: [
                            // 未绑定提示 - 放置在播放按钮和下半屏之间
                            // Padding(
                            //   padding: const EdgeInsets.only(
                            //     left: 20,
                            //     right: 20,
                            //     bottom: 15,
                            //   ),
                            //   child: _FloatingUnbindNotification(
                            //     controller: widget.controller,
                            //     screenHeight: screenHeight,
                            //     initialHeight: initialHeight,
                            //   ),
                            // ),
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  // boxShadow: [
                                  //   BoxShadow(
                                  //     color: Colors.black12,
                                  //     blurRadius: 10,
                                  //     offset: Offset(0, -2),
                                  //   ),
                                  // ],
                                ),
                                child: Stack(
                                  children: [
                                    NotificationListener<ScrollNotification>(
                                      onNotification: (notification) {
                                        if (notification
                                            is ScrollStartNotification) {
                                          return true;
                                        }
                                        return false;
                                      },
                                      child: CustomScrollView(
                                        controller: scrollController,
                                        slivers: [
                                          // 顶部固定区域
                                          SliverToBoxAdapter(
                                            child: Stack(
                                              children: [
                                                // Container(
                                                //   width: double.infinity,
                                                //   height: 30,
                                                //   decoration: BoxDecoration(
                                                //     gradient: LinearGradient(
                                                //       begin: Alignment.topCenter,
                                                //       end: Alignment.bottomCenter,
                                                //       colors: [
                                                //         Color(0xffFFF7D0),
                                                //         Colors.white,
                                                //       ],
                                                //     ),
                                                //     borderRadius:
                                                //         BorderRadius.circular(16),
                                                //   ),
                                                // ),
                                                Column(
                                                  children: [
                                                    // const SizedBox(height: 12),
                                                    // Container(
                                                    //   width: 40,
                                                    //   height: 4,
                                                    //   decoration: BoxDecoration(
                                                    //     color: Colors.grey[300],
                                                    //     borderRadius:
                                                    //         BorderRadius.circular(
                                                    //           2,
                                                    //         ),
                                                    //   ),
                                                    // ),
                                                    // const SizedBox(height: 16),
                                                    // 虚拟数据提示文字 - 设备信息模块上方居中显示
                                                    //以下为虚拟数据

                                                    // 虚拟提示文字 - 仅查看另一半数据且未绑定时显示
                                                    Obx(() {
                                                      // 只有查看另一半数据(isOneself=0)且未绑定时才显示虚拟数据提示
                                                      if (widget.controller.isOneself.value == 0 && 
                                                          !widget.controller.isBindPartner.value) {
                                                        return Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Center(
                                                              child: Container(
                                                                width: 125,
                                                                height: 23,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .white,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        12.5,
                                                                      ),
                                                                ),
                                                                child: const Text(
                                                                  '以下为虚拟数据',
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Color(
                                                                      0xFF999999,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 10,
                                                            ),
                                                          ],
                                                        );
                                                      }
                                                      return const SizedBox.shrink();
                                                    }),
                                                    //离线提醒
                                                    Obx(() {
                                                      // 只有在已绑定状态下，且另一半离线时才显示
                                                      if (widget.controller.isBindPartner.value && 
                                                          widget.controller.partnerOnlineStatus.value != null &&
                                                          widget.controller.partnerOnlineStatus.value!.status == 0) {
                                                        
                                                        // 格式化离线时间
                                                        String offlineTime = '';
                                                        if (widget.controller.partnerOnlineStatus.value!.updateTime != null) {
                                                          offlineTime = widget.controller.partnerOnlineStatus.value!.updateTime!;
                                                        }
                                                        
                                                        return GestureDetector(
                                                          onTap: () {
                                                            // 点击查看原因，跳转到常见问题页面
                                                            widget.controller.navigateToQuestionPage(
                                                              widget.controller.partnerOnlineStatus.value!.problemId
                                                            );
                                                          },
                                                          child: Container(
                                                            width: double.infinity,
                                                            margin: EdgeInsets.only(
                                                              left: 14,
                                                              right: 14,
                                                              bottom: 10,
                                                            ),
                                                            padding: EdgeInsets.only(
                                                              left: 10,
                                                              right: 10,
                                                            ),
                                                            height: 28,
                                                            decoration: BoxDecoration(
                                                              color: Color(0xffFFFCE8),
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            alignment: Alignment.center,
                                                            child: Row(
                                                              children: [
                                                                Image.asset(
                                                                  'assets/phone_history/kissu3_history_yichang.webp',
                                                                  width: 16,
                                                                  height: 16,
                                                                ),
                                                                SizedBox(width: 4),
                                                                Expanded(
                                                                  child: Text(
                                                                    'Ta离线啦${offlineTime.isNotEmpty ? '，离线时间: $offlineTime' : ''}',
                                                                    style: TextStyle(
                                                                      fontSize: 12,
                                                                      color: Color(0xFF333333),
                                                                    ),
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ),
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  children: [
                                                                    Text(
                                                                      '查看原因',
                                                                      style: TextStyle(
                                                                        fontSize: 13,
                                                                        color: Color(0xFFFF9500),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(width: 4),
                                                                    Image.asset(
                                                                      'assets/phone_history/kissu3_arrow_blue.webp',
                                                                      color: Color(0xFFAD6D48),
                                                                      width: 16,
                                                                      height: 16,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                      return const SizedBox.shrink();
                                                    }),
                                                    _buildDeviceInfoSection(),
                                                    const SizedBox(height: 10),
                                                    _buildLocationInfoSection(),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // 列表 + 背景色 - 使用 SliverFillRemaining 确保白色背景填充到底部
                                          SliverFillRemaining(
                                            hasScrollBody: false,
                                            child: Stack(
                                              children: [
                                                Container(
                                                  margin: EdgeInsets.only(
                                                    left: 15,
                                                    right: 15,
                                                    top: 10,
                                                    bottom: 15,
                                                  ),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 15,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    // border: Border.all(
                                                    //   color: Color(0xffFF88AA),
                                                    // ),
                                                  ),
                                                  child: Obx(() {
                                                    if (widget
                                                        .controller
                                                        .locationRecords
                                                        .isEmpty) {
                                                      return Container(
                                                        width: double.infinity,
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 40,
                                                            ),
                                                        child: Column(
                                                          children: [
                                                            Image.asset(
                                                              'assets/kissu_location_empty.webp',
                                                              width: 128,
                                                              height: 128,
                                                            ),
                                                            SizedBox(
                                                              height: 16,
                                                            ),
                                                            Text(
                                                              '对方目前还没有停留点哦～',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: Color(
                                                                  0xff666666,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }

                                                    return _OptimizedLocationRecordsList(
                                                      controller:
                                                          widget.controller,
                                                    );
                                                  }),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // 统一的会员限制遮罩层 - 覆盖整个滚动区域（带毛玻璃效果）
                                    // 🔧 修改：只有已绑定、查看另一半头像时且非会员时才显示蒙版
                                    Obx(() {
                                      // 先读取响应式值，避免被非响应式条件短路，导致未注册依赖
                                      final isSelfFlag =
                                          widget.controller.isOneself.value;
                                      final isBindPartner =
                                          widget.controller.isBindPartner.value;
                                      final isVip = widget
                                          .controller
                                          .isVip
                                          .value; // 🔧 使用controller的响应式isVip
                                      final shouldShowVipMask =
                                          !isVip &&
                                          isSelfFlag == 0 &&
                                          isBindPartner;
                                      if (shouldShowVipMask) {
                                        return Positioned.fill(
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(20),
                                                ),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                sigmaX: 10.0,
                                                sigmaY: 10.0,
                                              ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFFFFFF,
                                                  ).withOpacity(0.2),
                                                  borderRadius:
                                                      const BorderRadius.vertical(
                                                        top: Radius.circular(
                                                          20,
                                                        ),
                                                      ),
                                                ),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    // 点击遮罩层时跳转到VIP页面，返回后刷新数据
                                                    Get.toNamed(
                                                      KissuRoutePath.vip,
                                                    )?.then((_) {
                                                      // 从VIP页面返回后，刷新用户信息和定位数据
                                                      widget.controller
                                                          .refreshUserInfo();
                                                    });
                                                  },
                                                  child: Container(
                                                    color: Colors
                                                        .transparent, // 确保整个区域可点击
                                                    child: Center(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          // 图片
                                                          GestureDetector(
                                                            onTap: () {
                                                              // 点击图片时跳转到VIP页面，返回后刷新数据
                                                              Get.toNamed(
                                                                KissuRoutePath
                                                                    .vip,
                                                              )?.then((_) {
                                                                // 从VIP页面返回后，刷新用户信息和定位数据
                                                                widget
                                                                    .controller
                                                                    .refreshUserInfo();
                                                              });
                                                            },
                                                            child: Image.asset(
                                                              'assets/kissu_go_bind.webp',
                                                              width: 111,
                                                              height: 34,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          // 文字
                                                          const Text(
                                                            '实时查看"另一半"的位置和行程轨迹',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Color(
                                                                0xFF333333,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  });
                },
              ),
            ),

            // 顶部返回按钮
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Image.asset(
                    'assets/kissu_mine_back.webp',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ),
            //顶部头像优化
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: _CachedAvatarRow(controller: widget.controller),
            ),
          ],
        ),
      ),
    );
  }

  // 设备信息模块
  Widget _buildDeviceInfoSection() {
    return Stack(
      children: [
        Container(
          height: !widget.controller.isBindPartner.value ? 134 : 92,
          padding: !widget.controller.isBindPartner.value
              ? EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ).copyWith(top: 55)
              : EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ).copyWith(top: 15),
          margin: EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: !widget.controller.isBindPartner.value
                  ? AssetImage(
                      'assets/location/kissu3_location_unbind_device_bg.webp',
                    )
                  : AssetImage(
                      'assets/location/kissu3_location_bind_device_bg.webp',
                    ),
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 距离和更新时间
              Row(
                children: [
                  const Text(
                    '我们相距',
                    style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
                  ),

                  const SizedBox(width: 22),
                  Image(
                    image: AssetImage('assets/kissu_location_time_logo.webp'),
                    width: 22,
                    height: 22,
                  ),
                  SizedBox(width: 4),
                  Obx(
                    () => Text(
                      widget.controller.speed.value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  Spacer(),
                  // 天气模块
                  Obx(() {
                    if (widget.controller.weatherIcon.value.isEmpty ||
                        widget.controller.weather.value.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Row(
                      children: [
                        const SizedBox(width: 12),
                        Image.network(
                          widget.controller.weatherIcon.value,
                          width: 16,
                          height: 16,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox.shrink();
                          },
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.controller.weather.value,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFFC04B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              Obx(
                () => IntrinsicWidth(
                  child: Text(
                    widget.controller.distance.value,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Obx(() {
          if (widget.controller.isBindPartner.value) {
            return const SizedBox.shrink();
          }
          return Positioned(
            right: 28,
            top: 12,
            child: GestureDetector(
              onTap: () => widget.controller.performBindAction(),
              child: Container(
                width: 70,
                height: 30,
                color: Colors.transparent,
              ),
            ),
          );
        }),
      ],
    );
  }

  //位置信息模块
  Widget _buildLocationInfoSection() {
    return Container(
      // height: 100,
      margin: EdgeInsets.symmetric(horizontal: 14),
      padding: EdgeInsets.symmetric(
        horizontal: 19,
        vertical: 14,
      ).copyWith(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2C4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "位置",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF000000),
                    fontFamily: 'LiuhuanKatongShoushu',
                  ),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Obx(() {
                  return Text(
                    widget.controller.currentLocationText.value,
                    style: TextStyle(fontSize: 12, color: Color(0xFF333333)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 设备信息行
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Obx(
                    () => DeviceInfoItem(
                      text: widget.controller.myDeviceModel.value,
                      iconPath: 'assets/phone_history/kissu_phone_type.webp',
                      isDevice: true,
                      onLongPress: widget.controller.showTooltip,
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(
                    () => DeviceInfoItem(
                      text: widget.controller.myBatteryLevel.value,
                      iconPath: 'assets/phone_history/kissu_phone_barry.webp',
                      isDevice: false,
                      onLongPress: widget.controller.showTooltip,
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(
                    () => DeviceInfoItem(
                      text: widget.controller.myNetworkName.value,
                      iconPath: 'assets/phone_history/kissu_phone_wifi.webp',
                      isDevice: false,
                      onLongPress: widget.controller.showTooltip,
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
}


// 全屏渐变背景遮罩 - 从中间滑到顶部时显示
class _GradientBackgroundOverlay extends StatelessWidget {
  final LocationV2Controller controller;
  final double screenHeight;
  final double initialHeight;
  final double maxHeight;

  const _GradientBackgroundOverlay({
    required this.controller,
    required this.screenHeight,
    required this.initialHeight,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 计算中间位置（屏幕中间）
      final middlePosition = 0.5; // 屏幕中间位置
      final maxPosition = maxHeight / screenHeight;
      final currentPercent = controller.sheetPercent.value;

      // 只在从中间位置滑到顶部时显示渐变背景
      // 当 currentPercent > middlePosition 时开始显示
      double opacity = 0.0;
      if (currentPercent > middlePosition) {
        // 从中间到顶部的进度：0 到 1
        final progress =
            (currentPercent - middlePosition) / (maxPosition - middlePosition);
        opacity = progress.clamp(0.0, 1.0);
      }

      return Positioned.fill(
        child: IgnorePointer(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: opacity,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFEF6F0), // 顶部颜色
                    Color(0xFFFFFFFF), // 中间颜色
                    Color(0xFFF6F6F6), // 底部颜色
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// 缓存的地图Widget - 避免不必要的重建
class _CachedMapWidget extends StatefulWidget {
  final LocationV2Controller controller;

  const _CachedMapWidget({required this.controller});

  @override
  State<_CachedMapWidget> createState() => _CachedMapWidgetState();
}

class _CachedMapWidgetState extends State<_CachedMapWidget> {
  Set<Marker>? _cachedMarkers;
  Set<Polyline>? _cachedPolylines;
  int _lastMarkersLength = -1;
  int _lastPolylinesLength = -1;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 使用公共getter获取集合长度，避免频繁重建
      final markersLength = widget.controller.markersLength;
      final polylinesLength = widget.controller.polylinesLength;

      // 只有当标记或连接线数量发生变化时才重新构建
      if (_lastMarkersLength != markersLength ||
          _lastPolylinesLength != polylinesLength) {
        _cachedMarkers = widget.controller.markers;
        _cachedPolylines = widget.controller.polylines;
        _lastMarkersLength = markersLength;
        _lastPolylinesLength = polylinesLength;

        print(
          '🗺️ 地图Widget重建 - 标记数量: ${markersLength}, 连接线数量: ${polylinesLength}',
        );
        if (_cachedMarkers != null && _cachedMarkers!.isNotEmpty) {
          print(
            '🗺️ 标记详情: ${_cachedMarkers!.map((m) => '标记: ${m.position}').join(', ')}',
          );
        }
      }

      // 根据控制器的mapType值转换为AMap的MapType
      final mapType = widget.controller.mapType.value == 2
          ? MapType.satellite
          : MapType.normal;

      return RepaintBoundary(
        child: SafeAMapWidget(
          initialCameraPosition: widget.controller.initialCameraPosition,
          onMapCreated: widget.controller.onMapCreated,
          markers: _cachedMarkers ?? {},
          polylines: _cachedPolylines ?? {},
          compassEnabled: true,
          scaleEnabled: true,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          mapType: mapType,
        ),
      );
    });
  }
}

// 优化的头像行Widget
class _CachedAvatarRow extends StatelessWidget {
  final LocationV2Controller controller;

  const _CachedAvatarRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 另一半的头像（左边）
        _AvatarButton(
          controller: controller,
          isMyself: false,
          onTap: () {
            if (controller.isOneself.value != 0) {
              // 直接调用onAvatarTapped，让controller内部处理状态更新和地图移动
              controller.onAvatarTapped(false);
            }
          },
        ),
        const SizedBox(width: 8.0),
        // 自己的头像（右边）
        _AvatarButton(
          controller: controller,
          isMyself: true,
          onTap: () {
            if (controller.isOneself.value != 1) {
              // 直接调用onAvatarTapped，让controller内部处理状态更新和地图移动
              controller.onAvatarTapped(true);
            }
          },
        ),
      ],
    );
  }
}

// 优化的头像按钮Widget
class _AvatarButton extends StatefulWidget {
  final LocationV2Controller controller;
  final bool isMyself;
  final VoidCallback onTap;

  const _AvatarButton({
    required this.controller,
    required this.isMyself,
    required this.onTap,
  });

  @override
  State<_AvatarButton> createState() => _AvatarButtonState();
}

class _AvatarButtonState extends State<_AvatarButton> {
  bool _isAvatarLoaded = false;
  int? _lastIsOneselfValue; // 缓存上次的isOneself值
  bool? _lastIsSelectedValue; // 缓存上次的选中状态

  @override
  Widget build(BuildContext context) {
    final baseSize = 32.0;

    // 使用 Obx 只监听必要的响应式变量
    return Obx(() {
      final currentIsOneselfValue = widget.controller.isOneself.value;

      // 检查当前头像是否被选中
      final isSelected =
          (widget.isMyself && currentIsOneselfValue == 1) ||
          (!widget.isMyself && currentIsOneselfValue == 0);

      // 只有当选中状态真正发生变化时才打印调试信息，减少日志噪音
      if (_lastIsOneselfValue != currentIsOneselfValue ||
          _lastIsSelectedValue != isSelected) {
        print(
          '🎯 头像选中状态变化 - isMyself: ${widget.isMyself}, isOneself: $currentIsOneselfValue, isSelected: $isSelected, isAvatarLoaded: $_isAvatarLoaded',
        );
        _lastIsOneselfValue = currentIsOneselfValue;
        _lastIsSelectedValue = isSelected;
      }

      // 根据选中状态调整缩放比例，但只有在头像加载成功后才应用选中效果
      final scale = (isSelected && _isAvatarLoaded) ? 1.2 : 0.9;
      final actualSize = baseSize * scale;

      final avatarUrl = widget.isMyself
          ? widget.controller.myAvatar.value
          : widget.controller.partnerAvatar.value;

      return GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: actualSize,
              height: actualSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: (isSelected && _isAvatarLoaded)
                    ? Border.all(color: const Color(0xFFFF88AA), width: 1)
                    : null,
                boxShadow: (isSelected && _isAvatarLoaded)
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF88AA).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: SmoothAvatarWidget(
                avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
                defaultAsset: '',
                width: actualSize,
                height: actualSize,
                borderRadius: BorderRadius.circular(9),
                fit: BoxFit.cover,
                onImageLoaded: () {
                  setState(() {
                    _isAvatarLoaded = true;
                  });
                },
              ),
            ),
            // 虚拟TA标签（只在未绑定且为另一半头像时显示）
            if (!widget.isMyself && !widget.controller.isBindPartner.value)
              Positioned(
                top: -18,
                left: actualSize / 2 - 23, // 居中显示
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: const Color(0xFFFF88AA),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    "虚拟TA",
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF000000),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

// 优化的定位记录列表Widget
class _OptimizedLocationRecordsList extends StatelessWidget {
  final LocationV2Controller controller;

  const _OptimizedLocationRecordsList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final records = controller.locationRecords;

      // 如果没有记录，返回空Container，使用原来的空状态显示
      if (records.isEmpty) {
        return Container();
      }

      // 使用ListView.builder优化大列表性能
      if (records.length > 10) {
        // 数据太多，不显示背景图片
        return SizedBox(
          height: 400, // 限制高度，启用滚动
          child: Column(
            children: [
              Obx(() {
                final recordCount = controller.locationRecords.length;
                return Row(
                  children: [
                    Text(
                      "今日停留$recordCount个地方",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF000000),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Image.asset(
                      'assets/kissu_love_yellow.webp',
                      width: 23,
                      height: 23,
                    ),
                  ],
                );
              }),
              SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  final isLast = index == records.length - 1;
                  return RepaintBoundary(
                    child: _LocationRecordItem(
                      record: record,
                      index: index,
                      isLast: isLast,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      } else {
        // 少量数据时使用Column，并显示背景图片
        return _LocationListWithBackground(
          controller: controller,
          records: records,
        );
      }
    });
  }
}

// 带背景图片的停留点列表（只在数据较少时使用）
class _LocationListWithBackground extends StatelessWidget {
  final LocationV2Controller controller;
  final List<LocationRecord> records;

  const _LocationListWithBackground({
    required this.controller,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight - 100; // 顶部吸顶位置
    final maxPercent = maxHeight / screenHeight;
    final imageHeight = 140.0;
    final startShowPercent =
        (maxHeight - imageHeight) / screenHeight; // 开始显示图片的位置

    return Obx(() {
      final currentPercent = controller.sheetPercent.value;

      // 计算图片透明度
      // 从 startShowPercent 滑动到 maxPercent 时，透明度从 0 到 1
      double imageOpacity = 0.0;
      if (currentPercent >= startShowPercent && currentPercent <= maxPercent) {
        final progress =
            (currentPercent - startShowPercent) /
            (maxPercent - startShowPercent);
        imageOpacity = progress.clamp(0.0, 1.0);
      } else if (currentPercent > maxPercent) {
        imageOpacity = 1.0;
      }

      return Stack(
        children: [
          Column(
            children: [
              Row(
                children: [
                  Text(
                    "今日停留${records.length}个地方",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF000000),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/kissu_love_yellow.webp',
                    width: 23,
                    height: 23,
                  ),
                ],
              ),
              SizedBox(height: 16),
              ...records.asMap().entries.map((entry) {
                final index = entry.key;
                final record = entry.value;
                final isLast = index == records.length - 1;
                return RepaintBoundary(
                  child: _LocationRecordItem(
                    record: record,
                    index: index,
                    isLast: isLast,
                  ),
                );
              }),
              // 添加底部间距，为背景图片留出空间
              SizedBox(height: imageHeight),
            ],
          ),
          // 底部背景图片 - 根据滑动位置逐渐显现
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: imageOpacity,
              child: Center(
                child: Image.asset(
                  'assets/location/kissu3_list_bottom_bg.webp',
                  width: 284,
                  height: imageHeight,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// 定位记录项Widget
class _LocationRecordItem extends StatelessWidget {
  final LocationRecord record;
  final int index;
  final bool isLast;

  const _LocationRecordItem({
    required this.record,
    required this.index,
    required this.isLast,
  });

  // 格式化时间范围显示
  String _formatTimeRange(String? startTime, String? endTime) {
    if (startTime == null || startTime.isEmpty) {
      return '未知时间';
    }

    // 如果startTime是"当前"，则显示特殊格式
    if (startTime == '当前') {
      return '当前停留';
    }

    // 如果endTime为空或为"当前"，则只显示开始时间
    if (endTime == null || endTime.isEmpty || endTime == '当前') {
      return '$startTime~当前';
    }

    return '$startTime~$endTime';
  }

  // 获取左侧文本
  String _getLeftText(LocationRecord record) {
    if (record.status == 'staying') {
      return '停留中';
    } else if (record.status == 'ended') {
      return '停留${record.duration ?? '未知'}';
    } else {
      // 默认情况，保持原有逻辑
      return '停留${record.duration ?? '未知'}';
    }
  }

  // 获取右侧文本
  String _getRightText(LocationRecord record) {
    if (record.status == 'staying') {
      return record.duration ?? '未知';
    } else if (record.status == 'ended') {
      return _formatTimeRange(record.startTime, record.endTime);
    } else {
      // 默认情况，保持原有逻辑
      return _formatTimeRange(record.startTime, record.endTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 点击item时跳转到轨迹页面，传递坐标信息
        if (record.latitude != null && record.longitude != null) {
          Get.to(
            () => TrackPage(
              initialLatitude: record.latitude!,
              initialLongitude: record.longitude!,
              initialLocationName: record.locationName,
              initialDuration: record.duration,
              initialStartTime: record.startTime,
              initialEndTime: record.endTime,
              autoShowInfoWindow: true, // 🎯 自动显示InfoWindow
            ),
            binding: TrackBinding(),
          );
        } else {
          // 如果没有坐标信息，只跳转到轨迹页面
          Get.to(() => TrackPage(), binding: TrackBinding());
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧时间
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Image(
                image: AssetImage('assets/kissu_location_circle.webp'),
                width: 8,
                height: 8,
              ),
            ),
            const SizedBox(width: 8),
            // 右侧内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    record.locationName ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFFFFF5EF), Color(0xFFFfffff)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                         record.status == 'staying' ? 'assets/kissu_track_staying.webp' : 'assets/kissu_track_location_end.webp',
                          width: 24,
                          height: 24,color: record.status == 'staying' ? Color(0xFFBE9DFF) : Color(0xFFFBAE84),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getLeftText(record),
                          style: const TextStyle(
                            fontSize: 12,fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Spacer(),
                        Text(
                          _getRightText(record),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
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
    );
  }
}

// // 浮动未绑定提示组件 - 位于播放按钮和下半屏之间
// class _FloatingUnbindNotification extends StatelessWidget {
//   final LocationV2Controller controller;
//   final double screenHeight;
//   final double initialHeight;

//   const _FloatingUnbindNotification({
//     required this.controller,
//     required this.screenHeight,
//     required this.initialHeight,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       // 只在未绑定时显示
//       if (controller.isBindPartner.value) {
//         return const SizedBox.shrink();
//       }

//       // final sheetPercent = controller.sheetPercent.value;
//       // final initialPosition = initialHeight / screenHeight;
//       // final shouldShow = (sheetPercent <= initialPosition + 0.15);

//       return Container(
//         height: 60,
//         padding: const EdgeInsets.symmetric(horizontal: 15),
//         decoration: const BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage('assets/kissu_unbind_bg.webp'),
//             fit: BoxFit.fill,
//           ),
//         ),
//         alignment: Alignment.center,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             const Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "还没有绑定另一半，快去绑定吧！",
//                   style: TextStyle(fontSize: 14, color: Color(0xff333333)),
//                 ),
//                 Text(
//                   "绑定关系，开启甜蜜之旅",
//                   style: TextStyle(fontSize: 12, color: Color(0xff666666)),
//                 ),
//               ],
//             ),
//             GestureDetector(
//               onTap: () => controller.performBindAction(),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: const Color(0xffFF88AA),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: const Text(
//                   "立即绑定",
//                   style: TextStyle(fontSize: 12, color: Colors.white),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     });
//   }
// }

// 右侧浮动按钮组
class _FloatingActionButtons extends StatelessWidget {
  final double screenHeight;
  final LocationV2Controller controller;

  const _FloatingActionButtons({
    required this.screenHeight,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 🔧 根据绑定状态动态计算按钮底部位置
      // 未绑定时设备信息模块高42px，需要向下偏移42px以对齐吸顶位置
      final isBindPartner = controller.isBindPartner.value;
      final deviceHeightDiff = -42.0; // 设备模块高度差
      final firstButtonBottom = isBindPartner
          ? screenHeight / 2 -
                deviceHeightDiff // 已绑定：屏幕中间
          : screenHeight / 2 - deviceHeightDiff; // 未绑定：向下偏移42px

      // 获取当前滑动进度
      // 下半屏有三个位置：
      // 1. 起始位置 (minHeight: 190px) - sheetPercent约为 190/screenHeight
      // 2. 中间吸顶位置 (snapSizes[0]: 动态) - sheetPercent根据绑定状态动态调整
      // 3. 顶部吸顶位置 (maxHeight: screenHeight-100) - sheetPercent约为 (screenHeight-100)/screenHeight
      final sheetPercent = controller.sheetPercent.value;

      // 🔧 动态计算中间吸顶位置（与DraggableScrollableSheet的snapSize保持一致）
      final middleSnapSize = isBindPartner ? 0.5 : 0.5;

      // 计算顶部吸顶位置的百分比
      final maxPercent = (screenHeight - 100) / screenHeight;

      // 🔧 计算透明度（使用动态的middleSnapSize）：
      // - 当 sheetPercent <= middleSnapSize（起始→中间吸顶）时，opacity = 1（完全显示，不变）
      // - 当 sheetPercent >= maxPercent（顶部吸顶）时，opacity = 0（完全隐藏）
      // - 当 middleSnapSize < sheetPercent < maxPercent（中间→顶部）时，线性插值
      double opacity;
      if (sheetPercent <= middleSnapSize) {
        opacity = 1.0;
      } else if (sheetPercent >= maxPercent) {
        opacity = 0.0;
      } else {
        // 线性插值：从middleSnapSize到maxPercent之间，透明度从1降到0
        opacity =
            (maxPercent - sheetPercent) /
            (maxPercent - middleSnapSize - 20 / screenHeight);
      }

      // 确保透明度在有效范围内 [0.0, 1.0]
      opacity = opacity.clamp(0.0, 1.0);

      return Positioned(
        right: 16,
        bottom: firstButtonBottom,
        child: Opacity(
          opacity: opacity,
          child: IgnorePointer(
            ignoring: opacity == 0.0, // 透明度为0时忽略点击
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 第四个按钮：聊天
                // _FloatingButton(
                //   assetPath: 'assets/location/kissu3_location_chat_an.webp',
                //   onTap: () {
                //     Get.to(() => const ChatPage(), binding: ChatBinding());
                //   },
                // ),
                const SizedBox(height: 5),

                // 第三个按钮：状态
                _FloatingButton(
                  assetPath: 'assets/location/kissu3_location_state_an.webp',
                  onTap: () {
                    Get.toNamed(KissuRoutePath.locationState);
                  },
                ),
                const SizedBox(height: 5),

                // 第二个按钮：轨迹
                _FloatingButton(
                  assetPath: 'assets/location/kissu3_location_track_an.webp',
                  onTap: () {
                    // 跳转到足迹页面
                    Get.toNamed(KissuRoutePath.track);
                  },
                ),
                const SizedBox(height: 5),

                // 第一个按钮：位置提醒
                _FloatingButton(
                  assetPath: 'assets/location/kissu3_location_knock_an.webp',
                  onTap: () {
                    // 跳转到位置提醒页面
                    Get.toNamed(KissuRoutePath.locationReminder);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// 单个浮动按钮
class _FloatingButton extends StatelessWidget {
  final String assetPath;
  final VoidCallback onTap;

  const _FloatingButton({required this.assetPath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Image.asset(
          assetPath,
          width: 50,
          height: 50,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// 左侧浮动按钮组
class _LeftFloatingButtons extends StatelessWidget {
  final double screenHeight;
  final LocationV2Controller controller;

  const _LeftFloatingButtons({
    required this.screenHeight,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 🔧 根据绑定状态动态计算按钮底部位置（与右侧按钮对齐）
      final isBindPartner = controller.isBindPartner.value;
      final deviceHeightDiff = -42.0; // 设备模块高度差
      final firstButtonBottom = isBindPartner
          ? screenHeight / 2 -
                deviceHeightDiff // 已绑定：屏幕中间
          : screenHeight / 2 - deviceHeightDiff; // 未绑定：向下偏移42px

      // 使用与右侧按钮相同的透明度计算逻辑
      final sheetPercent = controller.sheetPercent.value;

      // 🔧 动态计算中间吸顶位置（与DraggableScrollableSheet的snapSize保持一致）
      final middleSnapSize = isBindPartner
          ? 0.5
          : 0.5 + (deviceHeightDiff / screenHeight);

      final maxPercent = (screenHeight - 100) / screenHeight;

      double opacity;
      if (sheetPercent <= middleSnapSize) {
        opacity = 1.0;
      } else if (sheetPercent >= maxPercent) {
        opacity = 0.0;
      } else {
        opacity = (maxPercent - sheetPercent) / (maxPercent - middleSnapSize);
      }

      opacity = opacity.clamp(0.0, 1.0);

      return Positioned(
        left: 16,
        bottom: firstButtonBottom,
        child: Opacity(
          opacity: opacity,
          child: IgnorePointer(
            ignoring: opacity == 0.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 刷新按钮
                  GestureDetector(
                    onTap: () async {
                      await controller.refreshLocationData();
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Image(
                        image: AssetImage(
                          'assets/location/kissu_refresh_map.webp',
                        ),
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // 切换地图类型按钮
                  GestureDetector(
                    onTap: () {
                      _showMapTypePicker(context);
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Image(
                        image: AssetImage(
                          'assets/location/kissu3_change_map.webp',
                        ),
                        fit: BoxFit.contain,
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // 显示地图类型选择弹窗
  void _showMapTypePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MapTypePickerSheet(controller: controller),
    );
  }
}

// 地图类型选择弹窗
class _MapTypePickerSheet extends StatelessWidget {
  final LocationV2Controller controller;

  const _MapTypePickerSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖动条
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // 地图类型选项
          Row(
            children: [
              // 经典地图
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    controller.switchMapType(1);
                    Navigator.pop(context);
                  },
                  child: Obx(
                    () => _MapTypeOption(
                      imagePath: 'assets/kissu3_map_custom.webp',
                      label: '经典地图',
                      isSelected: controller.mapType.value == 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 卫星地图
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    controller.switchMapType(2);
                    Navigator.pop(context);
                  },
                  child: Obx(
                    () => _MapTypeOption(
                      imagePath: 'assets/kissu3_map_3d.webp',
                      label: '卫星地图',
                      isSelected: controller.mapType.value == 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// 地图类型选项组件
class _MapTypeOption extends StatelessWidget {
  final String imagePath;
  final String label;
  final bool isSelected;

  const _MapTypeOption({
    required this.imagePath,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 地图预览图
        Container(
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFD1E4)
                  : const Color(0xFFffffff),
              width: isSelected ? 5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // 如果图片加载失败，显示占位符
                return Container(
                  color: const Color(0xFFF5F5F5),
                  child: const Center(
                    child: Icon(Icons.map, size: 48, color: Color(0xFFCCCCCC)),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 地图类型标签
        Stack(
          children: [
            Positioned(
              bottom: 1,
              left: 0,
              right: 0,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFEBF3)
                      : const Color(0xFFffffff),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

