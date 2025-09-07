import 'package:flutter/material.dart';
import 'package:kissu_app/utils/user_manager.dart';

/// 用户数据使用示例
/// 展示如何在应用的各个页面中使用缓存的用户数据
class UserDataUsageExample {
  
  /// 示例1: 在AppBar中显示用户信息
  static AppBar buildUserAppBar() {
    return AppBar(
      title: Text('欢迎, ${UserManager.displayName}'),
      actions: [
        if (UserManager.isVip)
          const Icon(Icons.star, color: Colors.amber), // VIP标识
        if (UserManager.userAvatar?.isNotEmpty == true)
          CircleAvatar(
            backgroundImage: NetworkImage(UserManager.userAvatar!),
          )
        else
          const CircleAvatar(
            child: Icon(Icons.person),
          ),
      ],
    );
  }

  /// 示例2: 构建用户信息卡片
  static Widget buildUserInfoCard() {
    if (!UserManager.isLoggedIn) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.person_off),
          title: Text('未登录'),
          subtitle: Text('请先登录以查看用户信息'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: UserManager.userAvatar?.isNotEmpty == true
                      ? NetworkImage(UserManager.userAvatar!)
                      : null,
                  child: UserManager.userAvatar?.isEmpty != false
                      ? Text(UserManager.displayName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        UserManager.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        UserManager.userStatusText,
                        style: TextStyle(
                          color: UserManager.isVip ? Colors.amber : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (UserManager.isVip) ...[
                        const SizedBox(height: 4),
                        Text(
                          UserManager.vipStatusText,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('手机号', UserManager.userPhone ?? '未设置'),
            _buildInfoRow('性别', UserManager.genderText),
            _buildInfoRow('生日', UserManager.userBirthday ?? '未设置'),
            _buildInfoRow('地区', UserManager.fullAddress),
            if (UserManager.friendCode?.isNotEmpty == true)
              _buildInfoRow('邀请码', UserManager.friendCode!),
          ],
        ),
      ),
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// 示例3: 检查用户权限
  static Widget buildFeatureWidget() {
    return Column(
      children: [
        if (UserManager.hasPermission('vip_features'))
          const ListTile(
            leading: Icon(Icons.star, color: Colors.amber),
            title: Text('VIP专属功能'),
            subtitle: Text('您可以使用VIP专属功能'),
          )
        else
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.grey),
            title: const Text('VIP专属功能'),
            subtitle: const Text('升级VIP后可使用'),
            onTap: () {
              // 跳转到VIP购买页面
            },
          ),
        
        if (UserManager.needsPerfectInfo)
          ListTile(
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: const Text('完善个人信息'),
            subtitle: const Text('请完善您的个人信息以获得更好的体验'),
            onTap: () {
              // 跳转到个人信息完善页面
            },
          ),
      ],
    );
  }

  /// 示例4: 在网络请求中使用用户Token
  static Map<String, String> buildAuthHeaders() {
    final headers = <String, String>{};
    
    if (UserManager.isLoggedIn && UserManager.userToken?.isNotEmpty == true) {
      headers['Authorization'] = 'Bearer ${UserManager.userToken}';
    }
    
    return headers;
  }

  /// 示例5: 用户状态变化处理
  static void handleUserStatusChange() {
    if (!UserManager.isLoggedIn) {
      // 用户未登录，跳转到登录页
      // Get.offAllNamed('/login');
      return;
    }

    if (UserManager.needsPerfectInfo) {
      // 需要完善信息，显示提示或跳转
      // Get.snackbar('提示', '请完善个人信息');
      return;
    }

    // 用户已登录且信息完整，继续正常流程
  }

  /// 示例6: 调试信息
  static void printUserDebugInfo() {
    final summary = UserManager.getUserSummary();
    print('=== 用户数据摘要 ===');
    summary.forEach((key, value) {
      print('$key: $value');
    });
    print('==================');
  }
}
