class ApiRequest {
  static const authLoginByCode = '/user/login';

  static const phoneCode = '/get/code';

  static const logout = '/drop/out';

  static const updateUserInfo = '/user/update';

  static const getUserInfo = '/get/user';

  static const problemList = '/problem/list';

  static const changePhone = '/change/phone';

  static const bindPartner = '/start/bind';

  static const getLocation = '/get/location';

  static const reportLocation = '/location/report';

  // VIP 相关 API
  static const vipPackageList = '/get/vipPackageList?os=1';
  static const wxPay = '/pay/wxPay';
  static const aliPay = '/pay/aliPay';
  static const vipIconBanner = '/pay/iconBanner';
  
  // 敏感数据上报 API
  static const sensitiveDataReport = '/reporting/sensitive/record';
  
  // 系统通知 API
  static const systemNotice = '/system/notice';
  
  // 消息中心绑定相关 API
  static const affirmBind = '/affirm/bind';
  static const refuseBind = '/refuse/bind';
}
