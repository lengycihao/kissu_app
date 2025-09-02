import 'package:flutter/material.dart';

class ToastDialog {
  // 显示基本的弹窗（带标题、内容和确认按钮）
  static Future<void> showBasicDialog(BuildContext context, String title, String content, VoidCallback onConfirm, {double height = 300.0}) {
    return showDialog(
      context: context,
      barrierColor: Color(0xB3000000), // 透明背景
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
  static Future<void> showTitleWithImageDialog(BuildContext context, String title, String titleImagePath, String content, VoidCallback onConfirm, {double height = 300.0}) {
    return showDialog(
      context: context,
      barrierColor: Color(0xB3000000),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
  static Future<void> showTwoButtonsDialog(BuildContext context, String title, String content, VoidCallback onConfirm, VoidCallback onCancel, {double height = 300.0}) {
    return showDialog(
      context: context,
      barrierColor: Color(0xB3000000),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
  static Future<void> showVerticalButtonsDialog(BuildContext context, String title, String content, VoidCallback onConfirm, VoidCallback onCancel, {double height = 300.0}) {
    return showDialog(
      context: context,
      barrierColor: Color(0xB3000000),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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

  // 显示带关闭按钮的弹窗
  static Future<void> showDialogWithCloseButton(BuildContext context, String title, String content, VoidCallback onConfirm, {double height = 300.0}) {
    return showDialog(
      context: context,
      barrierColor: Color(0xB3000000),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.only(top: 10),
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
                  padding: const EdgeInsets.all(18.0),
                  child: Text(content, style: TextStyle(color: Color(0xff333333),fontSize: 14),),
                ),
                _buildSingleButton(onConfirm,sureStr: "同意并继续"),
                _buildCloseButton(context),
              ],
            ),
          ),
        );
      },
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
      child: Text(
        title,
        style: TextStyle(fontSize: 14, color: Colors.white),
      ),
    );
  }

  // 单个按钮
  static Widget _buildSingleButton(VoidCallback onPressed,{String sureStr = "确认"}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 45,
        margin: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Color(0xffFF7C98 ),
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
  static Widget _buildButton(String text, VoidCallback onPressed, {Color color = Colors.blue}) {
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
        child:  Center(
          child: Text(
            "放弃登录",
            
            style: TextStyle(color: Color(0xffD4CECE), fontSize: 12),
          ),
        ),
      ),
    );
  }
}
