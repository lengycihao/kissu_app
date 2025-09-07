// 便捷访问属性
String? get userId, userPhone, userNickname, userAvatar, userToken
int? get userGender  
bool get isVip, isForeverVip
String get displayName, genderText

// 数据管理方法
updateUserInfo()      // 更新完整用户信息
updateUserAvatar()    // 更新头像
updateUserNickname()  // 更新昵称
logout()             // 登出并清除数据
refreshToken()       // 刷新Token
getUserSummary()     // 获取调试信息

// 静态访问用户数据
UserManager.isLoggedIn     // 登录状态
UserManager.displayName    // 显示名称
UserManager.isVip         // VIP状态
UserManager.fullAddress   // 完整地址

// 权限检查
UserManager.hasPermission('vip_features')

// 状态描述
UserManager.userStatusText    // 用户状态文本
UserManager.vipStatusText     // VIP状态文本
UserManager.vipRemainingDays  // VIP剩余天数

// 检查登录状态
if (UserManager.isLoggedIn) {
  // 显示用户昵称
  Text(UserManager.displayName)
  
  // 显示用户头像
  CircleAvatar(
    backgroundImage: NetworkImage(UserManager.userAvatar ?? ''),
  )
  
  // 检查VIP状态
  if (UserManager.isVip) {
    Icon(Icons.star, color: Colors.amber)
  }
}

// 检查功能权限
if (UserManager.hasPermission('vip_features')) {
  // 显示VIP功能
} else {
  // 显示升级提示
}

final headers = <String, String>{};
if (UserManager.userToken?.isNotEmpty == true) {
  headers['Authorization'] = 'Bearer ${UserManager.userToken}';
}

// 在AppBar显示用户信息
AppBar(
  title: Text('欢迎, ${UserManager.displayName}'),
  actions: [
    if (UserManager.isVip) Icon(Icons.star),
  ],
)

// 功能权限控制
Widget buildVipFeature() {
  return UserManager.hasPermission('vip_features')
    ? VipFeatureWidget()
    : UpgradePromptWidget();
}

// 用户状态检查
if (UserManager.needsPerfectInfo) {
  // 提示完善信息
}