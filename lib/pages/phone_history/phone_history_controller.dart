import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'phone_history_setting_dialog.dart';

class PhoneHistoryController extends GetxController {
  // 是否绑定情侣
  final isBinding = true.obs; // 默认设置为true以便测试UI

  // 选中的日期索引
  final selectedDateIndex = 0.obs;
  var tooltipText = Rxn<String>(); // 保存当前提示信息，null 表示不显示
  OverlayEntry? _overlayEntry;
  late BuildContext pageContext;
 void showTooltip(  String text, Offset position) {
  hideTooltip(); // 先移除旧的

  final screenSize = MediaQuery.of(pageContext).size;
  const padding = 12.0;

  // 先预估提示框的大小
  final maxWidth = screenSize.width * 0.6;
  final estimatedHeight = 40.0;

  double left = position.dx;
  double top = position.dy;

  // 避免溢出右边
  if (left + maxWidth + padding > screenSize.width) {
    left = screenSize.width - maxWidth - padding;
  }

  // 避免溢出下边
  if (top + estimatedHeight + padding > screenSize.height) {
    top = screenSize.height - estimatedHeight - padding;
  }

  _overlayEntry = OverlayEntry(
    builder: (_) {
      return Stack(
        children: [
          // ✅ 全屏透明点击区域
          Positioned.fill(
            child: GestureDetector(
              onTap: hideTooltip,
              behavior: HitTestBehavior.translucent, // 即使透明也能点到
              child: Container(color: Colors.transparent),
            ),
          ),
          // 提示框
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      text,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                    ),
                  ),
                  // 关闭按钮
                  Positioned(
                    top: -8,
                    right: -8,
                    child: GestureDetector(
                      onTap: hideTooltip,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  Overlay.of(pageContext, rootOverlay: true).insert(_overlayEntry!);
}

  void hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  

  // 显示设置弹窗
  void showSettingDialog() {
    PhoneHistorySettingDialog.show();
  }

  // 模拟的用机记录数据
  List<PhoneUsageRecord> getUsageRecords() {
    if (!isBinding.value) return [];

    // 模拟数据
    return [
      PhoneUsageRecord(
        time: '2025-09-05 13:51:32',
        action: '对方更换手机进行了登录',
        isPartner: true,
      ),
      PhoneUsageRecord(
        time: '2025-09-05 11:50:10',
        action: '对方退出了账号',
        isPartner: true,
      ),
      PhoneUsageRecord(
        time: '2025-09-05 11:30:51',
        action: '对方手机结束充电，对方手机结束充电对方手机结束充电当前电量:55%',
        isPartner: true,
      ),
      PhoneUsageRecord(
        time: '2025-09-05 11:12:35',
        action: '对方打开了定位',
        isPartner: true,
      ),
      PhoneUsageRecord(
        time: '2025-09-05 11:12:27',
        action: '对方关闭了定位',
        isPartner: true,
      ),
      PhoneUsageRecord(
        time: '2025-09-05 11:12:26',
        action: '对方关闭了定位',
        isPartner: true,
      ),
      PhoneUsageRecord(
        time: '2025-09-05 11:11:41',
        action: '对方更换了网络WIFI(vuluo-5G)',
        isPartner: true,
      ),
    ];
  }
}

// 用机记录数据模型
class PhoneUsageRecord {
  final String time;
  final String action;
  final bool isPartner;

  PhoneUsageRecord({
    required this.time,
    required this.action,
    required this.isPartner,
  });
}
