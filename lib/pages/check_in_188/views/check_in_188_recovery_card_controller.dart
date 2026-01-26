import 'package:get/get.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';

/// 188补签卡购买页面控制器
class CheckIn188RecoveryCardController extends GetxController {
  /// 累计打卡天数
  final RxInt checkedInDays = 87.obs;
  
  /// 已有补签卡数量
  final RxInt recoveryCardCount = 4.obs;
  
  /// 是否显示新人福利卡
  final RxBool showNewUserCard = true.obs;
  
  /// 选中的补签卡选项索引 (-1表示未选中，0表示新人福利卡，1-4表示普通卡)
  final RxInt selectedCardIndex = (-1).obs;
  
  /// 支付方式 (0: 微信支付, 1: 支付宝)
  final RxInt paymentMethod = 0.obs;
  
  /// 补签卡选项列表
  final List<RecoveryCardOption> cardOptions = [
    RecoveryCardOption(count: 3, price: 42.00, originalPrice: null),
    RecoveryCardOption(count: 6, price: 81.00, originalPrice: null),
    RecoveryCardOption(count: 12, price: 156.00, originalPrice: null, discount: '低至6.5折'),
  ];
  
  /// 新人福利卡选项
  final RecoveryCardOption newUserCardOption = RecoveryCardOption(
    count: 1,
    price: 9.00,
    originalPrice: 20.00,
    isNewUser: true,
    limitText: '仅限4张',
  );
  
  /// 选择补签卡
  void selectCard(int index) {
    selectedCardIndex.value = index;
  }
  
  /// 选择支付方式
  void selectPaymentMethod(int method) {
    paymentMethod.value = method;
  }
  
  /// 获取当前选中的卡片选项
  RecoveryCardOption? getSelectedCard() {
    if (selectedCardIndex.value == -1) return null;
    if (selectedCardIndex.value == 0 && showNewUserCard.value) {
      return newUserCardOption;
    }
    final normalIndex = showNewUserCard.value ? selectedCardIndex.value - 1 : selectedCardIndex.value;
    if (normalIndex >= 0 && normalIndex < cardOptions.length) {
      return cardOptions[normalIndex];
    }
    return null;
  }
  
  /// 立即购买
  void onBuyNow() {
    if (selectedCardIndex.value == -1) {
      OKToastUtil.showInfo('请选择补签卡');
      return;
    }
    
    final selectedCard = getSelectedCard();
    if (selectedCard == null) {
      OKToastUtil.showInfo('请选择补签卡');
      return;
    }
    
    // TODO: 调用支付接口
    final paymentName = paymentMethod.value == 0 ? '微信支付' : '支付宝';
    OKToastUtil.showInfo('购买${selectedCard.count}张补签卡，使用$paymentName，金额¥${selectedCard.price.toStringAsFixed(2)}');
  }
  
  /// 参与活动获取补签卡
  void onGetCardByActivity() {
     Get.toNamed(KissuRoutePath.checkIn188Activity);
  }
  
  /// 查看补签卡日志
  void onViewCardLog() {
    Get.toNamed(KissuRoutePath.checkIn188CardLog);
  }
  
  /// 返回上一页
  void goBack() {
    Get.back();
  }
}

/// 补签卡选项数据模型
class RecoveryCardOption {
  final int count; // 数量
  final double price; // 价格
  final double? originalPrice; // 原价
  final String? discount; // 折扣标签
  final bool isNewUser; // 是否是新人福利卡
  final String? limitText; // 限制文本
  
  RecoveryCardOption({
    required this.count,
    required this.price,
    this.originalPrice,
    this.discount,
    this.isNewUser = false,
    this.limitText,
  });
}
