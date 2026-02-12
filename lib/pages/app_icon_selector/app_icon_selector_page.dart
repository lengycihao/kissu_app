import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/utils/source_page_utils.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'app_icon_selector_controller.dart';

/// App图标选择页面
class AppIconSelectorPage extends StatefulWidget {
  const AppIconSelectorPage({super.key});

  @override
  State<AppIconSelectorPage> createState() => _AppIconSelectorPageState();
}

class _AppIconSelectorPageState extends State<AppIconSelectorPage>
    with WidgetsBindingObserver {
  late AppIconSelectorController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AppIconSelectorController>();
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

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      controller.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      controller.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFffffff),
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
          Column(
            children: [
              // 顶部导航栏
              _buildAppBar(),
              // 图标列表
              Expanded(
                child: Obx(
                  () => GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 一行3个
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.68, // 宽高比，为文字预留空间
                    ),
                    itemCount: controller.iconItems.length,
                    itemBuilder: (context, index) {
                      final item = controller.iconItems[index];
                      return _buildIconItem(item);
                    },
                  ),
                ),
              ),
              //预览区域
              _buildPreviewSection(),
            ],
          ),
          // 加载遮罩
          Obx(
            () => controller.isLoading.value
                ? Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF9DC4),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// 构建顶部导航栏
  Widget _buildAppBar() {
    return SizedBox(
      height: 64 + MediaQuery.of(context).padding.top,
      child: Stack(
        children: [
          // 返回按钮
          Positioned(
            left: 5,
            top: 20,
            bottom: 0,
            child: GestureDetector(
              onTap: () => Get.back(),
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
            top: 20,
            bottom: 0,
            child: Center(
              child: Text(
                "更换APP图标",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xff333333),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

           
        ],
      ),
    );
  }

  /// 构建底部预览区域
  Widget _buildPreviewSection() {
    return Obx(() {
      final selectedItem = controller.getSelectedItem();
      if (selectedItem == null) return const SizedBox.shrink();

      final isCurrentUsed = controller.isSelectedCurrentUsed;
      final isUserVip = UserManager.isVip;
      final needVip = selectedItem.needVip == 1;

      return Container(
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff999999).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 图标
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                selectedItem.previewPath,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // logo名字
                Text(
                  selectedItem.logoName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff333333),
                  ),
                ),
                const SizedBox(height: 5),
                // logo描述
                Text(
                  selectedItem.numStr,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xff777777),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // 右侧按钮区域
            _buildActionButton(isCurrentUsed, isUserVip, needVip, selectedItem),
          ],
        ),
      );
    });
  }

  /// 构建操作按钮
  Widget _buildActionButton(bool isCurrentUsed, bool isUserVip, bool needVip, AppIconItem item) {
    if (isCurrentUsed) {
      // 正在使用
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xffEBEBEB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "正在使用",
          style: TextStyle(
            fontSize: 12,
            color: Color(0xff333333),
          ),
        ),
      );
    } else if (!needVip || isUserVip) {
      // 免费图标 或 用户是VIP：显示“更换”
      return GestureDetector(
        onTap: () => controller.changeIcon(item.id, item.logoName),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFA9E0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "更换",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else {
      // 需要VIP且用户不是VIP：显示“开通会员”
      return GestureDetector(
        onTap: () {
          controller.onNavigateToNextPage?.call();
          Get.toNamed(
            KissuRoutePath.vip,
            arguments: {
              'source_page': SourcePageUtilsCaller.mine,
              'source_event': ChangeLogoEvents.itemBtn,
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_vip.webp',
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 4),
              const Text(
                "开通会员",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// 构建图标项
  Widget _buildIconItem(AppIconItem item) {
    return GestureDetector(
      onTap: () => controller.selectIcon(item.id),
      child: Obx(() {
        final isSelected = item.id == controller.selectedIconId.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isSelected ? const Color(0xffff9ad9) : Colors.transparent,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图标图片（带边框）- 正方形
              AspectRatio(
                aspectRatio: 1.0,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.asset(
                        item.previewPath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    // 选中指示器
                    if (isSelected)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFA1DB),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // 图标名称
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  item.needVip == 1
                      ? Image.asset(
                          'assets/images/logo_vip.webp',
                          width: 20,
                        )
                      : const Text(
                          '免费',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFaaaaaa),
                          ),
                          textAlign: TextAlign.center,
                        ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.numStr,
                style: const TextStyle(fontSize: 10, color: Color(0xFF777777)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }
}
