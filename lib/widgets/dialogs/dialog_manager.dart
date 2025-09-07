import 'package:flutter/material.dart';
import 'confirm_dialog.dart';
import 'gender_select_dialog.dart';
import 'input_dialog.dart';
import 'bind_confirm_dialog.dart';
import 'vip_dialog.dart';

/// 导出所有弹窗组件
export 'base_dialog.dart';
export 'confirm_dialog.dart';
export 'gender_select_dialog.dart';
export 'input_dialog.dart';
export 'bind_confirm_dialog.dart';
export 'vip_dialog.dart';

/// 弹窗管理器
class DialogManager {
  DialogManager._();

  /// 显示通用确认弹窗
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    String? content,
    String? subContent,
    String confirmText = '确定',
    String? cancelText = '取消',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool showCancel = true,
    bool barrierDismissible = true,
  }) {
    return ConfirmDialog.show(
      context: context,
      title: title,
      content: content,
      subContent: subContent,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      showCancel: showCancel,
      barrierDismissible: barrierDismissible,
    );
  }

  /// 显示退出登录确认弹窗
  static Future<bool?> showLogoutConfirm(BuildContext context) {
    return LogoutConfirmDialog.show(context);
  }

  /// 显示手机号更改确认弹窗
  static Future<bool?> showPhoneChangeConfirm(
    BuildContext context,
    String phoneNumber,
  ) {
    return PhoneChangeConfirmDialog.show(context, phoneNumber);
  }

  /// 显示解除关系确认弹窗
  static Future<bool?> showUnbindConfirm(BuildContext context) {
    return UnbindConfirmDialog.show(context);
  }

  /// 显示性别选择弹窗
  static Future<String?> showGenderSelect({
    required BuildContext context,
    String? selectedGender,
    Function(String gender)? onGenderSelected,
  }) {
    return GenderSelectDialog.show(
      context: context,
      selectedGender: selectedGender,
      onGenderSelected: onGenderSelected,
    );
  }

  /// 显示输入框弹窗
  static Future<String?> showInput({
    required BuildContext context,
    required String title,
    String? hintText,
    String? initialValue,
    String confirmText = '确定',
    Function(String value)? onConfirm,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return InputDialog.show(
      context: context,
      title: title,
      hintText: hintText,
      initialValue: initialValue,
      confirmText: confirmText,
      onConfirm: onConfirm,
      maxLength: maxLength,
      keyboardType: keyboardType,
    );
  }

  /// 显示昵称输入弹窗
  static Future<String?> showNicknameInput(
    BuildContext context, {
    String? currentNickname,
  }) {
    return NicknameInputDialog.show(context, currentNickname: currentNickname);
  }

  /// 显示绑定确认弹窗
  static Future<bool?> showBindConfirm({
    required BuildContext context,
    required String title,
    required String content,
    String? subContent,
    String confirmText = '确认绑定',
    VoidCallback? onConfirm,
    String? userAvatar1,
    String? userAvatar2,
  }) {
    return BindConfirmDialog.show(
      context: context,
      title: title,
      content: content,
      subContent: subContent,
      confirmText: confirmText,
      onConfirm: onConfirm,
      userAvatar1: userAvatar1,
      userAvatar2: userAvatar2,
    );
  }

  /// 显示情侣绑定确认弹窗
  static Future<bool?> showCoupleBindConfirm(
    BuildContext context, {
    String? userAvatar1,
    String? userAvatar2,
  }) {
    return CoupleBindConfirmDialog.show(
      context,
      userAvatar1: userAvatar1,
      userAvatar2: userAvatar2,
    );
  }

  /// 显示VIP弹窗
  static Future<void> showVip({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? content,
    String buttonText = '继续观看',
    VoidCallback? onButtonTap,
    bool showFireEffect = true,
  }) {
    return VipDialog.show(
      context: context,
      title: title,
      subtitle: subtitle,
      content: content,
      buttonText: buttonText,
      onButtonTap: onButtonTap,
      showFireEffect: showFireEffect,
    );
  }

  /// 显示"再看30秒得会员"弹窗
  static Future<void> showVipWatchMore(BuildContext context) {
    return VipDialogPresets.showWatchMoreDialog(context);
  }

  /// 显示"再看2个视频得全天免费会员"弹窗
  static Future<void> showVipWatchVideos(BuildContext context) {
    return VipDialogPresets.showWatchVideosDialog(context);
  }

  /// 显示"恭喜你完成了今天任务"弹窗
  static Future<void> showVipTaskComplete(BuildContext context) {
    return VipDialogPresets.showTaskCompleteDialog(context);
  }

  /// 显示"恭喜成功开通会员"弹窗
  static Future<void> showVipSuccess(BuildContext context) {
    return VipDialogPresets.showVipSuccessDialog(context);
  }
}
