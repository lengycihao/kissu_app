// 使用示例：如何在其他页面中使用 DeviceInfoItem 组件

import 'package:flutter/material.dart';
import 'package:kissu_app/widgets/device_info_item.dart';

class ExampleUsagePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('设备信息组件使用示例')),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 基础使用方式
            Text(
              '基础使用：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DeviceInfoItem(
                    text: 'iPhone 14',
                    iconPath: 'assets/phone_history/kissu_phone_type.webp',
                    isDevice: true,
                  ),
                ),
                Expanded(
                  child: DeviceInfoItem(
                    text: '85%',
                    iconPath: 'assets/phone_history/kissu_phone_barry.webp',
                  ),
                ),
                Expanded(
                  child: DeviceInfoItem(
                    text: 'WiFi-Home',
                    iconPath: 'assets/phone_history/kissu_phone_wifi.webp',
                  ),
                ),
              ],
            ),

            SizedBox(height: 32),

            // 带长按提示功能的使用方式
            Text(
              '带长按提示功能：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DeviceInfoItem(
                    text: 'Samsung S23',
                    iconPath: 'assets/phone_history/kissu_phone_type.webp',
                    isDevice: true,
                    onLongPress: (text, position) {
                      // 这里可以显示自定义的提示框
                      print('长按了: $text, 位置: $position');
                      // 实际使用中可以调用 showTooltip 等方法
                    },
                    onLongPressEnd: () {
                      print('长按结束');
                      // 可以在这里隐藏提示框
                    },
                  ),
                ),
                Expanded(
                  child: DeviceInfoItem(
                    text: '78%',
                    iconPath: 'assets/phone_history/kissu_phone_barry.webp',
                    onLongPress: (text, position) {
                      print('电量信息: $text');
                    },
                  ),
                ),
                Expanded(
                  child: DeviceInfoItem(
                    text: '5G网络',
                    iconPath: 'assets/phone_history/kissu_phone_wifi.webp',
                    onLongPress: (text, position) {
                      print('网络信息: $text');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
