import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PhoneHistorySettingDialog {
  static void show() {
    Get.bottomSheet(
      Container(
        height: 400,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/phone_history/kissu_show_bottom_bg.webp"),
            fit: BoxFit.cover,
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
          // 标题
Padding(
  padding: const EdgeInsets.only(left: 16, right: 16, top: 30),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Image.asset(
        "assets/phone_history/kissu_phone_setting.webp",
        width: 20,
        height: 20,
      ),
      const SizedBox(width: 8),
      Expanded( // ✅ 保证文本可以自动换行
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
            SizedBox(height: 8),
            Text(
              '关闭后敏感行为将不会通过消息进行推送，但是仍会在此列表展示',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF999999),
              ),
              softWrap: true,                 // ✅ 自动换行
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
              margin: const EdgeInsets.only(left: 16,right: 16,bottom: 16),
              child: CustomPaint(
                painter: _DashedLinePainter(),
              ),
            ),
            // 内容区（固定，不可滚动）
            Expanded(
              child: Column(
                children: [
                  _buildSettingItem("系统消息敏感行为"),
                  _buildSettingItem("Kissu消息敏感行为"),
                  _buildSettingItem("位置信息敏感行为"),
                  _buildSettingItem("手机状态消息敏感行为"),
                ],
              ),
            ),
            // 底部确定按钮
            Container(
              padding: const EdgeInsets.all(35),
              child: GestureDetector(
                onTap: () => Get.back(),
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
            ),const SizedBox(height: 10,)
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  static Widget _buildSettingItem(String title) {
    final isSelected = false.obs;
    return Obx(() {
      return GestureDetector(
        onTap: () => isSelected.value = !isSelected.value,
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Image.asset(
                isSelected.value
                    ? "assets/phone_history/kissu_show_bottem_sel.webp"
                    : "assets/phone_history/kissu_show_bottom_unsel.webp",
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                ),
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
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
