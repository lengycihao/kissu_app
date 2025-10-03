import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';

/// 解除关系提示弹窗
class UnbindRelationshipDialog extends StatefulWidget {
  const UnbindRelationshipDialog({super.key});

  @override
  State<UnbindRelationshipDialog> createState() => _UnbindRelationshipDialogState();
}

class _UnbindRelationshipDialogState extends State<UnbindRelationshipDialog> {
  final TextEditingController _textController = TextEditingController();
  final String _requiredText = '我确认解除当前关系，如出现任何因我解除产生的问题，我也愿意承担';
  
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// 获取三天后的日期
  String _getThreeDaysLaterDate() {
    final now = DateTime.now();
    final threeDaysLater = now.add(const Duration(days: 3));
    return '${threeDaysLater.year}年${threeDaysLater.month}月${threeDaysLater.day}号';
  }

  /// 确认解除关系
  void _confirmUnbind() {
    final inputText = _textController.text.trim();
    if (inputText == _requiredText) {
      Get.back(result: true);
    } else {
      CustomToast.show(
        Get.context!,
        '请准确输入以上确认解除关系文字',
      );
    }
  }

  /// 取消解除
  void _cancelUnbind() {
    Get.back(result: false);
  }

  @override
  Widget build(BuildContext context) {
    final threeDaysLaterDate = _getThreeDaysLaterDate();
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/3.0/kissu3_dialog_jiechu_bg.webp'),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 标题
              const Text(
                '解除关系提示',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 副标题
              const Text(
                '双方账号绑定期间的回忆来之不易',
                style: TextStyle(
                  fontSize: 14,fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 内容
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(text: '点击确认解除后，双方的Kissu账号将会立即解除关系\n\n'),
                    const TextSpan(text: '但是双方数据将会被保存'),
                    TextSpan(
                      text: '3日($threeDaysLaterDate)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF408D),
                      ),
                    ),
                    const TextSpan(text: '，在此期间重新绑定数据将会恢复，3日后双方数据将会被删除\n'),
                    const TextSpan(text: '如在此期间，双方任一方选择绑定其他用户则双方数据也将会被提前删除'),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 确认文字提示
              RichText(
                
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF333333),height: 1.6,
                  ),
                  children: [
                      TextSpan(text: '确认解除关系，请在下方输入框输入以下文字', style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),),
                    TextSpan(
                      text: _requiredText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF408D),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 输入框
              Container(
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                    hintText: '请输入',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 按钮区域
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 我再想想按钮
                  GestureDetector(
                    onTap: _cancelUnbind,
                    child: Container(
                      width: 106,
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF999999),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Text(
                          '我再想想',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // 确认解除按钮
                  GestureDetector(
                    onTap: _confirmUnbind,
                    child: Container(
                      width: 106,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9DC4),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Text(
                          '确认解除',
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

/// 显示解除关系提示弹窗
class UnbindRelationshipDialogUtil {
  /// 显示解除关系提示弹窗
  static Future<bool?> showUnbindRelationshipDialog() {
    return Get.dialog<bool>(
      const UnbindRelationshipDialog(),
      barrierDismissible: false,
    );
  }
}
