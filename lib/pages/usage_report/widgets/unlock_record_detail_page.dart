// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:kissu_app/models/unlock_record_model.dart';
// import 'package:kissu_app/models/usage_record_api_model.dart';
// import 'package:kissu_app/pages/usage_report/usage_report_controller.dart';
// import '../common/unlock_record_item.dart';
// import '../common/type19_unlock_record_item.dart';
// import '../common/generic_record_item.dart';

// /// 解锁记录详情页面
// class UnlockRecordDetailPage extends StatefulWidget {
//   const UnlockRecordDetailPage({super.key});

//   @override
//   State<UnlockRecordDetailPage> createState() =>
//       _UnlockRecordDetailPageState();
// }

// class _UnlockRecordDetailPageState extends State<UnlockRecordDetailPage> {
//   final ScrollController _scrollController = ScrollController();
//   final UsageReportController _controller = Get.find<UsageReportController>();

//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: Center(
//         child: Container(
//           constraints: const BoxConstraints(maxWidth: 600),
//           child: Obx(() {
//             final controller = Get.find<UsageReportController>();
            
//             // 检查是否所有敏感度筛选都未选中
//             final hasNoSensitiveLevelSelected = !controller.filterHighSensitive.value && 
//                                                !controller.filterMediumSensitive.value && 
//                                                !controller.filterLowSensitive.value;
            
//             if (hasNoSensitiveLevelSelected) {
//               return _buildNoSensitiveLevelSelectedState();
//             }
            
//             // 获取所有解锁相关的记录（14、15、19类型）
//             final allUnlockRecords = _getAllUnlockRecords();
//             final unlockCount = _getUnlockCount();
            
//             // 如果没有数据，显示空状态
//             if (allUnlockRecords.isEmpty) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Image.asset(
//                       'assets/phone_history/kissu_phone_list_empty.webp',
//                       width: 128,
//                       height: 128,
//                     ),
//                     const SizedBox(height: 16),
//                     const Text(
//                       '暂无解锁记录',
//                       style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
//                     ),
//                   ],
//                 ),
//               );
//             }
            
//             return CustomScrollView(
//               controller: _scrollController,
//               slivers: [
//                 // 标题
//                 SliverToBoxAdapter(
//                   child: _buildTitleWithCount(unlockCount),
//                 ),
//                 // 图表部分作为header（图表数据暂时为空，接口还没做好）
//                 // SliverToBoxAdapter(
//                 //   child: _buildChartsSection(data),
//                 // ),
//                 // 记录列表
//                 SliverPadding(
//                   padding: const EdgeInsets.only(top: 12, bottom: 20),
//                   sliver: SliverList(
//                     delegate: SliverChildBuilderDelegate(
//                       (context, index) {
//                         return _buildMixedRecordItem(allUnlockRecords[index]);
//                       },
//                       childCount: allUnlockRecords.length,
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           }),
//         ),
//       ),
//     );
//   }


//   /// 获取所有解锁相关的记录
//   List<dynamic> _getAllUnlockRecords() {
//     final allRecords = <dynamic>[];
    
//     // 直接使用转换好的解锁记录数据
//     final unlockData = _controller.unlockRecordData.value;
//     if (unlockData != null && unlockData.records.isNotEmpty) {
//       // 按时间排序（最新的在前）
//       final sortedRecords = List<UnlockRecordItem>.from(unlockData.records);
//       sortedRecords.sort((a, b) => b.time.compareTo(a.time));
//       allRecords.addAll(sortedRecords);
//     }
    
//     return allRecords;
//   }
  
//   /// 获取解锁次数
//   int _getUnlockCount() {
//     final unlockData = _controller.unlockRecordData.value;
//     return unlockData?.unlockCount ?? 0;
//   }
  
//   /// 构建标题（带解锁次数）
//   Widget _buildTitleWithCount(int unlockCount) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20).copyWith(bottom: 5),
//       child: RichText(
//         text: TextSpan(
//           style: const TextStyle(
//             fontSize: 14,
//             color: Color(0xFF333333),
//             height: 1.5,
//           ),
//           children: [
//             const TextSpan(text: '解锁手机次数 ', style: TextStyle(fontSize: 14, color: Color(0xFF333333))),
//             TextSpan(
//               text: '$unlockCount',
//               style: const TextStyle(
//                 fontSize: 16,color: Color(0xFF333333),
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const TextSpan(text: ' 次', style: TextStyle(fontSize: 14, color: Color(0xFF333333))),
//           ],
//         ),
//       ),
//     );
//   }
  
//   /// 构建混合记录项（根据类型选择不同组件）
//   Widget _buildMixedRecordItem(dynamic record) {
//     // 现在主要处理UnlockRecordItem类型
//     if (record is UnlockRecordItem) {
//       return _buildRecordItem(record);
//     }
    
//     // 兜底：如果是RecordItem，使用通用组件
//     if (record is RecordItem) {
//       return GenericRecordItemWidget(
//         record: record,
//         showTimeLabel: false, // 解锁记录页面不显示时间标签
//         onVipStatusChanged: () {
//           // 解锁记录页面需要刷新混合记录数据
//           // 这里可以通过回调通知父页面刷新
//         },
//       );
//     }
    
//     return const SizedBox.shrink();
//   }
  

//   /// 构建记录项（根据eventType选择组件）
//   Widget _buildRecordItem(UnlockRecordItem record) {
//     // 类型19（解锁记录）使用专门的类型19组件
//     if (record.eventType == 19) {
//       return Type19UnlockRecordItemWidget(
//         record: record,
//         showTimeLabel: true, // 解锁记录页面显示时间标签
//       );
//     }
    
//     // 其他类型使用普通解锁记录组件
//     return UnlockRecordItemWidget(record: record);
//   }

//   /// 构建未选择敏感度筛选的状态
//   Widget _buildNoSensitiveLevelSelectedState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Image.asset('assets/phone_history/kissu_phone_list_empty.webp', width: 128, height: 128),
//           const SizedBox(height: 16),
//           const Text(
//             '请选择敏感度筛选条件',
//             style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             '在右上角筛选中选择高敏感、中敏感或低敏感',
//             style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)),
//           ),
//         ],
//       ),
//     );
//   }
// }

