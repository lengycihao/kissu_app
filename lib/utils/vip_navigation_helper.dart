import 'package:get/get.dart';
import 'package:kissu_app/pages/location/location_v2_page.dart';
import 'package:kissu_app/pages/location/location_v2_binding.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/utils/debug_util.dart';

/// VIP导航助手类
/// 用于统一处理需要会员权限的页面跳转
class VipNavigationHelper {
  /// 检查会员状态并导航到定位页面
  /// 在入口处获取会员信息 is_vip, is_for_ever_vip, vip_end_time
  static void navigateToLocationWithVipCheck() {
    DebugUtil.info('🔍 检查会员状态后导航到定位页面');
    
    // 检查用户是否已登录
    if (!UserManager.isLoggedIn) {
      DebugUtil.warning('用户未登录，无法进入定位页面');
      // 可以在这里添加登录提示或跳转到登录页面
      return;
    }
    
    final user = UserManager.currentUser;
    if (user == null) {
      DebugUtil.error('用户信息为空');
      return;
    }
    
    // 获取用户信息接口中的关键字段
    final isVip = user.isVip; // is_vip
    final isForEverVip = user.isForEverVip; // is_for_ever_vip  
    final vipEndTime = user.vipEndTime; // vip_end_time (10位时间戳)
    
    DebugUtil.info('📊 会员信息 - isVip: $isVip, isForEverVip: $isForEverVip, vipEndTime: $vipEndTime');
    
    // 直接跳转到定位页面，让 LocationTipsManager 根据这些字段处理会员到期提示
    _navigateToLocationPage();
  }
  
  /// 跳转到定位页面
  static void _navigateToLocationPage() {
    Get.to(
      () => LocationV2Page(),
      binding: LocationV2Binding(),
      transition: Transition.downToUp,
    );
  }
  
  
  /// 检查会员是否有效（不导航，仅返回结果）
  static bool isVipValid() {
    return UserManager.isVip;
  }
  
  /// 获取会员剩余天数
  static int getVipRemainingDays() {
    return UserManager.vipRemainingDays ?? 0;
  }
  
  /// 获取会员剩余小时数
  static int getVipRemainingHours() {
    final days = getVipRemainingDays();
    if (days <= 0) return 0;
    
    // 如果剩余天数大于1天，返回天数*24
    if (days > 1) return days * 24;
    
    // 如果剩余天数为1天或更少，计算精确小时数
    final vipEndDate = UserManager.vipEndDate;
    if (vipEndDate == null) return 0;
    
    try {
      final endDate = DateTime.parse(vipEndDate);
      final now = DateTime.now();
      final difference = endDate.difference(now).inHours;
      return difference > 0 ? difference : 0;
    } catch (e) {
      return days * 24;
    }
  }
}
