import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/login/info_setting/info_setting_controller.dart';

class InfoSettingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => InfoSettingController());
  }
}
