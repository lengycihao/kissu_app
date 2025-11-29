// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:kissu_app/models/sensitive_record_model.dart';

// /// 敏感记录列表项组件
// class SensitiveRecordItem extends StatelessWidget {
//   final SensitiveRecordModel record;
//   final VoidCallback? onViewTap; // 点击"查看"的回调

//   const SensitiveRecordItem({
//     super.key,
//     required this.record,
//     this.onViewTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 8),
//         // 时间标签
//         _buildTimeLabel(),
//         const SizedBox(height: 8),
//         // 内容卡片
//         _buildContentCard(),
//       ],
//     );
//   }

//   /// 构建时间标签
//   Widget _buildTimeLabel() {
//     final timeStr = DateFormat('HH: mm').format(record.time);
//     return Center(
//       child: Text(
//         timeStr,
//         style: const TextStyle(
//           fontSize: 12,
//           color: Color(0xFF999999),
//         ),
//       ),
//     );
//   }

//   /// 构建内容卡片
//   Widget _buildContentCard() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           // 左侧图标
//           _buildIcon(),
//           const SizedBox(width: 8),
//           // 内容
//           _buildContent(),
//         ],
//       ),
//     );
//   }

//   /// 构建图标
//   Widget _buildIcon() {
//     String iconPath;

//     switch (record.type) {
//       case SensitiveRecordType.location:
//         iconPath = 'assets/phone_history/kissu3_history_time_icon.webp';
//         break;
//       case SensitiveRecordType.track:
//         iconPath = 'assets/images/kissu_track_location.webp';
//         break;
//       case SensitiveRecordType.wifi:
//         iconPath = 'assets/phone_history/kissu_phone_wifi.webp';
//         break;
//       case SensitiveRecordType.battery:
//         iconPath = 'assets/phone_history/kissu_phone_barry.webp';
//         break;
//       case SensitiveRecordType.device:
//         iconPath = 'assets/phone_history/kissu_phone_type.webp';
//         break;
//     }

//     return Image.asset(
//       iconPath,
//       width: 20,
//       height: 20,
//     );
//   }

//   /// 构建内容
//   Widget _buildContent() {
//     switch (record.type) {
//       case SensitiveRecordType.location:
//         return _buildLocationContent();
//       case SensitiveRecordType.track:
//         return _buildTrackContent();
//       case SensitiveRecordType.wifi:
//         return _buildWifiContent();
//       case SensitiveRecordType.battery:
//         return _buildBatteryContent();
//       case SensitiveRecordType.device:
//         return _buildDeviceContent();
//     }
//   }

//   /// 定位类型内容
//   Widget _buildLocationContent() {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text.rich(
//           TextSpan(
//             children: [
//               const TextSpan(
//                 text: '对方在当前位置',
//                 style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
//               ),
//               TextSpan(
//                 text: '停留超${record.locationDuration ?? ""}',
//                 style: const TextStyle(fontSize: 13, color: Color(0xFFB66CF2)),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 8),
//         _buildViewButton(),
//       ],
//     );
//   }

//   /// 轨迹类型内容
//   Widget _buildTrackContent() {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text.rich(
//           TextSpan(
//             children: [
//               const TextSpan(
//                 text: '对方产生',
//                 style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
//               ),
//               TextSpan(
//                 text: '${record.trackPointCount ?? 0}个停留点足迹',
//                 style: const TextStyle(fontSize: 13, color: Color(0xFFB66CF2)),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 8),
//         _buildViewButton(),
//       ],
//     );
//   }

//   /// WiFi类型内容
//   Widget _buildWifiContent() {
//     String content = '';
//     String highlight = '';

//     switch (record.wifiActionType) {
//       case WifiActionType.changed:
//         content = '对方';
//         highlight = '更换了wifi';
//         break;
//       case WifiActionType.opened:
//         content = '对方开启了';
//         highlight = 'WIFI权限';
//         break;
//       case WifiActionType.closed:
//         content = '对方关闭了';
//         highlight = 'WIFI权限';
//         break;
//       default:
//         content = 'WiFi记录';
//     }

//     return Text.rich(
//       TextSpan(
//         children: [
//           TextSpan(
//             text: content,
//             style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
//           ),
//           TextSpan(
//             text: highlight,
//             style: const TextStyle(fontSize: 13, color: Color(0xFFB66CF2)),
//           ),
//         ],
//       ),
//     );
//   }

//   /// 电量类型内容
//   Widget _buildBatteryContent() {
//     return Text.rich(
//       TextSpan(
//         children: [
//           const TextSpan(
//             text: '对方手机正在充电，当前',
//             style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
//           ),
//           TextSpan(
//             text: '电量${record.batteryLevel ?? 0}%',
//             style: const TextStyle(fontSize: 13, color: Color(0xFFB66CF2)),
//           ),
//         ],
//       ),
//     );
//   }

//   /// 手机类型内容
//   Widget _buildDeviceContent() {
//     return Text.rich(
//       TextSpan(
//         children: [
//           const TextSpan(
//             text: '对方',
//             style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
//           ),
//           TextSpan(
//             text: '更换了手机（${record.deviceModel ?? ""}）',
//             style: const TextStyle(fontSize: 13, color: Color(0xFFB66CF2)),
//           ),
//           const TextSpan(
//             text: '进行了登录',
//             style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
//           ),
//         ],
//       ),
//     );
//   }

//   /// 构建"查看"按钮
//   Widget _buildViewButton() {
//     return GestureDetector(
//       onTap: onViewTap,
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text(
//             '查看',
//             style: TextStyle(
//               fontSize: 13,
//               color: Color(0xFFFF9500),
//             ),
//           ),
//           const SizedBox(width: 2),
//           Image.asset(
//             'assets/phone_history/kissu3_history_info_go.webp',
//             width: 6,
//             height: 6,
//           ),
//         ],
//       ),
//     );
//   }
// }

