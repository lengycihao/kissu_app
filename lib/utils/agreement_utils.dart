import 'package:get/get.dart';
import 'package:kissu_app/constants/agreement_constants.dart';
import 'package:kissu_app/pages/agreement/agreement_webview_page.dart';

/// 协议跳转工具类
class AgreementUtils {
  /// 跳转到隐私协议
  static void toPrivacyAgreement() {
    Get.to(() => AgreementWebViewPage(
      title: AgreementConstants.privacyAgreementTitle,
      url: AgreementConstants.privacyAgreement,
    ));
  }

  /// 跳转到用户协议
  static void toUserAgreement() {
    Get.to(() => AgreementWebViewPage(
      title: AgreementConstants.userAgreementTitle,
      url: AgreementConstants.userAgreement,
    ));
  }

  /// 跳转到会员协议
  static void toVipAgreement() {
    Get.to(() => AgreementWebViewPage(
      title: AgreementConstants.vipAgreementTitle,
      url: AgreementConstants.vipAgreement,
    ));
  }

  /// 跳转到隐私安全
  static void toPrivacySecurity() {
    Get.to(() => AgreementWebViewPage(
      title: AgreementConstants.privacySecurityTitle,
      url: AgreementConstants.privacySecurity,
    ));
  }
}
