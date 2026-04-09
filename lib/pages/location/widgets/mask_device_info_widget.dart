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
      height: 93,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ).copyWith(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // 位置信息行
          _buildLocationRow(),
          const SizedBox(height: 3),
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
            color: const Color(0xFFFFF18D),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            "位置",
            style: TextStyle(
              fontSize: 12,
              color: Color(0xe6333333),
              fontFamily: 'AlimamaShuHeiTi',
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Obx(() {
            final text = controller.currentLocationText.value;
            return LayoutBuilder(
              builder: (context, constraints) {
                const baseStyle = TextStyle(
                  fontSize: 12,
                  color: Color(0xFF333333),
                );

                // 使用 TextPainter 计算文本在单行 12pt 下的宽度，判断是否会换行
                final painter = TextPainter(
                  text: TextSpan(
                    text: text,
                    style: baseStyle,
                  ),
                  maxLines: 1,
                  textDirection: TextDirection.ltr,
                );

                // 不限制最大宽度，获取完整单行文本宽度
                painter.layout();
                final isSingleLine = painter.width <= constraints.maxWidth;

                final effectiveStyle = baseStyle.copyWith(
                  fontSize: isSingleLine ? 12 : 10,
                );

                return Text(
                  text,
                  style: effectiveStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
              },
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
