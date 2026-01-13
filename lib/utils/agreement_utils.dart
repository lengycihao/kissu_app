import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/constants/agreement_constants.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/pages/agreement/agreement_webview_page.dart';
import 'package:kissu_app/network/tools/config/app_configN.dart';

/// 协议跳转工具类
class AgreementUtils {
  /// 跳转到隐私协议
  static void toPrivacyAgreement() {
    try {
      Get.to(
        () => AgreementWebViewPage(
          title: AgreementConstants.privacyAgreementTitle,
          url: AgreementConstants.privacyAgreement,
        ),
        transition: Transition.rightToLeft,
      );
    } catch (e) {
      // 🔥 修复：如果Get.to失败，尝试使用Navigator（可能在Dialog中）
      try {
        final context = Get.context;
        if (context != null && Navigator.of(context).canPop()) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AgreementWebViewPage(
                title: AgreementConstants.privacyAgreementTitle,
                url: AgreementConstants.privacyAgreement,
              ),
            ),
          );
        }
      } catch (e2) {
        // 如果都失败，记录日志但不崩溃
        logError('打开隐私协议页面失败: $e2');
      }
    }
  }

  /// 跳转到用户协议
  static void toUserAgreement() {
    try {
      Get.to(
        () => AgreementWebViewPage(
          title: AgreementConstants.userAgreementTitle,
          url: AgreementConstants.userAgreement,
        ),
        transition: Transition.rightToLeft,
      );
    } catch (e) {
      // 🔥 修复：如果Get.to失败，尝试使用Navigator（可能在Dialog中）
      try {
        final context = Get.context;
        if (context != null && Navigator.of(context).canPop()) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AgreementWebViewPage(
                title: AgreementConstants.userAgreementTitle,
                url: AgreementConstants.userAgreement,
              ),
            ),
          );
        }
      } catch (e2) {
        // 如果都失败，记录日志但不崩溃
        logError('打开用户协议页面失败: $e2');
      }
    }
  }

  /// 跳转到会员协议
  static void toVipAgreement() {
    Get.to(
      () => AgreementWebViewPage(
        title: AgreementConstants.vipAgreementTitle,
        url: AgreementConstants.vipAgreement,
      ),
      transition: Transition.rightToLeft,
    );
  }

  /// 跳转到隐私安全
  static void toPrivacySecurity() {
    Get.to(
      () => AgreementWebViewPage(
        title: AgreementConstants.privacySecurityTitle,
        url: AgreementConstants.privacySecurity,
      ),
      transition: Transition.rightToLeft,
    );
  }

  /// 跳转到位置须知
  static void toLocationNotice() {
    // 根据环境选择对应的URL
    final url = AppConfigN.serverEnvironmentTest
        ? AgreementConstants.locationNoticeTest
        : AgreementConstants.locationNotice;
    
    Get.to(
      () => AgreementWebViewPage(
        title: AgreementConstants.locationNoticeTitle,
        url: url,
      ),
      transition: Transition.rightToLeft,
    );
  }
}
