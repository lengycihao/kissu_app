import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'system_permission_controller.dart';
import '../../../widgets/dialogs/permission_setting_dialog.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';

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
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
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

  /// 构建权限列表
  Widget _buildPermissionList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const _PermissionLoadingView();
      }

      final items = controller.permissionItems;
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _PermissionItemCard(
            item: item,
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

  const _PermissionItemCard({
    required this.item,
    required this.index,
    required this.controller,
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // 手指图片缩放动画：从0.8到1.2
    _scaleFlashAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
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
              ? const Color(0xFF999999)
              : const Color(0xFFFFA9E0);
          
          // 点击整个卡片进入二级页面
          final VoidCallback buttonAction = () {
            // 埋点：权限设置页面按钮点击
            AnalyticsHelper.trackPermissionSetBtnClick(
              permissionName: widget.item["title"],
              btnName: buttonText,
            );
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
          // 手指图片居中显示
          Positioned.fill(
            child: Transform.translate(offset: Offset(80, 0),child: Center(
              child: AnimatedBuilder(
                animation: _scaleFlashAnimation!,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleFlashAnimation!.value,
                    child: Image.asset(
                      'assets/lock/kissu_touch.png',
                      width: 60,
                      height: 60,
                      color: Colors.blue,
                    ),
                  );
                },
              ),
            ),),
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // 权限已开启时没有边框，未开启时显示粉色边框
        border: isGranted ? null : Border.all(color: const Color(0xFFFF97CE)),
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
