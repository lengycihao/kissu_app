import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/services/sensitive_data_service.dart';
import 'package:kissu_app/network/public/service_locator.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';

/// 敏感数据上报测试页面
class SensitiveDataTestPage extends StatelessWidget {
  const SensitiveDataTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('敏感数据上报测试'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '敏感数据上报功能测试',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // APP打开事件测试
            ElevatedButton(
              onPressed: () => _testAppOpen(),
              child: const Text('测试APP打开事件上报'),
            ),
            const SizedBox(height: 10),
            
            // 定位打开事件测试
            ElevatedButton(
              onPressed: () => _testLocationOpen(),
              child: const Text('测试定位打开事件上报'),
            ),
            const SizedBox(height: 10),
            
            // 定位关闭事件测试
            ElevatedButton(
              onPressed: () => _testLocationClose(),
              child: const Text('测试定位关闭事件上报'),
            ),
            const SizedBox(height: 10),
            
            // 网络更换事件测试
            ElevatedButton(
              onPressed: () => _testNetworkChange(),
              child: const Text('测试网络更换事件上报'),
            ),
            const SizedBox(height: 10),
            
            // 充电事件测试
            ElevatedButton(
              onPressed: () => _testChargingEvents(),
              child: const Text('测试充电事件上报'),
            ),
            const SizedBox(height: 10),
            
            // 地图标记测试
            ElevatedButton(
              onPressed: () => Get.toNamed(KissuRoutePath.testMapMarkers),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('测试地图标记功能'),
            ),
            const SizedBox(height: 20),
            
            // 服务状态显示
            const Text(
              '服务状态:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Obx(() {
              try {
                final service = getIt<SensitiveDataService>();
                final status = service.getServiceStatus();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('当前网络: ${status['currentNetworkName']}'),
                        Text('当前电池状态: ${status['currentBatteryState']}'),
                        Text('是否正在充电: ${status['isCharging']}'),
                        Text('是否应该上报: ${status['shouldReport']}'),
                      ],
                    ),
                  ),
                );
              } catch (e) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text('获取服务状态失败: $e'),
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  /// 测试APP打开事件上报
  void _testAppOpen() async {
    try {
      final service = getIt<SensitiveDataService>();
      await service.reportAppOpen();
      OKToastUtil.show('APP打开事件上报已发送');
    } catch (e) {
      OKToastUtil.show('APP打开事件上报失败: $e');
    }
  }

  /// 测试定位打开事件上报
  void _testLocationOpen() async {
    try {
      final service = getIt<SensitiveDataService>();
      await service.reportLocationOpen();
      OKToastUtil.show('定位打开事件上报已发送');
    } catch (e) {
      OKToastUtil.show('定位打开事件上报失败: $e');
    }
  }

  /// 测试定位关闭事件上报
  void _testLocationClose() async {
    try {
      final service = getIt<SensitiveDataService>();
      await service.reportLocationClose();
      OKToastUtil.show('定位关闭事件上报已发送');
    } catch (e) {
      OKToastUtil.show('定位关闭事件上报失败: $e');
    }
  }

  /// 测试网络更换事件上报
  void _testNetworkChange() async {
    try {
      final service = getIt<SensitiveDataService>();
      await service.manualReportNetworkChange('wifi'); // 传入'wifi'让服务自动获取SSID
      OKToastUtil.show('网络更换事件上报已发送');
    } catch (e) {
      OKToastUtil.show('网络更换事件上报失败: $e');
    }
  }

  /// 测试充电事件上报
  void _testChargingEvents() async {
    try {
      final service = getIt<SensitiveDataService>();
      await service.manualReportCharging(true, 85);
      await Future.delayed(const Duration(seconds: 1));
      await service.manualReportCharging(false, 90);
      OKToastUtil.show('充电事件上报已发送');
    } catch (e) {
      OKToastUtil.show('充电事件上报失败: $e');
    }
  }
}
