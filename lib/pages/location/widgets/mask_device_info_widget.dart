import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/device_info_item.dart';
import '../location_v2_controller.dart';

/// 蒙版上的设备信息组件（白色背景）
/// 显示设备型号、电池电量、网络信息
class MaskDeviceInfoWidget extends StatelessWidget {
  final LocationV2Controller controller;

  const MaskDeviceInfoWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(
        horizontal: 19,
        vertical: 8,
      ).copyWith(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // 位置信息行
          _buildLocationRow(),
          const SizedBox(height: 2),
          // 设备信息行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 设备型号
              Expanded(
                child: Obx(() {
                  // 判断是否应该掩码设备信息
                  final shouldMask = _shouldMaskDeviceInfo(
                    controller.isBindPartner.value,
                    controller.isVip.value,
                    controller.isOneself.value,
                  );
                  return DeviceInfoItem(
                    text: shouldMask
                        ? '******'
                        : controller.myDeviceModel.value,
                    iconPath: 'assets/phone_history/kissu_phone_type.webp',
                    isDevice: true,
                    onLongPress: controller.showTooltip,
                  );
                }),
              ),
              // 电池电量
              Expanded(
                child: Obx(() {
                  // 判断是否应该掩码设备信息
                  final shouldMask = _shouldMaskDeviceInfo(
                    controller.isBindPartner.value,
                    controller.isVip.value,
                    controller.isOneself.value,
                  );
                  return DeviceInfoItem(
                    text: shouldMask ? '**%' : controller.myBatteryLevel.value,
                    iconPath: 'assets/phone_history/kissu_phone_barry.webp',
                    isDevice: false,
                    onLongPress: controller.showTooltip,
                  );
                }),
              ),
              // 网络信息
              Expanded(
                child: Obx(() {
                  // 判断是否应该掩码设备信息
                  final shouldMask = _shouldMaskDeviceInfo(
                    controller.isBindPartner.value,
                    controller.isVip.value,
                    controller.isOneself.value,
                  );
                  return DeviceInfoItem(
                    text: shouldMask
                        ? '******'
                        : controller.myNetworkName.value,
                    iconPath: 'assets/phone_history/kissu_phone_wifi.webp',
                    isDevice: false,
                    onLongPress: controller.showTooltip,
                  );
                }),
              ),
            ],
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2C4),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            "位置",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF000000),
              fontFamily: 'LiuhuanKatongShoushu',
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Obx(() {
            return Text(
              controller.currentLocationText.value,
              style: const TextStyle(fontSize: 10, color: Color(0xFF333333)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            );
          }),
        ),
      ],
    );
  }

  /// 判断是否应该掩码设备信息
  /// 返回 true 表示需要显示掩码（******  **%  ******）
  /// 返回 false 表示正常显示
  ///
  /// 规则：
  /// 1. 未绑定时，正常显示自己的设备信息
  /// 2. 绑定且开通会员时，都正常显示
  /// 3. 绑定但未开通会员时：
  ///    - 看自己（isOneself == 1）：正常显示
  ///    - 看对方（isOneself == 2）：显示掩码
  bool _shouldMaskDeviceInfo(bool isBindPartner, bool isVip, int isOneself) {
    // 1. 未绑定时，正常显示自己的设备信息
    if (!isBindPartner) {
      return false;
    }

    // 2. 绑定且开通会员时，都正常显示
    if (isBindPartner && isVip) {
      return false;
    }

    // 3. 绑定但未开通会员时：
    //    - 看自己（isOneself == 1）：正常显示
    //    - 看对方（isOneself == 2）：显示掩码
    if (isBindPartner && !isVip) {
      // 看对方时需要掩码
      return isOneself == 2;
    }

    // 默认不掩码
    return false;
  }
}
