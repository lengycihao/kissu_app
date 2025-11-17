class ApiRequest {
  static const authLoginByCode = '/user/login';

  static const phoneCode = '/get/code';

  static const logout = '/drop/out';

  static const updateUserInfo = '/user/update';

  static const getUserInfo = '/get/user';

  static const problemList = '/problem/list';

  static const changePhone = '/change/phone';

  static const bindPartner = '/start/bind';

  static const saveOaidIdfa = '/user/saveOaidIdfa';

  static const getLocation = '/get/location';

  static const reportLocation = '/location/report';

  // VIP 相关 API
  static const vipPackageList = '/get/vipPackageList?os=1';
  static const wxPay = '/pay/wxPay';
  static const aliPay = '/pay/aliPay';
  static const vipIconBanner = '/pay/iconBanner';
  
  // 敏感数据上报 API
  static const sensitiveDataReport = '/v3/reporting/sensitive/record';
  
  // 系统通知 API
  static const systemNotice = '/system/notice';
  
  // 互动消息 API
  static const interactionNotice = '/interaction/notice';
  
  // 消息中心绑定相关 API
  static const affirmBind = '/affirm/bind';
  static const refuseBind = '/refuse/bind';
  
    
  // 状态表情相关 API
  static const getFaceStatus = '/get/face';
  static const setFaceStatus = '/save/face';
  static const deleteFaceStatus = '/del/face';
  
  // 位置提醒（地理围栏）相关 API
  static const getGeofencing = '/get/geofencing';
  static const saveGeofencing = '/save/geofencing';
  static const updateGeofencing = '/update/geofencing';
  static const deleteGeofencing = '/del/geofencing';
  
  // 版本检查 API
  static const checkVersion = '/version/checkVersion';
  
  // 用机记录 API
  static const getSensitiveRecord = '/v2/get/sensitive/record';
  static const getMobileUsageRecordSta = '/v4/mobileUsage/recordSta';
  
  // 照片墙 API
  static const savePhotoWall = '/save/photo/wall';
  
  // 解绑关系相关 API
  static const unbindReasonSelect = '/unbind/reasonSelect';
  static const unbind = '/unbind';
}
