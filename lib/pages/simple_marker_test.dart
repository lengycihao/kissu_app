// import 'package:flutter/material.dart';
// import 'package:amap_map/amap_map.dart';
// import 'package:x_amap_base/x_amap_base.dart';
// import 'package:kissu_app/widgets/safe_amap_widget.dart';

// class SimpleMarkerTestPage extends StatefulWidget {
//   const SimpleMarkerTestPage({super.key});

//   @override
//   State<SimpleMarkerTestPage> createState() => _SimpleMarkerTestPageState();
// }

// class _SimpleMarkerTestPageState extends State<SimpleMarkerTestPage> {
//   AMapController? mapController;
//   Set<Marker> markers = {};

//   @override
//   void initState() {
//     super.initState();
//     _createSimpleMarkers();
//   }

//   void _createSimpleMarkers() async {
//     print('🔄 开始创建简单标记测试...');
    
//     try {
//       // 基础位置
//       const baseLat = 30.2751;
//       const baseLng = 120.2216;
      
//       final testMarkers = <Marker>[];
      
//       // 1. 默认标记（红色）
//       testMarkers.add(Marker(
//         position: LatLng(baseLat, baseLng),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//         infoWindow: InfoWindow(
//           title: '🔴 默认红色标记',
//           snippet: '这是一个默认的红色标记',
//         ),
//       ));
      
//       // 2. 默认标记（蓝色）
//       testMarkers.add(Marker(
//         position: LatLng(baseLat + 0.001, baseLng + 0.001),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//         infoWindow: InfoWindow(
//           title: '🔵 默认蓝色标记',
//           snippet: '这是一个默认的蓝色标记',
//         ),
//       ));
      
//       // 3. 尝试使用PNG图片
//       print('📸 尝试加载PNG图片...');
//       try {
//         final pngIcon = await BitmapDescriptor.fromAssetImage(
//           createLocalImageConfiguration(context, size: Size(32, 32)),
//           'assets/kissu_home_notiicon.png',
//         );
//         print('✅ PNG图片加载成功');
        
//         testMarkers.add(Marker(
//           position: LatLng(baseLat + 0.002, baseLng + 0.002),
//           icon: pngIcon,
//           infoWindow: InfoWindow(
//             title: '🔔 PNG图标标记',
//             snippet: '使用PNG格式的自定义图标',
//           ),
//         ));
//       } catch (pngError) {
//         print('❌ PNG图片加载失败: $pngError');
//       }
      
//       // 4. 尝试使用另一个PNG图片
//       print('📸 尝试加载另一个PNG图片...');
//       try {
//         final png2Icon = await BitmapDescriptor.fromAssetImage(
//           createLocalImageConfiguration(context, size: Size(32, 32)),
//           'assets/kissu_home_moneyicon.png',
//         );
//         print('✅ 第二个PNG图片加载成功');
        
//         testMarkers.add(Marker(
//           position: LatLng(baseLat + 0.003, baseLng + 0.003),
//           icon: png2Icon,
//           infoWindow: InfoWindow(
//             title: '💰 金币图标标记',
//             snippet: '使用金币PNG格式的自定义图标',
//           ),
//         ));
//       } catch (png2Error) {
//         print('❌ 第二个PNG图片加载失败: $png2Error');
//       }
      
//       setState(() {
//         markers = testMarkers.toSet();
//       });
      
//       print('✅ 简单标记创建完成: ${markers.length}个标记');
      
//     } catch (e, stackTrace) {
//       print('❌ 简单标记创建失败: $e');
//       print('📝 错误堆栈: $stackTrace');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('简单标记测试'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: () {
//               _createSimpleMarkers();
//             },
//           ),
//         ],
//       ),
//       body: SafeAmapWidget(
//         initialCameraPosition: CameraPosition(
//           target: LatLng(30.2751, 120.2216),
//           zoom: 15,
//         ),
//         markers: markers,
//         onMapCreated: (AMapController controller) {
//           mapController = controller;
//           print('✅ 地图初始化完成');
//         },
//         onTap: (LatLng position) {
//           print('📍 地图点击位置: ${position.latitude}, ${position.longitude}');
//         },
//       ),
//       floatingActionButton: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           FloatingActionButton(
//             heroTag: "refresh",
//             onPressed: _createSimpleMarkers,
//             child: Icon(Icons.refresh),
//             tooltip: '刷新标记',
//           ),
//           SizedBox(height: 10),
//           FloatingActionButton(
//             heroTag: "info",
//             onPressed: () {
//               showDialog(
//                 context: context,
//                 builder: (context) => AlertDialog(
//                   title: Text('标记信息'),
//                   content: Text('当前地图上有 ${markers.length} 个标记'),
//                   actions: [
//                     TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: Text('确定'),
//                     ),
//                   ],
//                 ),
//               );
//             },
//             child: Icon(Icons.info),
//             tooltip: '显示信息',
//           ),
//         ],
//       ),
//     );
//   }
// }
