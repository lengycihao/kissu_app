/// 协议链接常量
class AgreementConstants {
  // 协议基础URL
  static const String _baseUrl = 'https://www.ikissu.cn/agreement';
  static const String _devBaseUrl = 'http://devweb.ikissu.cn/agreement';

  // 各种协议链接
  static const String privacyAgreement = '$_baseUrl/privacy.html';
  static const String userAgreement = '$_baseUrl/user.html';
  static const String vipAgreement = '$_baseUrl/vip.html';
  static const String privacySecurity = '$_baseUrl/privacyView.html';
  
  // 位置须知链接
  static const String locationNotice = '$_baseUrl/locationNotice.html';
  static const String locationNoticeTest = '$_devBaseUrl/locationNotice.html';

  // 协议标题
  static const String privacyAgreementTitle = '隐私协议';
  static const String userAgreementTitle = '用户协议';
  static const String vipAgreementTitle = '会员协议';
  static const String privacySecurityTitle = '隐私安全';
  static const String locationNoticeTitle = '使用须知';
}
