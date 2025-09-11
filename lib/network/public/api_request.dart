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

  // VIP 相关 API
  static const vipPackageList = '/get/vipPackageList';
  static const wxPay = '/pay/wxPay';
  static const aliPay = '/pay/aliPay';
}
