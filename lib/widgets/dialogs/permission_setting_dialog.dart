import 'package:flutter/material.dart';

/// 权限请求说明弹窗
class PermissionSettingDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onContinue;
  final VoidCallback? onCancel;

  const PermissionSettingDialog({
    super.key,
    required this.title,
    required this.content,
    this.onContinue,
    this.onCancel,
  });

  /// 显示相机权限请求弹窗
  static Future<bool?> showPermissionSettingDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionSettingDialog(
        title: '权限开启提醒',
        content: '建议开启所有权限，否则会导致本人或对方数据显示异常',
        onContinue: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 主弹窗容器
          Container(
            width: 270,
            height: 183,
            padding: EdgeInsets.symmetric(horizontal: 15),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/kissu_permission_bg.webp'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题区域
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // 内容区域
               Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
SizedBox(height: 20,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        width: 106,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(0xffffffff),
                          border: Border.all(
                            width: 1,
                            color: Color(0xff999999),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            "稍后开启",
                            style: TextStyle(color: Color(0xff999999)),
                          ),
                        ),
                      ),
                    ),
                    // 继续按钮区域
                    SizedBox(
                      width: 106,
                      height: 36,
                      child: ElevatedButton(
                        onPressed: onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA9E0), // 新的按钮颜色
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          '知道了',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xffffffff),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
 
        ],
      ),
    );
  }
}
