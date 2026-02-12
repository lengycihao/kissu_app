import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routers/kissu_route_path.dart';
import '../../network/public/auth_service.dart';
import '../../network/public/service_locator.dart';
import '../../network/tools/logging/logging.dart';

/// 开屏引导页
/// 首次下载打开App时展示，共4张引导图，支持侧滑和跳过
class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  final PageController _pageController = PageController();
  final RxInt _currentPage = 0.obs;

  // 引导图资源列表
  final List<String> _guideImages = [
    'assets/home/kissu_guide1.webp',
    'assets/home/kissu_guide2.webp',
    'assets/home/kissu_guide3.webp',
    'assets/home/kissu_guide4.webp',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 跳过引导页，继续正常启动流程
  Future<void> _skipGuide() async {
    // 引导页完成，检查登录状态并导航到对应页面
    await _navigateToNextPage();
  }
  
  /// 导航到下一个页面（根据登录状态）
  Future<void> _navigateToNextPage() async {
    try {
      // 检查登录状态
      final authService = getIt<AuthService>();
      final isLoggedIn = authService.isLoggedIn; // isLoggedIn是getter，不是方法
      
      if (isLoggedIn) {
        logDebug('用户已登录，导航到主页');
        Get.offAllNamed(KissuRoutePath.home);
      } else {
        logDebug('用户未登录，导航到登录页');
        Get.offAllNamed(KissuRoutePath.login);
      }
    } catch (e) {
      logError('检查登录状态失败: $e，默认导航到登录页');
      Get.offAllNamed(KissuRoutePath.login);
    }
  }

  /// 下一页
  void _nextPage() {
    if (_currentPage.value < _guideImages.length - 1) {
      // 不是最后一页，跳转到下一页
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 最后一页，关闭引导页
      _skipGuide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 引导图PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              _currentPage.value = index;
            },
            itemCount: _guideImages.length,
            itemBuilder: (context, index) {
              return Image.asset(
                _guideImages[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),

          // 右上角跳过按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 16,
            child: GestureDetector(
              onTap: _skipGuide,
              child: Image.asset(
                'assets/home/kissu_guide_jump.webp',
                width: 48,
                height: 26,
              ),
            ),
          ),

          // 右下角下一页按钮
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 65,
            right: 40,
            child: GestureDetector(
              onTap: _nextPage,
              child: Obx(() {
                // 判断是否是最后一页
                final isLastPage = _currentPage.value == _guideImages.length - 1;
                return Image.asset(
                  isLastPage 
                    ? 'assets/home/kissu_guide_last_open.webp'
                    : 'assets/home/kissu_guide_last.webp',
                  width: isLastPage ? 140 : 40,
                  height: 40,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
