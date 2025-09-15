import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/model/system_info_model.dart';

class PhoneHistorySettingDialog {
  static void show({
    SystemInfoModel? systemInfo,
    required Function(SystemInfoModel) onConfirm,
  }) {
    Get.bottomSheet(
      _PhoneHistorySettingBottomSheet(
        systemInfo: systemInfo,
        onConfirm: onConfirm,
      ),
      isScrollControlled: true,
    );
  }
}

class _PhoneHistorySettingBottomSheet extends StatefulWidget {
  final SystemInfoModel? systemInfo;
  final Function(SystemInfoModel) onConfirm;

  const _PhoneHistorySettingBottomSheet({
    this.systemInfo,
    required this.onConfirm,
  });

  @override
  State<_PhoneHistorySettingBottomSheet> createState() =>
      _PhoneHistorySettingBottomSheetState();
}

class _PhoneHistorySettingBottomSheetState
    extends State<_PhoneHistorySettingBottomSheet> {
  // 响应式变量，对应4个设置项
  final isPushSystemMsg = false.obs; // 系统消息敏感行为
  final isPushKissuMsg = false.obs; // Kissu消息敏感行为
  final isPushLocationMsg = false.obs; // 位置信息敏感行为
  final isPushPhoneStatusMsg = false.obs; // 手机状态消息敏感行为

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  void _initSettings() {
    if (widget.systemInfo != null) {
      isPushSystemMsg.value = widget.systemInfo!.isPushSystemMsg == 1;
      isPushKissuMsg.value = widget.systemInfo!.isPushKissuMsg == 1;
      isPushLocationMsg.value = widget.systemInfo!.isPushLocationMsg == 1;
      isPushPhoneStatusMsg.value = widget.systemInfo!.isPushPhoneStatusMsg == 1;
    }
  }

  void _handleConfirm() {
    final newSystemInfo = SystemInfoModel(
      id: widget.systemInfo?.id,
      userId: widget.systemInfo?.userId,
      isPushSystemMsg: isPushSystemMsg.value ? 1 : 0,
      isPushKissuMsg: isPushKissuMsg.value ? 1 : 0,
      isPushLocationMsg: isPushLocationMsg.value ? 1 : 0,
      isPushPhoneStatusMsg: isPushPhoneStatusMsg.value ? 1 : 0,
    );

    widget.onConfirm(newSystemInfo);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/phone_history/kissu_show_bottom_bg.webp"),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.only(left: 22, right: 16, top: 30),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/phone_history/kissu_phone_setting.webp",
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  // ✅ 保证文本可以自动换行
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '敏感行为推送设置',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '关闭后敏感行为将不会通过消息进行推送，但是仍会在此列表展示',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF999999),
                        ),
                        softWrap: true, // ✅ 自动换行
                        overflow: TextOverflow.visible, // ✅ 不截断
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 虚线
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 22, right: 16, bottom: 16),
            child: CustomPaint(painter: _DashedLinePainter()),
          ),
          // 内容区（固定，不可滚动）
          Expanded(
            child: Column(
              children: [
                _buildSettingItem("系统消息敏感行为", isPushSystemMsg),
                _buildSettingItem("Kissu消息敏感行为", isPushKissuMsg),
                _buildSettingItem("位置信息敏感行为", isPushLocationMsg),
                _buildSettingItem("手机状态消息敏感行为", isPushPhoneStatusMsg),
              ],
            ),
          ),
          // 底部确定按钮
          Container(
            padding: const EdgeInsets.all(35),
            child: GestureDetector(
              onTap: _handleConfirm,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B9D),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text(
                    '确定',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, RxBool isSelected) {
    return Obx(() {
      return GestureDetector(
        onTap: () => isSelected.value = !isSelected.value,
        child: Container(
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Image.asset(
                isSelected.value
                    ? "assets/phone_history/kissu_show_bottem_sel.webp"
                    : "assets/phone_history/kissu_show_bottom_unsel.webp",
                width: 15,
                height: 15,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// 自定义虚线绘制器
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    final paint = Paint()
      ..color = const Color(0xFFDDDDDD)
      ..strokeWidth = 1;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
