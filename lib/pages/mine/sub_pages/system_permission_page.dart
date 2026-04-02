import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'system_permission_controller.dart';
import '../../../widgets/dialogs/permission_setting_dialog.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';
import 'package:kissu_app/services/permission_upload_service.dart';


class SystemPermissionPage extends StatefulWidget {
  const SystemPermissionPage({super.key});

  @override
  State<SystemPermissionPage> createState() => _SystemPermissionPageState();
}

class _SystemPermissionPageState extends State<SystemPermissionPage> {
  SystemPermissionController get controller => Get.find<SystemPermissionController>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // 返回时检查权限并显示挽留弹窗
        final shouldPop = await _checkAndShowPermissionDialog();
        if (shouldPop && context.mounted) {
          // 🔥 返回时上传权限状态到后端
          PermissionUploadService.instance.markDirtyAndUpload();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFFfffff),
      body: Stack(
        children: [
          // 背景图
          Positioned.fill(
            child: Image.asset(
              "assets/images/quanxian_bg.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 顶部导航栏
                _buildTopBar(),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 20),
                    child: Stack(
                      children: [
                        Transform.translate(
                          offset: Offset(0, 15),
                          child: Image(
                            image: AssetImage(
                              "assets/images/quanxian_title.webp",
                            ),
                            width: 188,
                            height: 28,
                          ),
                        ),
                        Text(
                          "设置重要权限",
                          style: TextStyle(
                            color: Color(0xff333333),
                            fontSize: 26,
                            fontFamily: 'AlimamaShuHeiTi',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16, right: 16,bottom: 16),
                  child: Text(
                    "双方都要开启权限，才能保证定位、足迹、用机记录等功能数据显示正常~",
                    style: TextStyle(color: Color(0xff333333), fontSize: 14),
                  ),
                ),
                // 权限列表
                Expanded(child: _buildPermissionList()),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// 检查权限并显示挽留弹窗
  /// 返回 true 表示允许返回，false 表示留在当前页面
  Future<bool> _checkAndShowPermissionDialog() async {
    // 如果权限检查中或所有权限已开启，直接返回
    if (controller.isLoading.value || controller.areAllPermissionsEnabled()) {
      return true;
    }
    
    // 显示挽留弹窗
    await PermissionSettingDialog.showPermissionSettingDialog(context);
    // 无论用户点击"知道了"还是"稍后开启"，都允许返回
    return true;
  }

  /// 构建顶部导航栏
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
              onTap: () async {
                // 检查权限并显示挽留弹窗
                final shouldPop = await _checkAndShowPermissionDialog();
                if (shouldPop && context.mounted) {
                  Get.back();
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
        ],
      ),
    );
  }


  /// 构建权限列表（分组显示）
  Widget _buildPermissionList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const _PermissionLoadingView();
      }

      final items = controller.permissionItems;

      // 按 guideType 分组
      final coreTypes = {
        SystemPermissionGuideType.location,
        SystemPermissionGuideType.preventSleep,
        SystemPermissionGuideType.allowBackgroundRun,
        SystemPermissionGuideType.lockInBackground,
      };

      final appUseTypes = {
        SystemPermissionGuideType.appUsage,
        SystemPermissionGuideType.overlayWindow,
      };

      final coreItems =
          items.where((i) => coreTypes.contains(i['guideType'])).toList();
          final appUsageItems =
          items.where((i) => appUseTypes.contains(i['guideType'])).toList();
 
      final notificationItems = items
          .where((i) =>
              i['guideType'] == SystemPermissionGuideType.notification)
          .toList();

      return Container(
        color: Colors.white,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          
          physics: const BouncingScrollPhysics(),
          children: [
            if (coreItems.isNotEmpty)
              _buildPermissionGroup(
                title: ' 核心权限，必须开启 ',
                subTitle: "★",
                items: coreItems,
                titleInside: true,
              ),
            if (appUsageItems.isNotEmpty)
              _buildPermissionGroup(
                title: 'App使用记录权限和一键锁机权限',
                items: appUsageItems,
                titleInside: true,
              ),
            // if (overlayItems.isNotEmpty)
            //   _buildPermissionGroup(
            //     title: '一键锁机权限',
            //     items: overlayItems,
            //   ),
            if (notificationItems.isNotEmpty)
              _buildPermissionGroup(
                title: '消息通知权限',
                items: notificationItems,
                titleInside: true,
              ),
            const SizedBox(height: 20),
          ],
        ),
      );
    });
  }

  /// 构建权限分组卡片
  Widget _buildPermissionGroup({
    required String title,
     String subTitle = "",
    required List<Map<String, dynamic>> items,
    bool titleInside = false,
  }) {
    const gradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color(0xFFFFDDFD),
        Color(0xFFFAF0FB),
        Color(0xFFF6F6F6),
      ],
    );

    Widget groupCard = Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
      child: Column(
        children: [
          if (titleInside)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(subTitle,style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ), ),
                  Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF000000),
                ),
              ), Text(subTitle,style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ), ),
                ],
              ),
            ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _PermissionItemCard(
              item: item,
              index: index,
              controller: controller,
              inGroup: true,
            );
          }),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          if (!titleInside)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          groupCard,
        ],
      ),
    );
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
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}

/// 权限项卡片组件 - 带动画效果
class _PermissionItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final SystemPermissionController controller;
  final bool inGroup;

  const _PermissionItemCard({
    required this.item,
    required this.index,
    required this.controller,
    this.inGroup = false,
  });

  @override
  State<_PermissionItemCard> createState() => _PermissionItemCardState();
}

class _PermissionItemCardState extends State<_PermissionItemCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  // 闪烁动画控制器
  AnimationController? _flashController;
  Animation<double>? _scaleFlashAnimation; // 手指图片缩放动画
  bool _showFinger = false; // 控制手指图片显示/隐藏

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
    
    // 检查是否需要闪烁
    final guideType = widget.item["guideType"] as SystemPermissionGuideType?;
    if (guideType != null && widget.controller.shouldFlash(guideType)) {
      _startFlashAnimation();
    }
  }
  
  void _startFlashAnimation() {
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // 手指图片缩放动画：从0.8到1.2
    _scaleFlashAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _flashController!, curve: Curves.easeInOut),
    );
    
    // 闪烁3次后停止
    int flashCount = 0;
    _flashController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _flashController!.reverse();
      } else if (status == AnimationStatus.dismissed) {
        flashCount++;
        if (flashCount < 3) {
          _flashController!.forward();
        } else {
          // 闪烁结束，隐藏手指并清除闪烁状态
          if (mounted) {
            setState(() {
              _showFinger = false;
            });
          }
          widget.controller.clearFlashState();
        }
      }
    });
    
    // 延迟启动闪烁，等待入场动画完成
    Future.delayed(Duration(milliseconds: 500 + (widget.index * 80)), () {
      if (mounted) {
        setState(() {
          _showFinger = true;
        });
        _flashController?.forward();
      }
    });
  }

  /// 立即停止闪烁动画并隐藏手指
  void _stopFlashAnimation() {
    if (_flashController != null) {
      _flashController!.stop();
      _flashController!.dispose();
      _flashController = null;
      _scaleFlashAnimation = null;
    }
    if (_showFinger && mounted) {
      setState(() {
        _showFinger = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _flashController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guideType = widget.item["guideType"] as SystemPermissionGuideType?;

    // 所有项目都使用 guideType，统一处理
    if (guideType == null) {
      // 如果没有 guideType，返回空容器（不应该发生）
      return const SizedBox.shrink();
    }

    Widget cardWidget = FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Obx(() {
          // 检查权限是否已开启
          final bool isGranted = widget.controller.isGuideCompleted(guideType);
          final String buttonText = isGranted ? "已开启" : "去设置";
          final Color buttonColor = isGranted
              ? const Color(0xFFC5C5C5)
              : const Color(0xFF000000);
          
          // 点击整个卡片进入二级页面
          final VoidCallback buttonAction = () {
            // 埋点：权限设置页面按钮点击
            AnalyticsHelper.trackPermissionSetBtnClick(
              permissionName: widget.item["title"],
              btnName: buttonText,
            );
            // 点击去设置时立即销毁手指动画
            _stopFlashAnimation();
            widget.controller.openGuidePage(guideType);
          };

          return GestureDetector(
            onTap: buttonAction,
            child: _buildCard(
              buttonText: buttonText,
              buttonColor: buttonColor,
              isGranted: isGranted,
              onTap: buttonAction,
            ),
          );
        }),
      ),
    );
    
    // 如果有闪烁动画且显示手指，在卡片中间显示手指图片
    if (_flashController != null && _scaleFlashAnimation != null && _showFinger) {
      return Stack(
        children: [
          cardWidget,
          // 手指图片居中显示，使用 IgnorePointer 让点击事件穿透
          Positioned.fill(
            child: IgnorePointer(
              child: Transform.translate(offset: Offset(-10, 0), child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedBuilder(
                  animation: _scaleFlashAnimation!,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleFlashAnimation!.value,
                      child: Image.asset(
                        'assets/lock/kissu_touch.png',
                        width: 60,
                        height: 60,
                        color: Color(0xffFF6792),
                      ),
                    );
                  },
                ),
              )),
            ),
          ),
        ],
      );
    }
    
    return cardWidget;
  }

  /// 复用的卡片 UI 构建
  Widget _buildCard({
    required String buttonText,
    required Color buttonColor,
    required bool isGranted,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: widget.inGroup ? 8 : 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: widget.inGroup
            ? null
            : (isGranted ? null : Border.all(color: const Color(0xFFFF97CE))),
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
              child: Image.asset(widget.item["icon"], width: 44, height: 44),
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
                    color: Color(0xff999999),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
