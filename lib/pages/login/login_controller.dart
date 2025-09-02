import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/login/info_setting/info_setting_controller.dart';
import 'package:kissu_app/pages/login/info_setting/info_setting_page.dart';
import 'package:kissu_app/utils/toast_toalog.dart';

class LoginController extends GetxController {
  var isChecked = false.obs;
  var phoneNumber = ''.obs;
  var verificationCode = ''.obs;

  late BuildContext context;

  // 校验手机号的简单方法
  void validatePhoneNumber() {
    if (phoneNumber.value.length == 10) {
      // 在这里添加实际的校验逻辑
      print("手机号校验通过");
    } else {
      print("手机号格式不正确");
    }
  }

  // 登录逻辑
  void login() {
    ToastDialog.showDialogWithCloseButton(
      context,
      '温馨提示', // 标题
      '为了更好的保障你的权益，请阅读并同意《用户协议》和《隐私协议》后进行登录', // 内容
      () {
        // 确认按钮点击回调
         Get.to(() => InfoSettingPage());
      },
      height: 245.0, // 传递弹窗的高度（例如：500.0）
    );
    if (isChecked.value) {
      print("登录成功");
    } else {
      print("请同意隐私协议和用户协议");
    }
  }
}
