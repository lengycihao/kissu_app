/// 埋点参数字段名常量定义
/// 统一管理所有埋点参数的字段名，避免硬编码
library;

/// 埋点参数字段名
class AnalyticsParams {
  // ==================== 用户相关参数 ====================
  
  /// 虚拟用户ID（通过设备号生成）
  static const String mockUserId = 'device_id';
  
  /// 用户ID（后台对应的用户ID）
  // static const String userId = 'user_id';
  
  // ==================== 页面相关参数 ====================
  
  /// 进入页面时间（格式：年-月-日 时:分:秒）
  static const String pageEnterTime = 'page_enter_time';
  
  /// 页面停留时长（格式：mm:ss）
  static const String pageDuration = 'page_duration';
  
  /// 来源页
  static const String sourcePage = 'source_page';
  
  /// 来源事件（触发当前页面/弹窗的事件ID）
  static const String sourceEvent = 'source_event';
  
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
  static const String memberType = 'vip_type';
  
  // ==================== 绑定相关参数 ====================
  
  /// 绑定状态
  static const String bindStatus = 'bind_status';

  ///绑定方式
  static const String bindType = 'bind_type';

  ///绑定码
  static const String friendCode = 'friend_code';

  ///绑定错误原因
  static const String errorMsg = 'error_msg';
  
  /// 绑定次数
  static const String bindNum = 'bind_num';
  
  // ==================== 活动相关参数 ====================
  
  /// 参与188活动
  static const String action188 = 'is_check_in';
  
  // ==================== 登录相关参数 ====================
  
  /// 是否输入
  static const String isInput = 'is_input';
  
  /// 发送状态
  static const String sendStatus = 'send_status';
  
  /// 登录状态
  static const String loginStatus = 'login_status';
  
  /// 操作协议（1同意 0不同意）
  static const String operation = 'operation';
  
  // ==================== 个人信息相关参数 ====================
  
  /// 性别
  static const String sex = 'sex';
  
  /// 选择的日期
  static const String selectDate = 'select_date';
  
  /// 是否更换头像
  static const String changeAvatar = 'is_change_avatar';
  
  /// 是否修改昵称
  static const String changeNickname = 'is_change_nickname';
  
  // ==================== 定位相关参数 ====================
  
  /// 是否设置状态
  static const String setStatus = 'is_set_mood';
  
  // ==================== 足迹相关参数 ====================
  
  /// 头像身份
  static const String avatarName = 'is_oneself';
  
  // ==================== 聊天相关参数 ====================
  
  /// 单方发送消息次数
  static const String sendSum = 'send_num';
  
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
  static const String clickStatus = 'vip_type';
  
  // ==================== 分享相关参数 ====================
  
  /// 分享渠道名称
  static const String shareChannelName = 'share_type';
  
  /// 分享状态
  static const String shareStatus = 'share_status';
  
  // ==================== 其他参数 ====================
  
  /// App图标名称
  static const String logoName = 'logo_name';
  
  /// 权限名称
  static const String permissionName = 'permission_name';
  
  /// 权限开启状态
  static const String status = 'status';
  
  /// 导航名称
  static const String navigationName = 'navigation_name';
  
  /// 按钮状态（用于弹窗等）
  static const String btnStatus = 'btn_status';
  
  // ==================== 锁机相关参数 ====================
  
  /// 锁机状态（0=无状态 1=锁机中 2=已解锁）
  static const String lockStatus = 'lock_status';
  
  /// 解锁状态（1=解锁成功 0=解锁失败）
  static const String unlockStatus = 'unlock_status';
  
  /// 来源页面位置（chat/mine）
  static const String previousPage = 'previous_page';
  
  /// 头像身份（足迹页面）
  // static const String isOneself = 'is_oneself';
  
  
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

/// 绑定方式枚举值
class BindTypeValue {
  static const int input = 1;//输入绑定
  static const int scan = 2;//扫码绑定
}

/// 188活动参与状态枚举值
class Action188Value {
  static const int participated = 1;//已参与
  static const int notParticipated = 0;//未参与
}

/// 离开方式枚举值
/// 注意：关闭app(2)已合并到切换到后台(3)，因为关闭app不好处理
class ExitTypeValue {
  static const int back = 1;//返回
  @Deprecated('使用 toBackground 代替，关闭app已合并到切换到后台')
  static const int closeApp = 3;//关闭应用（已合并到后台）
  static const int toBackground = 3;//到后台（包含关闭app）
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
  static const String defaultMale = "默认男";//默认男性
  static const String male = "男";//男性
  static const String female = "女";//女性
}

/// 支付方式枚举值
class PayTypeValue {
  static const int apple = 1;//苹果支付
  static const int wechat = 2;//微信支付

  static const int alipay = 3;//支付宝支付
}


/// 支付按钮枚举值
class PayBtnValue {
  static const String payNow = "立即支付";//立即支付
  static const String payLater = "立即续费";//立即续费
}

/// 支付状态枚举值
class PayStatusValue {
 
  static const int failed = 0;//失败
   static const int success = 1;//成功
  static const int cancelled = 2;//取消
}

/// 分享状态枚举值
class ShareStatusValue {
  
  static const int failed = 0;//失败
  static const int success = 1;//成功
  static const int copied = 2;//已复制
  static const int notShared = 3;//未分享
  static const int cancelled = 4;//取消
}

/// 分享渠道枚举值
class ShareChannelValue {
  static const int wechat = 1;
  static const int qq = 2;
  static const int copyLink = 3;
}

/// 底部导航名称枚举值
class NavigationNameValue {
  static const String location = 'location';//定位
  static const String track = 'track';//足迹
  static const String chat = 'chat';//聊天
  static const String appUse = 'mobile_use';//用机记录
  static const String mine = 'my';//我的
}

/// 头像身份枚举值
class AvatarNameValue {
  static const String self = '自己';
  static const String partner = '另一半';
}

/// 功能模块名称枚举值
class FunctionModuleValue {
  static const String realTimeLocation = '实时定位';//实时定位
  static const String appUsageRecord = 'app使用记录';//app使用记录
  static const String phoneHistory = '用机记录';//用机记录
  static const String track = '足迹';//足迹
  static const String hotelAntiSpy = '酒店防偷拍';//酒店防偷拍
  static const String oneKeyLock = '一键锁机';//个性化首页
  static const String sensitiveRecord = '敏感操作记录';//敏感操作记录
  static const String changeAppIcon = '更换app图标';//更换app图标
}

/// 会员模块按钮名称枚举值
class VipModuleBtnValue {
  static const String bindNow = "立即绑定";//立即绑定
  static const String openVip = "开通会员";//开通会员
  static const String renewVip = "去续费";//去续费
  static const String vipCenter = "会员中心";//会员中心
}

/// 会员页面支付按钮名称枚举值
class MembershipPayBtnValue {
  static const String payNow = "立即支付";//立即支付
  static const String renewNow = "立即续费";//
}
