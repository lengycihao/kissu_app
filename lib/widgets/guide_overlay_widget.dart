import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/home/home_controller.dart';

/// 引导图类型枚举
enum GuideType {
  swipe, // 引导图1：左右滑动
  datingTime, // 引导图2：相恋时间设置
}

/// 引导覆盖层组件
/// 用于在首页显示引导用户操作的覆盖层
class GuideOverlayWidget extends StatefulWidget {
  /// 是否显示引导层
  final bool isVisible;

  /// 引导层关闭回调
  final VoidCallback? onDismiss;

  /// 是否允许点击背景关闭
  final bool dismissible;

  /// 引导图类型
  final GuideType guideType;

  const GuideOverlayWidget({
    Key? key,
    required this.isVisible,
    this.onDismiss,
    this.dismissible = false,
    this.guideType = GuideType.swipe,
  }) : super(key: key);

  @override
  State<GuideOverlayWidget> createState() => _GuideOverlayWidgetState();
}

class _GuideOverlayWidgetState extends State<GuideOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  bool _isVisible = false;

  @override
  void initState() {
    super.initState();

    // 淡入淡出动画控制器
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 缩放动画控制器
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // 滑动动画控制器
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 淡入淡出动画
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // 缩放动画
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // 滑动动画 - 从中心位置开始，左右对称滑动
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    // 如果初始状态为显示，则开始动画
    if (widget.isVisible) {
      _showGuide();
    }
  }

  @override
  void didUpdateWidget(GuideOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _showGuide();
      } else {
        _hideGuide();
      }
    }
  }

  /// 显示引导层
  void _showGuide() {
    if (!_isVisible) {
      setState(() {
        _isVisible = true;
      });

      _fadeController.forward();
      _scaleController.forward();
      _slideController.repeat(reverse: true);
    }
  }

  /// 隐藏引导层
  void _hideGuide() {
    if (_isVisible) {
      _fadeController.reverse();
      _scaleController.reverse();
      _slideController.stop();
      _slideController.reset();
      _scaleController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isVisible = false;
          });
          widget.onDismiss?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _fadeAnimation,
        _scaleAnimation,
        _slideAnimation,
      ]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _buildGuideContent(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建引导内容
  Widget _buildGuideContent() {
    switch (widget.guideType) {
      case GuideType.swipe:
        return _buildSwipeGuide();
      case GuideType.datingTime:
        return _buildDatingTimeGuide();
    }
  }

  /// 构建滑动引导内容（引导图1）
  Widget _buildSwipeGuide() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 手势指示图标（带滑动动画）
          Transform.translate(
            offset: Offset(
              (_slideAnimation.value - 0.5) * 40,
              0,
            ), // 从-20到+20，完全对称
            child: Image.asset(
              'assets/3.0/kissu3_guide_touch.webp',
              width: 155,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 16),

          // 引导文字
          const Text(
            '左右滑动',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFFffffff),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            '查看更多惊喜场景',
            style: TextStyle(fontSize: 20, color: Color(0xFFffffff)),
          ),

          const SizedBox(height: 20),

          // 我知道了按钮
          GestureDetector(
            onTap: _hideGuide,
            child: Image.asset(
              'assets/3.0/kissu3_guide_konw.webp',
              width: 108,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建相恋时间引导内容（引导图2）
  Widget _buildDatingTimeGuide() {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return Stack(
          children: [
            Positioned(
              top: 92,
              right: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xffFFECEA)),
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                child: Text(
                  "在一起${controller.loveDays.value}天",
                  style: TextStyle(color: Color(0xff666666), fontSize: 12),
                ),
              ),
            ),
            // 竖线
            Positioned(
              top: 110,
              right: 42,
              child: Image.asset(
                'assets/3.0/kissu3_guide_line.webp',
                width: 14,
                height: 58,
                fit: BoxFit.contain,
              ),
            ),

            // 文字和我知道了按钮
            Positioned(
              top: 170,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 引导文字
                  const Text(
                    '相恋时间在这里设置哦~',
                    style: TextStyle(fontSize: 20, color: Color(0xFFffffff)),
                  ),

                  const SizedBox(height: 8),

                  // 我知道了按钮
                  GestureDetector(
                    onTap: _hideGuide,
                    child: Image.asset(
                      'assets/3.0/kissu3_guide_konw.webp',
                      width: 108,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 引导层管理器
/// 用于管理引导层的显示状态
class GuideManager {
  static final GuideManager _instance = GuideManager._internal();
  factory GuideManager() => _instance;
  GuideManager._internal();

  /// 是否已显示过引导层
  bool _hasShownGuide = false;

  /// 引导层显示状态
  final RxBool _isGuideVisible = false.obs;

  /// 当前引导图类型
  final Rx<GuideType> _currentGuideType = GuideType.swipe.obs;

  /// 获取引导层显示状态
  bool get isGuideVisible => _isGuideVisible.value;

  /// 获取当前引导图类型
  GuideType get currentGuideType => _currentGuideType.value;

  /// 引导层显示状态流
  Stream<bool> get guideVisibleStream => _isGuideVisible.stream;

  /// 引导图类型流
  Stream<GuideType> get guideTypeStream => _currentGuideType.stream;

  /// 显示引导层
  void showGuide({GuideType guideType = GuideType.swipe}) {
    if (!_hasShownGuide) {
      _currentGuideType.value = guideType;
      _isGuideVisible.value = true;
      _hasShownGuide = true;
    }
  }

  /// 隐藏引导层
  void hideGuide() {
    _isGuideVisible.value = false;
  }

  /// 重置引导状态（用于测试）
  void resetGuide() {
    _hasShownGuide = false;
    _isGuideVisible.value = false;
    _currentGuideType.value = GuideType.swipe;
  }

  /// 检查是否应该显示引导层
  bool shouldShowGuide() {
    return !_hasShownGuide;
  }
}
