import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'widgets/home/check_in_188_retention_dialog.dart';
import 'widgets/home/check_in_188_ticket_bottom_sheet.dart';

/// 188打卡页面控制器
class CheckIn188Controller extends GetxController {
  /// 滚动控制器
  late ScrollController scrollController;
  
  /// 导航栏透明度 (0.0 - 1.0)
  final RxDouble navBarOpacity = 0.0.obs;
  
  /// 当前累计参与人数
  final RxInt participantCount = 2318.obs;
  
  /// 累计被领取奖金金额
  final RxInt totalPrize = 170560.obs;
  
  /// 参与用户头像列表
  final RxList<String> participantAvatars = <String>[].obs;
  
  /// 提现成功案例列表
  final RxList<SuccessCase> successCases = <SuccessCase>[].obs;
  
  /// 是否同意协议
  final RxBool isAgreed = false.obs;
  
  /// 轮播当前索引
  final RxInt currentCaseIndex = 0.obs;
  
  /// PageController for 成功案例轮播
  late PageController casePageController;
  
  /// 是否已参与活动
  final RxBool hasJoined = false.obs;
  
  /// 选中的门票索引 (0: 0元打卡门票+1张补签卡, 1: 打卡门票)
  final RxInt selectedTicketIndex = 0.obs;
  
  /// 选中的支付方式 (0: 微信支付, 1: 支付宝)
  final RxInt selectedPaymentMethod = 0.obs;
  
  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController();
    scrollController.addListener(_onScroll);
    casePageController = PageController(viewportFraction: 0.85);
    
    // 初始化模拟数据
    _initMockData();
  }
  
  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    casePageController.dispose();
    super.onClose();
  }
  
  /// 滚动监听 - 控制导航栏透明度
  void _onScroll() {
    // 滚动距离在 0-100 之间时，透明度从 0 变到 1
    final offset = scrollController.offset;
    final opacity = (offset / 100).clamp(0.0, 1.0);
    navBarOpacity.value = opacity;
  }
  
  /// 初始化模拟数据
  void _initMockData() {
    // 模拟参与用户头像
    participantAvatars.value = [
      'assets/3.0/kissu3_love_avater.webp',
      'assets/3.0/kissu3_love_avater.webp',
      'assets/3.0/kissu3_love_avater.webp',
      'assets/3.0/kissu3_love_avater.webp',
      'assets/3.0/kissu3_love_avater.webp',
    ];
    
    // 模拟提现成功案例
    successCases.value = [
      SuccessCase(
        nickname: '陈冰·冰',
        avatar: 'assets/3.0/kissu3_love_avater.webp',
        amount: 520,
        description: '朋友邀我俩帮她整补签卡，然后就一直在坚持打卡了。也没想过真的拿到这笔钱，就觉得天天对对方说我爱.',
        actionText: '活动简介',
      ),
      SuccessCase(
        nickname: '小明',
        avatar: 'assets/3.0/kissu3_love_avater.webp',
        amount: 520,
        description: '美滋滋的收到钱了，最后拿到钱的那一刻，真的有些泪目。1314活动是真实有效的。开始知道这个是因为闺…',
        actionText: '活动简介',
      ),
      SuccessCase(
        nickname: '爱你的人',
        avatar: 'assets/3.0/kissu3_love_avater.webp',
        amount: 520,
        description: '朋友邀我俩帮她整补签卡，然后就一直在坚持打卡了。也没想过真的拿到这笔钱，就觉得天天对对方说我爱.',
        actionText: '活动简介',
      ),
    ];
  }
  
  /// 切换协议同意状态
  void toggleAgreement() {
    isAgreed.value = !isAgreed.value;
  }
  
  /// 点击参与按钮
  void onPayButtonTap() {
    if (!isAgreed.value) {
      OKToastUtil.showError('请先同意活动协议');
      return;
    }
    // 弹出门票选择弹窗
    _showTicketBottomSheet();
  }
  
  /// 返回上一页
  void goBack() {
    // 如果未参与活动，弹出挽留弹窗
    if (!hasJoined.value) {
      _showRetentionDialog();
    } else {
      Get.back();
    }
  }
  
  /// 显示挽留弹窗
  void _showRetentionDialog() {
    CheckIn188RetentionDialog.show(
      onJoinNow: () {
        // 立即参加，弹出门票选择弹窗
        _showTicketBottomSheet();
      },
    );
  }
  
  /// 显示门票选择底部弹窗
  void _showTicketBottomSheet() {
    CheckIn188TicketBottomSheet.show(this);
  }
  
  /// 选择门票
  void selectTicket(int index) {
    selectedTicketIndex.value = index;
  }
  
  /// 选择支付方式
  void selectPaymentMethod(int index) {
    selectedPaymentMethod.value = index;
  }
  
  /// 确认支付
  void onConfirmPayment() {
    // TODO: 对接支付接口
    // 这里预留接口对接位置
    // 支付参数：
    // - ticketType: selectedTicketIndex.value (0: 套餐, 1: 单票)
    // - paymentMethod: selectedPaymentMethod.value (0: 微信, 1: 支付宝)
    // - amount: 根据选择的门票类型确定金额
    
    // 模拟支付成功
    Get.back(); // 关闭底部弹窗
    hasJoined.value = true;
    
    // 跳转到打卡进行中页面
    Get.offNamed(KissuRoutePath.checkIn188Progress);
  }
}

/// 提现成功案例模型
class SuccessCase {
  final String nickname;
  final String avatar;
  final int amount;
  final String description;
  final String actionText;
  
  SuccessCase({
    required this.nickname,
    required this.avatar,
    required this.amount,
    required this.description,
    required this.actionText,
  });
}
