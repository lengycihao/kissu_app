import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/oktoast_util.dart';

/// 自定义题目弹窗
class CustomTopicDialog extends StatefulWidget {
  final void Function(String answer, String description) onConfirm;

  const CustomTopicDialog({super.key, required this.onConfirm});

  @override
  State<CustomTopicDialog> createState() => _CustomTopicDialogState();
}

class _CustomTopicDialogState extends State<CustomTopicDialog> {
  final _answerController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Center(
        child: SingleChildScrollView(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              margin: const EdgeInsets.symmetric(vertical: 50),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFE4EC), Colors.white],
                  stops: [0.0, 0.4],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              // 标题 + 关闭按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const Text(
                    '添加题目',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.close, size: 20, color: Color(0xFFaaaaaa)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 题目输入
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('题目', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              ),
              const SizedBox(height: 16),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: _answerController,
                  maxLength: 5,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(5),
                  ],
                  decoration: const InputDecoration(
                    hintText: '请输入题目(2-5个字)',
                    hintStyle: TextStyle(fontSize: 14, color: Color(0xFFaaaaaa)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    isDense: true,
                    counterText: '',
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),

              // 描述输入
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('描述', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              ),
              const SizedBox(height: 16),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: _descController,
                  maxLength: 5,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(5),
                  ],
                  decoration: const InputDecoration(
                    hintText: '描述词不能包含答案任一个字',
                    hintStyle: TextStyle(fontSize: 14, color: Color(0xFFaaaaaa)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    isDense: true,
                    counterText: '',
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),

              // 完成按钮
              GestureDetector(
                onTap: () {
                  final answer = _answerController.text.trim();
                  final desc = _descController.text.trim();
                  
                  if (answer.isEmpty || answer.length < 2) {
                    OKToastUtil.showError('题目至少需要2个字');
                    return;
                  }
                  if (answer.length > 5) {
                    OKToastUtil.showError('题目最多5个字');
                    return;
                  }
                  if (desc.isNotEmpty && desc.length < 1) {
                    OKToastUtil.showError('描述至少需要1个字');
                    return;
                  }
                  if (desc.length > 5) {
                    OKToastUtil.showError('描述最多5个字');
                    return;
                  }
                  
                  widget.onConfirm(answer, desc);
                  Get.back();
                },
                child: Container(
                  width: double.infinity,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA9E0),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Center(
                    child: Text(
                      '完成',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
