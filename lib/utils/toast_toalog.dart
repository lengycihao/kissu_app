import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:kissu_app/widgets/dialogs/base_dialog.dart';

class ToastDialog {
  // 显示基本的弹窗（带标题、内容和确认按钮）
  static Future<void> showBasicDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm, {
    double height = 300.0,
  }) {
    return showDialog(
      context: context,
      barrierColor: Color(0xB3000000), // 透明背景
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            height: height, // 设置弹窗的高度
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/kissu_toast_bg.webp'), // 弹窗背景图
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitle(title),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(content, style: TextStyle(color: Colors.black)),
                ),
                _buildSingleButton(onConfirm),
              ],
            ),
          ),
        );
      },
    );
  }

  // 显示标题有图片背景的弹窗（仅支持本地图片）
  static Future<void> showTitleWithImageDialog(
    BuildContext context,
    String title,
    String titleImagePath,
    String content,
    VoidCallback onConfirm, {
    double height = 300.0,
  }) {
    return showDialog(
      context: context,
      barrierColor: Color(0xB3000000),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            height: height, // 设置弹窗的高度
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/kissu_toast_bg.webp'), // 弹窗背景图
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitleWithImage(title, titleImagePath), // 本地图片作为标题背景
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(content, style: TextStyle(color: Colors.black)),
                ),
                _buildSingleButton(onConfirm),
              ],
            ),
          ),
        );
      },
    );
  }

  // 显示带有两个按钮（确认和取消）的弹窗（横向排列）
  static Future<void> showTwoButtonsDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
    VoidCallback onCancel, {
    double height = 300.0,
  }) {
    return showDialog(
      context: context,
      barrierColor: Color(0xB3000000),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            height: height, // 设置弹窗的高度
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/kissu_toast_bg.webp'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitle(title),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(content, style: TextStyle(color: Colors.black)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildButton('取消', onCancel, color: Colors.red),
                    SizedBox(width: 20),
                    _buildButton('确认', onConfirm, color: Colors.green),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 显示竖直排列的两个按钮弹窗（确认和取消）
  static Future<void> showVerticalButtonsDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
    VoidCallback onCancel, {
    double height = 300.0,
  }) {
    return showDialog(
      context: context,
      barrierColor: Color(0xB3000000),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            height: height, // 设置弹窗的高度
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/kissu_toast_bg.webp'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitle(title),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(content, style: TextStyle(color: Colors.black)),
                ),
                Column(
                  children: [
                    _buildButton('确认', onConfirm, color: Colors.green),
                    SizedBox(height: 10),
                    _buildButton('取消', onCancel, color: Colors.red),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 显示带关闭按钮的弹窗（支持富文本）
  static Future<void> showDialogWithCloseButton(
    BuildContext context,
    String title,
    dynamic content, // 可以是String或Widget（如RichText）
    VoidCallback onConfirm, {
    double height = 300.0,
    Function(String)? onLinkTap, // 链接点击回调
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Color(0xB3000000),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.only(top: 20, left: 10, right: 10),
            height: height, // 设置弹窗的高度
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/kissu_toast_bg.webp'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitle(title),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  child: _buildContent(content, onLinkTap),
                ),
                _buildSingleButton(onConfirm, sureStr: "同意并继续"),
                _buildCloseButton(context),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // 出现动画：由小到大，带回弹效果
        final scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut, // 回弹效果
          ),
        );

        // 消失动画：由大到小
        final scaleOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInBack),
        );

        // 透明度动画
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: animation.status == AnimationStatus.reverse
                ? scaleOutAnimation
                : scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }

  // 第一次登录弹窗
  static Future<void> showDialogWithCloseButtonWithFirst(
    BuildContext context,
    String title,
    dynamic content, // 可以是String或Widget（如RichText）
    VoidCallback onConfirm, {
    double height = 340.0,
    Function(String)? onLinkTap, // 链接点击回调
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Color(0xB3000000),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.only(top: 20, left: 10, right: 10),
            height: height, // 设置弹窗的高度
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/kissu_privacy_bg.webp'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // _buildTitle(title),
                SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  child: _buildContent(content, onLinkTap),
                ),
                // _buildSingleButton(onConfirm, sureStr: "同意并继续"),
                // _buildCloseButton(context),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                     
                    DialogButton(
                      text: '暂不同意',
                      width: 100,
                      backgroundImage:
                          'assets/kissu_dialop_common_cancel_bg.webp', // 使用取消背景
                      onTap: () {
                        Navigator.of(context).pop(false); // 返回 false 表示取消
                      },
                    ), DialogButton(
                      text: '同意并继续',
                      width: 100,
                      backgroundImage:
                          'assets/kissu_dialop_common_sure_bg.webp', // 使用确认背景
                      onTap: onConfirm,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // 出现动画：由小到大，带回弹效果
        final scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut, // 回弹效果
          ),
        );

        // 消失动画：由大到小
        final scaleOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInBack),
        );

        // 透明度动画
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: animation.status == AnimationStatus.reverse
                ? scaleOutAnimation
                : scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }

  // 构建内容部分（支持普通文本和富文本）
  static Widget _buildContent(dynamic content, Function(String)? onLinkTap) {
    if (content is Widget) {
      return content;
    } else if (content is String) {
      // 如果是字符串且包含协议关键词，则创建富文本
      if (content.contains('《用户协议》') || content.contains('《隐私政策》')) {
        return _buildRichTextContent(content, onLinkTap);
      } else {
        // 普通文本
        return Text(
          content,
          textAlign: TextAlign.left,
          style: TextStyle(color: Color(0xff333333), fontSize: 14, height: 1.5),
        );
      }
    } else {
      return Text(
        content.toString(),
        textAlign: TextAlign.left,
        style: TextStyle(color: Color(0xff333333), fontSize: 14, height: 1.5),
      );
    }
  }

  // 构建富文本内容（带可点击链接）
  static Widget _buildRichTextContent(
    String content,
    Function(String)? onLinkTap,
  ) {
    final linkColor = Color(0xFFFF7C98); // #FF7C98
    final normalColor = Color(0xff333333);

    List<TextSpan> spans = [];

    // 使用正则表达式匹配《xxx》格式的文本
    final regex = RegExp(r'《([^》]+)》');
    final matches = regex.allMatches(content);

    int lastEnd = 0;

    for (final match in matches) {
      // 添加匹配前的普通文本
      if (match.start > lastEnd) {
        final normalText = content.substring(lastEnd, match.start);
        if (normalText.isNotEmpty) {
          spans.add(
            TextSpan(
              text: normalText,
              style: TextStyle(color: normalColor, fontSize: 14, height: 1.5),
            ),
          );
        }
      }

      // 添加链接文本（包含《》）
      final fullLinkText = match.group(0)!; // 完整的《xxx》
      final linkName = match.group(1)!; // 只有xxx部分

      spans.add(
        TextSpan(
          text: fullLinkText,
          style: TextStyle(
            color: linkColor,
            fontSize: 14,
            height: 1.5,
            // decoration: TextDecoration.underline, // 移除下划线
          ),
          recognizer: onLinkTap != null
              ? (TapGestureRecognizer()..onTap = () => onLinkTap(linkName))
              : null,
        ),
      );

      lastEnd = match.end;
    }

    // 添加最后一段普通文本
    if (lastEnd < content.length) {
      final remainingText = content.substring(lastEnd);
      if (remainingText.isNotEmpty) {
        spans.add(
          TextSpan(
            text: remainingText,
            style: TextStyle(color: normalColor, fontSize: 14),
          ),
        );
      }
    }

    return RichText(
      textAlign: TextAlign.left,
      text: TextSpan(children: spans),
    );
  }

  // 标题部分（无图片背景）
  static Widget _buildTitle(String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      child: Text(
        title,
        style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
      ),
    );
  }

  // 标题部分（有本地图片背景）
  static Widget _buildTitleWithImage(String title, String titleImagePath) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(titleImagePath), // 只支持本地图片
          fit: BoxFit.cover,
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Text(title, style: TextStyle(fontSize: 14, color: Colors.white)),
    );
  }

  // 单个按钮
  static Widget _buildSingleButton(
    VoidCallback onPressed, {
    String sureStr = "确认",
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 45,
        margin: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Color(0xffFF7C98),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            sureStr,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  // 按钮（确认或取消）
  static Widget _buildButton(
    String text,
    VoidCallback onPressed, {
    Color color = Colors.blue,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 120,
        height: 45,
        margin: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  // 关闭按钮
  static Widget _buildCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(
            "放弃登录",

            style: TextStyle(color: Color(0xffD4CECE), fontSize: 12),
          ),
        ),
      ),
    );
  }
}
