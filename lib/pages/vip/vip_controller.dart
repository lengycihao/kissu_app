import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:kissu_app/models/vip_banner_model.dart';
import 'package:kissu_app/models/vip_package_model.dart';
import 'package:kissu_app/services/vip_service.dart';
import 'package:kissu_app/services/payment_service.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class VipController extends GetxController {
  // Logger实例
  final Logger _logger = Logger();
  // VIP服务实例
  final VipService _vipService = VipService();
  // 支付服务实例
  final PaymentService _paymentService = PaymentService.to;
  // 轮播图数据
  var bannerData = Rxn<VipBannerModel>();
  
  // VIP套餐列表数据
  var vipPackages = <VipPackageModel>[].obs;
  
  // 是否正在加载套餐数据
  var isLoadingPackages = false.obs;
  
  // 轮播图控制器
  late PageController pageController;
  
  // 评价轮播图滚动控制器
  late ScrollController commentScrollController;
  
  // 价格组件横向滚动控制器
  late ScrollController priceScrollController;
  
  // 当前轮播图索引
  var currentIndex = 0.obs;
  
  // 当前评价轮播图索引
  var commentCurrentIndex = 0.obs;
  
  // Chewie 视频播放器控制器列表
  var chewieControllers = <ChewieController?>[].obs;
  
  // VideoPlayerController 列表（底层控制器）
  var videoPlayerControllers = <VideoPlayerController?>[].obs;
  
  // 选中的价格索引
  var selectedPriceIndex = 0.obs; // 默认选中第一个套餐
  
  // 选中的支付方式 (0: 支付宝, 1: 微信)
  var selectedPaymentMethod = 0.obs; // 默认支付宝
  
  // 是否同意协议
  var agreementChecked = false.obs;
  
  // 是否正在购买
  var isPurchasing = false.obs;
  
  // 页面是否可见
  var isPageVisible = false.obs;
  
  // 是否已经初始化过
  var _isInitialized = false;
  
  // 用于防止重复dispose的标志
  var _isDisposed = false;
  
  // 自动轮播定时器
  Timer? _topCarouselTimer;
  Timer? _commentCarouselTimer;
  
  // 自动轮播配置
  static const Duration _topCarouselInterval = Duration(seconds: 3);
  static const Duration _commentCarouselInterval = Duration(seconds: 4);

  @override
  void onInit() {
    super.onInit();
    pageController = PageController();
    commentScrollController = ScrollController();
    priceScrollController = ScrollController();
  }

  @override
  void onReady() {
    super.onReady();
    
    // 防止重复初始化
    if (_isInitialized || _isDisposed) {
      return;
    }
    _isInitialized = true;
    
    // 标记页面为可见状态
    isPageVisible.value = true;
    
    // 添加延迟确保页面完全渲染
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_isDisposed && isPageVisible.value) {
        // 只在页面真正显示时才加载视频数据
        _loadVipBannerData();
        // 加载VIP套餐数据
        _loadVipPackages();
      }
    });
  }


  @override
  void onClose() {
    // 防止重复dispose
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    
    // 标记页面为不可见状态
    isPageVisible.value = false;
    
    // 停止所有自动轮播
    _stopAutoCarousel();
    
    // 销毁 Chewie 控制器
    _disposeChewieControllers();
    
    // 销毁页面控制器
    try {
      pageController.dispose();
    } catch (e) {
      print('PageController dispose失败: $e');
    }
    
    try {
      commentScrollController.dispose();
    } catch (e) {
      print('CommentScrollController dispose失败: $e');
    }
    
    try {
      priceScrollController.dispose();
    } catch (e) {
      print('PriceScrollController dispose失败: $e');
    }
    
    super.onClose();
  }
  
  /// 释放所有 Chewie 控制器
  void _disposeChewieControllers() {
    // 先释放 Chewie 控制器
    for (int i = 0; i < chewieControllers.length; i++) {
      final chewieController = chewieControllers[i];
      if (chewieController != null) {
        try {
          chewieController.dispose();
        } catch (e) {
          // 静默处理释放错误（可能已经被dispose了）
          print('释放ChewieController失败: $e');
        }
      }
    }
    chewieControllers.clear();
    
    // 再释放底层 VideoPlayerController
    for (int i = 0; i < videoPlayerControllers.length; i++) {
      final videoController = videoPlayerControllers[i];
      if (videoController != null) {
        try {
          // 通过检查value来判断是否已被dispose
          videoController.value;
          videoController.dispose();
        } catch (e) {
          // 静默处理释放错误（可能已经被dispose了）
          print('释放VideoPlayerController失败: $e');
        }
      }
    }
    videoPlayerControllers.clear();
  }

  /// 加载VIP横幅数据
  void _loadVipBannerData() async {
    try {
      // 模拟接口调用，实际应该调用 /pay/iconBanner 接口
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 使用测试数据
      final testData = {
        "comment_list": [
          {
            "date": "09月11日",
            "nickname": "甜蜜小窝",
            "content": "异地恋三年，靠这个APP随时查看对方位置，安全感爆棚！再也不担心突然失联了，还能悄悄准备惊喜，超贴心～"
          },
          {
            "date": "09月11日",
            "nickname": "心动信号",
            "content": "跨国产粮必备！时差党靠它同步生活节奏，看到对方定位就感觉彼此还在同一个时空，距离不再是问题"
          },
          {
            "date": "09月11日",
            "nickname": "猫系女友",
            "content": "加班党福音！女朋友再也不用问我'到公司了吗'，直接看定位就行。矛盾少了，默契多了，这钱花得值！"
          }
        ],
        "vip_icon_banner": [
          {
            "vip_icon_video": "https://kissustatic.yuluojishu.com/uploads/2025/08/31/32ae25afac4432c94afc4f1adc18a393.mp4",
            "vip_icon_banner": "",
            "vip_icon": "https://kissustatic.yuluojishu.com/uploads/2025/08/22/092f1c38cdad6b28a1feba13d3f8c4d5.png",
            "vip_icon_select": "https://kissustatic.yuluojishu.com/uploads/2025/08/22/7d71d319498be3d2966b922e2ac7c00d.png"
          },
          {
            "vip_icon_video": "https://kissustatic.yuluojishu.com/uploads/2025/08/31/7857e206f8ccde38200e0790393f06e5.mp4",
            "vip_icon_banner": "",
            "vip_icon": "https://kissustatic.yuluojishu.com/uploads/2025/08/22/0a7781998dd34375e9e337543904bf12.png",
            "vip_icon_select": "https://kissustatic.yuluojishu.com/uploads/2025/08/31/ee2e55f486245a32f1dd356fb409e863.png"
          },
          {
            "vip_icon_video": "https://kissustatic.yuluojishu.com/uploads/2025/08/31/434a2bcd998b4f5c17576fc0c72a2540.mp4",
            "vip_icon_banner": "",
            "vip_icon": "https://kissustatic.yuluojishu.com/uploads/2025/08/22/47ec5e48be2e22f5d8886b8243518eb2.png",
            "vip_icon_select": "https://kissustatic.yuluojishu.com/uploads/2025/08/22/57b7079d5f3a1c3d13670b313311fa87.png"
          },
          {
            "vip_icon_video": "https://kissustatic.yuluojishu.com/uploads/2025/08/31/564f9a9b142b39a98a63f711a3bf275e.mp4",
            "vip_icon_banner": "",
            "vip_icon": "https://kissustatic.yuluojishu.com/uploads/2025/08/22/f7fe0d2416bf219d16e05ddcf752ee5d.png",
            "vip_icon_select": "https://kissustatic.yuluojishu.com/uploads/2025/08/22/07c2af127a33d18ddc72e0908bf6fbbb.png"
          }
        ]
      };
      
      bannerData.value = VipBannerModel.fromJson(testData);
      _initializeChewieControllers();
      
      // 启动自动轮播
      _startAutoCarousel();
    } catch (e) {
      // 静默处理加载错误
    }
  }
  
  /// 初始化 Chewie 视频播放器控制器
  void _initializeChewieControllers() {
    // 检查页面状态
    if (_isDisposed || !isPageVisible.value) {
      return;
    }
    
    // 如果已经有控制器且数量匹配，不需要重新初始化
    final banners = bannerData.value?.vipIconBanner ?? [];
    if (chewieControllers.length == banners.length && 
        chewieControllers.isNotEmpty) {
      return;
    }
    
    // 安全地清理现有控制器
    try {
      _disposeChewieControllers();
    } catch (e) {
      print('清理现有控制器失败: $e');
    }
    
    // 先初始化 VideoPlayerController 列表
    try {
      videoPlayerControllers.value = List.generate(banners.length, (index) {
        // 再次检查页面状态
        if (_isDisposed || !isPageVisible.value) {
          return null;
        }
        
        final banner = banners[index];
        if (banner.hasVideo) {
          try {
            final videoController = VideoPlayerController.networkUrl(
              Uri.parse(banner.vipIconVideo),
              videoPlayerOptions: VideoPlayerOptions(
                mixWithOthers: false, // 避免与其他音频混合
                allowBackgroundPlayback: false,
              ),
              httpHeaders: {
                'User-Agent': 'KissuApp/1.0',
              },
            );
            
            // 设置循环播放
            videoController.setLooping(true);
            
            // 异步初始化，增强错误处理
            _initializeVideoController(videoController);
            
            return videoController;
          } catch (e) {
            print('创建VideoPlayerController失败 $index: $e');
            return null;
          }
        } else {
          return null;
        }
      });
    } catch (e) {
      print('创建VideoPlayerController列表失败: $e');
      videoPlayerControllers.value = [];
    }
    
    // 再初始化 ChewieController 列表
    try {
      chewieControllers.value = List.generate(banners.length, (index) {
        // 再次检查页面状态
        if (_isDisposed || !isPageVisible.value) {
          return null;
        }
        
        final videoController = videoPlayerControllers[index];
        if (videoController != null) {
          try {
            final chewieController = ChewieController(
              videoPlayerController: videoController,
              autoPlay: true, // 启用自动播放
              looping: true, // 循环播放
              showControls: false, // 隐藏控制条
              autoInitialize: true, // 自动初始化
              placeholder: Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorBuilder: (context, errorMessage) {
                print('Chewie播放器错误: $errorMessage');
                return Container(
                  color: Colors.grey[100],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.grey[600],
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '视频暂时无法播放',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
            
            return chewieController;
          } catch (e) {
            print('创建ChewieController失败 $index: $e');
            return null;
          }
        }
        return null;
      });
    } catch (e) {
      print('创建ChewieController列表失败: $e');
      chewieControllers.value = [];
    }
    
    update(); // 更新UI
  }
  
  /// 异步初始化视频控制器，增强错误处理
  Future<void> _initializeVideoController(VideoPlayerController controller) async {
    try {
      // 检查页面是否还存在
      if (_isDisposed || !isPageVisible.value) {
        return;
      }
      
      // 检查控制器是否已经初始化或已被dispose
      try {
        // 通过访问value来检查控制器是否可用
        final value = controller.value;
        if (value.isInitialized) {
          return;
        }
      } catch (e) {
        // 控制器可能已经被dispose，直接返回
        print('控制器已被dispose，跳过初始化: $e');
        return;
      }
      
      // 初始化视频播放器，增加超时处理
      await controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('视频初始化超时');
        },
      );
      
      // 再次检查页面状态
      if (_isDisposed || !isPageVisible.value) {
        return;
      }
      
      // 初始化完成后立即设置静音
      await controller.setVolume(0.0);
      
      // 添加错误监听器（避免重复添加）
      controller.addListener(() {
        if (!_isDisposed && controller.value.hasError) {
          print('VideoPlayer错误: ${controller.value.errorDescription}');
          // 尝试重新初始化或静默处理错误
          _handleVideoError(controller);
        }
      });
      
    } catch (e) {
      print('视频初始化失败: $e');
      // 静默处理初始化错误
    }
  }
  
  /// 处理视频播放错误
  void _handleVideoError(VideoPlayerController controller) {
    try {
      // 静默处理错误，避免影响用户体验
      controller.pause();
    } catch (e) {
      print('处理视频错误时发生异常: $e');
    }
  }
  
  /// 轮播图页面改变
  void onPageChanged(int index) {
    // 停止当前播放的视频
    _pauseCurrentVideo();
    currentIndex.value = index;
    // 如果新页面是视频，静音自动播放
    playCurrentVideo();
    
    // 重置顶部轮播图自动轮播定时器
    _resetTopCarouselTimer();
  }
  
  /// 确保第一个视频静音自动播放
  void ensureFirstVideoPlay() {
    if (chewieControllers.isNotEmpty && chewieControllers[0] != null) {
      final firstController = chewieControllers[0]!.videoPlayerController;
      
      if (firstController.value.isInitialized && !firstController.value.hasError) {
        if (!firstController.value.isPlaying) {
          // 设置静音和循环播放
          firstController.setVolume(0.0);
          firstController.setLooping(true);
          firstController.play();
          update();
        }
      } else {
        // 如果还没初始化，等待一下再试
        Future.delayed(const Duration(milliseconds: 300), () {
          if (firstController.value.isInitialized && 
              !firstController.value.isPlaying && 
              !firstController.value.hasError) {
            // 设置静音和循环播放
            firstController.setVolume(0.0);
            firstController.setLooping(true);
            firstController.play();
            update();
          }
        });
      }
    }
  }
  
  /// 暂停当前视频
  void _pauseCurrentVideo() {
    try {
      if (chewieControllers.isNotEmpty && 
          currentIndex.value < chewieControllers.length &&
          chewieControllers[currentIndex.value] != null) {
        chewieControllers[currentIndex.value]?.videoPlayerController.pause();
      }
    } catch (e) {
      // 静默处理暂停错误
    }
  }

  /// 暂停所有视频
  void pauseAllVideos() {
    try {
      for (int i = 0; i < chewieControllers.length; i++) {
        final chewieController = chewieControllers[i];
        if (chewieController != null) {
          final controller = chewieController.videoPlayerController;
          if (controller.value.isPlaying) {
            controller.pause();
          }
        }
      }
    } catch (e) {
      // 静默处理暂停所有视频错误
    }
  }
  
  /// 播放当前视频
  void playCurrentVideo() {
    // 只有在页面可见时才播放视频
    if (!isPageVisible.value) {
      return;
    }
    
    try {
      if (chewieControllers.isNotEmpty && 
          currentIndex.value < chewieControllers.length &&
          chewieControllers[currentIndex.value] != null) {
        final controller = chewieControllers[currentIndex.value]!.videoPlayerController;
        
        // 检查是否有错误
        if (controller.value.hasError) {
          print('视频播放器存在错误，跳过播放: ${controller.value.errorDescription}');
          return;
        }
        
        if (controller.value.isInitialized == true) {
          controller.setVolume(0.0); // 静音播放
          controller.setLooping(true); // 循环播放
          controller.play();
          update(); // 立即更新UI
        } else {
          // 如果还没初始化完成，等待一下再试
          Future.delayed(const Duration(milliseconds: 200), () {
            if (controller.value.isInitialized == true && 
                isPageVisible.value && 
                !controller.value.hasError) {
              controller.setVolume(0.0); // 静音播放
              controller.setLooping(true);
              controller.play();
              update();
            }
          });
        }
      }
    } catch (e) {
      print('播放视频时发生错误: $e');
      // 静默处理播放错误
    }
  }
  
  /// 选择标签（图片按钮）
  void selectTab(int index) {
    _pauseCurrentVideo();
    currentIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    playCurrentVideo();
  }

  /// 评价轮播图滚动监听
  void onCommentScroll() {
    if (commentScrollController.hasClients) {
      final scrollOffset = commentScrollController.offset;
      final itemWidth = 266.0 + 13.0; // 每个item宽度 + 间距
      final currentIndex = (scrollOffset / itemWidth).round();
      commentCurrentIndex.value = currentIndex.clamp(0, (bannerData.value?.commentList.length ?? 1) - 1);
      
      // 重置评论轮播图自动轮播定时器
      _resetCommentCarouselTimer();
    }
  }
  
  /// 获取指定索引的 Chewie 控制器
  ChewieController? getChewieController(int index) {
    if (index < chewieControllers.length) {
      return chewieControllers[index];
    }
    return null;
  }
  
  /// 获取指定索引的视频控制器
  VideoPlayerController? getVideoController(int index) {
    if (index < chewieControllers.length && chewieControllers[index] != null) {
      return chewieControllers[index]!.videoPlayerController;
    }
    return null;
  }
  
  /// 选择价格
  void selectPrice(int index) {
    debugPrint('🎯 selectPrice被调用: index=$index');
    debugPrint('🎯 当前套餐数量: ${vipPackages.length}');
    debugPrint('🎯 当前选中索引: ${selectedPriceIndex.value}');
    
    if (index >= 0 && index < vipPackages.length) {
      // 检查是否真的需要更新
      if (selectedPriceIndex.value != index) {
        selectedPriceIndex.value = index;
        debugPrint('🎯 价格选择成功: 新索引=$index, 套餐=${vipPackages[index].title}');
        _scrollToSelectedPrice(index);
        
        // 强制更新UI (对于使用GetBuilder的组件)
        update();
      } else {
        debugPrint('🎯 价格选择: 已经是选中状态 index=$index');
      }
    } else {
      debugPrint('🎯 价格选择失败: 索引超出范围 index=$index, length=${vipPackages.length}');
    }
  }
  
  /// 滚动到选中的价格项
  void _scrollToSelectedPrice(int index) {
    if (!priceScrollController.hasClients) return;
    
    const itemWidth = 100.0;
    const itemSpacing = 10.0;
    const sideMargin = 15.0;
    
    // 计算目标位置
    final targetOffset = (itemWidth + itemSpacing) * index;
    final screenWidth = Get.width;
    final maxOffset = priceScrollController.position.maxScrollExtent;
    
    // 确保选中项在可见区域内
    final currentOffset = priceScrollController.offset;
    final viewPortWidth = screenWidth - (sideMargin * 2);
    
    double newOffset = targetOffset;
    
    // 如果项目在右侧看不到，滚动到它
    if (targetOffset + itemWidth > currentOffset + viewPortWidth) {
      newOffset = targetOffset + itemWidth - viewPortWidth;
    }
    // 如果项目在左侧看不到，滚动到它
    else if (targetOffset < currentOffset) {
      newOffset = targetOffset;
    } else {
      // 项目已经可见，不需要滚动
      return;
    }
    
    // 限制在有效范围内
    newOffset = newOffset.clamp(0.0, maxOffset);
    
    // 平滑滚动到目标位置
    priceScrollController.animateTo(
      newOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  /// 选择支付方式
  void selectPaymentMethod(int index) {
    selectedPaymentMethod.value = index;
  }
  
  /// 切换协议同意状态
  void toggleAgreement() {
    debugPrint('💫 协议勾选按钮被点击，当前状态: ${agreementChecked.value}');
    agreementChecked.value = !agreementChecked.value;
    debugPrint('💫 协议勾选状态已切换为: ${agreementChecked.value}');
  }
  
  /// 加载VIP套餐数据
  Future<void> _loadVipPackages() async {
    try {
      isLoadingPackages.value = true;
      final result = await _vipService.getVipPackageList();
      if (result.isSuccess && result.data != null) {
        vipPackages.value = result.data!;
        // 如果有数据，默认选中第一个套餐
        if (vipPackages.isNotEmpty) {
          selectedPriceIndex.value = 0;
        }
      } else {
        Get.snackbar('错误', result.msg ?? '加载套餐数据失败');
      }
    } catch (e) {
      Get.snackbar('错误', '加载套餐数据失败: $e');
    } finally {
      isLoadingPackages.value = false;
    }
  }

  /// 获取当前选中的套餐
  VipPackageModel? get selectedPackage {
    if (selectedPriceIndex.value < vipPackages.length) {
      return vipPackages[selectedPriceIndex.value];
    }
    return null;
  }

  /// 获取当前选中的价格文本
  String getCurrentPrice() {
    final package = selectedPackage;
    return package?.priceText ?? '¥0.00';
  }

  /// 购买VIP
  void purchaseVip() async {
    debugPrint('💫 支付按钮被点击，开始购买VIP流程');
    debugPrint('💫 当前协议勾选状态: ${agreementChecked.value}');
    debugPrint('💫 当前是否正在购买: ${isPurchasing.value}');
    
    if (isPurchasing.value) {
      debugPrint('💫 正在购买中，忽略重复点击');
      return;
    }
    
    if (!agreementChecked.value) {
      debugPrint('💫 协议未勾选，显示提示');
      Get.snackbar(
        '提示',
        '请先同意会员服务协议',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // 检查是否选择了套餐
    final package = selectedPackage;
    if (package == null) {
      Get.snackbar(
        '提示',
        '请选择一个套餐',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      isPurchasing.value = true;
      
      // 获取选中的支付方式
      final paymentMethod = _getSelectedPaymentMethod();
      
      // 显示购买确认对话框
      final confirmed = await _showPurchaseConfirmDialog(package, paymentMethod);
      if (!confirmed) {
        return;
      }
      
      // 处理购买过程
      await _processPurchase(package);
      
      // 购买成功提示
      Get.snackbar(
        '购买成功',
        '恭喜您成功开通${package.title}！',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
      // 延迟后返回上一页
      Future.delayed(const Duration(seconds: 1), () {
        Get.back();
      });
      
    } catch (e) {
      // 购买失败提示
      Get.snackbar(
        '购买失败',
        '购买过程中出现错误，请重试',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isPurchasing.value = false;
    }
  }

  
  /// 获取选中的支付方式
  String _getSelectedPaymentMethod() {
    switch (selectedPaymentMethod.value) {
      case 0:
        return '支付宝支付';
      case 1:
        return '微信支付';
      default:
        return '支付宝支付';
    }
  }

  /// 显示购买确认对话框
  Future<bool> _showPurchaseConfirmDialog(
    VipPackageModel package, 
    String paymentMethod
  ) async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: const Text('确认购买'),
        content: Text(
          '确定要购买${package.title}吗？\n'
          '价格：${package.priceText}\n'
          '支付方式：$paymentMethod'
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0A6C),
              foregroundColor: Colors.white,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
      barrierDismissible: false,
    ) ?? false;
  }

  /// 处理购买流程
  Future<void> _processPurchase(VipPackageModel package) async {
    try {
      bool result = false;
      
      if (selectedPaymentMethod.value == 0) {
        // 支付宝支付
        final aliPayResult = await _vipService.aliPay(vipPackageId: package.id);
        if (aliPayResult.isSuccess && aliPayResult.data != null) {
          // 调用支付宝支付
          result = await _paymentService.payWithAlipay(
            orderInfo: aliPayResult.data!.orderString ?? '',
          );
        } else {
          throw Exception(aliPayResult.msg ?? '支付宝支付订单创建失败');
        }
      } else {
        // 微信支付
        final wxPayResult = await _vipService.wxPay(vipPackageId: package.id);
        if (wxPayResult.isSuccess && wxPayResult.data != null) {
          // 解析微信支付参数
          final payData = wxPayResult.data!;
          result = await _paymentService.payWithWechat(
            appId: payData.appId ?? '',
            partnerId: payData.partnerId ?? '',
            prepayId: payData.prepayId ?? '',
            packageValue: payData.packageValue ?? '',
            nonceStr: payData.nonceStr ?? '',
            timeStamp: payData.timestamp ?? '',
            sign: payData.sign ?? '',
          );
        } else {
          throw Exception(wxPayResult.msg ?? '微信支付订单创建失败');
        }
      }
      
      if (result) {
        // 购买成功后更新本地状态
        _updateVipStatus(package);
      } else {
        throw Exception('支付失败');
      }
    } catch (e) {
      _logger.e('支付处理失败: $e');
      rethrow; // 重新抛出异常，让上层处理
    }
  }

  /// 更新VIP状态
  void _updateVipStatus(VipPackageModel package) {
    // 这里应该更新用户的VIP状态
    // 例如保存到本地存储或更新用户管理器中的状态
    debugPrint('VIP购买成功: ${package.title}');
  }

  /// 启动自动轮播
  void _startAutoCarousel() {
    if (_isDisposed || !isPageVisible.value) {
      return;
    }
    
    // 启动顶部轮播图自动轮播
    _startTopCarousel();
    
    // 启动评论轮播图自动轮播
    _startCommentCarousel();
  }

  /// 启动顶部轮播图自动轮播
  void _startTopCarousel() {
    if (_isDisposed || !isPageVisible.value) {
      return;
    }
    
    _stopTopCarousel(); // 先停止现有定时器
    
    final bannerList = bannerData.value?.vipIconBanner ?? [];
    if (bannerList.length <= 1) {
      return; // 只有一个或没有项目时不需要自动轮播
    }
    
    _topCarouselTimer = Timer.periodic(_topCarouselInterval, (timer) {
      if (_isDisposed || !isPageVisible.value) {
        timer.cancel();
        return;
      }
      
      if (pageController.hasClients) {
        final nextIndex = (currentIndex.value + 1) % bannerList.length;
        pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  /// 启动评论轮播图自动轮播
  void _startCommentCarousel() {
    if (_isDisposed || !isPageVisible.value) {
      return;
    }
    
    _stopCommentCarousel(); // 先停止现有定时器
    
    final commentList = bannerData.value?.commentList ?? [];
    if (commentList.length <= 1) {
      return; // 只有一个或没有项目时不需要自动轮播
    }
    
    _commentCarouselTimer = Timer.periodic(_commentCarouselInterval, (timer) {
      if (_isDisposed || !isPageVisible.value) {
        timer.cancel();
        return;
      }
      
      if (commentScrollController.hasClients) {
        final nextIndex = (commentCurrentIndex.value + 1) % commentList.length;
        final itemWidth = 266.0 + 13.0; // 每个item宽度 + 间距
        final targetOffset = itemWidth * nextIndex;
        
        commentScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  /// 停止顶部轮播图自动轮播
  void _stopTopCarousel() {
    _topCarouselTimer?.cancel();
    _topCarouselTimer = null;
  }

  /// 停止评论轮播图自动轮播
  void _stopCommentCarousel() {
    _commentCarouselTimer?.cancel();
    _commentCarouselTimer = null;
  }

  /// 停止所有自动轮播
  void _stopAutoCarousel() {
    _stopTopCarousel();
    _stopCommentCarousel();
  }

  /// 重置顶部轮播图自动轮播定时器
  void _resetTopCarouselTimer() {
    if (_isDisposed || !isPageVisible.value) {
      return;
    }
    
    _startTopCarousel(); // 重新启动定时器
  }

  /// 重置评论轮播图自动轮播定时器
  void _resetCommentCarouselTimer() {
    if (_isDisposed || !isPageVisible.value) {
      return;
    }
    
    _startCommentCarousel(); // 重新启动定时器
  }

  /// 暂停自动轮播（页面不可见时调用）
  void pauseAutoCarousel() {
    _stopAutoCarousel();
  }

  /// 恢复自动轮播（页面可见时调用）
  void resumeAutoCarousel() {
    if (isPageVisible.value) {
      _startAutoCarousel();
    }
  }

  /// 获取套餐描述文本
  String getPriceDescription(int index) {
    switch (index) {
      case 0:
        return '适合短期体验用户';
      case 1:
        return '性价比之选，省¥39.8';
      case 2:
        return '最划算选择，省¥190.8';
      default:
        return '';
    }
  }

  /// 检查是否是推荐套餐
  bool isRecommendedPrice(int index) {
    return index == 2; // 年卡为推荐套餐
  }
}