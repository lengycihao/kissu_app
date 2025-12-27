// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:kissu_app/services/screen_lock_service.dart';
// import 'package:kissu_app/services/sensitive_data_service.dart';
// import 'package:kissu_app/utils/debug_util.dart';

// /// 锁屏监听调试页面
// /// 
// /// 用于测试和诊断锁屏/解锁监听功能
// class ScreenLockDebugPage extends StatefulWidget {
//   const ScreenLockDebugPage({super.key});

//   @override
//   State<ScreenLockDebugPage> createState() => _ScreenLockDebugPageState();
// }

// class _ScreenLockDebugPageState extends State<ScreenLockDebugPage> {
//   final List<String> _logs = [];
  
//   @override
//   void initState() {
//     super.initState();
//     _addLog('📱 锁屏监听调试页面已初始化');
//     _checkServiceStatus();
//   }
  
//   void _addLog(String message) {
//     setState(() {
//       _logs.insert(0, '${DateTime.now().toString().substring(11, 19)} - $message');
//       if (_logs.length > 50) {
//         _logs.removeLast();
//       }
//     });
//     DebugUtil.info(message);
//   }
  
//   void _checkServiceStatus() {
//     try {
//       if (Get.isRegistered<ScreenLockService>()) {
//         final service = ScreenLockService.instance;
//         final status = service.getServiceStatus();
//         _addLog('✅ ScreenLockService 已注册');
//         _addLog('   - isInitialized: ${status['isInitialized']}');
//         _addLog('   - hasSubscription: ${status['hasSubscription']}');
//       } else {
//         _addLog('❌ ScreenLockService 未注册');
//       }
      
//       if (Get.isRegistered<SensitiveDataService>()) {
//         _addLog('✅ SensitiveDataService 已注册');
//       } else {
//         _addLog('❌ SensitiveDataService 未注册');
//       }
//     } catch (e) {
//       _addLog('❌ 检查服务状态失败: $e');
//     }
//   }
  
//   void _startListening() {
//     try {
//       _addLog('🔧 尝试启动锁屏监听...');
//       if (Get.isRegistered<ScreenLockService>()) {
//         final service = ScreenLockService.instance;
//         service.startListening();
//         _addLog('✅ 已调用 startListening()');
        
//         // 延迟检查状态
//         Future.delayed(const Duration(milliseconds: 500), () {
//           final status = service.getServiceStatus();
//           _addLog('📊 服务状态更新:');
//           _addLog('   - isInitialized: ${status['isInitialized']}');
//           _addLog('   - hasSubscription: ${status['hasSubscription']}');
//         });
//       } else {
//         _addLog('❌ ScreenLockService 未注册，无法启动');
//       }
//     } catch (e) {
//       _addLog('❌ 启动监听失败: $e');
//     }
//   }
  
//   void _stopListening() {
//     try {
//       _addLog('🛑 尝试停止锁屏监听...');
//       if (Get.isRegistered<ScreenLockService>()) {
//         final service = ScreenLockService.instance;
//         service.stopListening();
//         _addLog('✅ 已调用 stopListening()');
        
//         Future.delayed(const Duration(milliseconds: 500), () {
//           final status = service.getServiceStatus();
//           _addLog('📊 服务状态更新:');
//           _addLog('   - isInitialized: ${status['isInitialized']}');
//           _addLog('   - hasSubscription: ${status['hasSubscription']}');
//         });
//       }
//     } catch (e) {
//       _addLog('❌ 停止监听失败: $e');
//     }
//   }
  
//   void _triggerUnlockEvent() {
//     try {
//       _addLog('🧪 手动触发解锁事件...');
//       if (Get.isRegistered<ScreenLockService>()) {
//         final service = ScreenLockService.instance;
//         service.triggerUnlockEvent();
//         _addLog('✅ 解锁事件已触发');
//       }
//     } catch (e) {
//       _addLog('❌ 触发解锁事件失败: $e');
//     }
//   }
  
//   void _triggerLockEvent() {
//     try {
//       _addLog('🧪 手动触发锁屏事件...');
//       if (Get.isRegistered<ScreenLockService>()) {
//         final service = ScreenLockService.instance;
//         service.triggerLockEvent();
//         _addLog('✅ 锁屏事件已触发');
//       }
//     } catch (e) {
//       _addLog('❌ 触发锁屏事件失败: $e');
//     }
//   }
  
//   void _testEventHandling() {
//     try {
//       _addLog('🧪 测试事件处理...');
//       if (Get.isRegistered<ScreenLockService>()) {
//         final service = ScreenLockService.instance;
        
//         // 测试解锁事件
//         final unlockEvent = {
//           'event_type': 'unlock',
//           'timestamp': DateTime.now().millisecondsSinceEpoch,
//         };
//         _addLog('📤 发送测试解锁事件: $unlockEvent');
//         service.handleTestEvent(unlockEvent);
        
//         // 测试锁屏事件
//         Future.delayed(const Duration(seconds: 2), () {
//           final lockEvent = {
//             'event_type': 'lock',
//             'timestamp': DateTime.now().millisecondsSinceEpoch,
//           };
//           _addLog('📤 发送测试锁屏事件: $lockEvent');
//           service.handleTestEvent(lockEvent);
//         });
//       }
//     } catch (e) {
//       _addLog('❌ 测试事件处理失败: $e');
//     }
//   }
  
//   void _clearLogs() {
//     setState(() {
//       _logs.clear();
//     });
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('锁屏监听调试'),
//         backgroundColor: const Color(0xFFFFA4A4),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.delete_outline),
//             onPressed: _clearLogs,
//             tooltip: '清空日志',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // 控制按钮区域
//           Container(
//             padding: const EdgeInsets.all(16),
//             color: Colors.grey[100],
//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: _checkServiceStatus,
//                         icon: const Icon(Icons.refresh),
//                         label: const Text('检查状态'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: _startListening,
//                         icon: const Icon(Icons.play_arrow),
//                         label: const Text('启动监听'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: _stopListening,
//                         icon: const Icon(Icons.stop),
//                         label: const Text('停止监听'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.orange,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: _triggerUnlockEvent,
//                         icon: const Icon(Icons.lock_open),
//                         label: const Text('模拟解锁'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFFFA4A4),
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: _triggerLockEvent,
//                         icon: const Icon(Icons.lock),
//                         label: const Text('模拟锁屏'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF9575CD),
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: _testEventHandling,
//                         icon: const Icon(Icons.science),
//                         label: const Text('测试事件'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF4DB6AC),
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
          
//           // 说明文字
//           Container(
//             padding: const EdgeInsets.all(12),
//             color: Colors.amber[100],
//             child: const Row(
//               children: [
//                 Icon(Icons.info_outline, color: Colors.orange),
//                 SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     '请先启动监听，然后锁屏/解锁手机测试实际效果。\n也可以使用"模拟"按钮测试事件处理逻辑。',
//                     style: TextStyle(fontSize: 12),
//                   ),
//                 ),
//               ],
//             ),
//           ),
          
//           // 日志区域
//           Expanded(
//             child: Container(
//               color: Colors.black87,
//               child: _logs.isEmpty
//                   ? const Center(
//                       child: Text(
//                         '暂无日志',
//                         style: TextStyle(color: Colors.white54),
//                       ),
//                     )
//                   : ListView.builder(
//                       itemCount: _logs.length,
//                       padding: const EdgeInsets.all(8),
//                       itemBuilder: (context, index) {
//                         final log = _logs[index];
//                         Color textColor = Colors.white;
                        
//                         if (log.contains('❌')) {
//                           textColor = Colors.red[300]!;
//                         } else if (log.contains('✅')) {
//                           textColor = Colors.green[300]!;
//                         } else if (log.contains('🔓') || log.contains('解锁')) {
//                           textColor = Colors.blue[300]!;
//                         } else if (log.contains('🔒') || log.contains('锁屏')) {
//                           textColor = Colors.orange[300]!;
//                         } else if (log.contains('🧪')) {
//                           textColor = Colors.purple[300]!;
//                         }
                        
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 2),
//                           child: Text(
//                             log,
//                             style: TextStyle(
//                               color: textColor,
//                               fontSize: 12,
//                               fontFamily: 'monospace',
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

