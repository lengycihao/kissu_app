import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../location_v2_controller.dart';

/// 设备信息模块组件
/// 显示距离、天气、设备信息等
class DeviceInfoSection extends StatelessWidget {
  final LocationV2Controller controller;

  const DeviceInfoSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height:92,
          padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ).copyWith(top: 15),
          margin: EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            image: DecorationImage(
              image:AssetImage(
                      'assets/location/kissu3_location_bind_device_bg.webp',
                    ),
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 距离和更新时间
              Row(
                children: [
                  const Text(
                    '我们相距',
                    style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
                  ),
                  const SizedBox(width: 22),
                  Image(
                    image: AssetImage('assets/kissu_location_time_logo.webp'),
                    width: 22,
                    height: 22,
                  ),
                  SizedBox(width: 4),
                  Obx(
                    () => Text(
                      controller.speed.value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  Spacer(),
                  // 天气模块
                  _buildWeatherWidget(),
                ],
              ),
              Obx(
                () => IntrinsicWidth(
                  child: Text(
                    controller.distance.value,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 绑定按钮（仅未绑定时显示）
        _buildBindButton(),
      ],
    );
  }

  /// 构建天气组件
  Widget _buildWeatherWidget() {
    return Obx(() {
      if (controller.weatherIcon.value.isEmpty ||
          controller.weather.value.isEmpty) {
        return const SizedBox.shrink();
      }
      return Row(
        children: [
          const SizedBox(width: 12),
          Image.network(
            controller.weatherIcon.value,
            width: 16,
            height: 16,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 5),
          Text(
            controller.weather.value,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFFFC04B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    });
  }

  /// 构建绑定按钮
  Widget _buildBindButton() {
    return Obx(() {
      if (controller.isBindPartner.value) {
        return const SizedBox.shrink();
      }
      return Positioned(
        right: 28,
        top: 12,
        child: GestureDetector(
          onTap: () => controller.performBindAction(),
          child: Container(
            width: 70,
            height: 30,
            color: Colors.transparent,
          ),
        ),
      );
    });
  }
}
