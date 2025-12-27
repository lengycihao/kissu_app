import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'location_v2_controller.dart';
import 'widgets/location_page_layout.dart';

/// 定位页面
/// 采用组件化架构，将复杂的UI逻辑拆分为多个独立组件
class LocationV2Page extends StatelessWidget {
  const LocationV2Page({super.key});

  @override
  Widget build(BuildContext context) {
    // 🚀 修复：使用安全的方式获取Controller，避免重复创建导致监听器重复注册
    final controller = Get.isRegistered<LocationV2Controller>()
        ? Get.find<LocationV2Controller>()
        : Get.put(LocationV2Controller());

    return LocationPageLayout(controller: controller);
  }
}
