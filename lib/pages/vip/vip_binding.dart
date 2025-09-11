import 'package:get/get.dart';
import 'package:kissu_app/pages/vip/vip_controller.dart';

class VipBinding extends Bindings {
  @override
  void dependencies() {
    // 使用put而不是lazyPut，确保控制器立即创建
    // 并在页面销毁时自动删除
    Get.put(VipController(), permanent: false);
  }
}