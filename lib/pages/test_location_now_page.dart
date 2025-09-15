// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:kissu_app/services/simple_location_service.dart';

// class TestLocationNowPage extends StatefulWidget {
//   @override
//   _TestLocationNowPageState createState() => _TestLocationNowPageState();
// }

// class _TestLocationNowPageState extends State<TestLocationNowPage> {
//   final SimpleLocationService _locationService = SimpleLocationService.instance;
//   bool _isLoading = false;
//   List<String> _logs = [];

//   @override
//   void initState() {
//     super.initState();
//     _addLog('页面初始化完成');
//     _addLog('定位服务状态: ${_locationService.isLocationEnabled.value ? "已启动" : "未启动"}');
//   }

//   void _addLog(String message) {
//     final timestamp = DateTime.now().toString().substring(11, 19);
//     setState(() {
//       _logs.add('[$timestamp] $message');
//     });
//     print('🔧 $message');
//   }

//   Future<void> _testLocationNow() async {
//     setState(() {
//       _isLoading = true;
//       _logs.clear();
//     });

//     _addLog('=== 开始定位测试 ===');

//     try {
//       // 1. 强制重新初始化
//       _addLog('1. 重新初始化定位服务...');
//       _locationService.init();
//       await Future.delayed(Duration(milliseconds: 500));

//       // 2. 申请权限
//       _addLog('2. 申请定位权限...');
//       bool hasPermission = await _locationService.requestLocationPermission();
//       _addLog('权限申请结果: ${hasPermission ? "成功" : "失败"}');

//       if (!hasPermission) {
//         _addLog('❌ 权限申请失败，测试结束');
//         return;
//       }

//       // 3. 启动定位服务
//       _addLog('3. 启动定位服务...');
//       bool started = await _locationService.startLocation();
//       _addLog('定位服务启动结果: ${started ? "成功" : "失败"}');

//       if (!started) {
//         _addLog('❌ 定位服务启动失败');
//         return;
//       }

//       // 4. 等待定位数据
//       _addLog('4. 等待定位数据（最多等待30秒）...');

//       int waitCount = 0;
//       while (waitCount < 30 && _locationService.currentLocation.value == null) {
//         await Future.delayed(Duration(seconds: 1));
//         waitCount++;

//         if (waitCount % 5 == 0) {
//           _addLog('等待中... ${waitCount}秒');
//         }
//       }

//       // 5. 检查结果
//       if (_locationService.currentLocation.value != null) {
//         final location = _locationService.currentLocation.value!;
//         _addLog('✅ 定位成功！');
//         _addLog('经度: ${location.longitude}');
//         _addLog('纬度: ${location.latitude}');
//         _addLog('精度: ${location.accuracy}米');
//         _addLog('地址: ${location.locationName}');
//         _addLog('时间: ${location.locationTime}');
//       } else {
//         _addLog('❌ 30秒内未获取到定位数据');
//         _addLog('建议检查：');
//         _addLog('- GPS信号是否良好');
//         _addLog('- 网络连接是否正常');
//         _addLog('- 高德API Key是否正确');
//         _addLog('- 应用权限是否完整授予');

//         // 运行诊断
//         _addLog('5. 运行诊断工具...');
//         await _locationService.diagnoseLocationService();
//       }

//     } catch (e) {
//       _addLog('❌ 测试过程中发生异常: $e');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//       _addLog('=== 测试结束 ===');
//     }
//   }

//   Future<void> _runDiagnostic() async {
//     setState(() {
//       _isLoading = true;
//     });

//     _addLog('=== 开始运行完整诊断 ===');

//     try {
//       await _locationService.comprehensiveLocationTroubleshoot();
//       _addLog('✅ 诊断完成，请查看控制台输出');
//     } catch (e) {
//       _addLog('❌ 诊断过程异常: $e');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('定位功能测试'),
//         backgroundColor: Colors.blue,
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // 状态显示
//             Obx(() => Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: _locationService.isLocationEnabled.value
//                     ? Colors.green.withOpacity(0.1)
//                     : Colors.red.withOpacity(0.1),
//                 border: Border.all(
//                   color: _locationService.isLocationEnabled.value
//                       ? Colors.green
//                       : Colors.red,
//                 ),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     '定位服务状态: ${_locationService.isLocationEnabled.value ? "运行中" : "未启动"}',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   if (_locationService.currentLocation.value != null) ...[
//                     SizedBox(height: 8),
//                     Text('当前位置: ${_locationService.currentLocation.value!.latitude}, ${_locationService.currentLocation.value!.longitude}'),
//                     Text('精度: ${_locationService.currentLocation.value!.accuracy}米'),
//                     Text('地址: ${_locationService.currentLocation.value!.locationName}'),
//                   ],
//                 ],
//               ),
//             )),

//             SizedBox(height: 16),

//             // 按钮区域
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _testLocationNow,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       foregroundColor: Colors.white,
//                     ),
//                     child: _isLoading
//                         ? CircularProgressIndicator(color: Colors.white)
//                         : Text('立即测试定位'),
//                   ),
//                 ),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _runDiagnostic,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orange,
//                       foregroundColor: Colors.white,
//                     ),
//                     child: Text('运行诊断'),
//                   ),
//                 ),
//               ],
//             ),

//             SizedBox(height: 16),

//             // 日志显示
//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   border: Border.all(color: Colors.grey[300]!),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         '测试日志：',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       SizedBox(height: 8),
//                       ..._logs.map((log) => Padding(
//                         padding: EdgeInsets.only(bottom: 4),
//                         child: Text(
//                           log,
//                           style: TextStyle(
//                             fontFamily: 'monospace',
//                             fontSize: 12,
//                             color: log.contains('❌') ? Colors.red :
//                                    log.contains('✅') ? Colors.green :
//                                    Colors.black87,
//                           ),
//                         ),
//                       )),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }