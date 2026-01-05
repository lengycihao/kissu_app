import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/model/unbind_reason_model.dart';
import 'package:kissu_app/model/unbind_result.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';

/// 自定义反馈弹窗（根据UI设计）
class CustomFeedbackDialog extends StatefulWidget {
  final List<UnbindReasonModel> reasons;

  const CustomFeedbackDialog({super.key, required this.reasons});

  @override
  State<CustomFeedbackDialog> createState() => _CustomFeedbackDialogState();
}

class _CustomFeedbackDialogState extends State<CustomFeedbackDialog> {
  final TextEditingController _textController = TextEditingController();
  UnbindReasonModel? _selectedReason; // 选中的原因

  @override
  void initState() {
    super.initState();
    // 不设置默认选项，用户必须主动选择
    _selectedReason = null;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// 确认按钮
  void _onConfirm() {
    if (_selectedReason == null) {
      CustomToast.show(Get.context!, '请选择解绑原因');
      return;
    }

    final otherText = _textController.text.trim();

    // 如果选中的原因需要补充说明，输入框必须填写
    if (_selectedReason!.needSupplement && otherText.isEmpty) {
      CustomToast.show(Get.context!, '${_selectedReason!.name}需要补充说明，请填写具体原因');
      return;
    }

    // 返回结果
    Get.back(
      result: UnbindResult(
        reasonId: _selectedReason!.id,
        supplementReason: otherText.isNotEmpty ? otherText : null,
      ),
    );
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

                  const SizedBox(height: 8),
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
                                colors: [Color(0xFFFFB5D5), Color(0xFFFF9DC4)],
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
    final List<Widget> rows = [];
    for (var i = 0; i < widget.reasons.length; i += 2) {
      final leftReason = widget.reasons[i];
      final rightReason = i + 1 < widget.reasons.length
          ? widget.reasons[i + 1]
          : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildReasonOption(
                  leftReason,
                  _selectedReason?.id == leftReason.id,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: rightReason != null
                    ? _buildReasonOption(
                        rightReason,
                        _selectedReason?.id == rightReason.id,
                      )
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  /// 构建单个原因选项
  Widget _buildReasonOption(UnbindReasonModel reason, bool isSelected) {
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
            width: 14,
            height: 14,
            decoration: BoxDecoration(
               
              color: Colors.white,
            ),
            child: isSelected
                ? Image(
                    image: AssetImage(
                      'assets/images/kissu_login_privite_sel.webp',
                    ),
                    width: 12,
                    height: 12,
                    color: Color(0xffFF408D),
                  )
                : Image(
                    image: AssetImage(
                      'assets/images/kissu_login_privite_unsel.webp',
                    ),
                    width: 12,
                    height: 12,
                    color: Color(0xffFF408D),
                  )
          ),
          const SizedBox(width: 6),
          // 选项文字
          Flexible(
            child: Text(
              reason.name,
              style: TextStyle(
                fontSize: 13,
                color: isSelected
                    ? const Color(0xFF333333)
                    : const Color(0xFF666666),
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
  static Future<UnbindResult?> show({
    required List<UnbindReasonModel> reasons,
  }) {
    return Get.dialog<UnbindResult>(
      CustomFeedbackDialog(reasons: reasons),
      barrierDismissible: false,
    );
  }
}
