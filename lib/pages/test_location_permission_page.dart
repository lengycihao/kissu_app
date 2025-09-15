// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:kissu_app/services/location_permission_service.dart';
// import 'package:permission_handler/permission_handler.dart';

// /// 定位权限测试页面
// /// 专门用于测试和调试定位权限相关功能
// class TestLocationPermissionPage extends StatefulWidget {
//   const TestLocationPermissionPage({super.key});

//   @override
//   State<TestLocationPermissionPage> createState() => _TestLocationPermissionPageState();
// }

// class _TestLocationPermissionPageState extends State<TestLocationPermissionPage> {
//   String _statusText = "等待操作...";
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkInitialStatus();
//   }

//   /// 检查初始状态
//   void _checkInitialStatus() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final status = await Permission.location.status;
//       final statusWhenInUse = await Permission.locationWhenInUse.status;
//       final statusAlways = await Permission.locationAlways.status;

//       setState(() {
//         _statusText = """
// 📋 权限状态检查:
// • 基础定位权限: ${_getStatusText(status)}
// • 使用期间定位: ${_getStatusText(statusWhenInUse)}
// • 始终定位权限: ${_getStatusText(statusAlways)}
// • 权限服务状态: 检查中...
//         """.trim();
//       });
//     } catch (e) {
//       setState(() {
//         _statusText = "检查权限状态失败: $e";
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   /// 获取权限状态文本
//   String _getStatusText(PermissionStatus status) {
//     switch (status) {
//       case PermissionStatus.granted:
//         return "✅ 已授权";
//       case PermissionStatus.denied:
//         return "❌ 被拒绝";
//       case PermissionStatus.restricted:
//         return "🚫 受限制";
//       case PermissionStatus.permanentlyDenied:
//         return "🔒 永久拒绝";
//       case PermissionStatus.provisional:
//         return "⚠️ 临时授权";
//       case PermissionStatus.limited:
//         return "⭕ 有限授权";
//     }
//   }

//   /// 请求基础定位权限
//   void _requestBasicPermission() async {
//     setState(() {
//       _isLoading = true;
//       _statusText = "正在请求基础定位权限...";
//     });

//     try {
//       final result = await Permission.location.request();
//       final isGranted = result == PermissionStatus.granted;
//       setState(() {
//         _statusText = isGranted 
//           ? "✅ 基础定位权限请求成功"
//           : "❌ 基础定位权限请求失败";
//       });
      
//       // 延迟检查状态
//       await Future.delayed(const Duration(milliseconds: 500));
//       _checkInitialStatus();
//     } catch (e) {
//       setState(() {
//         _statusText = "请求基础定位权限出错: $e";
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   /// 请求后台定位权限
//   void _requestBackgroundPermission() async {
//     setState(() {
//       _isLoading = true;
//       _statusText = "正在请求后台定位权限...";
//     });

//     try {
//       final result = await Permission.locationAlways.request();
//       final isGranted = result == PermissionStatus.granted;
//       setState(() {
//         _statusText = isGranted 
//           ? "✅ 后台定位权限请求成功"
//           : "❌ 后台定位权限请求失败";
//       });
      
//       // 延迟检查状态
//       await Future.delayed(const Duration(milliseconds: 500));
//       _checkInitialStatus();
//     } catch (e) {
//       setState(() {
//         _statusText = "请求后台定位权限出错: $e";
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   /// 检查并请求所有权限
//   void _checkAndRequestAllPermissions() async {
//     setState(() {
//       _isLoading = true;
//       _statusText = "正在检查并请求所有权限...";
//     });

//     try {
//       final locationResult = await Permission.location.request();
//       final backgroundResult = await Permission.locationAlways.request();
//       final result = locationResult == PermissionStatus.granted && 
//                     backgroundResult == PermissionStatus.granted;
//       setState(() {
//         _statusText = result 
//           ? "✅ 所有权限检查完成，权限充足"
//           : "❌ 权限检查失败或权限不足";
//       });
      
//       // 延迟检查状态
//       await Future.delayed(const Duration(milliseconds: 500));
//       _checkInitialStatus();
//     } catch (e) {
//       setState(() {
//         _statusText = "检查权限时出错: $e";
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   /// 打开系统设置
//   void _openAppSettings() async {
//     setState(() {
//       _statusText = "正在打开系统设置...";
//     });

//     try {
//       final result = await openAppSettings();
//       setState(() {
//         _statusText = result 
//           ? "✅ 已打开系统设置"
//           : "❌ 打开系统设置失败";
//       });
//     } catch (e) {
//       setState(() {
//         _statusText = "打开系统设置出错: $e";
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("定位权限测试"),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // 状态显示区域
//             Container(
//               padding: const EdgeInsets.all(16.0),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8.0),
//                 border: Border.all(color: Colors.grey[300]!),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "📊 权限状态",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue[800],
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   _isLoading 
//                     ? const Row(
//                         children: [
//                           SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(strokeWidth: 2),
//                           ),
//                           SizedBox(width: 8),
//                           Text("处理中..."),
//                         ],
//                       )
//                     : Text(
//                         _statusText,
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontFamily: 'monospace',
//                         ),
//                       ),
//                 ],
//               ),
//             ),
            
//             const SizedBox(height: 20),
            
//             // 操作按钮
//             Text(
//               "🎛️ 测试操作",
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.green[800],
//               ),
//             ),
//             const SizedBox(height: 12),
            
//             // 检查状态按钮
//             ElevatedButton.icon(
//               onPressed: _isLoading ? null : _checkInitialStatus,
//               icon: const Icon(Icons.refresh),
//               label: const Text("刷新权限状态"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//             ),
            
//             const SizedBox(height: 8),
            
//             // 请求基础权限按钮
//             ElevatedButton.icon(
//               onPressed: _isLoading ? null : _requestBasicPermission,
//               icon: const Icon(Icons.location_on),
//               label: const Text("请求基础定位权限"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//             ),
            
//             const SizedBox(height: 8),
            
//             // 请求后台权限按钮
//             ElevatedButton.icon(
//               onPressed: _isLoading ? null : _requestBackgroundPermission,
//               icon: const Icon(Icons.location_history),
//               label: const Text("请求后台定位权限"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//             ),
            
//             const SizedBox(height: 8),
            
//             // 检查所有权限按钮
//             ElevatedButton.icon(
//               onPressed: _isLoading ? null : _checkAndRequestAllPermissions,
//               icon: const Icon(Icons.security),
//               label: const Text("检查并请求所有权限"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.purple,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//             ),
            
//             const SizedBox(height: 8),
            
//             // 打开系统设置按钮
//             ElevatedButton.icon(
//               onPressed: _isLoading ? null : _openAppSettings,
//               icon: const Icon(Icons.settings),
//               label: const Text("打开系统设置"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//             ),
            
//             const SizedBox(height: 20),
            
//             // 使用说明
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "📋 使用说明",
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue[800],
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     const Text(
//                       "1. 首先点击'刷新权限状态'查看当前权限状态\n"
//                       "2. 如果权限不足，使用相应按钮请求权限\n"
//                       "3. 如果权限被永久拒绝，需要打开系统设置手动授权\n"
//                       "4. 后台定位权限需要先获得基础定位权限\n"
//                       "5. 建议使用'检查并请求所有权限'一次性处理",
//                       style: TextStyle(fontSize: 13),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
