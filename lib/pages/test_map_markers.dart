import 'package:flutter/material.dart';
import 'package:amap_map/amap_map.dart';
import 'package:x_amap_base/x_amap_base.dart';
import 'package:kissu_app/widgets/safe_amap_widget.dart';
import 'dart:math' as math;

class TestMapMarkersPage extends StatefulWidget {
  const TestMapMarkersPage({super.key});

  @override
  State<TestMapMarkersPage> createState() => _TestMapMarkersPageState();
}

class _TestMapMarkersPageState extends State<TestMapMarkersPage> {
  AMapController? mapController;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    // 异步创建测试标记
    _initializeMarkers();
  }
  
  void _initializeMarkers() async {
    await _createTestMarkers();
    setState(() {
      // 标记创建完成后刷新界面
    });
  }

  // 处理地图点击事件，检测是否点击了marker
  void _handleMapTap(LatLng position) {
    print('🗺️ 地图点击位置: ${position.latitude}, ${position.longitude}');
    
    // 检查点击位置是否接近任何marker
    for (var marker in markers) {
      double distance = _calculateDistance(position, marker.position);
      if (distance < 50) { // 50米范围内认为是点击了marker
        _onMarkerTapped(marker);
        return;
      }
    }
    
    print('🗺️ 点击了空白区域');
  }

  // 处理marker点击
  void _onMarkerTapped(Marker marker) {
    print('🎯 点击了marker: ${marker.infoWindow.title}');
    
    // 显示弹窗
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(marker.infoWindow.title ?? 'Marker'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('位置: ${marker.position.latitude.toStringAsFixed(6)}, ${marker.position.longitude.toStringAsFixed(6)}'),
              if (marker.infoWindow.snippet != null)
                Text('详情: ${marker.infoWindow.snippet}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _moveToMarker(marker);
              },
              child: const Text('移动到此位置'),
            ),
          ],
        );
      },
    );
  }

  // 计算两点之间的距离（米）
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // 地球半径，单位：米
    
    double lat1Rad = point1.latitude * (3.14159265359 / 180);
    double lat2Rad = point2.latitude * (3.14159265359 / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (3.14159265359 / 180);
    double deltaLngRad = (point2.longitude - point1.longitude) * (3.14159265359 / 180);
    
    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  // 移动地图到指定marker
  void _moveToMarker(Marker marker) async {
    if (mapController != null) {
      try {
        await mapController!.moveCamera(
          CameraUpdate.newLatLng(marker.position),
        );
        print('📍 移动到marker位置: ${marker.position.latitude}, ${marker.position.longitude}');
      } catch (e) {
        print('❌ 移动相机失败: $e');
      }
    }
  }

  Future<void> _createTestMarkers() async {
    print('🧪 开始创建自定义图片标记...');
    
    // 生成随机位置
    final random = DateTime.now().millisecondsSinceEpoch;
    final baseLat = 30.2751 + (random % 100) / 10000.0; // 添加随机偏移
    final baseLng = 120.2216 + (random % 100) / 10000.0;
    
    try {
      print('🔄 开始创建自定义标记...');
      
      // 创建自定义图片标记
      final customMarkers = <Marker>[];
      
      // 1. 使用心形图标作为marker
      print('📸 加载心形图标...');
      final heartIcon = await BitmapDescriptor.fromAssetImage(
        createLocalImageConfiguration(context, size: Size(48, 48)),
        'assets/kissu_heart.webp',
      );
      print('✅ 心形图标加载成功');
      
      customMarkers.add(Marker(
          position: LatLng(baseLat, baseLng),
        icon: heartIcon,
          infoWindow: InfoWindow(
          title: '💖 爱心标记 ${DateTime.now().second}',
          snippet: '使用自定义心形图标的标记 - ${DateTime.now().millisecondsSinceEpoch}',
        ),
      ));
      
      // 2. 使用位置图标作为marker
      print('📸 加载位置图标...');
      final locationIcon = await BitmapDescriptor.fromAssetImage(
        createLocalImageConfiguration(context, size: Size(48, 48)),
        'assets/kissu_location_circle.webp',
      );
      print('✅ 位置图标加载成功');
      
      customMarkers.add(Marker(
          position: LatLng(baseLat + 0.001, baseLng + 0.001),
        icon: locationIcon,
          infoWindow: InfoWindow(
          title: '📍 位置标记 ${DateTime.now().second}',
          snippet: '使用自定义位置图标的标记 - ${DateTime.now().millisecondsSinceEpoch}',
        ),
      ));
      
      // 3. 使用应用图标作为marker
      print('📸 加载应用图标...');
      final appIcon = await BitmapDescriptor.fromAssetImage(
        createLocalImageConfiguration(context, size: Size(48, 48)),
        'assets/kissu_icon.webp',
      );
      print('✅ 应用图标加载成功');
      
      customMarkers.add(Marker(
          position: LatLng(baseLat + 0.002, baseLng + 0.002),
        icon: appIcon,
          infoWindow: InfoWindow(
          title: '🏠 应用标记 ${DateTime.now().second}',
          snippet: '使用应用图标的标记 - ${DateTime.now().millisecondsSinceEpoch}',
        ),
      ));
      
      // 4. 使用追踪位置图标作为marker
      print('📸 加载追踪图标...');
      final trackIcon = await BitmapDescriptor.fromAssetImage(
        createLocalImageConfiguration(context, size: Size(48, 48)),
        'assets/kissu_track_location.webp',
      );
      print('✅ 追踪图标加载成功');
      
      customMarkers.add(Marker(
          position: LatLng(baseLat + 0.003, baseLng + 0.003),
        icon: trackIcon,
          infoWindow: InfoWindow(
          title: '🎯 追踪标记 ${DateTime.now().second}',
          snippet: '使用自定义追踪图标的标记 - ${DateTime.now().millisecondsSinceEpoch}',
        ),
      ));
      
      // 5. 使用PNG格式图片测试兼容性
      print('📸 加载PNG图标...');
      final pngIcon = await BitmapDescriptor.fromAssetImage(
        createLocalImageConfiguration(context, size: Size(48, 48)),
        'assets/kissu_home_notiicon.png',
      );
      print('✅ PNG图标加载成功');
      
      customMarkers.add(Marker(
        position: LatLng(baseLat - 0.001, baseLng - 0.001),
        icon: pngIcon,
        infoWindow: InfoWindow(
          title: '🔔 通知图标 ${DateTime.now().second}',
          snippet: '使用PNG格式图标的标记 - ${DateTime.now().millisecondsSinceEpoch}',
        ),
      ));
      
      // 6. 使用默认标记作为对比
      customMarkers.add(Marker(
          position: LatLng(baseLat + 0.004, baseLng + 0.004),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
          title: '🔴 默认标记 ${DateTime.now().second}',
          snippet: '默认红色标记作为对比 - ${DateTime.now().millisecondsSinceEpoch}',
        ),
      ));
      
      // 添加所有标记到集合中
      markers.addAll(customMarkers);
      
      print('✅ 测试标记创建成功: ${markers.length}个');
      print('📍 标记位置: 基础位置($baseLat, $baseLng)');
    } catch (e, stackTrace) {
      print('❌ 测试标记创建失败: $e');
      print('📝 错误堆栈: $stackTrace');
      
      // 降级方案：使用无图标的标记
      try {
        markers.addAll([
          Marker(
            position: LatLng(baseLat, baseLng),
            infoWindow: InfoWindow(
              title: '默认标记1 ${DateTime.now().second}',
              snippet: '无图标标记测试 - ${DateTime.now().millisecondsSinceEpoch}',
            ),
          ),
          Marker(
            position: LatLng(baseLat + 0.001, baseLng + 0.001),
            infoWindow: InfoWindow(
              title: '默认标记2 ${DateTime.now().second}',
              snippet: '无图标标记测试 - ${DateTime.now().millisecondsSinceEpoch}',
            ),
          ),
        ]);
        print('✅ 降级标记创建成功: ${markers.length}个');
      } catch (fallbackError) {
        print('❌ 降级方案也失败: $fallbackError');
      }
    }
  }

  void _createCustomMarkers() async {
    print('🎨 开始创建自定义标记...');
    
    // 生成随机位置
    final random = DateTime.now().millisecondsSinceEpoch;
    final baseLat = 30.2751 + (random % 100) / 10000.0;
    final baseLng = 120.2216 + (random % 100) / 10000.0;
    
    try {
      // 使用有效的图片资源
      BitmapDescriptor? validImageIcon;
      try {
        validImageIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(48, 48)),
          'assets/kissu_icon.webp',
        );
        print('✅ 有效图片加载成功: kissu_icon.webp');
      } catch (e) {
        print('❌ 有效图片加载失败: $e');
      }
      
      // 创建彩色标记
      final startIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      final endIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      final stayIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      final currentIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      final backupIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      
      markers.addAll([
        // 如果有效图片可用，使用它
        if (validImageIcon != null)
          Marker(
            position: LatLng(baseLat - 0.001, baseLng - 0.001),
            icon: validImageIcon,
            infoWindow: InfoWindow(
              title: '有效图片标记 ${DateTime.now().second}',
              snippet: '使用kissu_icon.webp - ${DateTime.now().millisecondsSinceEpoch}',
            ),
          ),
        Marker(
          position: LatLng(baseLat, baseLng),
          icon: startIcon,
          infoWindow: InfoWindow(
            title: '起点标记 ${DateTime.now().second}',
            snippet: '使用绿色彩色标记 - ${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
        Marker(
          position: LatLng(baseLat + 0.001, baseLng + 0.001),
          icon: endIcon,
          infoWindow: InfoWindow(
            title: '终点标记 ${DateTime.now().second}',
            snippet: '使用红色彩色标记 - ${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
        Marker(
          position: LatLng(baseLat + 0.002, baseLng + 0.002),
          icon: stayIcon,
          infoWindow: InfoWindow(
            title: '停留点标记 ${DateTime.now().second}',
            snippet: '使用蓝色彩色标记 - ${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
        Marker(
          position: LatLng(baseLat + 0.003, baseLng + 0.003),
          icon: currentIcon,
          infoWindow: InfoWindow(
            title: '当前位置标记 ${DateTime.now().second}',
            snippet: '使用橙色彩色标记 - ${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
        Marker(
          position: LatLng(baseLat + 0.004, baseLng + 0.004),
          icon: backupIcon,
          infoWindow: InfoWindow(
            title: '备用标记 ${DateTime.now().second}',
            snippet: '使用紫色彩色标记 - ${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
      ]);
      
      print('✅ 自定义标记创建成功: ${markers.length}个');
      print('📍 标记位置: 基础位置($baseLat, $baseLng)');
      
      // 更新UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('❌ 自定义标记创建失败: $e');
      
      // 降级方案：使用彩色默认标记
      try {
        markers.addAll([
          Marker(
            position: LatLng(baseLat, baseLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: '起点降级标记 ${DateTime.now().second}',
              snippet: '使用彩色默认标记 - ${DateTime.now().millisecondsSinceEpoch}',
            ),
          ),
          Marker(
            position: LatLng(baseLat + 0.001, baseLng + 0.001),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: '终点降级标记 ${DateTime.now().second}',
              snippet: '使用彩色默认标记 - ${DateTime.now().millisecondsSinceEpoch}',
            ),
          ),
          Marker(
            position: LatLng(baseLat + 0.002, baseLng + 0.002),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(
              title: '停留点降级标记 ${DateTime.now().second}',
              snippet: '使用彩色默认标记 - ${DateTime.now().millisecondsSinceEpoch}',
            ),
          ),
          Marker(
            position: LatLng(baseLat + 0.003, baseLng + 0.003),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: '当前位置降级标记 ${DateTime.now().second}',
              snippet: '使用彩色默认标记 - ${DateTime.now().millisecondsSinceEpoch}',
            ),
          ),
        ]);
        print('✅ 降级标记创建成功: ${markers.length}个');
        
        // 更新UI
        if (mounted) {
          setState(() {});
        }
      } catch (fallbackError) {
        print('❌ 降级方案也失败: $fallbackError');
        
        // 最终降级：使用无图标的基础标记
        try {
          markers.addAll([
            Marker(
              position: LatLng(baseLat, baseLng),
              infoWindow: InfoWindow(
                title: '基础标记1 ${DateTime.now().second}',
                snippet: '最终降级方案 - ${DateTime.now().millisecondsSinceEpoch}',
              ),
            ),
            Marker(
              position: LatLng(baseLat + 0.001, baseLng + 0.001),
              infoWindow: InfoWindow(
                title: '基础标记2 ${DateTime.now().second}',
                snippet: '最终降级方案 - ${DateTime.now().millisecondsSinceEpoch}',
              ),
            ),
          ]);
          print('✅ 基础标记创建成功: ${markers.length}个');
          
          // 更新UI
          if (mounted) {
            setState(() {});
          }
        } catch (finalError) {
          print('❌ 所有降级方案都失败: $finalError');
        }
      }
    }
  }

  void _createMixedMarkers() async {
    print('🎯 开始创建混合标记（自定义+默认）...');
    
    // 生成随机位置
    final random = DateTime.now().millisecondsSinceEpoch;
    final baseLat = 30.2751 + (random % 100) / 10000.0;
    final baseLng = 120.2216 + (random % 100) / 10000.0;
    
    try {
      // 尝试加载一个自定义图标
      BitmapDescriptor? customIcon;
      try {
        customIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(48, 48)),
          'assets/kissu_icon.webp', // 替换损坏的PNG文件
        );
        print('✅ 自定义图标加载成功');
      } catch (e) {
        print('⚠️ 自定义图标加载失败: $e，使用彩色默认标记');
        customIcon = null;
      }
      
      // 创建混合标记
      markers.addAll([
        // 自定义图标标记（如果加载成功）
        if (customIcon != null)
          Marker(
            position: LatLng(baseLat, baseLng),
            icon: customIcon,
            infoWindow: InfoWindow(
              title: '自定义图标标记 ${DateTime.now().second}',
              snippet: '使用assets/markers/start_point.png',
            ),
          ),
        
        // 彩色默认标记
        Marker(
          position: LatLng(baseLat + 0.001, baseLng + 0.001),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '红色默认标记 ${DateTime.now().second}',
            snippet: '使用彩色默认标记',
          ),
        ),
        
        Marker(
          position: LatLng(baseLat + 0.002, baseLng + 0.002),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: '绿色默认标记 ${DateTime.now().second}',
            snippet: '使用彩色默认标记',
          ),
        ),
        
        // 无图标标记（系统默认）
        Marker(
          position: LatLng(baseLat + 0.003, baseLng + 0.003),
          infoWindow: InfoWindow(
            title: '系统默认标记 ${DateTime.now().second}',
            snippet: '无自定义图标的标记',
          ),
        ),
      ]);
      
      print('✅ 混合标记创建成功: ${markers.length}个');
      print('📍 标记位置: 基础位置($baseLat, $baseLng)');
      
      // 更新UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('❌ 混合标记创建失败: $e');
      
      // 降级方案：只使用彩色默认标记
      try {
        markers.addAll([
          Marker(
            position: LatLng(baseLat, baseLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(
              title: '蓝色降级标记 ${DateTime.now().second}',
              snippet: '混合标记降级方案',
            ),
          ),
          Marker(
            position: LatLng(baseLat + 0.001, baseLng + 0.001),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: '橙色降级标记 ${DateTime.now().second}',
              snippet: '混合标记降级方案',
            ),
          ),
        ]);
        print('✅ 混合标记降级方案成功: ${markers.length}个');
        
        // 更新UI
        if (mounted) {
          setState(() {});
        }
      } catch (fallbackError) {
        print('❌ 混合标记降级方案也失败: $fallbackError');
      }
    }
  }

  void _debugCustomMarkers() async {
    print('🔍🔍🔍 ===== 开始深度调试自定义标记 =====');
    
    // 1. 检查Flutter服务是否可用
    print('1️⃣ 检查Flutter服务状态...');
    try {
      final binding = WidgetsBinding.instance;
      print('✅ WidgetsBinding可用: ${binding.toString()}');
    } catch (e) {
      print('❌ WidgetsBinding检查失败: $e');
    }
    
    // 2. 检查AssetBundle是否可用
    print('2️⃣ 检查AssetBundle...');
    try {
      final bundle = DefaultAssetBundle.of(context);
      print('✅ AssetBundle获取成功: ${bundle.toString()}');
      
      // 尝试直接加载图片数据
      final testPaths = [
        'assets/kissu_icon.webp', // 替换损坏的PNG文件
        'assets/kissu_icon.webp', // 已知存在的图片
      ];
      
      for (final path in testPaths) {
        try {
          final data = await bundle.load(path);
          print('✅ 图片数据加载成功: $path (${data.lengthInBytes} bytes)');
        } catch (e) {
          print('❌ 图片数据加载失败: $path - $e');
        }
      }
    } catch (e) {
      print('❌ AssetBundle检查失败: $e');
    }
    
    // 3. 尝试不同的BitmapDescriptor创建方法
    print('3️⃣ 测试BitmapDescriptor创建方法...');
    
    final baseLat = 30.2751;
    final baseLng = 120.2216;
    
    // 方法1: fromAssetImage with different configurations
    print('📋 方法1: fromAssetImage');
    try {
      final configs = [
        const ImageConfiguration(),
        const ImageConfiguration(size: Size(32, 32)),
        const ImageConfiguration(size: Size(48, 48)),
        const ImageConfiguration(size: Size(64, 64)),
        ImageConfiguration(
          size: const Size(48, 48),
          devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
        ),
      ];
      
      for (int i = 0; i < configs.length; i++) {
        try {
          final icon = await BitmapDescriptor.fromAssetImage(
            configs[i],
            'assets/kissu_icon.webp', // 替换损坏的PNG文件
          );
          
          final marker = Marker(
            position: LatLng(baseLat + i * 0.0005, baseLng),
            icon: icon,
            infoWindow: InfoWindow(
              title: 'Method1-$i',
              snippet: 'Config: ${configs[i].size}',
            ),
          );
          
          markers.add(marker);
          print('✅ 方法1-$i 成功: ${configs[i].size}');
        } catch (e) {
          print('❌ 方法1-$i 失败: $e');
        }
      }
    } catch (e) {
      print('❌ 方法1整体失败: $e');
    }
    
    // 方法2: 使用asset路径的不同变体
    print('📋 方法2: 不同路径格式');
    final pathVariants = [
      'assets/markers/start_point.png',
      'assets/markers/end_point.png',
      'assets/markers/stay_point.png',
      'assets/markers/current_location.png',
    ];
    
    for (int i = 0; i < pathVariants.length; i++) {
      try {
        final icon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(40, 40)),
          pathVariants[i],
        );
        
        final marker = Marker(
          position: LatLng(baseLat, baseLng + i * 0.0005),
          icon: icon,
          infoWindow: InfoWindow(
            title: 'Method2-$i',
            snippet: pathVariants[i].split('/').last,
          ),
        );
        
        markers.add(marker);
        print('✅ 方法2-$i 成功: ${pathVariants[i]}');
      } catch (e) {
        print('❌ 方法2-$i 失败: ${pathVariants[i]} - $e');
      }
    }
    
    // 方法3: 尝试使用已知存在的图片
    print('📋 方法3: 使用已知存在的图片');
    try {
      final icon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/kissu_icon.webp',
      );
      
      final marker = Marker(
        position: LatLng(baseLat + 0.002, baseLng + 0.002),
        icon: icon,
        infoWindow: const InfoWindow(
          title: 'Method3-Known',
          snippet: 'kissu_icon.webp',
        ),
      );
      
      markers.add(marker);
      print('✅ 方法3 成功: 使用已知图片');
    } catch (e) {
      print('❌ 方法3 失败: $e');
    }
    
    // 4. 添加对比标记（彩色默认标记）
    print('4️⃣ 添加对比标记...');
    try {
      final compareMarker = Marker(
        position: LatLng(baseLat + 0.003, baseLng + 0.003),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(
          title: 'Compare',
          snippet: '彩色默认标记对比',
        ),
      );
      
      markers.add(compareMarker);
      print('✅ 对比标记添加成功');
    } catch (e) {
      print('❌ 对比标记添加失败: $e');
    }
    
    print('🔍 调试完成，标记总数: ${markers.length}');
    print('🔍🔍🔍 ===== 深度调试结束 =====');
    
    // 更新UI
    if (mounted) {
      setState(() {});
    }
  }

  void _showAssetTestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Assets图片测试'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: Column(
              children: [
                const Text('测试assets/markers/目录下的图片是否能正常显示:'),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    children: [
                      _buildAssetTestItem('assets/markers/start_point.png', '起点'),
                      _buildAssetTestItem('assets/markers/end_point.png', '终点'),
                      _buildAssetTestItem('assets/markers/stay_point.png', '停留点'),
                      _buildAssetTestItem('assets/markers/current_location.png', '当前位置'),
                      _buildAssetTestItem('assets/kissu_icon.webp', '应用图标'),
                      _buildAssetTestItem('assets/kissu_home_tab_map.webp', '地图标签'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAssetTestItem(String assetPath, String label) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Image.asset加载失败: $assetPath - $error');
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      Text('加载失败', style: TextStyle(fontSize: 10, color: Colors.red)),
                    ],
                  );
                },
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (frame != null) {
                    print('✅ Image.asset加载成功: $assetPath');
                  }
                  return child;
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('地图标记测试'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SafeAMapWidget(
            initialCameraPosition: const CameraPosition(
              target: LatLng(30.2751, 120.2216),
              zoom: 15.0,
            ),
            onMapCreated: (AMapController controller) {
              mapController = controller;
              print('✅ 地图创建成功');
            },
            onTap: (LatLng position) {
              _handleMapTap(position);
            },
            markers: markers,
            compassEnabled: true,
            scaleEnabled: true,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '标记数量: ${markers.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        markers.clear();
                        _createTestMarkers();
                      });
                    },
                    child: const Text('重新创建标记'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        markers.clear();
                        _createCustomMarkers();
                      });
                    },
                    child: const Text('创建自定义标记'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        markers.clear();
                        _createMixedMarkers();
                      });
                    },
                    child: const Text('创建混合标记'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        markers.clear();
                        _debugCustomMarkers();
                      });
                    },
                    child: const Text('深度调试自定义标记'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      _showAssetTestDialog();
                    },
                    child: const Text('测试Assets图片'),
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
