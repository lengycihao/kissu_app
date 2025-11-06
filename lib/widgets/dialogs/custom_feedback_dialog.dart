import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 自定义反馈弹窗（根据UI设计）
class CustomFeedbackDialog extends StatefulWidget {
  const CustomFeedbackDialog({super.key});

  @override
  State<CustomFeedbackDialog> createState() => _CustomFeedbackDialogState();
}

class _CustomFeedbackDialogState extends State<CustomFeedbackDialog> {
  final TextEditingController _textController = TextEditingController();
  String? _selectedReason; // 选中的原因
  
  final List<String> _reasons = [
    '两人已分手',
    '用户隐私安全',
    'App功能单一',
    'App bug多',
    'App体验不好',
    '页面不美观',
    '其他原因',
  ];

  @override
  void initState() {
    super.initState();
    // 默认选中第一个
    _selectedReason = _reasons[0];
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// 确认按钮
  void _onConfirm() {
    final otherText = _textController.text.trim();
    
    // 如果选择了"其他原因"，输入框必须填写
    if (_selectedReason == '其他原因' && otherText.isEmpty) {
      Get.snackbar(
        '提示',
        '选择其他原因时，请填写具体原因',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
      return;
    }
    
    // 返回结果
    String result = _selectedReason ?? '';
    if (otherText.isNotEmpty) {
      result = '$result: $otherText';
    }
    Get.back(result: result);
  }

  /// 取消按钮
  void _onCancel() {
    Get.back(result: null);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = screenSize.width * 0.85; // 最大宽度为屏幕宽度的85%
    final dialogWidth = maxWidth > 320 ? 320.0 : maxWidth; // 在320和最大宽度之间选择较小值

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.8, // 最大高度为屏幕高度的80%
          maxWidth: dialogWidth,
        ),
        child: Container(
          width: dialogWidth,
          decoration: const BoxDecoration(
            // 使用和解除关系弹窗一样的背景图片
            image: DecorationImage(
              image: AssetImage('assets/3.0/kissu3_dialog_jiechu_bg.webp'),
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  const Center(
                    child: Text(
                      '解除关系提示',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 内容描述
                  const Text(
                    '我们尝努力让两颗心的信号同频。如今信号减弱，我们深感惋惜。若你愿意，可告诉我们，是哪个频率出现了杂音？',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 选项列表
                  ..._buildReasonOptions(),

                  const SizedBox(height: 16),

                  // 其他原因输入框（一直显示）
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                        hintText: '若有其他原因，可在这里补充',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFCCCCCC),
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
                      // 解除按钮（灰色边框）
                      Expanded(
                        child: GestureDetector(
                          onTap: _onConfirm,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFCCCCCC),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                              child: Text(
                                '解除',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // 取消按钮（粉色填充）
                      Expanded(
                        child: GestureDetector(
                          onTap: _onCancel,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFFB5D5),
                                  Color(0xFFFF9DC4),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                              child: Text(
                                '取消',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
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
        ),
      ),
    );
  }

  /// 构建原因选项列表
  List<Widget> _buildReasonOptions() {
    return _reasons.asMap().entries.map((entry) {
      final index = entry.key;
      final reason = entry.value;
      final isSelected = _selectedReason == reason;

      // 每两个选项一行
      if (index % 2 == 0) {
        final nextReason = index + 1 < _reasons.length ? _reasons[index + 1] : null;
        final isNextSelected = _selectedReason == nextReason;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              // 左侧选项
              Expanded(
                child: _buildReasonOption(reason, isSelected),
              ),
              const SizedBox(width: 12),
              // 右侧选项（如果存在）
              Expanded(
                child: nextReason != null
                    ? _buildReasonOption(nextReason, isNextSelected)
                    : const SizedBox(),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }).toList();
  }

  /// 构建单个原因选项
  Widget _buildReasonOption(String reason, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReason = reason;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 单选圆圈
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFFFF9DC4) : const Color(0xFFDDDDDD),
                width: 2,
              ),
              color: Colors.white,
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF9DC4),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          // 选项文字
          Flexible(
            child: Text(
              reason,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? const Color(0xFF333333) : const Color(0xFF666666),
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 显示自定义反馈弹窗工具类
class CustomFeedbackDialogUtil {
  /// 显示自定义反馈弹窗
  static Future<String?> show() {
    return Get.dialog<String>(
      const CustomFeedbackDialog(),
      barrierDismissible: false,
    );
  }
}

