import 'package:get/get.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/utils/debug_util.dart';

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
      
      // 绑定状态处理 (1绑定，2未绑定，0初始未绑定)
      final bindStatus = user.bindStatus.toString();
      isBound.value = bindStatus == "1";
      
      DebugUtil.info('ForeverVipController: bindStatus=$bindStatus, isBound=${isBound.value}');
      DebugUtil.info('ForeverVipController: loverInfo=${user.loverInfo}');
      DebugUtil.info('ForeverVipController: halfUserInfo=${user.halfUserInfo}');
      
      // 配对用户信息 - 优先使用halfUserInfo，然后loverInfo覆盖
      if (isBound.value) {
        // 先尝试从halfUserInfo获取
        if (user.halfUserInfo != null) {
          partnerNickname.value = user.halfUserInfo!.nickname ?? "另一半";
          partnerAvatar.value = user.halfUserInfo!.headPortrait ?? "";
          // DebugUtil.info('ForeverVipController: 从halfUserInfo获取 - nickname=${partnerNickname.value}, avatar=${partnerAvatar.value}');
        }
        
        // 然后用loverInfo覆盖（如果有的话）
        if (user.loverInfo != null) {
          if (user.loverInfo!.nickname != null && user.loverInfo!.nickname!.isNotEmpty) {
            partnerNickname.value = user.loverInfo!.nickname!;
          }
          if (user.loverInfo!.headPortrait != null && user.loverInfo!.headPortrait!.isNotEmpty) {
            partnerAvatar.value = user.loverInfo!.headPortrait!;
          }
          // DebugUtil.info('ForeverVipController: loverInfo覆盖后 - nickname=${partnerNickname.value}, avatar=${partnerAvatar.value}');
        }
      } else {
        partnerNickname.value = "等待配对";
        partnerAvatar.value = "";
        // DebugUtil.info('ForeverVipController: 未绑定');
      }
    }
  }

  /// 刷新用户信息
  Future<void> refreshUserInfo() async {
    await UserManager.refreshUserInfo();
    _loadUserInfo();
  }
}