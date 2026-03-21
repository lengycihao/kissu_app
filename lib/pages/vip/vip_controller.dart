import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/pages/mine/mine_controller.dart';
import 'package:kissu_app/services/analytics/analytics_page_ids.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/utils/source_page_utils.dart';
import 'package:logger/logger.dart';
import 'package:kissu_app/models/vip_banner_model.dart';
import 'package:kissu_app/models/vip_package_model.dart';
import 'package:kissu_app/services/vip_service.dart';
import 'package:kissu_app/services/payment_service.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/widgets/dialogs/discount_bottom_sheet.dart';
import 'package:kissu_app/widgets/dialogs/vip_cancel_retention_dialog.dart';
import 'package:kissu_app/widgets/dialogs/vip_open_success_dialog.dart';
import 'package:kissu_app/services/analytics/analytics_manager.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';
import 'package:kissu_app/services/analytics/analytics_params.dart';

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

  // 会员状态（响应式，用于更新UI）
  var isVipStatus = false.obs;

  // 是否已经初始化过
  var _isInitialized = false;

  // 用于防止重复dispose的标志
  var _isDisposed = false;

  // 使用Flutter视频播放器（已移除原生播放器支持）

  // 自动轮播定时器
  Timer? _topCarouselTimer;
  Timer? _commentCarouselTimer;
  Timer? _lifetimeCountdownTimer;
  final lifetimeActivityDesc = ''.obs;
  final lifetimeActivitySeconds = 0.obs;
  
  // 评论轮播初始化标志，防止jumpTo触发无限递归
  bool _isInitializingCommentCarousel = false;

  // 自动轮播配置
  static const Duration _topCarouselInterval = Duration(seconds: 2);
  static const Duration _commentCarouselInterval = Duration(seconds: 3);

  // 支付结果监听器
  StreamSubscription<Map<String, dynamic>>? _paymentResultSubscription;

  // 埋点相关
  int? _pageEnterTime;
  int _exitType = ExitTypeValue.back;
  bool _hasTrackedExit = false; // 是否已上报离开埋点
  VoidCallback? onNavigateToNextPage;
  int _pageScrollNum = 0;
  int? _payStartTime; // 支付开始时间（十位时间戳）
  SourcePageUtilsCaller? _sourcePage; // 来源页
  String? _sourceEvent; // 来源事件ID
  int? _isDiscount; // 是否获取折扣套餐（1=是）

  @override
  void onInit() {
    super.onInit();

    // 埋点：记录页面进入时间（十位时间戳）
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // 注册页面离开回调
    onNavigateToNextPage = () {
      _trackPageExit(ExitTypeValue.nextPage);
    };

    // 初始化控制器
    pageController = PageController();
    commentScrollController = ScrollController();
    priceScrollController = ScrollController();
    mainScrollController = ScrollController();

    // 添加滑动监听器用于统计滑动次数
    mainScrollController.addListener(_onScroll);

    // 获取传入的参数
    final arguments = Get.arguments as Map<String, dynamic>?;
    _sourcePage = arguments?['source_page'] as SourcePageUtilsCaller?;
    _sourceEvent = arguments?['source_event'] as String?;
    _isDiscount = arguments?['is_discount'] as int?;
    final defaultVipType = arguments?['defaultVipType'] as int?;
    if (defaultVipType != null) {
      debugPrint('📦 VIP页面接收到参数: defaultVipType=$defaultVipType');
    }
    if (_isDiscount != null) {
      debugPrint('📦 VIP页面接收到参数: is_discount=$_isDiscount');
    }

    // 设置支付结果监听
    _setupPaymentResultListener();
  }

  /// 根据 caller 获取来源页面ID
  String? _getSourcePageFromCaller() {
    if (_sourcePage == null) return PageSourceIds.home;

    switch (_sourcePage!) {
      case SourcePageUtilsCaller.home:
        return PageSourceIds.home;
      case SourcePageUtilsCaller.mine:
        return PageSourceIds.myPage;
      case SourcePageUtilsCaller.loveInfo:
        return PageSourceIds.editProfile; // 恋爱信息页面归类到编辑资料
      case SourcePageUtilsCaller.track:
        return PageSourceIds.track;
      case SourcePageUtilsCaller.location:
        return PageSourceIds.location;
      case SourcePageUtilsCaller.usageReport:
        return PageSourceIds.sensitiveRecords; // 用机记录（敏感操作）
      case SourcePageUtilsCaller.deviceUsage:
        return PageSourceIds.phoneHistory; // 用机记录页面
      case SourcePageUtilsCaller.chat:
        return PageSourceIds.chat; // 聊天页面
      case SourcePageUtilsCaller.bind:
        return PageSourceIds.bind; // 绑定页面
      case SourcePageUtilsCaller.changeLogo:
        return PageSourceIds.changeLogo; // 更换Logo页面
        case SourcePageUtilsCaller.unbindPage:
        return PageSourceIds.unbindPage; // 更换Logo页面
    }
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

    // 初始化会员状态
    isVipStatus.value = UserManager.isVip;

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
    _stopLifetimeCountdown();

    // 重置其他状态
    currentIndex.value = 0;
    commentCurrentIndex.value = 0;
    selectedPriceIndex.value = 0;
    selectedPaymentMethod.value = 0;
    agreementChecked.value = true; // 默认勾选
    isPurchasing.value = false;
    isLoadingPackages.value = false;
    lifetimeActivityDesc.value = '';
    lifetimeActivitySeconds.value = 0;
  }

  /// 滑动监听器，用于统计滑动次数
  double _lastScrollPosition = 0;
  void _onScroll() {
    if (mainScrollController.hasClients) {
      final currentPosition = mainScrollController.position.pixels;
      // 只统计向下滑动，且滑动距离超过50px
      if (currentPosition > _lastScrollPosition &&
          (currentPosition - _lastScrollPosition) > 50) {
        _pageScrollNum++;
        _lastScrollPosition = currentPosition;
      }
    }
  }

  /// 上报页面离开埋点
  void _trackPageExit(int exitType) {
    if (_hasTrackedExit || _pageEnterTime == null) return;
    _hasTrackedExit = true;
    
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final duration = currentTime - _pageEnterTime!;
    
    AnalyticsManager.instance.trackPageView(
      pageId: MembershipEvents.pageId,
      eventId: MembershipEvents.page,
      enterTime: _pageEnterTime!,
      duration: duration,
      sourcePage: _getSourcePageFromCaller(),
      sourceEvent: _sourceEvent,
      exitType: exitType,
      params: {AnalyticsParams.pageScrollNum: _pageScrollNum},
    );
    
    // 如果是进入下一页，立即重置状态，为从下一页返回后的埋点做准备
    if (exitType == ExitTypeValue.nextPage) {
      _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _hasTrackedExit = false;
      _exitType = ExitTypeValue.back;
    }
  }
  
  /// 应用切换到后台
  void onAppPaused() {
    _exitType = ExitTypeValue.toBackground;
    _trackPageExit(ExitTypeValue.toBackground);
  }
  
  /// 应用从后台返回
  void onAppResumed() {
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _hasTrackedExit = false;
    _exitType = ExitTypeValue.back;
  }
  
  @override
  void onClose() {
    // _logger.i('📦 VipController onClose 被调用');

    // 埋点：记录页面离开事件（返回）
    _trackPageExit(_exitType);

    // 设置销毁标志
    _isDisposed = true;

    // 停止轮播
    _stopAutoCarousel();
    _stopLifetimeCountdown();

    // 取消支付结果监听
    _paymentResultSubscription?.cancel();

    // 销毁页面控制器
    try {
      pageController.dispose();
    } catch (e) {
      logError('PageController dispose失败: $e');
    }

    try {
      commentScrollController.dispose();
    } catch (e) {
      logError('CommentScrollController dispose失败: $e');
    }

    try {
      priceScrollController.dispose();
    } catch (e) {
      logError('PriceScrollController dispose失败: $e');
    }

    try {
      mainScrollController.dispose();
    } catch (e) {
      logError('MainScrollController dispose失败: $e');
    }

    super.onClose();
  }

  /// 返回按钮点击（用于埋点）
  Future<void> onBackTap() async {
    // 显示挽留弹窗
    final shouldLeave = await _showRetentionDialog();

    if (shouldLeave) {
      Get.back();
    }
  }

  /// 显示挽留弹窗
  Future<bool> _showRetentionDialog() async {
    try {
      // 如果用户已经是VIP，直接返回，不展示挽留弹窗
      if (UserManager.isVip) {
         return true;
      }

      final context = Get.context;
      if (context == null) {
        logError('❌ 无法获取Context，直接返回');
        return true;
      }

      // 使用封装好的弹窗
      final result = await VipCancelRetentionDialog.show(
        context: context,
        onUnlock: () {
           _handleUnlockFromRetention();
        },
        onCancel: () {},
        barrierDismissible: true,
      );

      // result 为 true 表示点击了"全部解锁"，不返回
      // result 为 false 表示点击了"下次再说"，允许返回
      // result 为 null 表示点击背景关闭，不允许返回
      return result == false; // 只有点击"下次再说"才返回true
    } catch (e) {
      logError('❌ 显示挽留弹窗失败: $e');
      return true; // 出错时允许返回
    }
  }

  /// 从挽留弹窗点击"全部解锁"
  Future<void> _handleUnlockFromRetention() async {
    debugPrint('💫 从挽留弹窗点击"全部解锁"，开始购买流程');

    // 检查是否正在购买
    if (isPurchasing.value) {
       return;
    }

    // 检查是否有套餐
    if (vipPackages.isEmpty) {
      OKToastUtil.show('暂无可用套餐');
      return;
    }

    // 使用当前选中的套餐（而不是固定的默认套餐）
    final currentPackage = selectedPackage;
    if (currentPackage == null) {
      OKToastUtil.show('请先选择套餐');
      return;
    }
 
    // 设置支付方式为微信
    selectedPaymentMethod.value = 0;
 
    // 设置正在购买标志
    isPurchasing.value = true;

    try {
      // 执行支付
      await _processPurchase(currentPackage);
    } catch (e) {
      logError('❌ 从挽留弹窗购买失败: $e');
      // 错误提示已在_processPurchase中处理
    } finally {
      isPurchasing.value = false;
    }
  }

  /// 加载VIP横幅数据
  void _loadVipBannerData() async {
    try {
 
      // 调用真实的 /pay/iconBanner 接口
      final result = await _vipService.getVipIconBanner();

      if (result.isSuccess && result.data != null) {
        bannerData.value = result.data!;
        

        // 启动自动轮播
        _startAutoCarousel();
      } else {
        logError('VIP横幅数据加载失败: ${result.msg}');
        // 加载失败时使用默认的测试数据作为备用
        _loadFallbackData();
      }
    } catch (e) {
      logError('VIP横幅数据加载异常: $e');
      // 出现异常时使用默认的测试数据作为备用
      _loadFallbackData();
    }
  }

  /// 加载备用数据（当API调用失败时使用）
  void _loadFallbackData() {
    try {
       final testData = {
        "desc": "想TA就立刻知道TA在哪儿",
        "comment_list": [
          {
            "date": "11月13日",
            "nickname": "嘟噜噜",
            "content": "让恋爱更有仪式感的小工具，我们都超爱！已经安利给身边所有情侣朋友了！",
            "avatar":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/5c2f222276748148038a2ada2d18c5d7.png",
            "vip_icon":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/4cddff093726fd1219fe2dc378a3c2a5.png",
            "star_image":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/e94205d837c5e5c9801caefe7b5e962b.png",
          },
          {
            "date": "11月13日",
            "nickname": "铁锤妹妹",
            "content": "再也不用因为失联而胡思乱想了。看他忙碌的记录就知道他安全，心里特别踏实",
            "avatar":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/93b9b4885c2371fee01ad3ef1159e06f.png",
            "vip_icon":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/4cddff093726fd1219fe2dc378a3c2a5.png",
            "star_image":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/e94205d837c5e5c9801caefe7b5e962b.png",
          },
          {
            "date": "11月13日",
            "nickname": "我爱吃毛豆",
            "content": "哇塞！这个软件太好用了，好有安全感，太爱了！！！！！",
            "avatar":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/3175b598716e580b17649bc8632d4473.png",
            "vip_icon":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/4cddff093726fd1219fe2dc378a3c2a5.png",
            "star_image":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/e94205d837c5e5c9801caefe7b5e962b.png",
          },
          {
            "date": "11月13日",
            "nickname": "再也不熬夜",
            "content": "看着我们两颗紧挨着的小头像，哪怕在各自上班，也感觉心是在一起的。",
            "avatar":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/bde98c4782e7dfd1297fbbaab5724ca6.png",
            "vip_icon":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/6141af551b5c8fd2bfe2dbcc4a660f7e.png",
            "star_image":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/e94205d837c5e5c9801caefe7b5e962b.png",
          },
          {
            "date": "11月13日",
            "nickname": "小羊咩咩",
            "content": "爱无需多说。这份随时可知彼此安好的默契，就足以让心里暖暖的。",
            "avatar":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/bde98c4782e7dfd1297fbbaab5724ca6.png",
            "vip_icon":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/8006a24d9aa8d4b63360e76f2288b540.png",
            "star_image":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/e94205d837c5e5c9801caefe7b5e962b.png",
          },
        ],
        "vip_icon_banner": [
          {
            "vip_icon_video": "",
            "vip_icon_banner":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/419caafc9f8a2e9618ffd3056c95aa4b.png",
            "vip_icon_banner_desc": "想TA就立刻知道TA在哪儿",
            "vip_icon":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/c7be636aa438b45bdbe8fd1e85d4ac43.png",
            "vip_icon_select":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/948fedaaa5354bcd29c84817ec004fd5.png",
          },
          {
            "vip_icon_video": "",
            "vip_icon_banner":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/bbf0a150cce5145422cf1395d7e591d6.png",
            "vip_icon_banner_desc": "自动通知报备黑科技",
            "vip_icon":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/e8b72050147d870fd2b3a2adbea23874.png",
            "vip_icon_select":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/9b795e45a318bcb2e56dfa1952cf72bf.png",
          },
          {
            "vip_icon_video": "",
            "vip_icon_banner":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/484527c3db8be369f4e3bff91c1661cb.png",
            "vip_icon_banner_desc": "全自动记录轨迹行程",
            "vip_icon":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/4ceb463778db186f2071341aa0a837ba.png",
            "vip_icon_select":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/2e79a0578eca0f066712a933b1224f2a.png",
          },
          {
            "vip_icon_video": "",
            "vip_icon_banner":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/6728a3051c38ac49ebea71c537c16b47.png",
            "vip_icon_banner_desc": "一键get手机使用全记录",
            "vip_icon":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/b14b155e2f400adc8b7d2e21ed3cf6c4.png",
            "vip_icon_select":
                "https://kissustatic.yuluojishu.com/uploads/2025/11/12/c2dc929b01c15814e530e355e19a71fe.png",
          },
        ],
      };

      bannerData.value = VipBannerModel.fromJson(testData);
 
      // 启动自动轮播
      _startAutoCarousel();
    } catch (e) {
      _logger.e('备用数据加载也失败: $e');
    }
  }

  void _updateLifetimeActivity(VipPackageModel? lifetimePlan) {
    lifetimeActivityDesc.value = lifetimePlan?.activityDesc ?? '';
    int duration = lifetimePlan?.activityRemainDuration ?? 0;
    if (duration > 1000000000) {
      duration = (duration ~/ 1000);
    }
    lifetimeActivitySeconds.value = duration > 0 ? duration : 0;

    _stopLifetimeCountdown();

    if (lifetimePlan == null) {
      return;
    }

    if (duration <= 0) {
      return;
    }

    _lifetimeCountdownTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      if (lifetimeActivitySeconds.value <= 1) {
        timer.cancel();
        lifetimeActivitySeconds.value = 0;
      } else {
        lifetimeActivitySeconds.value--;
      }
    });
  }

  void _stopLifetimeCountdown() {
    _lifetimeCountdownTimer?.cancel();
    _lifetimeCountdownTimer = null;
  }

  String get lifetimeCountdownText {
    if (lifetimeActivitySeconds.value <= 0) {
      return '';
    }
    return _formatCountdown(lifetimeActivitySeconds.value);
  }

  String _formatCountdown(int seconds) {
    final clamped = seconds < 0 ? 0 : seconds;
    final hours = (clamped ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((clamped % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (clamped % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
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
    // 如果正在初始化，跳过处理，防止无限递归
    if (_isInitializingCommentCarousel) {
      return;
    }
    
    if (commentScrollController.hasClients) {
      final scrollOffset = commentScrollController.offset;
      final itemWidth = 266.0 + 13.0; // 每个item宽度 + 间距
      final commentList = bannerData.value?.commentList ?? [];
      if (commentList.isEmpty) return;
      
      // 计算当前显示的评论索引（通过取模运算映射到实际索引）
      final virtualIndex = (scrollOffset / itemWidth).round();
      commentCurrentIndex.value = virtualIndex % commentList.length;

      // 重置评论轮播图自动轮播定时器
      _resetCommentCarouselTimer();
    }
  }

  /// 选择价格
  void selectPrice(int index) {
     

    if (index >= 0 && index < vipPackages.length) {
      final package = vipPackages[index];
      int vipType;
    if (package.isForever) {
      vipType = 3; // 永久会员
    } else if (package.type == 3) {
      vipType = 2; // 年度会员
    } else {
      vipType = 1; // 月度会员
    }
      // 埋点：记录会员套餐点击
      AnalyticsHelper.trackMembershipTypeClick(clickStatus: vipType);

      // 先选中套餐
      selectedPriceIndex.value = index;
       _scrollToSelectedPrice(index);

      // 强制更新UI (对于使用GetBuilder的组件)
      update();

      // 然后检查是否有折扣，如果有则显示弹窗
      if (package.hasDiscount) {
         _showDiscountDialog(package);
      }
    } else {
      logError(
        '🎯 价格选择失败: 索引超出范围 index=$index, length=${vipPackages.length}',
      );
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
     agreementChecked.value = !agreementChecked.value;
   }

  /// 显示协议警告提示
  void showAgreementWarning() {
     CustomToast.show(Get.context!, '请先同意《会员服务协议》');
  }

  /// 显示折扣底部弹窗
  void _showDiscountDialog(VipPackageModel package) {
    // 埋点：19元弹窗曝光（在显示弹窗时调用，确保只触发一次）
    AnalyticsHelper.trackPopup19DialogExposure(
      pageEnterTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    
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
      final result = await _vipService.getVipPackageList(isDiscount: _isDiscount);
      if (result.isSuccess && result.data != null) {
        vipPackages.value = result.data!;
        VipPackageModel? lifetimePlan;
        for (final package in vipPackages) {
          if (package.isForever) {
            lifetimePlan = package;
            break;
          }
        }
        _updateLifetimeActivity(lifetimePlan);
        // 如果有数据，根据传入参数或 isChecked 字段选中套餐
        if (vipPackages.isNotEmpty) {
          int defaultIndex = 0;

          // 获取传入的参数
          final arguments = Get.arguments as Map<String, dynamic>?;
          final defaultVipType = arguments?['defaultVipType'] as int?;

          if (defaultVipType != null) {
            // 如果传入了 defaultVipType，优先根据 type 字段选择
             for (int i = 0; i < vipPackages.length; i++) {
              if (vipPackages[i].type == defaultVipType) {
                defaultIndex = i;
                 break;
              }
            }
          } else {
            // 否则根据 isChecked 字段选择（1=选中，0=未选中）
             for (int i = 0; i < vipPackages.length; i++) {
              if (vipPackages[i].isChecked == 1) {
                defaultIndex = i;
                 break;
              }
            }
          }

          selectedPriceIndex.value = defaultIndex;

          // 延迟滚动到选中的套餐，确保UI已经渲染
          Future.delayed(const Duration(milliseconds: 100), () {
            if (!_isDisposed && isPageVisible.value) {
              _scrollToSelectedPrice(defaultIndex);
            }
          });

          // 检查默认选中的套餐是否有折扣，如果有则显示弹窗
          final defaultPackage = vipPackages[defaultIndex];
          if (defaultPackage.hasDiscount) {
            // 延迟一点显示弹窗，确保页面已经渲染完成
            Future.delayed(const Duration(milliseconds: 500), () {
              if (!_isDisposed && isPageVisible.value) {
                 _showDiscountDialog(defaultPackage);
              }
            });
          }
        }
      } else {
        CustomToast.show(Get.context!, result.msg ?? '加载套餐数据失败');
        _updateLifetimeActivity(null);
      }
    } catch (e) {
      CustomToast.show(Get.context!, '加载套餐数据失败: $e');
      _updateLifetimeActivity(null);
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

  // /// 获取默认套餐或null（如果没有套餐则返回null）
  // VipPackageModel? _getDefaultPackageOrNull() {
  //   if (vipPackages.isEmpty) {
  //     return null;
  //   }
  //   // 查找 type = 4 的套餐
  //   for (final package in vipPackages) {
  //     if (package.type == 4) {
  //       return package;
  //     }
  //   }
  //   // 如果没有 type = 4 的套餐，返回第一个
  //   return vipPackages.first;
  // }

  /// 获取当前选中的价格文本
  String getCurrentPrice() {
    final package = selectedPackage;
    final price = package?.priceText ?? '0.00';
    return price.replaceFirst(RegExp(r'^[¥￥]'), '');
  }

  String getCurrentPeriodLabel() {
    final package = selectedPackage;
    return package?.periodLabel ?? '';
  }

  /// 从弹窗购买VIP（不需要协议检查）
  void _purchaseVipFromDialog() async { 

    if (isPurchasing.value) {
       return;
    }

    // 检查是否选择了套餐
    final package = selectedPackage;
    if (package == null) {
      CustomToast.show(Get.context!, '请选择一个套餐');
      return;
    }

    try {
      isPurchasing.value = true;

      // 彻底检查并重置异常支付状态
      _paymentService.thoroughCheckAndResetPaymentState();

      

  
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
    if (isPurchasing.value) {
       return;
    }

    // 协议检查已在UI层面处理，这里可以省略
    // 但为了安全起见，仍然保留检查
    if (!agreementChecked.value) {
       showAgreementWarning();
      return;
    }

    // 检查是否选择了套餐
    final package = selectedPackage;
    if (package == null) {
      CustomToast.show(Get.context!, '请选择一个套餐');
      return;
    }

    try {
      isPurchasing.value = true;

      // 彻底检查并重置异常支付状态
      _paymentService.thoroughCheckAndResetPaymentState();

  
  
  
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
    _paymentResultSubscription = _paymentService.listenToPaymentResult((
      result,
    ) {
 
      final success = result['success'] ?? false;
      final payType = result['payType'] ?? '';
      final message = result['message'] ?? '';

      if (success) {
 
        // 获取当前选中的套餐
        if (selectedPriceIndex.value >= 0 &&
            selectedPriceIndex.value < vipPackages.length) {
          final package = vipPackages[selectedPriceIndex.value];

          // 埋点：记录支付成功
          _trackPaymentResult(package, payStatus: 1);

          // 显示成功提示
          OKToastUtil.show('支付成功');

          // 更新VIP状态
          _updateVipStatus(package);

          // 处理支付成功
          _handlePaymentSuccess(package);
        }
      } else {
        logError('❌ 支付失败通知 - 类型: $payType, 原因: $message');

        // 埋点：记录支付失败或取消
        if (selectedPriceIndex.value >= 0 &&
            selectedPriceIndex.value < vipPackages.length) {
          final package = vipPackages[selectedPriceIndex.value];
          // 判断是取消还是失败：2=取消支付, 0=支付失败
          final payStatus = message.contains('取消') ? 2 : 0;
          _trackPaymentResult(package, payStatus: payStatus);
        }

        // 重置购买状态
        isPurchasing.value = false;

        // 检查是否是用户取消
        if (message.contains('取消')) {
         } else {
          // 支付失败时，仍然检查一下VIP状态
          _checkVipStatusAfterFailure();
        }
      }
    });
  }

  /// 支付失败后检查VIP状态
  Future<void> _checkVipStatusAfterFailure() async {
     await Future.delayed(const Duration(seconds: 2));

    final refreshSuccess = await UserManager.refreshUserInfo();
    if (refreshSuccess) {
      final user = UserManager.currentUser;
      if (user?.vipEndTime != null && user!.vipEndTime! > 0) {
        final vipEndTime = DateTime.fromMillisecondsSinceEpoch(
          user.vipEndTime! * 1000,
        );
        if (vipEndTime.isAfter(DateTime.now())) {
 
          if (selectedPriceIndex.value >= 0 &&
              selectedPriceIndex.value < vipPackages.length) {
            final package = vipPackages[selectedPriceIndex.value];
            
            // 埋点：记录延迟检测到的支付成功
            _trackPaymentResult(package, payStatus: 1);
            
            OKToastUtil.show('支付成功');
            // 更新会员状态
            isVipStatus.value = UserManager.isVip;
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
      // 记录支付开始时间（十位时间戳）
      _payStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
       
      bool result = false;

      if (selectedPaymentMethod.value == 0) {
        // 微信支付
        // 🔥 先检查微信是否安装
        final isWechatInstalled = await _paymentService.isWechatInstalled();
        if (!isWechatInstalled) {
          logError('💫 微信未安装');
          // 埋点：记录微信未安装（支付失败）
          _trackPaymentResult(package, payStatus: 0);
          OKToastUtil.show('请先安装微信');
          isPurchasing.value = false;
          return;
        }
        
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
          logError('💫 微信支付订单创建失败: ${wxPayResult.msg}');
          throw Exception(wxPayResult.msg ?? '微信支付订单创建失败');
        }
      } else {
        // 支付宝支付
        // 🔥 先检查支付宝是否安装
        final isAlipayInstalled = await _paymentService.isAlipayInstalled();
        if (!isAlipayInstalled) {
          logError('💫 支付宝未安装');
          // 埋点：记录支付宝未安装（支付失败）
          _trackPaymentResult(package, payStatus: 0);
          OKToastUtil.show('请先安装支付宝');
          isPurchasing.value = false;
          return;
        }
        
         final aliPayResult = await _vipService.aliPay(vipPackageId: package.id);
         

        if (aliPayResult.isSuccess && aliPayResult.data != null) {
           

          // 调用支付宝支付
           
          result = await _paymentService.payWithAlipay(
            orderInfo: aliPayResult.data!.orderString ?? '',
          );
         } else {
          logError('💫 支付宝订单创建失败: ${aliPayResult.msg}');
          throw Exception(aliPayResult.msg ?? '支付宝支付订单创建失败');
        }
      }

 
      // 注意：对于微信支付，result 只表示是否成功唤起微信，不表示支付结果
      // 实际支付结果通过 PaymentService 的回调处理
      // 对于支付宝，result 表示实际支付结果
      if (selectedPaymentMethod.value == 0) {
        // 微信支付
        if (result) {
          // 成功唤起微信，等待回调
           // 不做任何处理，让 PaymentService 的回调来处理结果
        } else {
          // 🔥 微信支付唤起失败（可能是微信未安装或版本过低）
          logError('💫 微信支付唤起失败（可能未安装微信）');
          
          // 埋点：记录微信支付失败（未安装/唤起失败）
          _trackPaymentResult(package, payStatus: 0);
          
          // 重置购买状态
          isPurchasing.value = false;
        }
      } else {
        // 支付宝支付：处理返回值
        if (result) {
           
          // 🔥 埋点：记录支付宝支付成功
          _trackPaymentResult(package, payStatus: 1);
          
          OKToastUtil.show('支付成功');
          _updateVipStatus(package);
          await _handlePaymentSuccess(package);
        } else {
          // 🔥 支付宝支付失败或取消
          logError('💫 支付宝支付失败或取消');
          
          // 埋点：记录支付宝支付取消（支付宝返回false通常是用户取消）
          _trackPaymentResult(package, payStatus: 2);
          
          OKToastUtil.show('支付已取消');
          
          // 重置购买状态
          isPurchasing.value = false;
        }
      }
    } catch (e) {
      logError('💫 支付处理失败: $e'); 
      
      // 🔥 埋点：记录支付异常失败
      if (selectedPriceIndex.value >= 0 &&
          selectedPriceIndex.value < vipPackages.length) {
        final package = vipPackages[selectedPriceIndex.value];
        _trackPaymentResult(package, payStatus: 0);
      }
      
      OKToastUtil.show("支付失败");
      rethrow; // 重新抛出异常，让上层处理
    }
  }

  /// 更新VIP状态
  void _updateVipStatus(VipPackageModel package) {
    // 这里应该更新用户的VIP状态
    // 例如保存到本地存储或更新用户管理器中的状态
     // 更新响应式会员状态
    isVipStatus.value = UserManager.isVip;
  }

  /// 支付成功后的处理
  Future<void> _handlePaymentSuccess(VipPackageModel package) async {
    try {
 
      // 显示支付成功提示
      // OKToastUtil.show('支付成功');

      // 等待用户信息刷新完成（支付服务中已经处理）
      // 这里稍等片刻，让支付服务的刷新操作完成
      await Future.delayed(const Duration(milliseconds: 500));

      // 更新会员状态
      isVipStatus.value = UserManager.isVip;

      // 显示VIP开通成功弹窗，点击"去体验"后再返回
      if (Get.context != null) {
        await VipOpenSuccessDialog.show(
          context: Get.context!,
          barrierDismissible: false, // 不允许点击背景关闭
          onExperience: () async {
            // 点击"去体验"后刷新页面数据并返回上一页
            await _refreshMinePageAndReturn();
          },
        );
      } else {
        // 如果context为空，直接返回
        await _refreshMinePageAndReturn();
      }
    } catch (e) {
      logError('支付成功后处理异常: $e');
      // 即使出现异常，也要尝试返回上一页
      Get.back();
    }
  }

  /// 刷新我的页面并返回上一页
  Future<void> _refreshMinePageAndReturn() async {
    try {
 
      // 刷新我的页面数据
      if (Get.isRegistered<MineController>()) {
        final mineController = Get.find<MineController>();
        await mineController.refreshUserInfo();
       }

      // 刷新首页数据（如果首页控制器存在）
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.loadUserInfo();
       }

      // 返回上一页
      Get.back();
     } catch (e) {
     logError('刷新页面数据失败: $e');
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

    // 初始化时将滚动位置设置到中间，避免边界问题
    if (commentScrollController.hasClients && commentScrollController.offset == 0) {
      _isInitializingCommentCarousel = true; // 设置初始化标志
      final itemWidth = 266.0 + 13.0;
      // 使用更小的初始位置，避免性能问题
      final middlePosition = itemWidth * (commentList.length * 50); // 50个循环的位置
      commentScrollController.jumpTo(middlePosition);
      _isInitializingCommentCarousel = false; // 清除初始化标志
    }

    _commentCarouselTimer = Timer.periodic(_commentCarouselInterval, (timer) {
      if (_isDisposed || !isPageVisible.value) {
        timer.cancel();
        return;
      }

      if (commentScrollController.hasClients) {
        final itemWidth = 266.0 + 13.0; // 每个item宽度 + 间距
        final currentOffset = commentScrollController.offset;
        final targetOffset = currentOffset + itemWidth; // 直接递增滚动位置
        
        // 检查是否接近边界，如果是则重置到中间位置
        const int infiniteCount = 10000;
        final maxOffset = itemWidth * (infiniteCount - 10); // 留一10个的缓冲
        if (targetOffset >= maxOffset) {
          // 重置到中间位置
          _isInitializingCommentCarousel = true;
          final middlePosition = itemWidth * (commentList.length * 50);
          commentScrollController.jumpTo(middlePosition);
          _isInitializingCommentCarousel = false;
          return;
        }

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

  /// 上报支付结果埋点
  /// [package] 套餐信息
  /// [payStatus] 支付状态：0=支付失败, 1=支付成功, 2=取消支付
  void _trackPaymentResult(VipPackageModel package, {required int payStatus}) {
    // 计算支付用时（秒）
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final payDuration = _payStartTime != null ? currentTime - _payStartTime! : 0;

    // 获取会员类型：1=月度会员, 2=年度会员, 3=永久会员
    int vipType;
    if (package.isForever) {
      vipType = 3; // 永久会员
    } else if (package.type == 3) {
      vipType = 2; // 年度会员
    } else {
      vipType = 1; // 月度会员
    }

    // 获取支付方式：1=支付宝, 2=微信, 3=苹果
    final payType = selectedPaymentMethod.value == 1 ? 1 : 2; // 0=微信(2), 1=支付宝(1)

    

 
    // 根据是否是会员设置按钮名称
    final btnName = isVipStatus.value ? PayBtnValue.payLater : PayBtnValue.payNow;

    // 调用埋点
    AnalyticsHelper.trackMembershipPayBtn(
      vipType: vipType,
      payType: payType,
      btnName: btnName,
      payStatus: payStatus,
      payDuration: payDuration,
    );

    // 🔥 如果是终身套餐（99元），额外上报 vip_page_99_pay_event 埋点
    if (package.isForever) {
      _track99PayEvent(package, payStatus: payStatus, payDuration: payDuration);
    }
  }

  /// 上报99元支付事件埋点（终身套餐专用）
  /// [package] 套餐信息
  /// [payStatus] 支付状态：0=支付失败, 1=支付成功, 2=取消支付
  /// [payDuration] 支付用时（秒）
  void _track99PayEvent(VipPackageModel package, {required int payStatus, required int payDuration}) {
    // 获取支付方式：1=支付宝, 2=微信, 3=苹果
    final payType = selectedPaymentMethod.value == 1 ? 1 : 2; // 0=微信(2), 1=支付宝(1)

    // 按钮名称
    final btnName = package.title;

 
    // 调用99元支付埋点
    AnalyticsHelper.track99PayEvent(
      vipType: 3, // 永久会员
      payType: payType,
      payStatus: payStatus,
      btnName: btnName,
      payDuration: payDuration,
    );
  }
}
