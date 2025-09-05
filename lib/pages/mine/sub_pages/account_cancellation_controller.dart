import 'package:get/get.dart';
import 'phone_verification_page.dart';

class AccountCancellationController extends GetxController {
  // 用户信息
  final userAvatar = 'assets/kissu_accout_header_bg.webp'.obs;
  final userName = '悠悠白茶'.obs;
  
  // 跳转到手机号验证页面
  void navigateToPhoneVerification() {
    Get.to(() => PhoneVerificationPage());
  }
  
  // 返回上一页
  void goBack() {
    Get.back();
  }
}