import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 删除位置提醒弹窗
class DeleteLocationReminderDialog extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String? title;
  final String? content;

  const DeleteLocationReminderDialog({
    Key? key,
    this.onConfirm,
    this.onCancel,
    this.title,
    this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 270,
        height: 255,
        margin: EdgeInsets.only(bottom: 100),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/location/kissu3_state_delete_bg.webp'),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.all(Radius.circular(25)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 20,right: 20,top: 125,bottom: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 标题
              Text(
                title ?? '确定要删除吗？',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 内容
              Text(
                content ?? '删除数据后将无法恢复数据，请谨慎操作！',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                  height: 1.7,
                ),
              ),
              
              const SizedBox(height: 18),
              
              // 按钮区域
              Row(
                children: [
                  // 取消按钮
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.back(result: false);
                        onCancel?.call();
                      },
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF999999),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '取消',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF999999),
                           ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 15),
                  
                  // 确认按钮
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.back(result: true);
                        onConfirm?.call();
                      },
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(0xFFFFA9E0),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '确认',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                           ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 显示删除位置提醒弹窗
class DeleteLocationReminderDialogUtil {
  /// 显示删除位置提醒弹窗
  static Future<bool?> show({
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    String title = "确定要删除吗？",
    String content = "删除数据后将无法恢复数据，请谨慎操作！",
  }) {
    return Get.dialog<bool>(
      DeleteLocationReminderDialog(
        onConfirm: onConfirm,
        onCancel: onCancel,
        title: title,
        content: content,
      ),
      barrierDismissible: false,
    );
  }
}

