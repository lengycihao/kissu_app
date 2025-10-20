import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/device_info_item.dart';
import '../location_v2_controller.dart';

/// 位置信息模块组件
/// 显示当前位置和设备信息（手机型号、电量、网络）
class LocationInfoSection extends StatelessWidget {
  final LocationV2Controller controller;

  const LocationInfoSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14),
      padding: EdgeInsets.symmetric(
        horizontal: 19,
        vertical: 14,
      ).copyWith(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // 位置信息行
          _buildLocationRow(),
          const SizedBox(height: 12),
          // 设备信息行
          _buildDeviceInfoRow(),
        ],
      ),
    );
  }

  /// 构建位置信息行
  Widget _buildLocationRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2C4),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            "位置",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF000000),
              fontFamily: 'LiuhuanKatongShoushu',
            ),
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: Obx(() {
            return Text(
              controller.currentLocationText.value,
              style: TextStyle(fontSize: 12, color: Color(0xFF333333)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            );
          }),
        ),
      ],
    );
  }

  /// 构建设备信息行
  Widget _buildDeviceInfoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 设备型号
        Expanded(
          child: Obx(
            () => DeviceInfoItem(
              text: controller.myDeviceModel.value,
              iconPath: 'assets/phone_history/kissu_phone_type.webp',
              isDevice: true,
              onLongPress: controller.showTooltip,
            ),
          ),
        ),
        // 电池电量
        Expanded(
          child: Obx(
            () => DeviceInfoItem(
              text: controller.myBatteryLevel.value,
              iconPath: 'assets/phone_history/kissu_phone_barry.webp',
              isDevice: false,
              onLongPress: controller.showTooltip,
            ),
          ),
        ),
        // 网络信息
        Expanded(
          child: Obx(
            () => DeviceInfoItem(
              text: controller.myNetworkName.value,
              iconPath: 'assets/phone_history/kissu_phone_wifi.webp',
              isDevice: false,
              onLongPress: controller.showTooltip,
            ),
          ),
        ),
      ],
    );
  }
}
