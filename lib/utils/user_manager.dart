import 'package:get/get.dart';
import 'package:kissu_app/model/login_model/login_model.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/public/service_locator.dart';
import 'package:kissu_app/network/public/phone_history_api.dart';
import 'package:kissu_app/pages/login/login_controller.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:kissu_app/services/privacy_compliance_manager.dart';
import 'package:kissu_app/utils/debug_util.dart';

/// 全局用户数据管理工具类
/// 提供便捷的用户数据访问方法
class UserManager {
  static AuthService get _authService => getIt<AuthService>();

  /// 获取当前登录用户
  static LoginModel? get currentUser => _authService.currentUser;

  /// 检查是否已登录
  static bool get isLoggedIn => _authService.isLoggedIn;

  /// 获取用户ID
  static String? get userId => _authService.userId;

  /// 获取用户手机号
  static String? get userPhone => _authService.userPhone;

  /// 获取用户昵称
  static String? get userNickname => _authService.userNickname;

  /// 获取用户头像
  static String? get userAvatar => _authService.userAvatar;

  /// 获取用户Token
  static String? get userToken => _authService.userToken;

  /// 获取用户性别
  static int? get userGender => _authService.userGender;

  /// 获取用户性别文本
  static String get genderText => _authService.genderText;

  /// 获取用户生日
  static String? get userBirthday => _authService.userBirthday;

  /// 检查是否VIP用户
  static bool get isVip => _authService.isVip;

  /// 检查是否永久VIP
  static bool get isForeverVip => _authService.isForeverVip;

  /// 获取VIP到期时间
  static String? get vipEndDate => _authService.vipEndDate;

  /// 获取省份名称
  static String? get provinceName => _authService.provinceName;

  /// 获取城市名称
  static String? get cityName => _authService.cityName;

  /// 获取好友邀请码
  static String? get friendCode => _authService.friendCode;

  /// 获取好友邀请码（带默认值）
  static String get friendCodeOrDefault => friendCode ?? '1000000';

  /// 获取登录时间戳
  static int? get loginTime => _authService.currentUser?.loginTime;

  /// 获取用户显示名称
  static String get displayName => _authService.displayName;

  /// 获取完整地址
  static String get fullAddress {
    final province = provinceName ?? '';
    final city = cityName ?? '';
    if (province.isNotEmpty && city.isNotEmpty) {
      return '$province $city';
    } else if (province.isNotEmpty) {
      return province;
    } else if (city.isNotEmpty) {
      return city;
    }
    return '未知地区';
  }

  /// 检查用户是否需要完善信息
  static bool get needsPerfectInfo => _authService.needsPerfectInfo;

  /// 更新用户信息
  static Future<void> updateUserInfo(LoginModel updatedUser) async {
    await _authService.updateUserInfo(updatedUser);
  }

  /// 更新用户头像
  static Future<void> updateUserAvatar(String avatarUrl) async {
    await _authService.updateUserAvatar(avatarUrl);
  }

  /// 更新用户昵称
  static Future<void> updateUserNickname(String nickname) async {
    await _authService.updateUserNickname(nickname);
  }

  /// 用户登出
  static Future<void> logout() async {
    // 停止定位服务
    stopLocationService();
    
    // 清除缓存
    clearPhoneHistoryCache();
    // clearLocationCache();
    // clearTrackDataCache();
    
    await _authService.logout();
  }

  /// 清除本地用户数据（用于注销后的数据清理，不调用退出登录API）
  static Future<void> clearLocalUserData() async {
    // 停止定位服务
    stopLocationService();
    
    // 清除缓存
    clearPhoneHistoryCache();
    // clearLocationCache();
    // clearTrackDataCache();
    
    // 清除协议同意状态（注销时需要重新同意协议）
    await LoginController.clearAgreementStatus();
    
    // 🔑 清除隐私合规状态
    try {
      if (Get.isRegistered<PrivacyComplianceManager>()) {
        final privacyManager = Get.find<PrivacyComplianceManager>();
        await privacyManager.clearPrivacyStatus();
        DebugUtil.success('隐私合规状态已清除');
      }
    } catch (e) {
      DebugUtil.error('清除隐私合规状态失败: $e');
    }

    // 清除用户数据
    await _authService.clearLocalUserData();
  }

  /// 清除当前用户的通话记录缓存
  static void clearPhoneHistoryCache() {
    PhoneHistoryApi.clearCurrentUserCache();
  }

  // /// 清除当前用户的位置数据缓存
  // static void clearLocationCache() {
  //   TrackApi.clearCurrentUserCache();
  // }

  // /// 清除轨迹数据缓存
  // static void clearTrackDataCache() {
  //   try {
  //     // 尝试获取TrackController实例并清除缓存
  //     if (Get.isRegistered<TrackController>()) {
  //       final trackController = Get.find<TrackController>();
  //       trackController.clearTrackDataCache();
  //     }
  //   } catch (e) {
  //     // 如果TrackController未注册或出错，忽略错误
  //     print('🔧 UserManager: 清除轨迹缓存失败（可能控制器未初始化）: $e');
  //   }
  // }

  /// 停止定位服务
  static void stopLocationService() {
    try {
      final locationService = Get.find<SimpleLocationService>();
      if (locationService.isLocationEnabled.value) {
        locationService.stopLocation();
        DebugUtil.info('UserManager: 定位服务已停止');
      }
    } catch (e) {
      DebugUtil.error('UserManager: 停止定位服务失败: $e');
    }
  }

  /// 刷新用户信息（从服务器获取最新数据）
  /// 只在用户信息更新后调用，不要频繁调用
  static Future<bool> refreshUserInfo() async {
    return await _authService.refreshUserInfoFromServer();
  }

  /// 刷新Token
  static Future<void> refreshToken(String newToken) async {
    await _authService.refreshToken(newToken);
  }

  /// 获取用户摘要信息（调试用）
  static Map<String, dynamic> getUserSummary() {
    return _authService.getUserSummary();
  }

  /// 📦 获取用户基本信息（用于UI展示）
  /// 返回包含昵称、匹配码、头像、绑定状态等常用信息
  static Map<String, dynamic> getUserBasicInfo() {
    final user = currentUser;
    if (user == null) {
      return {
        'nickname': '小可爱',
        'matchCode': '1000000',
        'avatar': '',
        'isBound': false,
        'partnerAvatar': '',
        'bindDate': '',
        'days': '',
      };
    }

    // 绑定状态处理 (0和2未绑定，1绑定)
    final isBound = user.bindStatus.toString() == "1";
    
    return {
      'nickname': user.nickname ?? '小可爱',
      'matchCode': user.friendCode ?? '1000000',
      'avatar': user.headPortrait ?? '',
      'isBound': isBound,
      'partnerAvatar': isBound && user.loverInfo?.headPortrait != null 
        ? user.loverInfo!.headPortrait! 
        : '',
      'bindDate': isBound && user.loverInfo?.bindDate != null 
        ? user.loverInfo!.bindDate! 
        : '',
      'days': isBound && user.loverInfo?.loveDays != null 
        ? user.loverInfo!.loveDays.toString() 
        : '',
    };
  }

  /// 检查用户权限的便捷方法
  static bool hasPermission(String permission) {
    if (!isLoggedIn) return false;

    switch (permission) {
      case 'vip_features':
        return isVip;
      case 'profile_complete':
        return !needsPerfectInfo;
      case 'basic_user':
        return true;
      default:
        return false;
    }
  }

  /// 获取用户状态描述
  static String get userStatusText {
    if (!isLoggedIn) return '未登录';
    if (isForeverVip) return '永久VIP';
    if (isVip) return 'VIP用户';
    return '普通用户';
  }

  /// 获取VIP剩余天数
  static int? get vipRemainingDays {
    if (!isVip || vipEndDate == null) return null;

    try {
      final endDate = DateTime.parse(vipEndDate!);
      final now = DateTime.now();
      final difference = endDate.difference(now).inDays;
      return difference > 0 ? difference : 0;
    } catch (e) {
      return null;
    }
  }

  /// 格式化VIP状态文本
  static String get vipStatusText {
    if (isForeverVip) return '永久VIP';
    if (isVip) {
      final days = vipRemainingDays;
      if (days != null) {
        return days > 0 ? 'VIP还有${days}天' : 'VIP已过期';
      }
      return 'VIP用户';
    }
    return '非VIP用户';
  }

  static String formatPhoneWithExcept(String phone) {
    if (phone.length >= 11) {
      return '${phone.substring(0, 3)}****${phone.substring(7)}';
    }
    return phone.isEmpty ? "未知" : phone;
  }
}
