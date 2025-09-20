import 'package:get/get.dart';
import 'package:kissu_app/pages/vip/vip_controller.dart';

class VipBinding extends Bindings {
  @override
  void dependencies() {
    // 使用lazyPut避免控制器重用问题，设置fenix为true确保每次进入都创建新实例
    Get.lazyPut<VipController>(() => VipController(), fenix: true);
  }
}