import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import '../location_v2_controller.dart';

/// 设备信息模块组件
/// 显示距离、天气、设备信息等
class DeviceInfoSection extends StatelessWidget {
  final LocationV2Controller controller;

  const DeviceInfoSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 92,
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ).copyWith(top: 11),
          margin: EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
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
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xcc000000),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xffffffff),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    alignment: Alignment.center,
                    child: _buildWeatherWidget(),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Obx(
                () => IntrinsicWidth(
                  child: Text(
                    controller.distance.value,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xcc000000),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Positioned(
          right: 15,
          bottom: -9,
          child: Image(
          image: AssetImage(
            'assets/location/kissu3_location_distance_logo.webp',
          ),
          width: 100,
          height: 100,
        )),
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
          // const SizedBox(width: 12),
          NetworkImageHelper.loadImage(
            imageUrl: controller.weatherIcon.value,
            width: 16,
            height: 16,
            errorWidget: const SizedBox.shrink(),
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
          child: Container(width: 70, height: 30, color: Colors.transparent),
        ),
      );
    });
  }
}
