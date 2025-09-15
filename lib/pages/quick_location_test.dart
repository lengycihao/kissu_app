// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:kissu_app/services/simple_location_service.dart';

// class QuickLocationTest extends StatefulWidget {
//   @override
//   _QuickLocationTestState createState() => _QuickLocationTestState();
// }

// class _QuickLocationTestState extends State<QuickLocationTest> {
//   final SimpleLocationService _locationService = SimpleLocationService.instance;
//   bool _isLoading = false;
//   String _result = '等待测试...';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('快速定位测试'),
//         backgroundColor: Colors.green,
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // 状态显示
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.blue.withOpacity(0.1),
//                 border: Border.all(color: Colors.blue),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 _result,
//                 style: TextStyle(fontSize: 16),
//                 textAlign: TextAlign.center,
//               ),
//             ),

//             SizedBox(height: 30),

//             // 测试按钮
//             ElevatedButton(
//               onPressed: _isLoading ? null : _quickTest,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//                 padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
//               ),
//               child: _isLoading
//                   ? CircularProgressIndicator(color: Colors.white)
//                   : Text('开始快速测试', style: TextStyle(fontSize: 18)),
//             ),

//             SizedBox(height: 20),

//             // 位置信息显示
//             Obx(() => Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(15),
//               decoration: BoxDecoration(
//                 color: _locationService.currentLocation.value != null
//                     ? Colors.green.withOpacity(0.1)
//                     : Colors.grey.withOpacity(0.1),
//                 border: Border.all(
//                   color: _locationService.currentLocation.value != null
//                       ? Colors.green
//                       : Colors.grey,
//                 ),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: _locationService.currentLocation.value != null
//                   ? Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('✅ 定位成功！',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.green,
//                             fontSize: 16,
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         Text('经度: ${_locationService.currentLocation.value!.longitude}'),
//                         Text('纬度: ${_locationService.currentLocation.value!.latitude}'),
//                         Text('精度: ${_locationService.currentLocation.value!.accuracy}米'),
//                         if (_locationService.currentLocation.value!.locationName.isNotEmpty)
//                           Text('地址: ${_locationService.currentLocation.value!.locationName}'),
//                       ],
//                     )
//                   : Text(
//                       '暂无定位数据',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _quickTest() async {
//     setState(() {
//       _isLoading = true;
//       _result = '正在测试...';
//     });

//     try {
//       print('🔧 ===== 快速定位测试开始 =====');

//       // 1. 申请权限
//       setState(() => _result = '1. 申请定位权限...');
//       bool hasPermission = await _locationService.requestLocationPermission();
//       print('🔐 权限申请结果: $hasPermission');

//       if (!hasPermission) {
//         setState(() => _result = '❌ 权限申请失败');
//         return;
//       }

//       // 2. 启动定位服务
//       setState(() => _result = '2. 启动定位服务...');
//       bool started = await _locationService.startLocation();
//       print('🚀 定位服务启动结果: $started');

//       if (!started) {
//         setState(() => _result = '❌ 定位服务启动失败');
//         return;
//       }

//       // 3. 等待定位数据
//       setState(() => _result = '3. 等待定位数据...');

//       // 简单等待10秒
//       for (int i = 1; i <= 10; i++) {
//         await Future.delayed(Duration(seconds: 1));
//         setState(() => _result = '3. 等待定位数据... ${i}/10秒');

//         if (_locationService.currentLocation.value != null) {
//           setState(() => _result = '✅ 定位成功！请查看下方位置信息');
//           print('✅ 定位成功！');
//           return;
//         }
//       }

//       setState(() => _result = '⚠️ 10秒内未获取到定位数据');
//       print('⚠️ 10秒内未获取到定位数据');

//     } catch (e) {
//       setState(() => _result = '❌ 测试异常: $e');
//       print('❌ 测试异常: $e');
//     } finally {
//       setState(() => _isLoading = false);
//       print('🔧 ===== 快速定位测试结束 =====');
//     }
//   }
// }