import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnswerDialog extends StatefulWidget {
  final int remainingAttempts;
  final Function(String) onSubmit;

  const AnswerDialog({
    super.key,
    required this.remainingAttempts,
    required this.onSubmit,
  });

  @override
  State<AnswerDialog> createState() => _AnswerDialogState();
}

class _AnswerDialogState extends State<AnswerDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final answer = _controller.text.trim();
    if (answer.isEmpty) return;
    Navigator.of(context).pop();
    widget.onSubmit(answer);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 270,
        height: 245,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/say_guess/kissu_say_guess_answer_dialog.webp'),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // 标题
            const Text(
              '填写答案',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            // 剩余次数提示
            Text(
              '还有${widget.remainingAttempts}次机会呦~',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFaaaaaa),
              ),
            ),
            const SizedBox(height: 20),
            // 输入框
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _controller,
                      textAlign: TextAlign.center,
                      maxLength: 5,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(5),
                      ],
                      decoration: const InputDecoration(
                        hintText: '',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFCCCCCC),
                        ),
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: (_) => _handleSubmit(),
                    ),
                  ),
                  // 字数统计
                  Positioned(
                    right: 16,
                    child: ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (context, value, child) {
                        return Text(
                          '${value.text.length}/5',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF333333),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // 确认按钮
            GestureDetector(
              onTap: _handleSubmit,
              child: Container(
                width: 180,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xffFF90CA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    '确认',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
