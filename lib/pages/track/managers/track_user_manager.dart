import 'package:get/get.dart';
import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/utils/debug_util.dart';

/// 轨迹页面用户管理器
/// 负责用户信息管理、头像管理等功能
class TrackUserManager {
  /// 用户头像
  final myAvatar = "".obs;
  final partnerAvatar = "".obs;
  final isBindPartner = false.obs; 
  
  /// 加载用户信息（初始化头像为用户信息中的头像）
  void loadUserInfo() {
    final user = UserManager.currentUser;
    if (user != null) { 
      // 设置我的头像（初始值，会被API数据覆盖）
      myAvatar.value = user.headPortrait ?? '';
      
      // 检查绑定状态 (0从未绑定，1绑定中，2已解绑)
      // bindStatus是dynamic类型，需要安全处理
      bool isBound = false;
      if (user.bindStatus != null) {
        logDebug('bindStatus原始值: ${user.bindStatus} (类型: ${user.bindStatus.runtimeType})');
        if (user.bindStatus is int) {
          isBound = user.bindStatus == 1;
        } else if (user.bindStatus is String) {
          isBound = user.bindStatus == "1";
        }
        logDebug('解析后的绑定状态: $isBound');
      } else {
        logWarning('bindStatus为null，默认为未绑定');
      }
      isBindPartner.value = isBound;
      
      // 设置伴侣头像（初始值，会被API数据覆盖）
      if (isBindPartner.value) {
        if (user.loverInfo?.headPortrait?.isNotEmpty == true) {
          partnerAvatar.value = user.loverInfo!.headPortrait!;
        } else if (user.halfUserInfo?.headPortrait?.isNotEmpty == true) {
          partnerAvatar.value = user.halfUserInfo!.headPortrait!;
        }
      }
      // 注意：无论绑定状态如何，都会显示两个头像，实际头像将从API数据中获取
    }
  }
  
  /// 从API数据中更新头像信息
  void updateAvatarsFromApiData(LocationResponse data) {
    logDebug('从API数据更新头像信息');
    
    // 从user字段中获取头像和绑定状态
    if (data.user != null) {
      final userInfo = data.user!;
      
      // 更新我的头像
      if (userInfo.headPortrait?.isNotEmpty == true) {
        myAvatar.value = userInfo.headPortrait!;
        logDebug('更新我的头像: ${myAvatar.value}');
      }
      
      // 更新伴侣头像
      if (userInfo.halfHeadPortrait?.isNotEmpty == true) {
        partnerAvatar.value = userInfo.halfHeadPortrait!;
        logDebug('更新伴侣头像: ${partnerAvatar.value}');
      }
      
      // 更新绑定状态
      isBindPartner.value = userInfo.isBind == 1;
      logDebug('更新绑定状态: ${isBindPartner.value}');

     
    }
    
    logDebug('头像更新完成 - 我的头像: ${myAvatar.value}, 伴侣头像: ${partnerAvatar.value}');
  }
  
  /// 获取用户头像
  String getUserAvatar(int userType) {
    return userType == 1 ? myAvatar.value : partnerAvatar.value;
  }
  
  /// 检查是否有头像
  bool hasAvatars() {
    return myAvatar.value.isNotEmpty || partnerAvatar.value.isNotEmpty;
  }
  
  /// 清除头像信息
  void clearAvatars() {
    myAvatar.value = "";
    partnerAvatar.value = "";
  }
}
