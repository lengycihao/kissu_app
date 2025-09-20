import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kissu_app/utils/agreement_utils.dart';

/// 可复用的富文本组件：协议与隐私为高亮可点
class AgreementRichText extends StatefulWidget {
  final TextAlign textAlign;

  const AgreementRichText({
    super.key,
    this.textAlign = TextAlign.left,
  });

  @override
  State<AgreementRichText> createState() => _AgreementRichTextState();
}

class _AgreementRichTextState extends State<AgreementRichText> {
  late TapGestureRecognizer _agreementTap;
  late TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _agreementTap = TapGestureRecognizer()..onTap = _onAgreementTap;
    _privacyTap = TapGestureRecognizer()..onTap = _onPrivacyTap;
  }

  @override
  void dispose() {
    _agreementTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  void _onAgreementTap() {
    // 使用app内WebView打开用户协议
    AgreementUtils.toUserAgreement();
  }
  
  void _onPrivacyTap() {
    // 使用app内WebView打开隐私政策
    AgreementUtils.toPrivacyAgreement();
  }

  @override
  Widget build(BuildContext context) {
    // 字体大小使用 20.0（Flutter 的逻辑像素），颜色按你的要求
    const normalStyle = TextStyle(fontSize: 14.0, color: Color(0xFF333333), height: 1.7);
    const linkStyle = TextStyle(fontSize: 14.0, color: Color(0xFFFF7C98));

    return RichText(
      textAlign: widget.textAlign,
      text: TextSpan(
        style: normalStyle,
        children: [
          const TextSpan(
            text:
                '我们深知个人信息对您的重要性，我们会根据您使用具体功能的需要，收集必要的用户信息。我们会坚决保障您的信息安全。请您在使用前，仔细阅读',
          ),
          TextSpan(text: '《用户协议》', style: linkStyle, recognizer: _agreementTap),
          const TextSpan(text: ' '),
          TextSpan(text: '《隐私政策》', style: linkStyle, recognizer: _privacyTap),
          const TextSpan(text: '，当您选择同意并继续则表示您已充分阅读、理解并接受前述所有内容。'),
        ],
      ),
    );
  }
}
