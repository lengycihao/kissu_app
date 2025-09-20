import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/services/openinstall_service.dart';

/// 邀请码使用示例
/// 展示如何在登录时自动使用OpenInstall获取的邀请码
class FriendCodeUsageExample {
  
  /// 示例1: 自动登录（使用OpenInstall邀请码）
  static Future<void> autoLoginWithInviteCode({
    required String phoneNumber,
    required String code,
  }) async {
    // 获取AuthService实例
    final authService = AuthService();
    
    // 登录时不需要手动传递friendCode，系统会自动从OpenInstall获取
    final result = await authService.loginWithCode(
      phoneNumber: phoneNumber,
      code: code,
      // friendCode参数不传，系统会自动获取OpenInstall邀请码
    );
    
    if (result.isSuccess) {
      print('登录成功，使用的邀请码: ${result.data?.friendCode}');
    } else {
      print('登录失败: ${result.msg}');
    }
  }
  
  /// 示例2: 手动指定邀请码登录
  static Future<void> manualLoginWithFriendCode({
    required String phoneNumber,
    required String code,
    required String friendCode,
  }) async {
    final authService = AuthService();
    
    // 手动指定邀请码
    final result = await authService.loginWithCode(
      phoneNumber: phoneNumber,
      code: code,
      friendCode: friendCode, // 手动指定邀请码
    );
    
    if (result.isSuccess) {
      print('登录成功，使用的邀请码: $friendCode');
    } else {
      print('登录失败: ${result.msg}');
    }
  }
  
  /// 示例3: 检查是否有OpenInstall邀请码
  static Future<void> checkInviteCode() async {
    try {
      // 检查是否通过OpenInstall安装
      final isFromOpenInstall = await OpenInstallService.isFromOpenInstall();
      print('是否通过OpenInstall安装: $isFromOpenInstall');
      
      if (isFromOpenInstall) {
        // 获取邀请码
        final inviteCode = await OpenInstallService.getInviteCode();
        if (inviteCode != null) {
          print('检测到邀请码: $inviteCode');
        } else {
          print('未检测到邀请码');
        }
        
        // 获取缓存的邀请码
        final cachedInviteCode = await OpenInstallService.getCachedInviteCode();
        print('缓存的邀请码: $cachedInviteCode');
      }
    } catch (e) {
      print('检查邀请码失败: $e');
    }
  }
  
  /// 示例4: 获取OpenInstall的完整参数信息
  static Future<void> getOpenInstallParams() async {
    try {
      final params = await OpenInstallService.getInstallParams();
      if (params != null) {
        print('OpenInstall参数: $params');
        
        // 提取各种信息
        final channelCode = params['channelCode'];
        final bindData = params['bindData'];
        final inviteCode = await OpenInstallService.getInviteCode();
        
        print('渠道代码: $channelCode');
        print('绑定数据: $bindData');
        print('邀请码: $inviteCode');
      } else {
        print('未获取到OpenInstall参数');
      }
    } catch (e) {
      print('获取OpenInstall参数失败: $e');
    }
  }
}
