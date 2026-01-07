/// 页面ID常量定义（用于 source_page 参数）
/// 对应 api1.md 中的页面ID映射表
library;

/// 页面来源ID
/// 用于标识用户从哪个页面进入当前页面
class PageSourceIds {
  /// 账号在其他设备登录被挤下线
  static const int kickedOut = 9999;
  
  /// 首次进入App的协议弹窗
  static const int agreementDialog = 1000;
  
  /// 登录
  static const int login = 1001;
  
  /// 完善信息
  static const int loginInfo = 1002;
  
  /// 首页
  static const int home = 1003;
  
  /// 消息中心
  static const int messageCenter = 1004;
  
  /// 定位
  static const int location = 1005;
  
  /// 足迹
  static const int track = 1006;
  
  /// 我的页面
  static const int myPage = 1007;
  
  /// 编辑资料
  static const int editProfile = 1008;
  
  /// 绑定页面
  static const int bind = 1009;
  
  /// 充值页面
  static const int recharge = 1010;
  
  /// 账号设置
  static const int accountSettings = 1011;
  
  /// 用机记录
  static const int phoneHistory = 1012;
  
  /// 手机使用记录
  static const int phoneUsage = 1013;
  
  /// app使用统计
  static const int appUsage = 1014;
  
  /// 敏感操作记录
  static const int sensitiveRecords = 1015;
  
  /// 更换App图标页面
  static const int changeAppIcon = 1016;
  
  /// 我的心情
  static const int myMood = 1017;
  
  /// 位置提醒
  static const int locationReminder = 1018;
  
  /// 添加地点
  static const int addLocation = 1019;
  
  /// 更换城市
  static const int changeCity = 1020;
  
  /// 使用须知
  static const int usageGuide = 1021;
  
  /// 视频回放
  static const int videoPlayback = 1022;
  
  /// 聊天
  static const int chat = 1023;
  
  /// 聊天设置
  static const int chatSettings = 1024;
  
  /// 设置聊天背景
  static const int setChatBackground = 1025;
  
  /// 设置聊天气泡
  static const int setChatBubble = 1026;
  
  /// 设置聊天主题
  static const int setChatTheme = 1027;
  
  /// 设置自动报备
  static const int setAutoReport = 1028;
  
  /// 用机记录设置
  static const int phoneHistorySettings = 1029;
  
  /// 权限设置
  static const int permissionSettings = 1030;
  
  /// 酒店防偷拍
  static const int hotelAntiSpy = 1031;
  
  /// 常见问题
  static const int faq = 1032;
  
  /// 意见反馈
  static const int feedback = 1033;
  
  /// 关于我们
  static const int aboutUs = 1034;
  
  /// 隐私政策
  static const int privacyPolicy = 1035;
  
  /// 用户协议
  static const int userAgreement = 1036;
  
  /// 个人信息收集清单
  static const int personalInfoCollection = 1037;
  
  /// 第三方信息共享清单
  static const int thirdPartyInfoSharing = 1038;
}
