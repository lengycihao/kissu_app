import 'package:get/get.dart';
import 'phone_verification_page.dart';
import '../../../utils/user_manager.dart';

class AccountCancellationController extends GetxController {
  // 用户信息
  final userAvatar = 'assets/kissu_accout_header_bg.webp'.obs;
  final userName = '悠悠白茶'.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserInfo();
  }

  /// 加载用户信息
  void loadUserInfo() {
    final currentUser = UserManager.currentUser;
    if (currentUser != null) {
      // 设置用户昵称
      if (currentUser.nickname?.isNotEmpty == true) {
        userName.value = currentUser.nickname!;
      }

      // 设置用户头像
      if (currentUser.headPortrait?.isNotEmpty == true) {
        userAvatar.value = currentUser.headPortrait!;
      }
    }
  }

  // 跳转到手机号验证页面
  void navigateToPhoneVerification() {
    Get.to(() => PhoneVerificationPage());
  }

  // 返回上一页
  void goBack() {
    Get.back();
  }
}
