import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../chat_controller.dart';
import 'package:kissu_app/pages/home/home_controller.dart';

/// 顶部设备信息栏，支持点击展开气泡提示。
class ChatDeviceInfoBar extends StatelessWidget {
  const ChatDeviceInfoBar({
    super.key,
    required this.controller,
    List<DeviceInfoData>? deviceInfos,
  }) : _deviceInfos = deviceInfos ?? _defaultInfos;

  final ChatController controller;
  final List<DeviceInfoData> _deviceInfos;

  static const List<DeviceInfoData> _defaultInfos = [
    DeviceInfoData(
      type: 'distance',
      icon: 'assets/phone_history/kissu_phone_distance.webp',
      text: '120km',
      maxLength: 6,
    ),
    DeviceInfoData(
      type: 'mobileModel',
      icon: 'assets/phone_history/kissu_phone_type.webp',
      text: 'Iphone 15 Pro',
      maxLength: 6,
    ),
    DeviceInfoData(
      type: 'network',
      icon: 'assets/phone_history/kissu_phone_wifi.webp',
      text: 'Unknown',
      maxLength: 8,
    ),
    DeviceInfoData(
      type: 'power',
      icon: 'assets/phone_history/kissu_phone_barry.webp',
      text: '85%',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedType = controller.selectedDeviceInfoType.value;

      // 从首页控制器中获取另一半设备信息（如果已注册并加载过 /index 数据）
      List<DeviceInfoData> deviceInfos;
      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        deviceInfos = [
          DeviceInfoData(
            type: 'distance',
            icon: 'assets/phone_history/kissu_phone_distance.webp',
            text: home.halfDeviceDistance.value,
            maxLength: 6,
          ),
          DeviceInfoData(
            type: 'mobileModel',
            icon: 'assets/phone_history/kissu_phone_type.webp',
            text: home.halfDeviceMobileModel.value,
            maxLength: 6,
          ),
          DeviceInfoData(
            type: 'network',
            icon: 'assets/phone_history/kissu_phone_wifi.webp',
            text: home.halfDeviceNetworkName.value,
            maxLength: 8,
          ),
          DeviceInfoData(
            type: 'power',
            icon: 'assets/phone_history/kissu_phone_barry.webp',
            text: home.halfDevicePower.value,
          ),
        ];
      } else {
        // 如果首页控制器未注册，则使用默认占位数据
        deviceInfos = _deviceInfos;
      }

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < deviceInfos.length; i++) ...[
                _DeviceInfoItem(
                  info: deviceInfos[i],
                  isSelected: selectedType == deviceInfos[i].type,
                  onTap: () => controller.toggleDeviceInfo(deviceInfos[i].type),
                ),
                if (i != deviceInfos.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
          if (selectedType != null)
            _DeviceInfoTooltip(
              selectedType: selectedType,
              deviceInfos: deviceInfos,
            ),
        ],
      );
    });
  }
}

class _DeviceInfoItem extends StatelessWidget {
  const _DeviceInfoItem({
    required this.info,
    required this.isSelected,
    required this.onTap,
  });

  final DeviceInfoData info;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayText = info.maxLength != null && info.text.length > info.maxLength!
        ? '${info.text.substring(0, info.maxLength)}...'
        : info.text;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 50),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'device_info_icon_${info.type}',
              child: Image.asset(info.icon, width: 16, height: 16),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Hero(
                tag: 'device_info_content_${info.type}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF333333),
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
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

class _DeviceInfoTooltip extends StatelessWidget {
  const _DeviceInfoTooltip({
    required this.selectedType,
    required this.deviceInfos,
  });

  final String selectedType;
  final List<DeviceInfoData> deviceInfos;

  @override
  Widget build(BuildContext context) {
    final selectedList = deviceInfos
        .where((item) => item.type == selectedType && item.text.isNotEmpty)
        .toList();
    if (selectedList.isEmpty) return const SizedBox.shrink();
    final selectedInfo = selectedList.first;

    return Positioned(
      top: -40,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < deviceInfos.length; i++) ...[
              Expanded(
                child: deviceInfos[i].type == selectedType
                    ? Align(
                        alignment: Alignment.center,
                        child: _DeviceInfoTooltipBubble(text: selectedInfo.text),
                      )
                    : const SizedBox.shrink(),
              ),
              if (i != deviceInfos.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeviceInfoTooltipBubble extends StatelessWidget {
  const _DeviceInfoTooltipBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      constrainedAxis: Axis.vertical,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
          CustomPaint(
            size: const Size(12, 6),
            painter: _TooltipArrowPainter(),
          ),
        ],
      ),
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DeviceInfoData {
  const DeviceInfoData({
    required this.type,
    required this.icon,
    required this.text,
    this.maxLength,
  });

  final String type;
  final String icon;
  final String text;
  final int? maxLength;
}

