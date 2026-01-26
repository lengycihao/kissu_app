import 'package:get/get.dart';
import 'check_in_188_controller.dart';

/// 188打卡页面绑定
class CheckIn188Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CheckIn188Controller>(() => CheckIn188Controller());
  }
}
