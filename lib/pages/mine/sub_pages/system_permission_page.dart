import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/common_back_button.dart';
import 'system_permission_controller.dart';
import '../../../services/permission_service.dart';

class SystemPermissionPage extends GetView<SystemPermissionController> {
  const SystemPermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          // 背景图
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
                const SizedBox(height: 20),
                // 权限列表
                Expanded(child: _buildPermissionList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建顶部导航栏
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 12,
      ),
      child: Row(
        children: [
          CommonBackButton(
            onTap: () => Get.back(),
            assetPath: "assets/images/kissu_mine_back.webp",
            iconSize: 22,
          ),
          const Expanded(
            child: Center(
              child: Text(
                "系统权限",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 22),
        ],
      ),
    );
  }

  /// 构建权限列表
  Widget _buildPermissionList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const _PermissionLoadingView();
      }

      final items = controller.permissionItems;
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final type = item["type"] as PermissionType?;
          return _PermissionItemCard(
            item: item,
            type: type,
            index: index,
            controller: controller,
          );
        },
      );
    });
  }

}

/// 权限加载中视图
class _PermissionLoadingView extends StatelessWidget {
  const _PermissionLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFEA39C)),
          ),
          SizedBox(height: 16),
          Text(
            '加载中...',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}

/// 权限项卡片组件 - 带动画效果
class _PermissionItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final PermissionType? type;
  final int index;
  final SystemPermissionController controller;

  const _PermissionItemCard({
    required this.item,
    required this.type,
    required this.index,
    required this.controller,
  });

  @override
  State<_PermissionItemCard> createState() => _PermissionItemCardState();
}

class _PermissionItemCardState extends State<_PermissionItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 400 + (widget.index * 80)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guideType = widget.item["guideType"] as SystemPermissionGuideType?;
    final bool isGuide = guideType != null;

    // 教程类 item：按钮文案与背景颜色由是否"已完成"决定，但始终可点击进入二级页面
    if (isGuide) {
      // 防止程序休眠：特殊处理，直接申请权限
      if (guideType == SystemPermissionGuideType.preventSleep) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Obx(() {
              // 检查权限状态
              final bool isGranted = widget.controller.isBatteryOptimized.value;
              final String buttonText = isGranted ? "已开启" : "去设置";
              final Color buttonColor =
                  isGranted ? const Color(0xFFCCCCCC) : const Color(0xFFFF839E);
              final VoidCallback? buttonAction = isGranted
                  ? null
                  : () => widget.controller.handlePreventSleepTap();

              return GestureDetector(
                onTap: buttonAction,
                child: _buildCard(
                  buttonText: buttonText,
                  buttonColor: buttonColor,
                  isEnabled: !isGranted,
                  onTap: buttonAction,
                ),
              );
            }),
          ),
        );
      }

      // 其他教程类 item：保持原有逻辑
      return FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Obx(() {
            final bool hasCompleted =
                widget.controller.isGuideCompleted(guideType);
            final String buttonText = hasCompleted ? "已开启" : "去设置";
            final Color buttonColor =
                hasCompleted ? const Color(0xFFCCCCCC) : const Color(0xFFFF839E);
            final VoidCallback buttonAction =
                () => widget.controller.openGuidePage(guideType);

            return GestureDetector(
              onTap: buttonAction,
              child: _buildCard(
                buttonText: buttonText,
                buttonColor: buttonColor,
                isEnabled: true,
                onTap: buttonAction,
              ),
            );
          }),
        ),
      );
    }

    // 普通权限类 item 使用 Obx 监听权限状态变化
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Obx(() {
          final permissionType = widget.type ?? PermissionType.usage;
          final String buttonText =
              widget.controller.getButtonText(permissionType);
          final Color buttonColor =
              widget.controller.getButtonColor(permissionType);
          final bool isEnabled =
              widget.controller.isButtonEnabled(permissionType);
          final VoidCallback? buttonAction = isEnabled
              ? () => widget.controller.onPermissionTap(permissionType)
              : null;

          return _buildCard(
            buttonText: buttonText,
            buttonColor: buttonColor,
            isEnabled: isEnabled,
            onTap: buttonAction,
          );
        }),
      ),
    );
  }

  /// 复用的卡片 UI 构建
  Widget _buildCard({
    required String buttonText,
    required Color buttonColor,
    required bool isEnabled,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6D4128),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 权限图标
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFffffff),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Image.asset(
                widget.item["icon"],
                width: 44,
                height: 44,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 权限信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item["title"],
                  style: const TextStyle(
                    color: Color(0xff333333),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item["subtitle"],
                  style: const TextStyle(
                    color: Color(0xff666666),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 设置按钮
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: buttonColor,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
