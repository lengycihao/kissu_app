import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kissu_app/constants/app_constants.dart';
import 'package:kissu_app/model/unbind_reason_model.dart';
import 'package:kissu_app/model/unbind_result.dart';
import 'package:kissu_app/utils/source_page_utils.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/utils/agreement_utils.dart';
import 'package:kissu_app/utils/permission_helper.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/analytics/analytics_manager.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/services/analytics/analytics_params.dart';

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
  bool _showInputError = false; // 是否显示输入框错误状态

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
      setState(() {
        _showInputError = true;
      });
      CustomToast.show(Get.context!, '请输入原因');
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

  /// 显示隐私安全提示弹窗
  void _showPrivacySecurityDialog() {
    final reasons = widget.reasons;

    // 先关闭当前弹窗
    Get.back();

    // 显示隐私安全弹窗
    Get.dialog<bool>(
      PrivacySecurityDialog(
        onKnow: () {
          // 关闭隐私弹窗
          Get.back();
          // 重新显示原弹窗
          CustomFeedbackDialogUtil.show(reasons: reasons);
        },
        onViewDetail: () {
          // 跳转H5，弹窗不消失
          AgreementUtils.toPrivacySecurity();
        },
      ),
      barrierDismissible: false,
    );
  }

  /// 显示VIP挽留弹窗
  void _showVipRetentionDialog() {
    // 保存当前选择的原因和输入内容
    final reasons = widget.reasons;

    // 先关闭当前弹窗
    Get.back();

    // 显示VIP挽留弹窗
    Get.dialog<bool>(
      VipRetentionDialog(
        onClose: () {
          // 关闭VIP弹窗
          Get.back();
          // 重新显示原弹窗
          CustomFeedbackDialogUtil.show(reasons: reasons);
        },
        onClaim: () {
          // 领取按钮点击，关闭所有弹窗并跳转到VIP页面
          Get.back(); // 关闭VIP挽留弹窗
          // 跳转到VIP页面，带 is_discount=1 参数和 source_event
          Get.toNamed(
            KissuRoutePath.vip,
            arguments: {
              'is_discount': 1,
              'source_event': UnbindEvents.couponDialogClick,
              'source_page':SourcePageUtilsCaller.unbindPage,
            },
          );
        },
      ),
      barrierDismissible: false,
    );
  }

  /// 显示吵架聊天挽留弹窗
  void _showQuarrelChatDialog() {
    final reasons = widget.reasons;
    Get.back();
    QuarrelChatDialog.showFromFeedback(reasons);
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
                    '我们曾努力让两颗心的信号同频。如今信号减弱，我们深感惋惜。若你愿意，可否告诉我们，是哪个频率出现了杂音？',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF333333),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 选项列表（输入框集成在选项内部）
                  ..._buildReasonOptions(),

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
    final List<Widget> widgets = [];
    for (var i = 0; i < widget.reasons.length; i += 2) {
      final leftReason = widget.reasons[i];
      final rightReason = i + 1 < widget.reasons.length
          ? widget.reasons[i + 1]
          : null;

      // 添加选项行
      widgets.add(
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 6,vertical: 10),
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

      // 如果左侧选项被选中且需要补充说明，在其下方显示输入框（全宽）
      if (_selectedReason?.id == leftReason.id && leftReason.needSupplement) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildInputField(isLeftColumn: true),
            ),
          ),
        );
      }

      // 如果右侧选项被选中且需要补充说明，在其下方显示输入框（全宽）
      if (rightReason != null &&
          _selectedReason?.id == rightReason.id &&
          rightReason.needSupplement) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildInputField(isLeftColumn: false),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  /// 构建输入框（带三角形指示器）
  List<Widget> _buildInputField({required bool isLeftColumn}) {
    // 获取当前选中原因的占位符文本
    final hintText = _selectedReason?.defaultText?.isNotEmpty == true
        ? _selectedReason!.defaultText!
        : '请输入原因';

    return [
      // 三角形指示器 - 根据选中的是左侧还是右侧选项来定位
      LayoutBuilder(
        builder: (context, constraints) {
          // 计算三角形位置：左侧选项时靠左，右侧选项时靠右
          final triangleLeft = isLeftColumn
              ? 40.0
              : (constraints.maxWidth / 2) + 40; // 右侧列起始位置 + 偏移
          return Padding(
            padding: EdgeInsets.only(left: triangleLeft),
            child: CustomPaint(
              size: const Size(12, 6),
              painter: _TrianglePainter(
                color: _showInputError
                    ? const Color(0xFFFF1B02)
                    : const Color(0xFFF0F0F0),
              ),
            ),
          );
        },
      ),
      // 输入框
      Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(8),
          border: _showInputError
              ? Border.all(color: const Color(0xFFFF1B02), width: 1)
              : null,
        ),
        child: TextField(
          controller: _textController,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          onChanged: (value) {
            // 输入时清除错误状态
            if (_showInputError && value.trim().isNotEmpty) {
              setState(() {
                _showInputError = false;
              });
            }
          },
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(10),
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)),
          ),
          style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
        ),
      ),
    ];
  }

  /// 构建单个原因选项
  Widget _buildReasonOption(UnbindReasonModel reason, bool isSelected) {
    return GestureDetector(
      onTap: () {
        // 先更新选中状态
        setState(() {
          _selectedReason = reason;
          _showInputError = false; // 重新选择时清除错误状态
          _textController.clear(); // 清空输入框
        });

        // 如果是特殊类型，立即弹出对应弹窗
        if (reason.isPrivacyType) {
          _showPrivacySecurityDialog();
        } else if (reason.isPriceType) {
          _showVipRetentionDialog();
        } else if (reason.isQuarrelChatType) {
          _showQuarrelChatDialog();
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 单选圆圈
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: Colors.white),
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
                  ),
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

/// 三角形绘制器
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height) // 左下角
      ..lineTo(size.width / 2, 0) // 顶点
      ..lineTo(size.width, size.height) // 右下角
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
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

/// 隐私安全提示弹窗
/// 当用户选择 operation_type=privacy 的选项时显示
class PrivacySecurityDialog extends StatelessWidget {
  final VoidCallback onKnow;
  final VoidCallback onViewDetail;

  const PrivacySecurityDialog({
    super.key,
    required this.onKnow,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.85 > 320
        ? 320.0
        : screenSize.width * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/dialog/kissu4_bind_sure.webp'),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              const Text(
                '提示',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // 内容
              const Text(
                '请您放心!Kissu已完成「工信部ICP」备案和「公安部网安」备案。我们严格遵守国家隐私保护法规，全程保障您的隐私安全。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF333333),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              // 两张安全认证图片
              Image.asset(
                'assets/setting/kissu_dialog_safe1.webp',
                width: 234,
                height: 44,
                fit: BoxFit.contain,
              ),const SizedBox(height: 6),
              Image.asset(
                'assets/setting/kissu_dialog_safe2.webp',
                width: 234,
                height: 44,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              // 按钮区域
              Row(
                children: [
                  // 知道了按钮（灰色边框）
                  Expanded(
                    child: GestureDetector(
                      onTap: onKnow,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF999999),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: Text(
                            '知道了',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 详细查看按钮（粉色填充）
                  Expanded(
                    child: GestureDetector(
                      onTap: onViewDetail,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF90CA),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: Text(
                            '详细查看',
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
    );
  }
}

/// VIP挽留弹窗
/// 当用户选择 operation_type=price 的选项时显示
/// 三个模块不在一个背景上，间隙可以看到底下的背景
class VipRetentionDialog extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onClaim;

  const VipRetentionDialog({
    super.key,
    required this.onClose,
    required this.onClaim,
  });

  @override
  State<VipRetentionDialog> createState() => _VipRetentionDialogState();
}

class _VipRetentionDialogState extends State<VipRetentionDialog> {
  @override
  void initState() {
    super.initState();
    // 曝光埋点
    _trackExposure();
  }

  /// 曝光埋点
  void _trackExposure() {
    AnalyticsManager.instance.trackEvent(
      pageId: UnbindEvents.pageId,
      eventId: UnbindEvents.couponDialogExposure,
      params: {
        AnalyticsParams.pageEnterTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
    );
  }

  /// 点击埋点
  /// [btnStatus] 0=关闭 1=进入
  void _trackClick(int btnStatus) {
    AnalyticsManager.instance.trackClick(
      pageId: UnbindEvents.pageId,
      eventId: UnbindEvents.couponDialogClick,
      params: {
        AnalyticsParams.btnStatus: btnStatus,
      },
    );
  }

  /// 关闭按钮点击
  void _onClose() {
    _trackClick(0); // 0=关闭
    widget.onClose();
  }

  /// 领取按钮点击
  void _onClaim() {
    _trackClick(1); // 1=进入
    widget.onClaim();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 主体图片
          GestureDetector(
            onTap: () {}, // 防止点击穿透
            child: Image.asset(
              'assets/dialog/kissu_unbind_vip.webp',
              width: 375,
              fit: BoxFit.contain,
            ),
          ),
           // 领取按钮
          GestureDetector(
            onTap: _onClaim,
            child: Image.asset(
              'assets/dialog/kissu_unbind_vip_get.webp',
              width: 168,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          // 关闭按钮
          GestureDetector(
            onTap: _onClose,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 15),
            ),
          ),
        ],
      ),
    );
  }
}

/// 吵架聊天挽留弹窗
/// 当用户选择 operation_type=quarrel_chat 的选项时显示
class QuarrelChatDialog extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onContact;

  const QuarrelChatDialog({
    super.key,
    required this.onClose,
    required this.onContact,
  });

  /// 直接显示弹窗（从我的页面等独立入口调用）
  static void show() {
    Get.dialog<bool>(
      QuarrelChatDialog(
        onClose: () => Get.back(),
        onContact: () async {
          Get.back();
          await _openQuarrelChatKf();
        },
      ),
      barrierDismissible: false,
    );
  }

  /// 从解绑反馈弹窗中调用（关闭后返回反馈弹窗）
  static void showFromFeedback(List<UnbindReasonModel> reasons) {
    Get.dialog<bool>(
      QuarrelChatDialog(
        onClose: () {
          Get.back();
          CustomFeedbackDialogUtil.show(reasons: reasons);
        },
        onContact: () async {
          Get.back();
          await _openQuarrelChatKf();
        },
      ),
      barrierDismissible: false,
    );
  }

  /// 打开情感客服（含鸿蒙系统兼容处理）
  static Future<void> _openQuarrelChatKf() async {
    const corpId = AppConstants.weComCorpId;
    const kfId = AppConstants.weComQuarrelChatKfId;
    final kfUrl = AppConstants.weComKfUrl(kfId);

    try {
      if (Platform.isAndroid && await _isHarmonyOS()) {
        final launched = await launchUrl(
          Uri.parse(kfUrl),
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          CustomToast.show(Get.context!, '无法打开客服链接');
        }
        return;
      }

      if (Platform.isAndroid) {
        await PermissionHelper.openWeComKfWithParams(corpId: corpId, kfId: kfId);
      } else {
        await launchUrl(Uri.parse(kfUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      try {
        await launchUrl(Uri.parse(kfUrl), mode: LaunchMode.externalApplication);
      } catch (_) {
        CustomToast.show(Get.context!, '拉起客服失败，请稍后重试');
      }
    }
  }

  /// 检测是否为鸿蒙系统
  static Future<bool> _isHarmonyOS() async {
    try {
      if (!Platform.isAndroid) return false;
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final brand = androidInfo.brand.toLowerCase();
      final displayLower = androidInfo.display.toLowerCase();
      final fingerprintLower = androidInfo.fingerprint.toLowerCase();
      final hostLower = androidInfo.host.toLowerCase();
      final osVersion = Platform.operatingSystemVersion.toLowerCase();
      final versionRelease = androidInfo.version.release;

      if (displayLower.contains('harmony') ||
          fingerprintLower.contains('harmony') ||
          hostLower.contains('harmony') ||
          displayLower.contains('ohos') ||
          fingerprintLower.contains('ohos') ||
          osVersion.contains('harmony') ||
          osVersion.contains('ohos')) {
        return true;
      }

      final isHuaweiOrHonor = brand.contains('huawei') || brand.contains('honor');
      if (isHuaweiOrHonor &&
          (displayLower.startsWith('system') || osVersion.startsWith('system'))) {
        return true;
      }

      if (isHuaweiOrHonor) {
        final parts = versionRelease.split('.');
        final majorVersion = int.tryParse(parts[0]) ?? 0;
        if (majorVersion >= 5 && parts.length > 1) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 图片 + 右上角关闭按钮 + 底部按钮
          Stack(
            clipBehavior: Clip.none,
            children: [
              // 主体图片
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/kissu_fenshou.webp',
                  width: 260,
                  height: 355,
                  fit: BoxFit.cover,
                ),
              ),
              // 右上角关闭按钮
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 30,
                    height: 30,
                     
                    child: const Icon(Icons.close, color: Color(0xffaaaaaa), size: 22),
                  ),
                ),
              ),
              // 底部按钮
              Positioned(
                left: 0,
                right: 0,
                bottom: 34,
                child: Center(
                  child: GestureDetector(
                    onTap: onContact,
                    child: Container(
                      width: 180,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF90CA),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Text(
                          '找人聊聊',
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
