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
  
  /// 按钮名称
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
  static const String notPaid = '未充值会员';
  static const String active = '会员中';
  static const String expired = '会员已到期';
}

/// 绑定状态枚举值
class BindStatusValue {
  static const String notBound = '未绑定';
  static const String bound = '已绑定';
  static const String unbound = '已解绑';
}

/// 188活动参与状态枚举值
class Action188Value {
  static const String participated = '已参与';
  static const String notParticipated = '未参与';
}

/// 离开方式枚举值
class ExitTypeValue {
  static const String back = '返回';
  static const String closeApp = '关闭App';
  static const String toBackground = '切换到后台';
  static const String nextPage = '进入下一页';
}

/// 是/否枚举值
class YesNoValue {
  static const String yes = '是';
  static const String no = '否';
}

/// 发送状态枚举值
class SendStatusValue {
  static const String success = '成功';
  static const String failed = '失败';
}

/// 登录状态枚举值
class LoginStatusValue {
  static const String success = '成功';
  static const String failed = '失败';
}

/// 性别枚举值
class GenderValue {
  static const String defaultMale = '默认男性';
  static const String male = '男性';
  static const String female = '女性';
}

/// 支付方式枚举值
class PayTypeValue {
  static const String apple = '苹果';
  static const String wechat = '微信';
  static const String alipay = '支付宝';
}

/// 支付状态枚举值
class PayStatusValue {
  static const String success = '支付成功';
  static const String failed = '支付失败';
  static const String cancelled = '用户取消';
}

/// 分享状态枚举值
class ShareStatusValue {
  static const String success = '分享成功';
  static const String failed = '分享失败';
  static const String notShared = '未分享';
  static const String copied = '复制成功';
}

/// 分享渠道枚举值
class ShareChannelValue {
  static const String wechat = '微信';
  static const String qq = 'QQ';
  static const String copyLink = '复制链接';
}

/// 底部导航名称枚举值
class NavigationNameValue {
  static const String location = '定位';
  static const String track = '足迹';
  static const String chat = '聊天';
  static const String phoneHistory = '用机记录';
  static const String mine = '我的';
}

/// 头像身份枚举值
class AvatarNameValue {
  static const String self = '本人头像';
  static const String partner = 'Ta的头像';
}

/// 功能模块名称枚举值
class FunctionModuleValue {
  static const String realTimeLocation = '实时定位';
  static const String appUsageRecord = 'app使用记录';
  static const String phoneHistory = '用机记录';
  static const String track = '足迹';
  static const String hotelAntiSpy = '酒店防偷拍';
  static const String personalizedHome = '个性化首页';
  static const String sensitiveRecord = '敏感记录统计';
  static const String changeAppIcon = '更换app图标';
}
