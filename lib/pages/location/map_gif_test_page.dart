import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/pages/location/services/marker_builder.dart';
import 'package:kissu_app/widgets/safe_amap_widget.dart';

/// GIF动画Marker测试页面
/// 
/// 展示三个marker（使用相同经纬度+不同锚点实现并排）：
/// 1. 我的头像marker（锚点偏右，显示在左边）
/// 2. Ta的头像marker（锚点偏左，显示在右边）
/// 3. GIF动画marker（锚点在顶部，显示在头像下方）
class MapGifTestPage extends StatefulWidget {
  const MapGifTestPage({super.key});

  @override
  State<MapGifTestPage> createState() => _MapGifTestPageState();
}

class _MapGifTestPageState extends State<MapGifTestPage> {
  AMapController? _mapController;
  final MarkerBuilder _markerBuilder = MarkerBuilder();
  
  // 测试坐标点（北京天安门附近）
  // 三个marker使用相同经纬度，通过不同锚点实现并排布局
  static const LatLng _testPosition = LatLng(39.909187, 116.397451);
  
  Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _gifStarted = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // 停止所有动画
    if (_mapController != null) {
      if (_gifStarted) {
        _mapController!.stopGifAnimation(markerId: 'gif_marker');
      }
      // 停止摆动动画
      _mapController!.stopSwingAnimation(markerId: 'partner_marker');
      _mapController!.stopSwingAnimation(markerId: 'my_marker');
    }
    super.dispose();
  }

  Future<void> _onMapCreated(AMapController controller) async {
    _mapController = controller;
    
    // 延迟创建markers，确保地图已完全初始化
    await Future.delayed(const Duration(milliseconds: 500));
    
    await _createMarkers();
  }

  Future<void> _createMarkers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final Set<Marker> markers = {};
      
      // 获取用户头像
      final user = UserManager.currentUser;
      final myAvatarUrl = user?.headPortrait ?? '';
      final partnerAvatarUrl = user?.loverInfo?.headPortrait ?? 
                               user?.halfUserInfo?.headPortrait ?? '';

      // 🎯 三个marker使用相同经纬度，通过不同锚点实现并排布局
      // 锚点原理：锚点是图标上的哪个点对准经纬度坐标
      // - Ta的头像（左边）：锚点偏右(1.0, 0.5)，逆时针旋转20度，尖尖指向中间
      // - 我的头像（右边）：锚点偏左(0.0, 0.5)，顺时针旋转20度，尖尖指向中间
      // - GIF动画：在两个头像底部尖尖下方

      // 1. 创建Ta的头像marker（左边，逆时针旋转20度）
      final partnerMarkerData = await _markerBuilder.createAvatarWithBgMarker(
        partnerAvatarUrl,
        defaultAsset: 'assets/3.0/kissu3_love_avater.webp',
        bgAsset: 'assets/images/kissu_map_avair_bg.webp',
        designAvatarSize: 50.0,   // 头像尺寸
        designBgWidth: 60.0,      // 背景图宽度
        designBgHeight: 65.0,     // 背景图高度
        avatarOffsetY: 5.5,       // 头像在背景图中的Y偏移
        rotationDegrees: -20.0,   // 逆时针旋转20度
      );
      final partnerIcon = partnerMarkerData['descriptor'] as BitmapDescriptor?;

      final partnerAnchor = partnerMarkerData['anchor'] as Offset? ?? const Offset(0.5, 1.0);
      // 左边头像：在计算出的锚点基础上，X向左偏移一点，让头像显示在坐标左边
      final partnerAnchorAdjusted = Offset(partnerAnchor.dx + 0.5, partnerAnchor.dy);
      if (partnerIcon != null) {
        final partnerMarker = Marker(
          position: _testPosition,  // 使用相同坐标
          icon: partnerIcon,
          anchor: partnerAnchorAdjusted,  // 调整后的锚点，让头像在左边
          zIndex: 2.0,
          clickable: true,
        );
        partnerMarker.setIdForCopy('partner_marker');
        markers.add(partnerMarker);
        debugPrint('✅ Ta的头像marker创建成功（左边），锚点: $partnerAnchorAdjusted');
      }

      // 2. 创建我的头像marker（右边，顺时针旋转20度）
      final myMarkerData = await _markerBuilder.createAvatarWithBgMarker(
        myAvatarUrl,
        defaultAsset: 'assets/3.0/kissu3_love_avater.webp',
        bgAsset: 'assets/images/kissu_map_avair_bg.webp',
        designAvatarSize: 50.0,
        designBgWidth: 60.0,
        designBgHeight: 65.0,
        avatarOffsetY: 5.5,
        rotationDegrees: 20.0,    // 顺时针旋转20度
      );
      final myIcon = myMarkerData['descriptor'] as BitmapDescriptor?;

      final myAnchor = myMarkerData['anchor'] as Offset? ?? const Offset(0.5, 1.0);
      // 右边头像：在计算出的锚点基础上，X向右偏移一点，让头像显示在坐标右边
      final myAnchorAdjusted = Offset(myAnchor.dx - 0.5, myAnchor.dy);
      if (myIcon != null) {
        final myMarker = Marker(
          position: _testPosition,  // 使用相同坐标
          icon: myIcon,
          anchor: myAnchorAdjusted,  // 调整后的锚点，让头像在右边
          zIndex: 2.0,
          clickable: true,
        );
        myMarker.setIdForCopy('my_marker');
        markers.add(myMarker);
        debugPrint('✅ 我的头像marker创建成功（右边），锚点: $myAnchorAdjusted');
      }

      // 3. 创建GIF动画marker（在两人头像底部尖尖下方）
      // 锚点Y值为负数，使GIF顶部在坐标点上方，这样GIF主体就在头像尖尖下方
      // 锚点(0.5, -0.1)表示：锚点在图标顶部再往上10%的位置
      final gifMarker = Marker(
        position: _testPosition,  // 使用相同坐标
        icon: BitmapDescriptor.defaultMarker,
        anchor: const Offset(0.5, 0.8),  // 锚点在顶部偏上，GIF主体在头像尖尖下方
        zIndex: 1.0, // 在头像下方（zIndex小于头像）
        clickable: false,
      );
      gifMarker.setIdForCopy('gif_marker');
      markers.add(gifMarker);
      debugPrint('✅ GIF占位marker创建成功');

      if (mounted) {
        setState(() {
          _markers = markers;
          _isLoading = false;
        });
      }

      // 启动GIF动画（异步加载，无需等待）
      await Future.delayed(const Duration(milliseconds: 100));
      if (_mapController != null && mounted) {
        // 获取设备像素比，计算实际像素尺寸
        final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
        // GIF显示尺寸：100x100逻辑像素，转换为物理像素
        final gifSizeW   = (498/2 * devicePixelRatio).toInt();
        final gifSizeH   = (633/2 * devicePixelRatio).toInt();
        
        final success = await _mapController!.startGifAnimation(
          markerId: 'gif_marker',
          assetPath: 'assets/gif/ceshi.gif',
          width: gifSizeW,   // GIF宽度（像素）
          height: gifSizeH,  // GIF高度（像素）
        );
        if (success) {
          _gifStarted = true;
          debugPrint('✅ GIF动画启动成功，尺寸: ${gifSizeW}x$gifSizeH');
        } else {
          debugPrint('❌ GIF动画启动失败');
        }
        
        // 🔄 启动头像摆动动画（雨刷器效果）
        // 左边头像（Ta）：从-20度摆动到-5度（向右摆，靠近中间）
        await _mapController!.startSwingAnimation(
          markerId: 'partner_marker',
          fromAngle: -20.0,
          toAngle: -5.0,
          duration: 800,
        );
        debugPrint('✅ Ta的头像摆动动画启动');
        
        // 右边头像（我）：从20度摆动到5度（向左摆，靠近中间）
        await _mapController!.startSwingAnimation(
          markerId: 'my_marker',
          fromAngle: 20.0,
          toAngle: 5.0,
          duration: 800,
        );
        debugPrint('✅ 我的头像摆动动画启动');
      }

    } catch (e) {
      debugPrint('❌ 创建markers失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GIF Marker测试'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          // 地图
          SafeAMapWidget(
            initialCameraPosition: CameraPosition(
              target: _testPosition,
              zoom: 18.0,
            ),
            onMapCreated: _onMapCreated,
            markers: _markers,
            compassEnabled: true,
            scaleEnabled: true,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
          ),
          
          // 加载指示器
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.pink,
                ),
              ),
            ),
          
          // 说明文字
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'GIF Marker测试页面',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 两个头像marker并列展示\n'
                    '• GIF动画在两人底部中间\n'
                    '• GIF: assets/gif/ceshi.gif',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
