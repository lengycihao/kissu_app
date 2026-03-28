// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:kissu_app/utils/network_image_helper.dart';
// import '../widget_center_controller.dart';

// /// 卡片1: 4×2 宽卡片
// /// 展示: 相距、在一起天数、头像、位置、电量、手机型号、WiFi
// class WidgetCardLarge extends StatelessWidget {
//   final WidgetCenterController controller;

//   const WidgetCardLarge({super.key, required this.controller});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(20),
//         gradient: const LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Color(0xFFFFB6D9), Color(0xFFFFC8E3), Color(0xFFFFDCEE)],
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFFFFB6D9).withOpacity(0.3),
//             blurRadius: 15,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildTopRow(),
//             const SizedBox(height: 12),
//             _buildPartnerInfo(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTopRow() {
//     return Obx(() {
//       final dist = controller.distance.value.isNotEmpty
//           ? controller.distance.value
//           : '---';
//       final days = controller.togetherDays.value.isNotEmpty
//           ? controller.togetherDays.value
//           : '0';
//       return Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             '相距$dist',
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF333333),
//             ),
//           ),
//           Row(
//             children: [
//               Text(
//                 '在一起${days}Day',
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF333333),
//                 ),
//               ),
//               const SizedBox(width: 4),
//               Image.asset(
//                 'assets/4.0/kissu4_widget_emoji.webp',
//                 width: 32,
//                 height: 32,
//                 errorBuilder: (_, __, ___) => const Text('🥰', style: TextStyle(fontSize: 24)),
//               ),
//             ],
//           ),
//         ],
//       );
//     });
//   }

//   Widget _buildPartnerInfo() {
//     return Obx(() {
//       final avatar = controller.partnerAvatar.value;
//       final location = controller.partnerLocation.value.isNotEmpty
//           ? controller.partnerLocation.value
//           : '位置信息加载中...';
//       final battery = controller.partnerBattery.value.isNotEmpty
//           ? controller.partnerBattery.value
//           : '--%';
//       final model = controller.partnerModel.value.isNotEmpty
//           ? controller.partnerModel.value
//           : '未知';
//       final wifi = controller.partnerWifiName.value.isNotEmpty
//           ? controller.partnerWifiName.value
//           : '未知';

//       return Container(
//         padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.64),
//           borderRadius: BorderRadius.circular(14),
//         ),
//         child: Row(
//           children: [
//             // 头像
//             avatar.isNotEmpty
//                 ? NetworkImageHelper.loadAvatar(
//                     imageUrl: avatar,
//                     size: 56,
//                     placeholder: 'assets/3.0/kissu3_love_avater.webp',
//                   )
//                 : ClipOval(
//                     child: Image.asset(
//                       'assets/3.0/kissu3_love_avater.webp',
//                       width: 56,
//                       height: 56,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//             const SizedBox(width: 12),
//             // 信息列
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // 位置
//                   Row(
//                     children: [
//                       const Icon(Icons.location_on, size: 14, color: Color(0xFFFF5092)),
//                       const SizedBox(width: 4),
//                       Expanded(
//                         child: Text(
//                           location,
//                           style: const TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                             color: Color(0xFF802145),
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   // 电量 + 型号 + WiFi
//                   Row(
//                     children: [
//                       _buildInfoChip(Icons.battery_std, battery, const Color(0xFF4CAF50)),
//                       const SizedBox(width: 10),
//                       _buildInfoChip(Icons.phone_android, model, const Color(0xFF2196F3)),
//                       const SizedBox(width: 10),
//                       _buildInfoChip(Icons.wifi, _truncate(wifi, 6), const Color(0xFF9C27B0)),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     });
//   }

//   Widget _buildInfoChip(IconData icon, String text, Color color) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: 14, color: color),
//         const SizedBox(width: 2),
//         Text(
//           text,
//           style: TextStyle(
//             fontSize: 12,
//             color: color,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }

//   String _truncate(String text, int maxLen) {
//     if (text.length <= maxLen) return text;
//     return '${text.substring(0, maxLen)}...';
//   }
// }
