/// 埋点参数字段名常量定义
/// 统一管理所有埋点参数的字段名，避免硬编码
library;

/// 埋点参数字段名
class AnalyticsParams {
  // ==================== 用户相关参数 ====================
  
  /// 虚拟用户ID（通过设备号生成）
  static const String mockUserId = 'mock_user_id';
  
  /// 用户ID（后台对应的用户ID）
  static const String userId = 'user_id';
  
  // ==================== 页面相关参数 ====================
  
  /// 进入页面时间（格式：年-月-日 时:分:秒）
  static const String pageEnterTime = 'page_enter_time';
  
  /// 页面停留时长（格式：mm:ss）
  static const String pageDuration = 'page_duration';
  
  /// 来源页
  static const String sourcePage = 'source_page';
  
  /// 离开方式
  static const String exitType = 'exit_type';
  
  /// 页面滑动次数
  static const String pageScrollNum = 'page_scroll_num';
  
  // ==================== 点击相关参数 ====================
  
  /// 点击时间（格式：年/月/日 时:分:秒）
  static const String clickTime = 'click_time';
  
  /// 按钮操作
  static const String btnName = 'btn_name';
  
  // ==================== 会员相关参数 ====================
  
  /// 会员状态
  static const String vipStatus = 'vip_status';
  
  /// 会员类型
  static const String memberType = 'member_type';
  
  // ==================== 绑定相关参数 ====================
  
  /// 绑定状态
  static const String bindStatus = 'bind_status';
  
  /// 绑定次数
  static const String bindNum = 'bind_num';
  
  // ==================== 活动相关参数 ====================
  
  /// 参与188活动
  static const String action188 = 'action_188';
  
  // ==================== 登录相关参数 ====================
  
  /// 是否输入
  static const String inputRequired = 'input_required';
  
  /// 发送状态
  static const String sendStatus = 'send_status';
  
  /// 登录状态
  static const String loginStatus = 'login_status';
  
  // ==================== 个人信息相关参数 ====================
  
  /// 性别
  static const String sex = 'sex';
  
  /// 选择的日期
  static const String selectDate = 'select_date';
  
  /// 是否更换头像
  static const String changeAvatar = 'change_avatar';
  
  /// 是否修改昵称
  static const String changeNickname = 'change_nickname';
  
  // ==================== 定位相关参数 ====================
  
  /// 是否设置状态
  static const String setStatus = 'set_status';
  
  // ==================== 足迹相关参数 ====================
  
  /// 头像身份
  static const String avatarName = 'avatar_name';
  
  // ==================== 聊天相关参数 ====================
  
  /// 单方发送消息次数
  static const String sendSum = 'send_sum';
  
  /// 背景名称
  static const String bgName = 'bg_name';
  
  /// 气泡名称
  static const String buddleName = 'buddle_name';
  
  /// 聊天主题名称
  static const String themeName = 'theme_name';
  
  // ==================== 支付相关参数 ====================
  
  /// 支付方式
  static const String payType = 'pay_type';
  
  /// 支付状态
  static const String payStatus = 'pay_status';
  
  /// 支付用时
  static const String payDuration = 'pay_duration';
  
  /// 点击的状态
  static const String clickStatus = 'click_status';
  
  // ==================== 分享相关参数 ====================
  
  /// 分享渠道名称
  static const String shareChannelName = 'share_channel_name';
  
  /// 分享状态
  static const String shareStatus = 'share_status';
  
  // ==================== 其他参数 ====================
  
  /// App图标名称
  static const String logoName = 'logo_name';
  
  /// 导航名称
  static const String navigationName = 'navigation_name';
}

/// 会员状态枚举值
class VipStatusValue {
  static const int notPaid = 0;//未充值会员
  static const int active = 1;//会员中
  static const int expired = 2;//会员已到期
}

/// 绑定状态枚举值
class BindStatusValue {
  static const int notBound = 0;//未绑定
  static const int bound = 1;//已绑定
  static const int unbound = 2;//已解绑
}

/// 188活动参与状态枚举值
class Action188Value {
  static const int participated = 1;//已参与
  static const int notParticipated = 0;//未参与
}

/// 离开方式枚举值
class ExitTypeValue {
  static const int back = 1;//返回
  static const int closeApp = 2;//关闭应用
  static const int toBackground = 3;//到后台
  static const int nextPage = 4;//下一页
}

/// 是/否枚举值
class YesNoValue {
  static const int yes = 1;//是
  static const int no = 0;//否
}

/// 发送状态枚举值
class SendStatusValue {
  static const int success = 1;//成功
  static const int failed = 0;//失败
}

/// 登录状态枚举值
class LoginStatusValue {
  static const int success = 1;//成功
  static const int failed = 0;//失败
}

/// 性别枚举值
class GenderValue {
  static const int defaultMale = 1;//默认男性
  static const int male = 2;//男性
  static const int female = 3;//女性
}

/// 支付方式枚举值
class PayTypeValue {
  static const String apple = 'apple';//苹果支付
  static const String wechat = 'wechat';//微信支付
  static const String alipay = 'alipay';//支付宝支付
}

/// 支付状态枚举值
class PayStatusValue {
  static const int success = 1;//成功
  static const int failed = 0;//失败
  static const int cancelled = 2;//取消
}

/// 分享状态枚举值
class ShareStatusValue {
  static const int success = 1;//成功
  static const int failed = 0;//失败
  static const int notShared = 2;//未分享
  static const int copied = 3;//已复制
}

/// 分享渠道枚举值
class ShareChannelValue {
  static const String wechat = 'wechat';
  static const String qq = 'qq';
  static const String copyLink = 'copy_link';
}

/// 底部导航名称枚举值
class NavigationNameValue {
  static const String location = 'location';
  static const String track = 'track';
  static const String chat = 'chat';
  static const String phoneHistory = 'phone_history';
  static const String mine = 'mine';
}

/// 头像身份枚举值
class AvatarNameValue {
  static const String self = 'self';
  static const String partner = 'partner';
}

/// 功能模块名称枚举值
class FunctionModuleValue {
  static const String realTimeLocation = 'real_time_location';//实时位置
  static const String appUsageRecord = 'app_usage_record';//app使用记录
  static const String phoneHistory = 'phone_history';//用机记录
  static const String track = 'track';//足迹
  static const String hotelAntiSpy = 'hotel_anti_spy';//酒店防偷拍
  static const String personalizedHome = 'personalized_home';//个性化首页
  static const String sensitiveRecord = 'sensitive_record';//敏感记录统计
  static const String changeAppIcon = 'change_app_icon';//更换app图标
}

/// 会员页面支付按钮名称枚举值
class MembershipPayBtnValue {
  static const int payNow = 1;//立即支付
  static const int renewNow = 2;//立即续费
}
