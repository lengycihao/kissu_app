// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// /// iPhone App使用记录提示对话框
// class IPhoneAppUsageDialog extends StatelessWidget {
//   const IPhoneAppUsageDialog({Key? key}) : super(key: key);

//   /// 显示对话框
//   static void show(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       barrierColor: Colors.black.withOpacity(0.5),
//       builder: (BuildContext context) {
//         return const IPhoneAppUsageDialog();
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.transparent,
//       child: Container(
//         width: 270,
//         height: 200,
//         decoration: BoxDecoration(
//           image: const DecorationImage(
//             image: AssetImage('assets/phone_history/kissu4_iphone_dialog_bg.webp'),
//             fit: BoxFit.fill,
//           ),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               // 标题
//               const Text(
//                 'App使用记录',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   color: Color(0xFF333333),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               // 内容
//               const Flexible(
//                 child: Text(
//                   'iPhone处于内测阶段，您的对象为iPhone用户。"App使用记录"暂时无法查看，我们将逐步开放，感谢您的理解！',
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: Color(0xFF333333),
//                     height: 1.5,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               // "知道了"按钮
//               GestureDetector(
//                 onTap: () {
//                   Get.back();
//                 },
//                 child: Container(
//                   width: 106,
//                   height: 36,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFFF408D),
//                     borderRadius: BorderRadius.circular(18),
//                   ),
//                   alignment: Alignment.center,
//                   child: const Text(
//                     '知道了',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

