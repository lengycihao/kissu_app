import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/common_back_button.dart';
import 'notification_settings_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:kissu_app/widgets/skeleton/notification_settings_skeleton.dart';

/// 通知设置页面
class NotificationSettingsPage extends GetView<NotificationSettingsController> {
  const NotificationSettingsPage({super.key});

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
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return RepaintBoundary(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: index < 3 ? 16 : 0,
                          ),
                          child: _buildModuleByIndex(index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建顶部导航栏
  Widget _buildTopBar() {
    return Container(
      height: 44,
      child: Stack(
        children: [
          // 返回按钮
          Positioned(
            left: 6,
            top: 0,
            bottom: 0,
            child: Center(
              child: CommonBackButton(
                onTap: () => Get.back(),
                assetPath: "assets/4.0/kissu4_back.webp",
                iconSize: 24,
              ),
            ),
          ),
          // 标题（居中）
          Center(
            child: Obx(() => Text(
              controller.pageTitle.value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
            )),
          ),
        ],
      ),
    );
  }

  /// 根据索引构建模块
  Widget _buildModuleByIndex(int index) {
    switch (index) {
      case 0:
        return _buildNotificationModule(
          title: '位置轨迹',
          items: controller.locationTrackItems,
        );
      case 1:
        return _buildNotificationModule(
          title: 'Kissu',
          items: controller.kissuItems,
        );
      case 2:
        return _buildNotificationModule(
          title: '手机状态',
          items: controller.phoneStatusItems,
        );
      case 3:
        return _buildNotificationModule(
          title: '系统通知',
          items: controller.systemNotificationItems,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// 构建通知模块
  Widget _buildNotificationModule({
    required String title,
    required RxList<NotificationItem> items,
  }) {
    return Obx(() {
      final isLoading = controller.isLoading.value;
      final hasItems = items.isNotEmpty;
      
      // 加载中显示骨架屏
      if (isLoading && !hasItems) {
        return NotificationSettingsSkeleton(title: title);
      }
      
      // 无数据不显示
      if (!hasItems) {
        return const SizedBox.shrink();
      }
      
      return AnimatedOpacity(
        opacity: isLoading ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.only(left: 10, right: 10, top: 12, bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 模块标题
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 11),
              // 通知项列表 - 添加淡入动画
              ...items.asMap().entries.map((entry) {
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 200 + (entry.key * 50)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _buildNotificationItem(entry.value),
                );
              }),
            ],
          ),
        ),
      );
    });
  }

  /// 构建单个通知项
  Widget _buildNotificationItem(NotificationItem item) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xfff9f9f9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 第一行：标题
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 第二行：描述
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 开关按钮
            _NotificationSwitch(
              isEnabled: item.isEnabled,
              onTap: () => controller.toggleSwitch(item),
            ),
          ],
        ),
      ),
    );
  }
}

/// 独立的开关组件，避免整个列表重建
class _NotificationSwitch extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onTap;

  const _NotificationSwitch({
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Image.asset(
        isEnabled
            ? "assets/4.0/kissu4_setting_switch_open.webp"
            : "assets/4.0/kissu4_setting_switch_close.webp",
        width: 38,
        height: 20,
        gaplessPlayback: true,
        cacheWidth: 76,
        cacheHeight: 40,
      ),
    );
  }
}
