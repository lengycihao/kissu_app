import 'package:get/get.dart';
import 'package:kissu_app/utils/user_manager.dart';

class ForeverVipController extends GetxController {
  // 用户信息
  var userNickname = "".obs;
  var userAvatar = "".obs;
  var partnerNickname = "".obs;
  var partnerAvatar = "".obs;
  var vipMemberId = "".obs;
  
  // 是否已绑定
  var isBound = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
  }


  /// 加载用户信息
  void _loadUserInfo() {
    final user = UserManager.currentUser;
    if (user != null) {
      // 当前用户信息
      userNickname.value = user.nickname ?? "小可爱";
      userAvatar.value = user.headPortrait ?? "";
      
      // 生成VIP会员号（基于用户ID）
      vipMemberId.value = "VIP${user.id?.toString().padLeft(9, '8') ?? '888888888'}";
      
      // 配对用户信息
      if (user.loverInfo != null) {
        isBound.value = true;
        partnerNickname.value = user.loverInfo!.nickname ?? "另一半";
        partnerAvatar.value = user.loverInfo!.headPortrait ?? "";
      } else {
        isBound.value = false;
        partnerNickname.value = "等待配对";
        partnerAvatar.value = "";
      }
    }
  }

  /// 刷新用户信息
  Future<void> refreshUserInfo() async {
    await UserManager.refreshUserInfo();
    _loadUserInfo();
  }
}