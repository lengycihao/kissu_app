import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:logger/logger.dart';
import 'package:kissu_app/models/vip_banner_model.dart';
import 'package:kissu_app/models/vip_package_model.dart';
import 'package:kissu_app/services/vip_service.dart';
import 'package:kissu_app/services/payment_service.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/pages/mine/mine_controller.dart';
import 'package:kissu_app/pages/home/home_controller.dart';

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
  
  // 使用Flutter视频播放器（已移除原生播放器支持）
  
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
    
    // 只在首次初始化时重置状态
    if (!_isInitialized) {
      _resetControllerState();
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

  /// 重置控制器状态
  void _resetControllerState() {
    _logger.i('重置控制器状态');
    
    // 重置状态标记
    _isInitialized = false;
    _isDisposed = false;
    
    // 清理可能存在的定时器
    _stopAutoCarousel();
    
    
    // 重置其他状态
    currentIndex.value = 0;
    commentCurrentIndex.value = 0;
    selectedPriceIndex.value = 0;
    selectedPaymentMethod.value = 0;
    agreementChecked.value = false;
    isPurchasing.value = false;
    isLoadingPackages.value = false;
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
  

  /// 加载VIP横幅数据
  void _loadVipBannerData() async {
    try {
      // 模拟接口调用，实际应该调用 /pay/iconBanner 接口
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 使用测试数据 - PAG动画暂时移除
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
            "vip_icon_video": "",
            "vip_icon_banner": "",
            "vip_icon": "https://kissustatic.yuluojishu.com/uploads/2025/08/22/092f1c38cdad6b28a1feba13d3f8c4d5.png",
            "vip_icon_select": "https://kissustatic.yuluojishu.com/uploads/2025/08/22/7d71d319498be3d2966b922e2ac7c00d.png",
            "vip_pag_asset": "pag/kissu_vip_top1.pag"
          },
          {
            "vip_icon_video": "",
            "vip_icon_banner": "",
            "vip_icon": "https://kissustatic.yuluojishu.com/uploads/2025/08/22/0a7781998dd34375e9e337543904bf12.png",
            "vip_icon_select": "https://kissustatic.yuluojishu.com/uploads/2025/08/31/ee2e55f486245a32f1dd356fb409e863.png",
            "vip_pag_asset": "pag/kissu_vip_top2.pag"
          },
          {
            "vip_icon_video": "",
            "vip_icon_banner": "",
            "vip_icon": "https://kissustatic.yuluojishu.com/uploads/2025/08/22/47ec5e48be2e22f5d8886b8243518eb2.png",
            "vip_icon_select": "https://kissustatic.yuluojishu.com/uploads/2025/08/22/57b7079d5f3a1c3d13670b313311fa87.png",
            "vip_pag_asset": "pag/kissu_vip_top3.pag"
          },
          {
            "vip_icon_video": "",
            "vip_icon_banner": "",
            "vip_icon": "https://kissustatic.yuluojishu.com/uploads/2025/08/22/f7fe0d2416bf219d16e05ddcf752ee5d.png",
            "vip_icon_select": "https://kissustatic.yuluojishu.com/uploads/2025/08/22/07c2af127a33d18ddc72e0908bf6fbbb.png",
            "vip_pag_asset": "pag/kissu_vip_top4.pag"
          }
        ]
      };
      
      bannerData.value = VipBannerModel.fromJson(testData);
      print('VIP页面数据加载完成，轮播图数量: ${bannerData.value?.vipIconBanner.length}');
      print('PAG动画暂时移除，使用图片轮播');
      
      // 启动自动轮播
      _startAutoCarousel();
    } catch (e) {
      // 静默处理加载错误
    }
  }
  
  
  /// 轮播图页面改变
  void onPageChanged(int index) {
    currentIndex.value = index;
    
    // 重置顶部轮播图自动轮播定时器
    _resetTopCarouselTimer();
  }
  
  
  /// 选择标签（图片按钮）
  void selectTab(int index) {
    currentIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
  
  /// 显示协议警告提示
  void showAgreementWarning() {
    debugPrint('💫 协议未勾选，显示提示');
    CustomToast.show(
      Get.context!,
      '请先同意《会员服务协议》',
    );
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
        CustomToast.show(Get.context!, result.msg ?? '加载套餐数据失败', );
      }
    } catch (e) {
      CustomToast.show(Get.context!, '加载套餐数据失败: $e', );
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
    
    // 协议检查已在UI层面处理，这里可以省略
    // 但为了安全起见，仍然保留检查
    if (!agreementChecked.value) {
      debugPrint('💫 协议未勾选，显示提示');
      showAgreementWarning();
      return;
    }

    // 检查是否选择了套餐
    final package = selectedPackage;
    if (package == null) {
      CustomToast.show(
        Get.context!,
        '请选择一个套餐',
      );
      return;
    }
    
    try {
      isPurchasing.value = true;
      
      // 获取选中的支付方式
      final paymentMethod = _getSelectedPaymentMethod();
      
      // 直接进入支付流程，不再显示确认对话框
      debugPrint('💫 开始处理支付，支付方式: $paymentMethod');
      
      // 处理购买过程
      await _processPurchase(package);
      
       
      
      // // 延迟后刷新我的页面并返回上一页
      // Future.delayed(const Duration(seconds: 1), () {
      //   _refreshMinePageAndReturn();
      // });
      
    } catch (e) {
      // 购买失败提示
      CustomToast.show(
        Get.context!,
        '购买过程中出现错误，请重试',
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
        
        // 支付成功后的UI处理
        _handlePaymentSuccess(package);
      } else {
        // throw Exception('支付失败');
        OKToastUtil.show("支付失败");
        throw Exception('支付失败');
      }
    } catch (e) {
      // _logger.e('支付处理失败: $e');
      OKToastUtil.show("支付失败");
      rethrow; // 重新抛出异常，让上层处理
    }
  }

  /// 更新VIP状态
  void _updateVipStatus(VipPackageModel package) {
    // 这里应该更新用户的VIP状态
    // 例如保存到本地存储或更新用户管理器中的状态
    debugPrint('VIP购买成功: ${package.title}');
  }
  
  /// 支付成功后的处理
  Future<void> _handlePaymentSuccess(VipPackageModel package) async {
    try {
      _logger.i('支付成功，开始处理后续操作...');
      
      // 显示支付成功提示
      OKToastUtil.show('支付成功');

      // 等待用户信息刷新完成（支付服务中已经处理）
      // 这里稍等片刻，让支付服务的刷新操作完成
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 刷新页面数据并返回上一页
      await _refreshMinePageAndReturn();
      
    } catch (e) {
      _logger.e('支付成功后处理异常: $e');
      // 即使出现异常，也要尝试返回上一页
      Get.back();
    }
  }
  
  /// 刷新我的页面并返回上一页
  Future<void> _refreshMinePageAndReturn() async {
    try {
      _logger.i('开始刷新页面数据...');
      
      // 刷新我的页面数据
      if (Get.isRegistered<MineController>()) {
        final mineController = Get.find<MineController>();
        await mineController.refreshUserInfo();
        _logger.i('我的页面数据已刷新');
      }
      
      // 刷新首页数据（如果首页控制器存在）
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.loadUserInfo();
        _logger.i('首页数据已刷新');
      }
      
      // 返回上一页
      Get.back();
      _logger.i('已返回上一页');
    } catch (e) {
      _logger.e('刷新页面数据失败: $e');
      // 即使刷新失败也要返回上一页
      Get.back();
    }
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