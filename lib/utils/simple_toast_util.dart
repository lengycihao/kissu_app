// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// /// 简单可靠的Toast工具类
// /// 使用Overlay实现屏幕中间显示，完全匹配原来的CustomToast样式
// class SimpleToastUtil {
//   static OverlayEntry? _currentOverlay;
//   static int _retryCount = 0;
//   static const int _maxRetries = 3;

//   /// 显示Toast消息
//   static void show(
//     String message, {
//     Duration duration = const Duration(seconds: 2),
//     Color backgroundColor = const Color(0xffFF7C98), // 使用您原来的粉色背景
//     Color textColor = const Color(0xFFFFFFFF), // 使用您原来的白色文字
//     double fontSize = 11.0, // 使用您原来的字体大小
//     double maxWidth = 275.0, // 使用您原来的最大宽度
//     EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 25, vertical: 5), // 使用您原来的内边距
//   }) {
//     try {
//       // 先移除之前的Toast
//       _removeCurrentToast();

//       // 获取当前上下文
//       final context = Get.context;
//       if (context == null) {
//         print('SimpleToastUtil: No context available');
//         return;
//       }

//       // 安全地获取Overlay
//       final overlay = Overlay.maybeOf(context);
//       if (overlay == null) {
//         print('SimpleToastUtil: No Overlay found, will retry later');
//         // 延迟重试，等待Overlay准备就绪
//         Future.delayed(const Duration(milliseconds: 100), () {
//           show(message, duration: duration, backgroundColor: backgroundColor, 
//                textColor: textColor, fontSize: fontSize, maxWidth: maxWidth, padding: padding);
//         });
//         return;
//       }

//       // 创建OverlayEntry
//       _currentOverlay = OverlayEntry(
//         builder: (context) => Center(
//           child: Material(
//             color: Colors.transparent,
//             child: Container(
//               constraints: BoxConstraints(maxWidth: maxWidth),
//               padding: padding,
//               decoration: BoxDecoration(
//                 color: backgroundColor,
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: Text(
//                 message,
//                 style: TextStyle(
//                   color: textColor,
//                   fontSize: fontSize,
//                   height: 1.2,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ),
//         ),
//       );

//       // 插入到Overlay
//       overlay.insert(_currentOverlay!);

//       // 自动移除
//       Future.delayed(duration, () {
//         _removeCurrentToast();
//       });
//     } catch (e) {
//       // 如果出错，延迟重试一次
//       print('SimpleToastUtil: Failed to show toast: $message, retrying...');
//       print('SimpleToastUtil: Error: $e');
//       Future.delayed(const Duration(milliseconds: 200), () {
//         try {
//           _removeCurrentToast();
//           final context = Get.context;
//           if (context != null) {
//             final overlay = Overlay.maybeOf(context);
//             if (overlay != null) {
//               _currentOverlay = OverlayEntry(
//                 builder: (context) => Center(
//                   child: Material(
//                     color: Colors.transparent,
//                     child: Container(
//                       constraints: BoxConstraints(maxWidth: maxWidth),
//                       padding: padding,
//                       decoration: BoxDecoration(
//                         color: backgroundColor,
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Text(
//                         message,
//                         style: TextStyle(
//                           color: textColor,
//                           fontSize: fontSize,
//                           height: 1.2,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//               overlay.insert(_currentOverlay!);
//               Future.delayed(duration, () {
//                 _removeCurrentToast();
//               });
//             }
//           }
//         } catch (retryError) {
//           print('SimpleToastUtil: Retry also failed: $retryError');
//         }
//       });
//     }
//   }

//   /// 移除当前的Toast
//   static void _removeCurrentToast() {
//     _currentOverlay?.remove();
//     _currentOverlay = null;
//   }

//   /// 显示成功Toast
//   static void showSuccess(String message) {
//     show(
//       message,
//       backgroundColor: const Color(0xFF4CAF50),
//       textColor: Colors.white,
//     );
//   }

//   /// 显示错误Toast
//   static void showError(String message) {
//     show(
//       message,
//       backgroundColor: const Color(0xFFF44336),
//       textColor: Colors.white,
//     );
//   }

//   /// 显示警告Toast
//   static void showWarning(String message) {
//     show(
//       message,
//       backgroundColor: const Color(0xFFFF9800),
//       textColor: Colors.white,
//     );
//   }

//   /// 显示信息Toast
//   static void showInfo(String message) {
//     show(
//       message,
//       backgroundColor: const Color(0xFF2196F3),
//       textColor: Colors.white,
//     );
//   }
// }
