import 'package:get/get.dart';
import '../../../utils/user_manager.dart';

class BreakRelationshipController extends GetxController {
  // 用户数据
  var myAvatar = ''.obs;
  var partnerAvatar = ''.obs;
  var loveDays = 0.obs;
  var isBindPartner = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  void loadUserData() {
    final user = UserManager.currentUser;
    if (user != null) {
      // 设置我的头像
      myAvatar.value = user.headPortrait ?? '';

      // 检查绑定状态
      final bindStatus = user.bindStatus.toString();
      isBindPartner.value = bindStatus.toString() == "1";

      if (isBindPartner.value) {
        // 已绑定状态，获取伴侣数据和天数
        _loadPartnerData(user);
        _calculateLoveDays(user);
      }
    }
  }

  void _loadPartnerData(user) {
    // 设置伴侣头像
    if (user.loverInfo?.headPortrait?.isNotEmpty == true) {
      partnerAvatar.value = user.loverInfo!.headPortrait!;
    } else if (user.halfUserInfo?.headPortrait?.isNotEmpty == true) {
      partnerAvatar.value = user.halfUserInfo!.headPortrait!;
    }
  }

  void _calculateLoveDays(user) {
    // 优先使用LoverInfo中的天数数据
    if (user.loverInfo != null &&
        user.loverInfo!.loveDays != null &&
        user.loverInfo!.loveDays! > 0) {
      loveDays.value = user.loverInfo!.loveDays!;
      return;
    }

    // 如果没有直接的天数数据，尝试从bindTime计算
    if (user.loverInfo?.bindTime?.isNotEmpty == true) {
      try {
        final bindTimestamp = int.parse(user.loverInfo!.bindTime!);
        final bindTime = DateTime.fromMillisecondsSinceEpoch(
          bindTimestamp * 1000,
        );
        final now = DateTime.now();
        final difference = now.difference(bindTime).inDays;
        loveDays.value = difference;
        return;
      } catch (e) {
        print('解析LoverInfo bindTime失败: $e');
      }
    }

    // 回退到使用latelyBindTime
    if (user.latelyBindTime != null) {
      final bindTime = DateTime.fromMillisecondsSinceEpoch(
        user.latelyBindTime! * 1000,
      );
      final now = DateTime.now();
      final difference = now.difference(bindTime).inDays;
      loveDays.value = difference;
    }
  }
}
