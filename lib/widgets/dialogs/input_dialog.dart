import 'package:flutter/material.dart';
import 'base_dialog.dart';

/// 输入框弹窗
class InputDialog extends BaseDialog {
  final String title;
  final String? hintText;
  final String? initialValue;
  final String confirmText;
  final Function(String value)? onConfirm;
  final int? maxLength;
  final TextInputType? keyboardType;

  const InputDialog({
    Key? key,
    required this.title,
    this.hintText,
    this.initialValue,
    this.confirmText = '确定',
    this.onConfirm,
    this.maxLength,
    this.keyboardType,
  }) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    return _InputDialogContent(
      title: title,
      hintText: hintText,
      initialValue: initialValue,
      confirmText: confirmText,
      onConfirm: onConfirm,
      maxLength: maxLength,
      keyboardType: keyboardType,
    );
  }

  /// 显示输入框弹窗
  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? hintText,
    String? initialValue,
    String confirmText = '确定',
    Function(String value)? onConfirm,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return BaseDialog.show<String>(
      context: context,
      dialog: InputDialog(
        title: title,
        hintText: hintText,
        initialValue: initialValue,
        confirmText: confirmText,
        onConfirm: onConfirm,
        maxLength: maxLength,
        keyboardType: keyboardType,
      ),
    );
  }
}

class _InputDialogContent extends StatefulWidget {
  final String title;
  final String? hintText;
  final String? initialValue;
  final String confirmText;
  final Function(String value)? onConfirm;
  final int? maxLength;
  final TextInputType? keyboardType;

  const _InputDialogContent({
    Key? key,
    required this.title,
    this.hintText,
    this.initialValue,
    required this.confirmText,
    this.onConfirm,
    this.maxLength,
    this.keyboardType,
  }) : super(key: key);

  @override
  State<_InputDialogContent> createState() => _InputDialogContentState();
}

class _InputDialogContentState extends State<_InputDialogContent> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DialogContainer(
      backgroundImage: 'assets/kissu_dialog_sex_bg.webp',
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 20),
          // 输入框
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: _controller,
              maxLength: widget.maxLength,
              keyboardType: widget.keyboardType,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFFCCCCCC),
                ),
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 25),
          // 确定按钮
          DialogButton(
            text: widget.confirmText,
            backgroundImage: 'assets/kissu_dialop_common_sure_bg.webp',
            onTap: () {
              final value = _controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(context).pop(value);
                widget.onConfirm?.call(value);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// 昵称输入弹窗
class NicknameInputDialog {
  static Future<String?> show(BuildContext context, {String? currentNickname}) {
    return InputDialog.show(
      context: context,
      title: '请输入您的昵称',
      hintText: '最多8个字',
      initialValue: currentNickname,
      confirmText: '确定',
      maxLength: 8,
    );
  }
}
