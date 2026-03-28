// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:kissu_app/utils/network_image_helper.dart';
// import '../widget_center_controller.dart';

// /// 卡片2: 2×2 方形卡片
// /// 展示: 头像、相距、位置、电量、手机型号、WiFi（无在一起天数）
// class WidgetCardInfo extends StatelessWidget {
//   final WidgetCenterController controller;

//   const WidgetCardInfo({super.key, required this.controller});

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
//             colors: [Color(0xFFFFF0F5), Color(0xFFFFF5F9)],
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: const Color(0xFFFFB6D9).withOpacity(0.2),
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
//     final avatar = controller.partnerAvatar.value;
//     final dist = controller.distance.value.isNotEmpty
//         ? controller.distance.value
//         : '---';
//     final location = controller.partnerLocation.value.isNotEmpty
//         ? controller.partnerLocation.value
//         : '位置加载中...';
//     final battery = controller.partnerBattery.value.isNotEmpty
//         ? controller.partnerBattery.value
//         : '--%';
//     final model = controller.partnerModel.value.isNotEmpty
//         ? controller.partnerModel.value
//         : '未知';
//     final wifi = controller.partnerWifiName.value.isNotEmpty
//         ? controller.partnerWifiName.value
//         : '未知';

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // 顶部: 头像 + 相距
//         Row(
//           children: [
//             avatar.isNotEmpty
//                 ? NetworkImageHelper.loadAvatar(
//                     imageUrl: avatar,
//                     size: 40,
//                     placeholder: 'assets/3.0/kissu3_love_avater.webp',
//                   )
//                 : ClipOval(
//                     child: Image.asset(
//                       'assets/3.0/kissu3_love_avater.webp',
//                       width: 40,
//                       height: 40,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//             const Spacer(),
//             Text(
//               '相距$dist',
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF333333),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         // 位置
//         Row(
//           children: [
//             const Icon(Icons.location_on, size: 14, color: Color(0xFFFF6BA8)),
//             const SizedBox(width: 4),
//             Expanded(
//               child: Text(
//                 _truncate(location, 10),
//                 style: const TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w500,
//                   color: Color(0xFF333333),
//                 ),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         // 电量
//         _buildInfoRow(Icons.battery_std, battery, const Color(0xFF4CAF50)),
//         const SizedBox(height: 6),
//         // 手机型号
//         _buildInfoRow(Icons.phone_android, model, const Color(0xFF2196F3)),
//         const SizedBox(height: 6),
//         // WiFi + 表情
//         Row(
//           children: [
//             _buildInfoRow(Icons.wifi, _truncate(wifi, 6), const Color(0xFF9C27B0)),
//             const Spacer(),
//             Image.asset(
//               'assets/4.0/kissu4_widget_emoji.webp',
//               width: 36,
//               height: 36,
//               errorBuilder: (_, __, ___) => const Text('🥰', style: TextStyle(fontSize: 28)),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildInfoRow(IconData icon, String text, Color color) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: 14, color: color),
//         const SizedBox(width: 4),
//         Text(
//           text,
//           style: TextStyle(
//             fontSize: 13,
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
