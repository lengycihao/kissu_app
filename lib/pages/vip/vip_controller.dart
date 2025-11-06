import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/mine/mine_controller.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:logger/logger.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/models/vip_banner_model.dart';
import 'package:kissu_app/models/vip_package_model.dart';
import 'package:kissu_app/services/vip_service.dart';
import 'package:kissu_app/services/payment_service.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/widgets/dialogs/discount_bottom_sheet.dart';
import 'package:kissu_app/widgets/dialogs/vip_cancel_retention_dialog.dart';
import 'package:kissu_app/services/tracking_service.dart';

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
  
  // 主内容滚动控制器（用于埋点检测）
  late ScrollController mainScrollController;
  
  // 当前轮播图索引
  var currentIndex = 0.obs;
  
  // 当前评价轮播图索引
  var commentCurrentIndex = 0.obs;
  
  
  // 选中的价格索引
  var selectedPriceIndex = 0.obs; // 默认选中第一个套餐
  
  // 选中的支付方式 (0: 微信, 1: 支付宝)
  var selectedPaymentMethod = 0.obs; // 默认微信
  
  // 是否同意协议
  var agreementChecked = true.obs; // 默认勾选
  
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
  
  // 支付结果监听器
  StreamSubscription<Map<String, dynamic>>? _paymentResultSubscription;

  // 页面浏览埋点相关
  DateTime? _pageEnterTime;
  var scrollTimes = 0.obs;
  var hasScrolled = false.obs;
  String previousPageName = ''; // 上个页面名称
  String previousPageId = ''; // 上个页面ID
  bool isFromDialogPurchase = false; // 是否从弹窗入口支付
  bool isFromRetentionDialog = false; // 是否从挽留弹窗入口支付
  VipPackageModel? retentionDialogPackage; // 挽留弹窗选择的套餐

  @override
  void onInit() {
    super.onInit();
    
    // 记录进入时间
    _pageEnterTime = DateTime.now();
    
    // 初始化控制器
    pageController = PageController();
    commentScrollController = ScrollController();
    priceScrollController = ScrollController();
    mainScrollController = ScrollController();
    
    // 从路由参数获取上个页面信息
    final args = Get.arguments as Map<String, dynamic>?;
    previousPageName = args?['previousPageName'] ?? '未知页面';
    previousPageId = args?['previousPageId'] ?? 'unknown';
    
    // 设置支付结果监听
    _setupPaymentResultListener();
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
    
    // 添加支付状态监听（通过定时器检查状态变化）
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      
      // 检查支付状态，如果支付完成则重置UI状态
      if (!_paymentService.paymentInProgress && isPurchasing.value) {
        _logger.i('检测到支付状态重置，同步UI状态');
        isPurchasing.value = false;
      }
    });
    
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
    agreementChecked.value = true; // 默认勾选
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
    
    // 上报页面浏览埋点
    _trackPageView();
    
    // 标记页面为不可见状态
    isPageVisible.value = false;
    
    // 停止所有自动轮播
    _stopAutoCarousel();
    
    // 取消支付结果监听
    _paymentResultSubscription?.cancel();
    
    
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
    
    try {
      mainScrollController.dispose();
    } catch (e) {
      print('MainScrollController dispose失败: $e');
    }
    
    super.onClose();
  }

  /// 处理滚动事件
  bool handleScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta.abs() > 10) {
        if (!hasScrolled.value) {
          hasScrolled.value = true;
        }
        scrollTimes.value++;
      }
    }
    return false;
  }

  /// 上报页面浏览埋点
  Future<void> _trackPageView() async {
    if (_pageEnterTime == null) return;
    
    try {
      final duration = DateTime.now().difference(_pageEnterTime!);
      final seconds = duration.inSeconds;
      final stayDuration = '${seconds}s';
      
      // 获取会员状态
      final isVip = UserManager.isVip ? '开通' : '未开通';
      
      await TrackingService.trackMembershipPageView(
        stayDuration: stayDuration,
        canScroll: hasScrolled.value,
        scrollTimes: scrollTimes.value,
        previousName: previousPageName,
        isVip: isVip,
        previousId: previousPageId,
      );
      
      debugPrint('✅ 会员页面浏览埋点上报成功: 停留时长=$stayDuration, 是否滑动=${hasScrolled.value}, 滑动次数=${scrollTimes.value}, 上个页面=$previousPageName, 会员状态=$isVip');
    } catch (e) {
      debugPrint('❌ 会员页面浏览埋点上报失败: $e');
    }
  }

  /// 返回按钮点击（用于埋点）
  Future<void> onBackTap() async {
    // 显示挽留弹窗
    final shouldLeave = await _showRetentionDialog();
    
    if (shouldLeave) {
      // 上报返回按钮埋点
      await TrackingService.trackMembershipLeave();
      debugPrint('✅ 会员页面返回按钮埋点上报成功');
      
      Get.back();
    }
  }
  
  /// 显示挽留弹窗
  Future<bool> _showRetentionDialog() async {
    try {
      final context = Get.context;
      if (context == null) {
        debugPrint('❌ 无法获取Context，直接返回');
        return true;
      }
      
      // 使用封装好的弹窗
      final result = await VipCancelRetentionDialog.show(
        context: context,
        onUnlock: () {
          debugPrint('💫 用户点击"全部解锁"');
          _handleUnlockFromRetention();
        },
        onCancel: () {
          debugPrint('💫 用户点击"下次再说"');
          _trackRetentionDialogCancel();
        },
        barrierDismissible: true,
      );
      
      // result 为 true 表示点击了"全部解锁"，不返回
      // result 为 false 表示点击了"下次再说"，允许返回
      // result 为 null 表示点击背景关闭，不允许返回
      return result == false; // 只有点击"下次再说"才返回true
    } catch (e) {
      debugPrint('❌ 显示挽留弹窗失败: $e');
      return true; // 出错时允许返回
    }
  }
  
  /// 从挽留弹窗点击"全部解锁"
  Future<void> _handleUnlockFromRetention() async {
    debugPrint('💫 从挽留弹窗点击"全部解锁"，开始购买流程');
    
    // 检查是否正在购买
    if (isPurchasing.value) {
      debugPrint('💫 正在购买中，忽略重复点击');
      return;
    }
    
    // 检查是否有套餐
    if (vipPackages.isEmpty) {
      OKToastUtil.show('暂无可用套餐');
      return;
    }
    
    // 获取第一个套餐
    final firstPackage = vipPackages.first;
    debugPrint('💫 选择第一个套餐: ${firstPackage.title}');
    
    // 设置支付方式为微信
    selectedPaymentMethod.value = 0;
    debugPrint('💫 设置支付方式为微信');
    
    // 标记为从挽留弹窗入口支付
    isFromRetentionDialog = true;
    retentionDialogPackage = firstPackage;
    
    // 上报挽留弹窗埋点 - 点击"全部解锁"
    await _trackRetentionDialogUnlock(firstPackage, '点击支付');
    
    // 设置正在购买标志
    isPurchasing.value = true;
    
    try {
      // 上报埋点
      await _trackMembershipOpen(firstPackage, '点击支付');
      
      // 执行支付
      await _processPurchase(firstPackage);
      
    } catch (e) {
      debugPrint('❌ 从挽留弹窗购买失败: $e');
      // 错误提示已在_processPurchase中处理
    } finally {
      isPurchasing.value = false;
    }
  }

  /// 服务协议点击（用于埋点）
  Future<void> onServiceAgreementTap() async {
    // 上报服务协议点击埋点
    await TrackingService.trackMembershipServiceAgreement();
    debugPrint('✅ 会员服务协议点击埋点上报成功');
  }
  

  /// 加载VIP横幅数据
  void _loadVipBannerData() async {
    try {
      _logger.i('开始加载VIP横幅和评价数据...');
      
      // 调用真实的 /pay/iconBanner 接口
      final result = await _vipService.getVipIconBanner();
      
      if (result.isSuccess && result.data != null) {
        bannerData.value = result.data!;
        _logger.i('VIP页面数据加载完成，轮播图数量: ${bannerData.value?.vipIconBanner.length}, 评价数量: ${bannerData.value?.commentList.length}');
        
        // 启动自动轮播
        _startAutoCarousel();
      } else {
        _logger.e('VIP横幅数据加载失败: ${result.msg}');
        // 加载失败时使用默认的测试数据作为备用
        _loadFallbackData();
      }
    } catch (e) {
      _logger.e('VIP横幅数据加载异常: $e');
      // 出现异常时使用默认的测试数据作为备用
      _loadFallbackData();
    }
  }

  /// 加载备用数据（当API调用失败时使用）
  void _loadFallbackData() {
    try {
      _logger.i('使用备用数据...');
      final testData = {
        "comment_list": [
           
           
        ],
        "vip_icon_banner": [
           
        ]
      };
      
      bannerData.value = VipBannerModel.fromJson(testData);
      _logger.i('备用数据加载完成');
      
      // 启动自动轮播
      _startAutoCarousel();
    } catch (e) {
      _logger.e('备用数据加载也失败: $e');
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
      final package = vipPackages[index];
      
      // 先选中套餐
      selectedPriceIndex.value = index;
      debugPrint('🎯 价格选择成功: 新索引=$index, 套餐=${vipPackages[index].title}');
      _scrollToSelectedPrice(index);
      
      // 强制更新UI (对于使用GetBuilder的组件)
      update();
      
      // 然后检查是否有折扣，如果有则显示弹窗
      if (package.hasDiscount) {
        debugPrint('🎯 套餐有折扣，显示折扣弹窗: ${package.title}');
        _showDiscountDialog(package);
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

  /// 显示折扣底部弹窗
  void _showDiscountDialog(VipPackageModel package) {
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DiscountBottomSheet(
        package: package,
        onPayment: (int paymentMethod) {
          // 同步支付方式选择
          selectedPaymentMethod.value = paymentMethod;
          
          // 关闭弹窗
          Navigator.pop(context);
          
          // 执行购买（使用当前选中的套餐）
          _purchaseVipFromDialog();
        },
      ),
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
          
          // 检查第一个套餐是否有折扣，如果有则显示弹窗
          final firstPackage = vipPackages[0];
          if (firstPackage.hasDiscount) {
            // 延迟一点显示弹窗，确保页面已经渲染完成
            Future.delayed(const Duration(milliseconds: 500), () {
              if (!_isDisposed && isPageVisible.value) {
                debugPrint('🎯 默认套餐有折扣，显示折扣弹窗: ${firstPackage.title}');
                _showDiscountDialog(firstPackage);
              }
            });
          }
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

  /// 从弹窗购买VIP（不需要协议检查）
  void _purchaseVipFromDialog() async {
    debugPrint('💫 从弹窗支付按钮被点击，开始购买VIP流程');
    debugPrint('💫 当前是否正在购买: ${isPurchasing.value}');
    
    if (isPurchasing.value) {
      debugPrint('💫 正在购买中，忽略重复点击');
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
      
      // 标记为从弹窗入口支付（重置挽留弹窗标记）
      isFromDialogPurchase = true;
      isFromRetentionDialog = false;
      retentionDialogPackage = null;
      
      // 彻底检查并重置异常支付状态
      _paymentService.thoroughCheckAndResetPaymentState();
      
      // 获取选中的支付方式
      final paymentMethod = _getSelectedPaymentMethod();
      
      // 直接进入支付流程，不再显示确认对话框
      debugPrint('💫 开始处理支付，支付方式: $paymentMethod');
      
      // 确保支付状态清理
      _logger.i('💫 开始新的支付流程，清理之前的状态');
      
      // 处理购买过程
      await _processPurchase(package);
      
    } catch (e) {
      // 购买失败提示已在_processPurchase中处理
    } finally {
      isPurchasing.value = false;
    }
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
      
      // 标记为非弹窗入口支付（重置挽留弹窗标记）
      isFromDialogPurchase = false;
      isFromRetentionDialog = false;
      retentionDialogPackage = null;
      
      // 彻底检查并重置异常支付状态
      _paymentService.thoroughCheckAndResetPaymentState();
      
      // 获取选中的支付方式
      final paymentMethod = _getSelectedPaymentMethod();
      
      // 直接进入支付流程，不再显示确认对话框
      debugPrint('💫 开始处理支付，支付方式: $paymentMethod');
      
      // 确保支付状态清理
      _logger.i('💫 开始新的支付流程，清理之前的状态');
      
      // 处理购买过程
      await _processPurchase(package);
      
       
      
      // // 延迟后刷新我的页面并返回上一页
      // Future.delayed(const Duration(seconds: 1), () {
      //   _refreshMinePageAndReturn();
      // });
      
    } catch (e) {
      // 购买失败提示
      // CustomToast.show(
      //   Get.context!,
      //   '购买过程中出现错误，请重试',
      // );
    } finally {
      isPurchasing.value = false;
    }
  }

  
  /// 获取选中的支付方式
  String _getSelectedPaymentMethod() {
    switch (selectedPaymentMethod.value) {
      case 0:
        return '微信支付';
      case 1:
        return '支付宝支付';
      default:
        return '微信支付';
    }
  }
  
  /// 设置支付结果监听
  void _setupPaymentResultListener() {
    _paymentResultSubscription = _paymentService.listenToPaymentResult((result) {
      _logger.i('🎯 收到支付结果回调: $result');
      
      final success = result['success'] ?? false;
      final payType = result['payType'] ?? '';
      final message = result['message'] ?? '';
      
      if (success) {
        _logger.i('✅ 支付成功通知 - 类型: $payType');
        
        // 获取当前选中的套餐
        if (selectedPriceIndex.value >= 0 && selectedPriceIndex.value < vipPackages.length) {
          final package = vipPackages[selectedPriceIndex.value];
          
          // 显示成功提示
          OKToastUtil.show('支付成功');
          
          // 更新VIP状态
          _updateVipStatus(package);
          
          // 处理支付成功
          _handlePaymentSuccess(package);
        }
      } else {
        _logger.e('❌ 支付失败通知 - 类型: $payType, 原因: $message');
        
        // 重置购买状态
        isPurchasing.value = false;
        
        // 检查是否是用户取消
        if (message.contains('取消')) {
          _logger.i('用户取消了支付');
          // 上报支付取消埋点
          _handlePaymentCancel();
        } else {
          // 支付失败时，仍然检查一下VIP状态
          _checkVipStatusAfterFailure();
        }
      }
    });
  }
  
  /// 处理支付取消埋点
  Future<void> _handlePaymentCancel() async {
    try {
      _logger.i('开始处理支付取消埋点...');
      
      // 获取当前选中的套餐
      VipPackageModel? package;
      if (selectedPriceIndex.value >= 0 && selectedPriceIndex.value < vipPackages.length) {
        package = vipPackages[selectedPriceIndex.value];
      } else {
        // 如果没有选中套餐，可能是从挽留弹窗支付的，使用挽留弹窗套餐
        package = retentionDialogPackage ?? (vipPackages.isNotEmpty ? vipPackages.first : null);
      }
      
      if (package == null) {
        _logger.w('支付取消埋点：无法获取套餐信息');
        return;
      }
      
      // 判断支付入口并上报相应埋点
      if (isFromRetentionDialog && retentionDialogPackage != null) {
        // 从挽留弹窗入口支付取消
        await _trackRetentionDialogUnlock(retentionDialogPackage!, '支付取消');
        debugPrint('✅ 会员挽留弹窗支付取消埋点已上报');
        
        // 重置标记
        isFromRetentionDialog = false;
        retentionDialogPackage = null;
      } else if (isFromDialogPurchase) {
        // 从19元弹窗入口支付取消
        await _trackVipSale(package, '支付取消');
        debugPrint('✅ 19元弹窗支付取消埋点已上报');
        
        // 重置标记
        isFromDialogPurchase = false;
      } else {
        // 从普通会员页面支付取消
        await _trackMembershipOpen(package, '支付取消');
        debugPrint('✅ 会员页面支付取消埋点已上报');
      }
      
    } catch (e) {
      _logger.e('支付取消埋点处理异常: $e');
    }
  }

  /// 支付失败后检查VIP状态
  Future<void> _checkVipStatusAfterFailure() async {
    _logger.i('💡 支付失败，延迟检查VIP状态...');
    await Future.delayed(const Duration(seconds: 2));
    
    final refreshSuccess = await UserManager.refreshUserInfo();
    if (refreshSuccess) {
      final user = UserManager.currentUser;
      if (user?.vipEndTime != null && user!.vipEndTime! > 0) {
        final vipEndTime = DateTime.fromMillisecondsSinceEpoch(user.vipEndTime! * 1000);
        if (vipEndTime.isAfter(DateTime.now())) {
          _logger.i('🎉 检测到用户已是VIP，可能支付已成功');
          
          if (selectedPriceIndex.value >= 0 && selectedPriceIndex.value < vipPackages.length) {
            final package = vipPackages[selectedPriceIndex.value];
            OKToastUtil.show('支付成功');
            _updateVipStatus(package);
            _handlePaymentSuccess(package);
          }
        }
      }
    }
  }


  /// 处理购买流程
  Future<void> _processPurchase(VipPackageModel package) async {
    try {
      _logger.i('💫 开始处理购买流程，套餐: ${package.title}, 支付方式: ${selectedPaymentMethod.value}');
      bool result = false;
      
      if (selectedPaymentMethod.value == 0) {
        // 微信支付
        _logger.i('💫 开始创建微信支付订单');
        final wxPayResult = await _vipService.wxPay(vipPackageId: package.id);
        _logger.i('💫 微信支付订单创建结果: isSuccess=${wxPayResult.isSuccess}, msg=${wxPayResult.msg}');
        
        if (wxPayResult.isSuccess && wxPayResult.data != null) {
          // 解析微信支付参数
          final payData = wxPayResult.data!;
          _logger.i('💫 微信支付参数: appId=${payData.appId}, partnerId=${payData.partnerId}, prepayId=${payData.prepayId}');
          
          result = await _paymentService.payWithWechat(
            appId: payData.appId ?? '',
            partnerId: payData.partnerId ?? '',
            prepayId: payData.prepayId ?? '',
            packageValue: payData.packageValue ?? '',
            nonceStr: payData.nonceStr ?? '',
            timeStamp: payData.timestamp ?? '',
            sign: payData.sign ?? '',
          );
          _logger.i('💫 微信支付SDK调用完成，结果: $result');
        } else {
          _logger.e('💫 微信支付订单创建失败: ${wxPayResult.msg}');
          throw Exception(wxPayResult.msg ?? '微信支付订单创建失败');
        }
      } else {
        // 支付宝支付
        _logger.i('💫 开始创建支付宝支付订单');
        final aliPayResult = await _vipService.aliPay(vipPackageId: package.id);
        _logger.i('💫 支付宝订单创建结果: isSuccess=${aliPayResult.isSuccess}, msg=${aliPayResult.msg}');
        
        if (aliPayResult.isSuccess && aliPayResult.data != null) {
          _logger.i('💫 支付宝订单创建成功，orderString长度: ${aliPayResult.data!.orderString?.length ?? 0}');
          _logger.i('💫 支付宝订单字符串前100字符: ${aliPayResult.data!.orderString?.substring(0, (aliPayResult.data!.orderString?.length ?? 0) > 100 ? 100 : (aliPayResult.data!.orderString?.length ?? 0))}...');
          
          // 调用支付宝支付
          _logger.i('💫 开始调用支付宝支付SDK');
          result = await _paymentService.payWithAlipay(
            orderInfo: aliPayResult.data!.orderString ?? '',
          );
          _logger.i('💫 支付宝支付SDK调用完成，结果: $result');
        } else {
          _logger.e('💫 支付宝订单创建失败: ${aliPayResult.msg}');
          throw Exception(aliPayResult.msg ?? '支付宝支付订单创建失败');
        }
      }
      
      _logger.i('💫 支付SDK调用结果: $result');
      
      if (result) {
        _logger.i('💫 成功唤起支付应用，等待支付结果回调...');
        // 支付结果将通过监听器处理，这里不需要做额外处理
      } else {
        _logger.e('💫 唤起支付应用失败');
        // 支付服务已经显示了错误信息，这里不再重复
      }
    } catch (e) {
      _logger.e('💫 支付处理失败: $e');
      _logger.e('💫 异常类型: ${e.runtimeType}');
      _logger.e('💫 异常堆栈: ${e.toString()}');
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
      
      // 判断是否从挽留弹窗入口支付
      if (isFromRetentionDialog && retentionDialogPackage != null) {
        // 上报挽留弹窗支付成功埋点
        await _trackRetentionDialogUnlock(retentionDialogPackage!, '支付成功');
        debugPrint('✅ 会员挽留弹窗支付成功埋点已上报');
        
        // 重置标记
        isFromRetentionDialog = false;
        retentionDialogPackage = null;
      }
      // 判断是否从19元弹窗入口支付
      else if (isFromDialogPurchase) {
        // 上报19元弹窗埋点
        await _trackVipSale(package, '支付成功');
        debugPrint('✅ 19元弹窗支付埋点已上报');
      } else {
        // 上报开通会员埋点
        await _trackMembershipOpen(package, '支付成功');
      }
      
      // 显示支付成功提示
      // OKToastUtil.show('支付成功');

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

  /// 上报开通会员埋点
  Future<void> _trackMembershipOpen(VipPackageModel package, String payResult) async {
    try {
      // 获取支付方式
      final payType = selectedPaymentMethod.value == 0 ? '微信' : '支付宝';
      
      // 判断是否是续费
      final isRenew = UserManager.isVip ? '是续费' : '不是续费';
      
      await TrackingService.trackMembershipOpen(
        vipPrice: package.vipPrice,
        vipName: package.title,
        payType: payType,
        isRenew: isRenew,
        previousName: previousPageName,
        payResult: payResult,
      );
      
      debugPrint('✅ 开通会员埋点上报成功: 套餐=${package.title}, 金额=${package.vipPrice}, 支付方式=$payType, 续费=$isRenew, 结果=$payResult');
    } catch (e) {
      debugPrint('❌ 开通会员埋点上报失败: $e');
    }
  }

  /// 上报19元弹窗支付埋点
  Future<void> _trackVipSale(VipPackageModel package, String payResult) async {
    try {
      // 获取支付方式
      final payType = selectedPaymentMethod.value == 0 ? '微信' : '支付宝';
      
      // 判断是否是续费
      final isRenew = UserManager.isVip ? '是续费' : '不是续费';
      
      await TrackingService.trackVipSale(
        vipPrice: package.vipPrice,
        vipName: package.title,
        payType: payType,
        isRenew: isRenew,
        previousName: previousPageName,
        payResult: payResult,
      );
      
      debugPrint('✅ 19元弹窗支付埋点上报成功: 套餐=${package.title}, 金额=${package.vipPrice}, 支付方式=$payType, 续费=$isRenew, 上个页面=$previousPageName, 结果=$payResult');
    } catch (e) {
      debugPrint('❌ 19元弹窗支付埋点上报失败: $e');
    }
  }

  /// 上报挽留弹窗埋点 - 点击"全部解锁"
  Future<void> _trackRetentionDialogUnlock(VipPackageModel package, String payResult) async {
    try {
      // 获取支付方式
      final payType = selectedPaymentMethod.value == 0 ? '微信' : '支付宝';
      
      // 判断是否是续费
      final isRenew = UserManager.isVip ? '是续费' : '不是续费';
      
      await TrackingService.trackVipRetentionPopup(
        buttonName: '全部解锁',
        vipPrice: package.vipPrice,
        vipName: package.title,
        payType: payType,
        isRenew: isRenew,
        previousName: previousPageName,
        payResult: payResult,
      );
      
      debugPrint('✅ 会员挽留弹窗埋点上报成功: 按钮=全部解锁, 套餐=${package.title}, 金额=${package.vipPrice}, 支付方式=$payType, 续费=$isRenew, 上个页面=$previousPageName, 结果=$payResult');
    } catch (e) {
      debugPrint('❌ 会员挽留弹窗埋点上报失败: $e');
    }
  }

  /// 上报挽留弹窗埋点 - 点击"下次再说"
  Future<void> _trackRetentionDialogCancel() async {
    try {
      // 获取当前选中的套餐，如果没有则使用第一个
      VipPackageModel? package;
      if (selectedPriceIndex.value >= 0 && selectedPriceIndex.value < vipPackages.length) {
        package = vipPackages[selectedPriceIndex.value];
      } else if (vipPackages.isNotEmpty) {
        package = vipPackages.first;
      }
      
      // 如果没有套餐数据，使用默认值
      final vipPrice = package?.vipPrice ?? '0.00';
      final vipName = package?.title ?? '未知套餐';
      
      // 获取支付方式
      final payType = selectedPaymentMethod.value == 0 ? '微信' : '支付宝';
      
      // 判断是否是续费
      final isRenew = UserManager.isVip ? '是续费' : '不是续费';
      
      await TrackingService.trackVipRetentionPopup(
        buttonName: '下次再说',
        vipPrice: vipPrice,
        vipName: vipName,
        payType: payType,
        isRenew: isRenew,
        previousName: previousPageName,
        payResult: '下次再说',
      );
      
      debugPrint('✅ 会员挽留弹窗埋点上报成功: 按钮=下次再说, 套餐=$vipName, 金额=$vipPrice, 支付方式=$payType, 续费=$isRenew, 上个页面=$previousPageName');
    } catch (e) {
      debugPrint('❌ 会员挽留弹窗埋点上报失败: $e');
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