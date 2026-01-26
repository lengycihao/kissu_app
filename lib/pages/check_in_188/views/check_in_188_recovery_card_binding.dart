import 'package:get/get.dart';
import 'check_in_188_recovery_card_controller.dart';

/// 188补签卡购买页面绑定
class CheckIn188RecoveryCardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CheckIn188RecoveryCardController>(
      () => CheckIn188RecoveryCardController(),
    );
  }
}
