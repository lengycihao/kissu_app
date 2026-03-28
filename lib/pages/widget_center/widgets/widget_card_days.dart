// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../widget_center_controller.dart';

// /// 卡片3: 2×2 方形卡片
// /// 展示: 只有在一起天数 + 装饰元素
// class WidgetCardDays extends StatelessWidget {
//   final WidgetCenterController controller;

//   const WidgetCardDays({super.key, required this.controller});

//   @override
//   Widget build(BuildContext context) {
//     return AspectRatio(
//       aspectRatio: 1,
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20),
//           gradient: const LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [Color(0xFFFFD6EC), Color(0xFFFFC8E3), Color(0xFFFFB6D9)],
//           ),
//           border: Border.all(color: const Color(0xFFFF8EC4), width: 1.5),
//           boxShadow: [
//             BoxShadow(
//               color: const Color(0xFFFFB6D9).withOpacity(0.3),
//               blurRadius: 15,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Obx(() => _buildContent()),
//         ),
//       ),
//     );
//   }

//   Widget _buildContent() {
//     final days = controller.togetherDays.value.isNotEmpty
//         ? controller.togetherDays.value
//         : '0';

//     return Stack(
//       children: [
//         // 左上角小爱心
//         Positioned(
//           left: 0,
//           top: 20,
//           child: Icon(Icons.favorite, size: 20, color: const Color(0xFFFF8EC4).withOpacity(0.6)),
//         ),
//         // 右上角小爱心
//         Positioned(
//           right: 20,
//           top: 0,
//           child: Icon(Icons.favorite, size: 14, color: const Color(0xFFFF8EC4).withOpacity(0.5)),
//         ),
//         // 左下角小爱心
//         Positioned(
//           left: 10,
//           bottom: 30,
//           child: Icon(Icons.favorite, size: 16, color: const Color(0xFFFF8EC4).withOpacity(0.4)),
//         ),
//         // 居中内容
//         Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 '我们相伴',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                   color: Color(0xFFFF4D94),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Text(
//                     days,
//                     style: const TextStyle(
//                       fontSize: 52,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFFFF4D94),
//                       height: 1.0,
//                     ),
//                   ),
//                   const Padding(
//                     padding: EdgeInsets.only(bottom: 6),
//                     child: Text(
//                       '天',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w500,
//                         color: Color(0xFFFF4D94),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Image.asset(
//                 'assets/4.0/kissu4_widget_couple.webp',
//                 width: 56,
//                 height: 56,
//                 errorBuilder: (_, __, ___) => const Text('💑', style: TextStyle(fontSize: 36)),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
