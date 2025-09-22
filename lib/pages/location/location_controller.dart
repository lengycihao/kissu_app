import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/network/public/location_api.dart';
import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kissu_app/utils/map_zoom_calculator.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:http/http.dart' as http;

class LocationController extends GetxController {
  /// 当前查看的用户类型 (1: 自己, 0: 另一半)
  final isOneself = 0.obs; // 🎯 默认显示另一半
  
  /// 用户信息
  final myAvatar = "".obs;
  final partnerAvatar = "".obs;
  final isBindPartner = false.obs;
  
  /// 位置信息
  /// 🔧 修复：明确位置数据的含义
  /// myLocation 始终存储当前查看的用户位置（根据isOneself动态变化）
  /// partnerLocation 始终存储另一个用户的位置
  /// actualMyLocation 始终存储自己的实际位置
  /// actualPartnerLocation 始终存储另一半的实际位置
  final myLocation = Rx<LatLng?>(null);
  final partnerLocation = Rx<LatLng?>(null);
  final actualMyLocation = Rx<LatLng?>(null);
  final actualPartnerLocation = Rx<LatLng?>(null);
  
  /// 距离信息
  final distance = "0.00km".obs;
  final updateTime = "".obs;
  
  /// 当前位置信息
  final currentLocationText = "位置信息加载中...".obs;
  
  /// 设备信息
  final myDeviceModel = "未知".obs;
  final myBatteryLevel = "未知".obs;
  final myNetworkName = "WiFi".obs;
  final speed = "0m/s".obs;
  
  /// 设备详细信息 (用于长按显示)
  final isWifi = "1".obs; // 是否WiFi连接
  final deviceId = "".obs; // 设备ID
  final locationTime = "".obs; // 定位时间
  
  /// 位置记录列表
  final RxList<LocationRecord> locationRecords = <LocationRecord>[].obs;
  
  /// 🔧 新增：缓存API返回的数据，用于切换用户时更新列表
  UserLocationMobileDevice? _cachedUserLocationMobileDevice;
  UserLocationMobileDevice? _cachedHalfLocationMobileDevice;
  
  
  /// DraggableScrollableSheet 状态
  final sheetPercent = 0.3.obs;
  
  /// 地图控制器
  AMapController? mapController;
  
  /// 加载状态
  final isLoading = false.obs;
  
  
  // 轨迹起点和终点标记集合 - 改为RxList以提升响应式更新
  final RxList<Marker> _trackStartEndMarkers = <Marker>[].obs;
  final RxSet<Polyline> _polylines = <Polyline>{}.obs;
  
  /// 定位服务
  late SimpleLocationService _locationService;
  
  /// Tooltip相关
  OverlayEntry? _overlayEntry;
  late BuildContext pageContext;

  @override
  void onInit() {
    super.onInit();
    DebugUtil.info(' LocationController onInit 开始');
    try {
      // 加载用户信息
      DebugUtil.info(' 开始加载用户信息...');
      _loadUserInfo();
      DebugUtil.info(' 用户信息加载完成');
      
      // 初始化定位服务（不自动启动）
      DebugUtil.info(' 开始初始化定位服务...');
      _initLocationService();
      DebugUtil.info(' 定位服务初始化完成');
      
      // 只加载历史位置数据，不自动启动定位
      DebugUtil.info(' 开始调用loadLocationData...');
      loadLocationData();
      DebugUtil.info(' loadLocationData调用完成');
    } catch (e) {
      DebugUtil.error(' onInit执行异常: $e');
      DebugUtil.error(' 异常类型: ${e.runtimeType}');
      DebugUtil.error(' 异常堆栈: ${StackTrace.current}');
    }
    DebugUtil.info(' LocationController onInit 完成');
  }

  @override
  void onReady() {
    super.onReady();
    // 页面准备完成后，检查定位权限
    _checkLocationPermissionOnPageEnter();
  }
  
  /// 初始化定位服务
  void _initLocationService() {
    try {
      DebugUtil.info(' 开始初始化定位服务');
      _locationService = SimpleLocationService.instance;
      DebugUtil.info(' 定位服务实例获取成功');
      
      // 不再监听实时定位数据变化，改为单次定位模式
      DebugUtil.success(' 定位服务初始化完成（单次定位模式）');
    } catch (e) {
      DebugUtil.error(' 定位服务初始化失败: $e');
    }
  }
  
  /// 定位页面进入时检查权限并执行单次定位
  Future<void> _checkLocationPermissionOnPageEnter() async {
    try {
      DebugUtil.info(' 定位页面检查权限状态...');

      // 检查定位权限
      var locationStatus = await Permission.location.status;
      DebugUtil.info(' 定位权限状态: $locationStatus');

      if (locationStatus.isDenied || locationStatus.isPermanentlyDenied) {
        // 权限未授予，请求权限
        DebugUtil.info(' 定位页面权限未授予，开始请求权限');
        await _requestLocationPermissionAndStartService();
      } else if (locationStatus.isGranted) {
        // 权限已授予，启动定位服务
        DebugUtil.info(' 定位页面权限已授予，启动定位服务');
        await _locationService.startLocation();
      }
    } catch (e) {
      DebugUtil.error(' 定位页面检查权限失败: $e');
    }
  }

  /// 请求定位权限并启动服务
  Future<void> _requestLocationPermissionAndStartService() async {
    try {
      // 检查定位权限状态
      final permission = await Permission.location.status;
      
      if (permission.isGranted) {
        debugPrint('✅ 定位权限已授予');
        // 权限已授予，启动定位服务
        await _checkAndStartLocationService();
      } else if (permission.isDenied) {
        debugPrint('❌ 定位权限被拒绝，请求权限');
        // 权限被拒绝，请求权限
        final result = await Permission.location.request();
        if (result.isGranted) {
          debugPrint('✅ 定位权限获取成功');
          await _checkAndStartLocationService();
        } else {
          debugPrint('❌ 定位权限被拒绝');
          _showPermissionDeniedDialog();
        }
      } else if (permission.isPermanentlyDenied) {
        debugPrint('❌ 定位权限被永久拒绝');
        // 权限被永久拒绝，显示打开设置提示
        _showOpenSettingsDialog();
      } else {
        debugPrint('❓ 定位权限状态未知: $permission');
      }
    } catch (e) {
      debugPrint('请求定位权限并启动服务失败: $e');
    }
  }

  /// 显示权限被拒绝的提示弹窗
  void _showPermissionDeniedDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('权限被拒绝'),
        content: Text('需要定位权限才能正常使用定位功能，请允许定位权限。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              // 重新请求权限
              await _requestLocationPermissionAndStartService();
            },
            child: Text('重新授权'),
          ),
        ],
      ),
    );
  }

  /// 显示打开系统设置的提示弹窗
  void _showOpenSettingsDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('权限被拒绝'),
        content: Text('定位权限已被永久拒绝，请前往系统设置手动开启定位权限。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await openAppSettings();
            },
            child: Text('打开设置'),
          ),
        ],
      ),
    );
  }



  /// 检查并启动定位服务（仅在用户已登录时）
  Future<void> _checkAndStartLocationService() async {
    try {
      // 定位服务在初始化时已确保非空

      // 检查用户是否已登录
      if (!UserManager.isLoggedIn) {
        DebugUtil.info(' 用户未登录，跳过自动启动定位服务');
        return;
      }

      // 检查定位服务状态
      final status = _locationService.currentServiceStatus;
      DebugUtil.check(' 定位服务状态: $status');

      if (!_locationService.isLocationEnabled.value) {
        DebugUtil.launch(' 用户已登录，定位服务未启动，尝试启动...');

        // 启动定位服务
        bool success = await _locationService.startLocation();

        if (success) {
          DebugUtil.success(' 定位服务启动成功');
        } else {
          DebugUtil.error(' 定位服务启动失败');
        }
      } else {
        DebugUtil.info(' 定位服务已在运行');
      }
    } catch (e) {
      DebugUtil.error(' 检查并启动定位服务失败: $e');
    }
  }
  
  

  /// 加载用户信息
  void _loadUserInfo() {
    final user = UserManager.currentUser;
    if (user != null) {
      // 检查绑定状态
      final bindStatus = user.bindStatus.toString();
      isBindPartner.value = bindStatus.toString() == "1";
      
      bool avatarUpdated = false;
      
      // 设置默认头像（如果定位接口没有返回头像数据时使用）
      if (myAvatar.value.isEmpty) {
        myAvatar.value = user.headPortrait ?? '';
        if (myAvatar.value.isNotEmpty) {
          avatarUpdated = true;
          DebugUtil.info(' 设置我的初始头像: ${myAvatar.value}');
        }
      }
      
      if (isBindPartner.value && partnerAvatar.value.isEmpty) {
        // 已绑定状态，设置默认伴侣头像（如果定位接口没有返回头像数据时使用）
        if (user.loverInfo?.headPortrait?.isNotEmpty == true) {
          partnerAvatar.value = user.loverInfo!.headPortrait!;
          avatarUpdated = true;
          DebugUtil.info(' 设置伴侣初始头像: ${partnerAvatar.value}');
        } else if (user.halfUserInfo?.headPortrait?.isNotEmpty == true) {
          partnerAvatar.value = user.halfUserInfo!.headPortrait!;
          avatarUpdated = true;
          DebugUtil.info(' 设置伴侣初始头像: ${partnerAvatar.value}');
        }
      }
      
      // 如果头像有更新，标记需要重建，但等待 API 数据一起处理
      if (avatarUpdated) {
        DebugUtil.info(' 用户头像信息已更新，等待 API 数据后统一创建标记');
      }
      
      DebugUtil.info(' 用户信息加载完成');
    }
  }
  
  /// 创建带"虚拟TA"标签的头像标记
  Future<BitmapDescriptor> _createAvatarMarkerWithVirtualLabel(String avatarUrl, {String? defaultAsset}) async {
    try {
      // 创建画布 - 增加高度以容纳标签
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(110, 135); // 标记图片尺寸，高度增加50像素用于标签
      
      // 绘制背景标记图片
      final markerImage = await _loadImageFromAsset('assets/kissu_location_start.webp');
      if (markerImage != null) {
        // 计算缩放比例，确保图片完整显示在画布上
        final imageSize = Size(markerImage.width.toDouble(), markerImage.height.toDouble());
        final scaleX = size.width / imageSize.width;
        final scaleY = (size.height - 50) / imageSize.height; // 减去标签高度
        final scale = math.min(scaleX, scaleY); // 使用较小的缩放比例以保持比例
        
        final scaledWidth = imageSize.width * scale;
        final scaledHeight = imageSize.height * scale;
        
        // 居中绘制，向下偏移以留出标签空间
        final offsetX = (size.width - scaledWidth) / 2;
        final offsetY = 50 + (size.height - 50 - scaledHeight) / 2; // 向下偏移50像素
        
        final srcRect = Rect.fromLTWH(0, 0, imageSize.width, imageSize.height);
        final dstRect = Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight);
        
        canvas.drawImageRect(markerImage, srcRect, dstRect, Paint());
      }
      
      // 绘制圆形头像
      final avatarSize = 80.0;
      final avatarCenter = Offset(55, 78); // 头像中心点位置，调整以与普通标记对齐
      
      // 创建圆形裁剪区域
      final avatarRect = Rect.fromCenter(
        center: avatarCenter,
        width: avatarSize,
        height: avatarSize,
      );
      
      // 绘制头像背景圆形
      final avatarPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(avatarCenter, avatarSize / 2, avatarPaint);
      
      // 绘制头像边框
      final borderPaint = Paint()
        ..color = const Color(0xFFE8B4CB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.75; // 边框宽度
      canvas.drawCircle(avatarCenter, avatarSize / 2, borderPaint);
      
      // 加载并绘制头像
      ui.Image? avatarImage;
      if (avatarUrl.isNotEmpty) {
        try {
          if (avatarUrl.startsWith('http')) {
            // 网络图片
            final response = await http.get(Uri.parse(avatarUrl));
            if (response.statusCode == 200) {
              final codec = await ui.instantiateImageCodec(response.bodyBytes);
              final frame = await codec.getNextFrame();
              avatarImage = frame.image;
            }
          } else {
            // 本地资源图片
            avatarImage = await _loadImageFromAsset(avatarUrl);
          }
        } catch (e) {
          DebugUtil.error(' 加载头像失败: $e');
        }
      }
      
      // 如果头像加载失败，使用默认头像
      if (avatarImage == null && defaultAsset != null) {
        avatarImage = await _loadImageFromAsset(defaultAsset);
      }
      
      // 绘制头像
      if (avatarImage != null) {
        // 保存画布状态
        canvas.save();
        
        // 创建圆形裁剪路径
        final clipPath = Path()
          ..addOval(avatarRect);
        canvas.clipPath(clipPath);
        
        // 计算头像绘制位置，使其居中
        final srcRect = Rect.fromLTWH(0, 0, avatarImage.width.toDouble(), avatarImage.height.toDouble());
        final dstRect = avatarRect;
        
        canvas.drawImageRect(avatarImage, srcRect, dstRect, Paint());
        
        // 恢复画布状态
        canvas.restore();
      } else {
        // 如果没有头像，绘制默认图标
        final iconPaint = Paint()
          ..color = const Color(0xFFE8B4CB);
        canvas.drawCircle(avatarCenter, avatarSize / 2 - 12.5, iconPaint); // 调整内边距为12.5
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: '?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 125, // 字体大小放大2.5倍
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            avatarCenter.dx - textPainter.width / 2,
            avatarCenter.dy - textPainter.height / 2,
          ),
        );
      }
      
      // 绘制"虚拟TA"标签
      final labelRect = Rect.fromLTWH(
        size.width / 2 - 37.5, // 居中，宽度75
        5, // 距离顶部5像素
        75, // 宽度
        30, // 高度
      );
      
      final labelRRect = RRect.fromRectAndRadius(labelRect, const Radius.circular(6));
      
      // 绘制标签背景（白色背景）
      final labelBgPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawRRect(labelRRect, labelBgPaint);
      
      // 绘制标签边框
      final labelBorderPaint = Paint()
        ..color = const Color(0xFFFF88AA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(labelRRect, labelBorderPaint);
      
      // 绘制标签文字
      final labelTextPainter = TextPainter(
        text: const TextSpan(
          text: "虚拟TA",
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelTextPainter.layout();
      labelTextPainter.paint(
        canvas,
        Offset(
          labelRect.center.dx - labelTextPainter.width / 2,
          labelRect.center.dy - labelTextPainter.height / 2,
        ),
      );
      
      // 完成绘制
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      
      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      DebugUtil.error(' 创建虚拟TA头像标记失败: $e');
      // 返回默认标记
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(44, 46)),
        'assets/kissu_location_start.webp',
      );
    }
  }

  /// 创建带头像的圆形标记
  Future<BitmapDescriptor> _createAvatarMarker(String avatarUrl, {String? defaultAsset}) async {
    try {
      // 创建画布
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(110, 115); // 标记图片尺寸 - 放大2.5倍
      
      // 绘制背景标记图片
      final markerImage = await _loadImageFromAsset('assets/kissu_location_start.webp');
      if (markerImage != null) {
        // 计算缩放比例，确保图片完整显示在画布上
        final imageSize = Size(markerImage.width.toDouble(), markerImage.height.toDouble());
        final scaleX = size.width / imageSize.width;
        final scaleY = size.height / imageSize.height;
        final scale = math.min(scaleX, scaleY); // 使用较小的缩放比例以保持比例
        
        final scaledWidth = imageSize.width * scale;
        final scaledHeight = imageSize.height * scale;
        
        // 居中绘制
        final offsetX = (size.width - scaledWidth) / 2;
        final offsetY = (size.height - scaledHeight) / 2;
        
        final srcRect = Rect.fromLTWH(0, 0, imageSize.width, imageSize.height);
        final dstRect = Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight);
        
        canvas.drawImageRect(markerImage, srcRect, dstRect, Paint());
      }
      
      // 绘制圆形头像 - 放大一倍为90x90像素
      final avatarSize = 80.0;
      final avatarCenter = Offset(45, 43); // 头像中心点位置，原始(22,15)×2.5倍 - 放大2.5倍
      
      // 创建圆形裁剪区域
      final avatarRect = Rect.fromCenter(
        center: avatarCenter,
        width: avatarSize,
        height: avatarSize,
      );
      
      // 绘制头像背景圆形
      final avatarPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(avatarCenter, avatarSize / 2, avatarPaint);
      
      // 绘制头像边框
      final borderPaint = Paint()
        ..color = const Color(0xFFE8B4CB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.75; // 边框宽度
      canvas.drawCircle(avatarCenter, avatarSize / 2, borderPaint);
      
      // 加载并绘制头像
      ui.Image? avatarImage;
      if (avatarUrl.isNotEmpty) {
        try {
          if (avatarUrl.startsWith('http')) {
            // 网络图片
            final response = await http.get(Uri.parse(avatarUrl));
            if (response.statusCode == 200) {
              final codec = await ui.instantiateImageCodec(response.bodyBytes);
              final frame = await codec.getNextFrame();
              avatarImage = frame.image;
            }
          } else {
            // 本地资源图片
            avatarImage = await _loadImageFromAsset(avatarUrl);
          }
        } catch (e) {
          DebugUtil.error(' 加载头像失败: $e');
        }
      }
      
      // 如果头像加载失败，使用默认头像
      if (avatarImage == null && defaultAsset != null) {
        avatarImage = await _loadImageFromAsset(defaultAsset);
      }
      
      // 绘制头像
      if (avatarImage != null) {
        // 保存画布状态
        canvas.save();
        
        // 创建圆形裁剪路径
        final clipPath = Path()
          ..addOval(avatarRect);
        canvas.clipPath(clipPath);
        
        // 计算头像绘制位置，使其居中
        final srcRect = Rect.fromLTWH(0, 0, avatarImage.width.toDouble(), avatarImage.height.toDouble());
        final dstRect = avatarRect;
        
        canvas.drawImageRect(avatarImage, srcRect, dstRect, Paint());
        
        // 恢复画布状态
        canvas.restore();
      } else {
        // 如果没有头像，绘制默认图标
        final iconPaint = Paint()
          ..color = const Color(0xFFE8B4CB);
        canvas.drawCircle(avatarCenter, avatarSize / 2 - 12.5, iconPaint); // 调整内边距为12.5
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: '?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 125, // 字体大小放大2.5倍
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            avatarCenter.dx - textPainter.width / 2,
            avatarCenter.dy - textPainter.height / 2,
          ),
        );
      }
      
      // 完成绘制
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      
      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      DebugUtil.error(' 创建头像标记失败: $e');
      // 返回默认标记
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(44, 46)),
        'assets/kissu_location_start.webp',
      );
    }
  }
  
  /// 从资源加载图片
  Future<ui.Image?> _loadImageFromAsset(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      DebugUtil.error(' 加载资源图片失败: $assetPath, $e');
      return null;
    }
  }

  /// 初始化用户位置标记
  Future<void> _initTrackStartEndMarkers() async {
    DebugUtil.info(' 初始化用户位置标记...');
    DebugUtil.info(' 我的位置: ${myLocation.value}');
    DebugUtil.info(' 伴侣位置: ${partnerLocation.value}');
    DebugUtil.info(' 我的头像: ${myAvatar.value}');
    DebugUtil.info(' 伴侣头像: ${partnerAvatar.value}');
    DebugUtil.info(' 地图控制器状态: ${mapController != null ? "已初始化" : "未初始化"}');
    
    // 清空现有标记
    _trackStartEndMarkers.clear();
    
    try {
      final List<Marker> tempMarkers = [];
      
      // 创建我的位置标记（带头像）
      if (myLocation.value != null) {
        try {
          // 🔧 根据isOneself动态选择正确的头像，确保头像与位置匹配
          String correctMyAvatar;
          if (isOneself.value == 1) {
            // 查看自己时，我的位置对应userLocationMobileDevice，使用myAvatar
            correctMyAvatar = myAvatar.value;
          } else {
            // 查看另一半时，我的位置对应halfLocationMobileDevice，使用partnerAvatar
            correctMyAvatar = partnerAvatar.value;
          }
          
          // 使用带头像的标记
          final myIcon = await _createAvatarMarker(
            correctMyAvatar,
            defaultAsset: 'assets/kissu_track_header_boy.webp',
          );
          
          final myMarker = Marker(
            position: myLocation.value!,
            icon: myIcon,
            anchor: const Offset(0.5, 0.913), // 锚点Y坐标调整到105像素位置
            onTap: (String markerId) {
              DebugUtil.info('点击了我的位置');
              _moveMapToLocation(myLocation.value!);
            },
          );
          
          tempMarkers.add(myMarker);
          DebugUtil.success(' 我的位置标记创建成功: ${myLocation.value}');
        } catch (e) {
          DebugUtil.error(' 创建我的位置标记失败: $e，使用默认标记');
          // 降级方案：使用蓝色默认标记
          try {
            final fallbackMyMarker = Marker(
              position: myLocation.value!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              anchor: const Offset(0.5, 1.0),
              onTap: (String markerId) {
                DebugUtil.info('点击了我的位置');
                _moveMapToLocation(myLocation.value!);
              },
            );
            tempMarkers.add(fallbackMyMarker);
            DebugUtil.success(' 我的位置降级标记创建成功');
          } catch (fallbackError) {
            DebugUtil.error(' 我的位置降级标记也失败: $fallbackError');
          }
        }
      }
      
      // 创建伴侣位置标记（带头像）
      if (partnerLocation.value != null) {
        try {
          // 🔧 根据isOneself动态选择正确的头像，确保头像与位置匹配
          String correctPartnerAvatar;
          if (isOneself.value == 1) {
            // 查看自己时，伴侣位置对应halfLocationMobileDevice，使用partnerAvatar
            correctPartnerAvatar = partnerAvatar.value;
          } else {
            // 查看另一半时，伴侣位置对应userLocationMobileDevice，使用myAvatar
            correctPartnerAvatar = myAvatar.value;
          }
          
          // 根据绑定状态选择标记类型
          final partnerIcon = isBindPartner.value 
              ? await _createAvatarMarker(
                  correctPartnerAvatar,
                  defaultAsset: 'assets/kissu_track_header_girl.webp',
                )
              : await _createAvatarMarkerWithVirtualLabel(
                  correctPartnerAvatar,
                  defaultAsset: 'assets/kissu_track_header_girl.webp',
                );
          
          final partnerMarker = Marker(
            position: partnerLocation.value!,
            icon: partnerIcon,
            anchor: isBindPartner.value 
                ? const Offset(0.5, 0.913) // 锚点Y坐标调整到105像素位置 
                : const Offset(0.5, 0.925), // 带虚拟TA标签的标记锚点调整
            onTap: (String markerId) {
              DebugUtil.info('点击了伴侣位置');
              _moveMapToLocation(partnerLocation.value!);
            },
          );
          
          tempMarkers.add(partnerMarker);
          DebugUtil.success(' 伴侣位置标记创建成功: ${partnerLocation.value}');
        } catch (e) {
          DebugUtil.error(' 创建伴侣位置标记失败: $e，使用默认标记');
          // 降级方案：使用红色默认标记
          try {
            final fallbackPartnerMarker = Marker(
              position: partnerLocation.value!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              anchor: const Offset(0.5, 1.0),
              onTap: (String markerId) {
                DebugUtil.info('点击了伴侣位置');
                _moveMapToLocation(partnerLocation.value!);
              },
            );
            tempMarkers.add(fallbackPartnerMarker);
            DebugUtil.success(' 伴侣位置降级标记创建成功');
          } catch (fallbackError) {
            DebugUtil.error(' 伴侣位置降级标记也失败: $fallbackError');
          }
        }
      }
      
      // 更新标记列表 - 使用重新赋值确保响应式更新
      if (tempMarkers.isNotEmpty) {
        _trackStartEndMarkers.value = tempMarkers;
        DebugUtil.success(' 用户位置标记更新成功: ${_trackStartEndMarkers.length}个');
        DebugUtil.info(' 标记详情: ${tempMarkers.map((m) => '标记: ${m.position}').join(', ')}');
      } else {
        DebugUtil.error(' 没有成功创建任何用户位置标记');
        _trackStartEndMarkers.clear();
      }
    } catch (e) {
      DebugUtil.error(' 用户位置标记更新过程失败: $e');
    }
  }
  
  /// 移动地图到指定位置
  void _moveMapToLocation(LatLng location) {
    if (mapController != null) {
      mapController!.moveCamera(
        CameraUpdate.newLatLngZoom(location, 16.0),
      );
    }
  }
  
  /// 更新轨迹线集合 - 连接两个用户位置
  void _updatePolylines() {
    _polylines.clear();
    
    // 检查两个用户位置是否都有效
    if (myLocation.value != null && partnerLocation.value != null) {
      final List<LatLng> connectionPoints = [
        myLocation.value!,
        partnerLocation.value!,
      ];
      
      _polylines.add(Polyline(
        points: connectionPoints,
        color: Colors.black, // 黑色连接线
        width: 3, // 3pt宽度
        visible: true,
        alpha: 0.8,
      ));
      
      DebugUtil.success(' 用户连接线创建成功，连接两个位置点');
    }
  }
  
  /// 获取标记集合
  Set<Marker> get markers => _trackStartEndMarkers.toSet();
  
  /// 获取连接线集合
  Set<Polyline> get polylines => _polylines;
  
  /// 获取标记数量（用于缓存优化）
  int get markersLength => _trackStartEndMarkers.length;
  
  /// 获取连接线数量（用于缓存优化）
  int get polylinesLength => _polylines.length;


  /// 地图初始相机位置（基于用户位置）
  CameraPosition get initialCameraPosition {
    // 如果两个用户都有位置，计算最佳视图
    if (myLocation.value != null && partnerLocation.value != null) {
      // 使用超缩小视角作为初始状态（两人位置看起来快重合）
      final centerLat = (myLocation.value!.latitude + partnerLocation.value!.latitude) / 2;
      final centerLng = (myLocation.value!.longitude + partnerLocation.value!.longitude) / 2;
      final center = LatLng(centerLat, centerLng);
      
      // 使用很小的缩放级别，让两人位置看起来快要重合
      final superFarPosition = CameraPosition(
        target: center,
        zoom: 6.0, // 超小缩放级别
      );
      
      DebugUtil.info(' 定位页面初始超缩小视角 - 两个用户位置看起来快重合: 缩放级别=6.0');
      return superFarPosition;
    }
    // 如果只有我的位置
    else if (myLocation.value != null) {
      return CameraPosition(
        target: myLocation.value!,
        zoom: 16.0,
      );
    }
    // 如果只有伴侣位置
    else if (partnerLocation.value != null) {
      return CameraPosition(
        target: partnerLocation.value!,
        zoom: 16.0,
      );
    }
    // 默认位置（杭州）
    else {
      return const CameraPosition(
        target: LatLng(30.2741, 120.2206),
        zoom: 16.0,
      );
    }
  }

  /// 地图创建完成回调
  void onMapCreated(AMapController controller) {
    mapController = controller;
    DebugUtil.info(' 高德地图创建成功');
    
    // 地图创建完成后，强制刷新标记（如果已有位置数据）
    if (myLocation.value != null || partnerLocation.value != null) {
      DebugUtil.info(' 地图创建完成，强制刷新已有标记');
      _initTrackStartEndMarkers();
    }
    
    // 地图创建完成后，不再自动切换头像（已默认显示另一半）
    // Future.delayed(const Duration(milliseconds: 500), () {
    //   if (isOneself.value == 1) {
    //     DebugUtil.info(' 地图初始化完成，自动切换到另一半头像');
    //     isOneself.value = 0;
    //     loadLocationData();
    //   }
    // });
    
    // 地图创建完成后，延迟1000ms再调整视图，确保加载动画完全消失
    // 先显示超缩小视角，然后延迟执行放大动画
    Future.delayed(const Duration(milliseconds: 1000), () {
      _animateMapToShowBothUsers();
      
    });
  }
  


  /// 使用动画移动地图到指定位置
  void _animateMapToLocation(LatLng location) {
    mapController?.moveCamera(
      CameraUpdate.newLatLngZoom(location, 16.0),
      animated: true,
      duration: 1500,
    );
  }
  
  /// 使用动画移动地图以显示两个用户的位置（从超缩小级别放大到合适观看级别）
  void _animateMapToShowBothUsers() {
    if (mapController == null) return;
    
    // 如果两个用户都有位置，则从超缩小级别动画放大到合适观看级别
    if (myLocation.value != null && partnerLocation.value != null) {
      final myPos = myLocation.value!;
      final partnerPos = partnerLocation.value!;
      
      // 使用MapZoomCalculator计算最佳缩放级别
      final optimalPosition = MapZoomCalculator.calculateOptimalCameraPosition(
        point1: myPos,
        point2: partnerPos,
        defaultZoom: 16.0,
      );
      
      // 根据距离动态调整额外缩放量
      final latDiff = (myPos.latitude - partnerPos.latitude).abs();
      final lngDiff = (myPos.longitude - partnerPos.longitude).abs();
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
      
      // 动态调整额外缩放：距离越远，额外缩放越小
      double extraZoom;
      if (maxDiff < 0.05) {
        extraZoom = 1.5; // 近距离(<5km)：放大1.5级
      } else if (maxDiff < 0.1) {
        extraZoom = 1.0; // 中距离(<10km)：放大1级
      } else if (maxDiff < 0.2) {
        extraZoom = 0.5; // 中远距离(<20km)：放大0.5级
      } else {
        extraZoom = 0.0; // 远距离(>20km)：不额外放大
      }
      
      final enhancedPosition = CameraPosition(
        target: optimalPosition.target,
        zoom: optimalPosition.zoom + extraZoom, // 动态调整缩放级别
      );
      
      DebugUtil.info(' 距离分析: maxDiff=$maxDiff, 最佳缩放=${optimalPosition.zoom}, 额外缩放=$extraZoom');
      DebugUtil.info(' 开始地图放大动画: 从超缩小级别(6.0) → 增强观看级别=${enhancedPosition.zoom}');
      
      // 从当前超缩小级别动画放大到增强观看级别
      mapController?.moveCamera(
        CameraUpdate.newCameraPosition(enhancedPosition),
        animated: true,
        duration: 500, // 500ms动画时间
      );
      DebugUtil.success(' 定位页面地图放大动画开始 - 目标缩放级别: ${enhancedPosition.zoom}');
    } else if (myLocation.value != null) {
      // 如果只有当前用户有位置，则动画移动到当前用户位置
      _animateMapToLocation(myLocation.value!);
    } else if (partnerLocation.value != null) {
      // 如果只有另一半有位置，则动画移动到另一半位置
      _animateMapToLocation(partnerLocation.value!);
    }
  }



  
  
  /// 头像点击时移动地图到对应用户位置并放大到最大等级
  void onAvatarTapped(bool isMyself) {
    DebugUtil.info(' 头像点击开始 - isMyself: $isMyself');
    
    if (mapController == null) {
      DebugUtil.error(' 地图控制器不存在，无法移动地图');
      return;
    }
    
    LatLng? targetLocation;
    String userName;
    
    // 🔧 简化逻辑：直接使用实际位置数据
    // actualMyLocation 始终存储自己的实际位置
    // actualPartnerLocation 始终存储另一半的实际位置
    
    if (isMyself) {
      // 点击自己头像，切换到自己的位置
      targetLocation = actualMyLocation.value;
      userName = "我的位置";
      // 更新状态为查看自己
      isOneself.value = 1;
    } else {
      // 点击另一半头像，切换到另一半的位置
      targetLocation = actualPartnerLocation.value;
      userName = "另一半的位置";
      // 更新状态为查看另一半
      isOneself.value = 0;
    }
    
    // 🔧 修复：切换用户时重新更新位置记录列表
    _updateLocationRecordsForCurrentUser();
    
    DebugUtil.info(' 目标位置信息：$userName = $targetLocation');
    DebugUtil.check(' 当前状态 - isOneself: ${isOneself.value}, 点击的是: ${isMyself ? "自己" : "另一半"}');
    
    if (targetLocation == null) {
      DebugUtil.error(' 无法移动到$userName：位置信息不存在');
      DebugUtil.check(' 当前位置状态 - actualMyLocation: ${actualMyLocation.value}, actualPartnerLocation: ${actualPartnerLocation.value}');
      return;
    }
    
    // 移动到目标位置并放大到最大等级（20级）
    final maxZoomPosition = CameraPosition(
      target: targetLocation,
      zoom: 20.0, // 最大缩放级别
    );
    
    DebugUtil.info(' 头像点击：移动地图到$userName并放大到最大级别(20.0)');
    
    try {
      mapController?.moveCamera(
        CameraUpdate.newCameraPosition(maxZoomPosition),
        animated: true,
        duration: 800, // 800ms平滑动画
      );
      DebugUtil.success(' 地图移动命令已发送');
    } catch (e) {
      DebugUtil.error(' 地图移动失败: $e');
    }
  }

  /// 手动刷新地图标记（调试用）
  Future<void> forceRefreshMarkers() async {
    DebugUtil.info(' 手动强制刷新地图标记');
    await _initTrackStartEndMarkers();
  }

  /// 加载位置数据
  Future<void> loadLocationData() async {
    DebugUtil.check(' loadLocationData 被调用，当前isLoading状态: ${isLoading.value}');
    if (isLoading.value) {
      DebugUtil.warning(' 跳过API调用，因为正在加载中');
      return;
    }
    
    DebugUtil.info('设置isLoading为true');
    isLoading.value = true;
    
    try {
      DebugUtil.launch('开始调用LocationApi.getLocation()...');
      // 调用真实API获取定位数据
      final result = await LocationApi().getLocation();
      DebugUtil.info('API调用完成，结果: ${result.isSuccess ? "成功" : "失败"}');
      
      if (result.isSuccess && result.data != null) {
        final locationData = result.data!;
        DebugUtil.success('成功获取locationData对象');
        
        DebugUtil.check('API返回数据结构:');
        DebugUtil.check('  userLocationMobileDevice: ${locationData.userLocationMobileDevice != null ? "存在" : "为空"}');
        DebugUtil.check('  halfLocationMobileDevice: ${locationData.halfLocationMobileDevice != null ? "存在" : "为空"}');
        
        // 添加详细的stops调试信息
        if (locationData.userLocationMobileDevice?.stops != null) {
          DebugUtil.check('userLocationMobileDevice stops数量: ${locationData.userLocationMobileDevice!.stops!.length}');
          for (int i = 0; i < locationData.userLocationMobileDevice!.stops!.length; i++) {
            final stop = locationData.userLocationMobileDevice!.stops![i];
            DebugUtil.check('  stops[$i]: ${stop.locationName} - ${stop.startTime}~${stop.endTime}');
          }
        } else {
          DebugUtil.check('userLocationMobileDevice stops为空');
        }
        
        if (locationData.halfLocationMobileDevice?.stops != null) {
          DebugUtil.check('halfLocationMobileDevice stops数量: ${locationData.halfLocationMobileDevice!.stops!.length}');
          for (int i = 0; i < locationData.halfLocationMobileDevice!.stops!.length; i++) {
            final stop = locationData.halfLocationMobileDevice!.stops![i];
            DebugUtil.check('  stops[$i]: ${stop.locationName} - ${stop.startTime}~${stop.endTime}');
          }
        } else {
          DebugUtil.check('halfLocationMobileDevice stops为空');
        }
        
        // 🎯 不再智能选择，默认显示另一半
        // _smartSelectUserWithStops(locationData);
        
        // 🔧 缓存API数据，用于切换用户时更新列表
        _cachedUserLocationMobileDevice = locationData.userLocationMobileDevice;
        _cachedHalfLocationMobileDevice = locationData.halfLocationMobileDevice;
        DebugUtil.info(' 已缓存API数据用于切换用户');
        
        // 🔧 修复头像显示错乱：直接按照用户身份更新头像，不根据isOneself动态切换
        // myAvatar 始终存储自己的头像，partnerAvatar 始终存储另一半的头像
        if (locationData.userLocationMobileDevice != null) {
          _updateMyAvatarData(locationData.userLocationMobileDevice!);
          _updateActualMyLocationData(locationData.userLocationMobileDevice!);
        }
        
        if (locationData.halfLocationMobileDevice != null) {
          _updatePartnerAvatarData(locationData.halfLocationMobileDevice!);
          _updateActualPartnerLocationData(locationData.halfLocationMobileDevice!);
        }
        
        // 根据当前查看的用户类型显示对应数据
        UserLocationMobileDevice? currentUser;
        UserLocationMobileDevice? partnerUser;
        
        if (isOneself.value == 1) {
          // 查看自己的数据
          currentUser = locationData.userLocationMobileDevice;
          partnerUser = locationData.halfLocationMobileDevice;
          DebugUtil.check(' 查看自己的数据 - isOneself=1');
        } else {
          // 查看另一半的数据
          currentUser = locationData.halfLocationMobileDevice;
          partnerUser = locationData.userLocationMobileDevice;
          DebugUtil.check(' 查看另一半的数据 - isOneself=0');
        }
        
        DebugUtil.check(' 当前用户数据: ${currentUser != null ? "存在" : "为空"}');
        if (currentUser != null) {
          DebugUtil.check(' 当前用户停留点数量: ${currentUser.stops?.length ?? 0}');
        }
        
        // 更新当前用户位置和设备信息（不包含头像，头像已单独处理）
        if (currentUser != null) {
          _updateCurrentUserData(currentUser);
        }
        
        // 更新另一半位置信息（不包含头像，头像已单独处理）
        if (partnerUser != null) {
          _updatePartnerData(partnerUser);
        }
        
        // 更新位置记录
        _updateLocationRecords(currentUser);
        
        // API数据更新完成后，创建轨迹起终点标记
        DebugUtil.info(' API数据更新完成，开始创建轨迹起终点标记');
        await _initTrackStartEndMarkers();
        
        // 不再自动移动地图，让用户自由控制地图视角
        
      } else {
        CustomToast.show(Get.context!, result.msg ?? '获取定位数据失败');
      }
      
    } catch (e) {
      DebugUtil.error(' loadLocationData API调用异常: $e');
      DebugUtil.error(' 异常类型: ${e.runtimeType}');
      DebugUtil.error(' 异常堆栈: ${StackTrace.current}');
      CustomToast.show(Get.context!, '加载位置数据失败: $e');
    } finally {
      DebugUtil.info(' 设置isLoading为false');
      isLoading.value = false;
    }
  }
  
  /// 🔧 新增：专门更新自己的头像数据
  void _updateMyAvatarData(UserLocationMobileDevice userData) {
    DebugUtil.info(' 开始更新我的头像数据...');
    
    // 从定位接口更新我的头像数据
    if (userData.headPortrait != null && userData.headPortrait!.isNotEmpty) {
      myAvatar.value = userData.headPortrait!;
      DebugUtil.info(' 更新我的头像: ${userData.headPortrait!}');
    }
  }
  
  /// 🔧 新增：专门更新另一半的头像数据
  void _updatePartnerAvatarData(UserLocationMobileDevice userData) {
    DebugUtil.info(' 开始更新伴侣头像数据...');
    
    // 从定位接口更新伴侣头像数据
    if (userData.headPortrait != null && userData.headPortrait!.isNotEmpty) {
      partnerAvatar.value = userData.headPortrait!;
      DebugUtil.info(' 更新伴侣头像: ${userData.headPortrait!}');
    }
  }
  
  /// 🔧 新增：专门更新自己的实际位置数据
  void _updateActualMyLocationData(UserLocationMobileDevice userData) {
    DebugUtil.info(' 开始更新我的实际位置数据...');
    
    // 更新自己的实际位置
    if (userData.latitude != null && userData.longitude != null) {
      final lat = double.tryParse(userData.latitude!);
      final lng = double.tryParse(userData.longitude!);
      if (lat != null && lng != null) {
        actualMyLocation.value = LatLng(lat, lng);
        DebugUtil.info(' 更新我的实际位置: ${actualMyLocation.value}');
      } else {
        DebugUtil.error(' 我的位置数据解析失败 - lat: $lat, lng: $lng');
      }
    } else {
      DebugUtil.error(' 我的位置数据为空 - latitude: ${userData.latitude}, longitude: ${userData.longitude}');
    }
  }
  
  /// 🔧 新增：专门更新另一半的实际位置数据
  void _updateActualPartnerLocationData(UserLocationMobileDevice userData) {
    DebugUtil.info(' 开始更新伴侣的实际位置数据...');
    
    // 更新另一半的实际位置
    if (userData.latitude != null && userData.longitude != null) {
      final lat = double.tryParse(userData.latitude!);
      final lng = double.tryParse(userData.longitude!);
      if (lat != null && lng != null) {
        actualPartnerLocation.value = LatLng(lat, lng);
        DebugUtil.info(' 更新伴侣的实际位置: ${actualPartnerLocation.value}');
      } else {
        DebugUtil.error(' 伴侣位置数据解析失败 - lat: $lat, lng: $lng');
      }
    } else {
      DebugUtil.error(' 伴侣位置数据为空 - latitude: ${userData.latitude}, longitude: ${userData.longitude}');
    }
  }

  /// 更新当前用户数据
  void _updateCurrentUserData(UserLocationMobileDevice userData) {
    DebugUtil.info(' 开始更新当前用户数据...');
    DebugUtil.info(' 原始数据 - 纬度: ${userData.latitude}, 经度: ${userData.longitude}');
    
    // 更新位置
    if (userData.latitude != null && userData.longitude != null) {
      final lat = double.tryParse(userData.latitude!);
      final lng = double.tryParse(userData.longitude!);
      if (lat != null && lng != null) {
        myLocation.value = LatLng(lat, lng);
        // 注意：不在这里立即更新标记，等待所有数据准备完成后统一更新
        DebugUtil.info(' 更新我的位置: ${myLocation.value}');
      } else {
        DebugUtil.error(' 位置数据解析失败 - lat: $lat, lng: $lng');
      }
    } else {
      DebugUtil.error(' 位置数据为空 - latitude: ${userData.latitude}, longitude: ${userData.longitude}');
    }
    
    // 更新设备信息
    myDeviceModel.value = (userData.mobileModel?.isEmpty ?? true) ? "未知设备" : userData.mobileModel!;
    myBatteryLevel.value = (userData.power?.isEmpty ?? true) ? "未知" : userData.power!;
    myNetworkName.value = (userData.networkName?.isEmpty ?? true) ? "未知网络" : userData.networkName!;
    speed.value = (userData.speed?.isEmpty ?? true) ? "0m/s" : userData.speed!;
    
    // 更新详细设备信息
    isWifi.value = userData.isWifi ?? "0";
    locationTime.value = userData.locationTime ?? "";
    
    // 更新距离和时间信息
    distance.value = userData.distance ?? "未知";
    updateTime.value = userData.calculateLocationTime ?? "未知";
    
    // 更新当前位置文本
    currentLocationText.value = userData.location ?? "位置信息不可用";
    
    // 🔧 头像更新已移至专门的方法中处理，这里不再处理头像
  }
  
  /// 更新另一半数据
  void _updatePartnerData(UserLocationMobileDevice partnerData) {
    DebugUtil.info(' 开始更新伴侣数据...');
    DebugUtil.info(' 伴侣原始数据 - 纬度: ${partnerData.latitude}, 经度: ${partnerData.longitude}');
    
    // 更新另一半位置
    if (partnerData.latitude != null && partnerData.longitude != null) {
      final lat = double.tryParse(partnerData.latitude!);
      final lng = double.tryParse(partnerData.longitude!);
      if (lat != null && lng != null) {
        partnerLocation.value = LatLng(lat, lng);
        // 注意：不在这里立即更新标记，等待所有数据准备完成后统一更新
        DebugUtil.info(' 更新伴侣位置: ${partnerLocation.value}');
      } else {
        DebugUtil.error(' 伴侣位置数据解析失败 - lat: $lat, lng: $lng');
      }
    } else {
      DebugUtil.error(' 伴侣位置数据为空 - latitude: ${partnerData.latitude}, longitude: ${partnerData.longitude}');
    }
    
    // 🔧 头像更新已移至专门的方法中处理，这里不再处理头像
  }
  

  /// 🔧 新增：根据当前isOneself状态更新位置记录
  void _updateLocationRecordsForCurrentUser() {
    DebugUtil.info(' 根据当前isOneself状态更新位置记录...');
    DebugUtil.check(' 当前isOneself值: ${isOneself.value}');
    
    UserLocationMobileDevice? currentUser;
    if (isOneself.value == 1) {
      // 查看自己的数据，使用userLocationMobileDevice
      currentUser = _getUserLocationMobileDevice();
      DebugUtil.check(' 查看自己的数据，使用userLocationMobileDevice');
    } else {
      // 查看另一半的数据，使用halfLocationMobileDevice  
      currentUser = _getHalfLocationMobileDevice();
      DebugUtil.check(' 查看另一半的数据，使用halfLocationMobileDevice');
    }
    
    _updateLocationRecords(currentUser);
  }
  
  /// 🔧 新增：获取userLocationMobileDevice数据（从缓存中获取）
  UserLocationMobileDevice? _getUserLocationMobileDevice() {
    DebugUtil.info(' 从缓存获取userLocationMobileDevice数据');
    return _cachedUserLocationMobileDevice;
  }
  
  /// 🔧 新增：获取halfLocationMobileDevice数据（从缓存中获取）
  UserLocationMobileDevice? _getHalfLocationMobileDevice() {
    DebugUtil.info(' 从缓存获取halfLocationMobileDevice数据');
    return _cachedHalfLocationMobileDevice;
  }

  /// 更新位置记录
  void _updateLocationRecords(UserLocationMobileDevice? userData) {
    DebugUtil.info('开始更新位置记录...');
    DebugUtil.check('调试信息 - userData: ${userData != null ? "存在" : "为空"}');
    if (userData != null) {
      DebugUtil.check('userData详细信息:');
      DebugUtil.check('  latitude: ${userData.latitude}');
      DebugUtil.check('  longitude: ${userData.longitude}');
      DebugUtil.check('  location: ${userData.location}');
      DebugUtil.check('  stops: ${userData.stops}');
      DebugUtil.check('  stops?.length: ${userData.stops?.length}');
      DebugUtil.check('  stops?.isNotEmpty: ${userData.stops?.isNotEmpty}');
    }
    
    // 清空现有记录
    locationRecords.clear();
    
    // 从API数据中提取停留点信息
    if (userData?.stops != null && userData!.stops!.isNotEmpty) {
      DebugUtil.info('发现 ${userData.stops!.length} 个停留点');
      DebugUtil.check('停留点详情:');
      for (int i = 0; i < userData.stops!.length; i++) {
        final stop = userData.stops![i];
        DebugUtil.check('  停留点$i: ${stop.locationName} - ${stop.startTime}~${stop.endTime} - 时长:${stop.duration}');
      }
      
      for (int i = 0; i < userData.stops!.length; i++) {
        final stop = userData.stops![i];
        
        // 转换为LocationRecord对象
        final record = LocationRecord(
          time: _formatTime(stop.startTime, stop.endTime),
          locationName: stop.locationName ?? '未知位置',
          distance: '0km', // 可以根据需要计算距离
          duration: stop.duration ?? '未知',
          startTime: stop.startTime,
          endTime: stop.endTime,
          status: stop.status,
          latitude: stop.latitude != null ? double.tryParse(stop.latitude!) : null,
          longitude: stop.longitude != null ? double.tryParse(stop.longitude!) : null,
        );
        
        locationRecords.add(record);
        DebugUtil.success('添加位置记录$i: ${record.locationName} - ${record.time} - 时长:${record.duration}');
      }
    } else {
      DebugUtil.warning('没有找到停留点数据');
      DebugUtil.check('调试信息 - userData?.stops: ${userData?.stops}');
      DebugUtil.check('调试信息 - userData?.stops?.length: ${userData?.stops?.length}');
      DebugUtil.check(' 调试信息 - userData?.stops?.isNotEmpty: ${userData?.stops?.isNotEmpty}');
      
      // 没有停留点数据时，不添加任何记录，让列表保持为空以显示空状态图
      DebugUtil.warning(' 没有停留点数据，保持列表为空以显示空状态');
    }
    
    DebugUtil.info(' 位置记录更新完成，共 ${locationRecords.length} 条记录');
    DebugUtil.check(' 最终记录列表:');
    for (int i = 0; i < locationRecords.length; i++) {
      final record = locationRecords[i];
      DebugUtil.check('  记录$i: ${record.locationName} - ${record.time} - 时长:${record.duration}');
    }
    
    // 更新轨迹线
    _updatePolylines();
  }
  
  /// 格式化时间显示
  String _formatTime(String? startTime, String? endTime) {
    if (startTime == null) return '未知时间';
    
    try {
      // 假设时间格式为 "HH:mm" 或 "yyyy-MM-dd HH:mm:ss"
      if (startTime.contains(':')) {
        if (endTime != null && endTime.contains(':')) {
          return '$startTime - $endTime';
        } else {
          return startTime;
        }
      }
      return startTime;
    } catch (e) {
      return startTime;
    }
  }
  
  
  
  
  /// 执行绑定操作
  void performBindAction() {
    // 直接跳转到分享页面，不再显示弹窗
    Get.toNamed(KissuRoutePath.share);
  }

  /// 根据设备组件类型生成详细信息
  String _getDeviceDetailInfo(String componentText) {
    // 根据当前显示的文本判断是哪个组件
    if (componentText == myDeviceModel.value) {
      // 手机设备组件
      return "设备型号：${myDeviceModel.value}";
    } else if (componentText == myBatteryLevel.value) {
      // 电量组件
      return "当前电量：${myBatteryLevel.value}";
    } else if (componentText == myNetworkName.value) {
      // 网络组件
      return "网络名称：${myNetworkName.value}" ;
    }
    
    // 默认返回原文本
    return componentText;
  }

  /// 显示提示框
  void showTooltip(String text, Offset position) {
    hideTooltip(); // 先移除旧的

    // 获取详细信息
    final detailText = _getDeviceDetailInfo(text);

    final screenSize = MediaQuery.of(pageContext).size;
    const padding = 12.0;

    // 先预估提示框的大小 - 多行文本需要更大高度
    final maxWidth = screenSize.width * 0.75;
    final estimatedHeight = 120.0; // 增加高度以容纳多行文本

    double left = position.dx;
    double top = position.dy;

    // 避免溢出右边
    if (left + maxWidth + padding > screenSize.width) {
      left = screenSize.width - maxWidth - padding;
    }

    // 避免溢出下边
    if (top + estimatedHeight + padding > screenSize.height) {
      top = screenSize.height - estimatedHeight - padding;
    }

    _overlayEntry = OverlayEntry(
      builder: (_) {
        return Stack(
          children: [
            // 全屏透明点击区域
            Positioned.fill(
              child: GestureDetector(
                onTap: hideTooltip,
                behavior: HitTestBehavior.translucent, // 即使透明也能点到
                child: Container(color: Colors.transparent),
              ),
            ),
            // 提示框
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        detailText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF333333),
                          height: 1.4, // 行间距
                        ),
                      ),
                    ),
                    // 关闭按钮
                    Positioned(
                      top: -8,
                      right: -8,
                      child: GestureDetector(
                        onTap: hideTooltip,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(pageContext, rootOverlay: true).insert(_overlayEntry!);
  }

  /// 隐藏提示框
  void hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 刷新用户信息（供绑定后调用）
  void refreshUserInfo() {
    UserManager.refreshUserInfo().then((_) {
      _loadUserInfo();
      loadLocationData();
    });
  }
  
  
  // /// 测试单次定位 - 使用独立插件实例避免Stream冲突
  // Future<void> testSingleLocation() async {
  //   try {
  //     print('🧪 手动触发单次定位测试...');
  //     CustomToast.show(pageContext, '正在进行单次定位测试...');
      
  //     // 使用新的testSingleLocation方法
  //     final result = await _locationService.testSingleLocation();
      
  //     if (result != null) {
  //       double? latitude = double.tryParse(result['latitude']?.toString() ?? '');
  //       double? longitude = double.tryParse(result['longitude']?.toString() ?? '');
  //       double? accuracy = double.tryParse(result['accuracy']?.toString() ?? '');
        
  //       CustomToast.show(pageContext, 
  //         '✅ 单次定位成功\n'
  //         '位置: ${latitude?.toString()}, ${longitude?.toString()}\n'
  //         '精度: ${accuracy?.toStringAsFixed(2)}米'
  //       );
        
  //       DebugUtil.success(' 单次定位成功: $latitude, $longitude, 精度: $accuracy米');
  //     } else {
  //       CustomToast.show(pageContext, '❌ 单次定位失败，请检查权限和网络');
  //       DebugUtil.error(' 单次定位失败');
  //     }
  //   } catch (e) {
  //     DebugUtil.error(' 测试定位失败: $e');
  //     CustomToast.show(pageContext, '测试定位失败: $e');
  //   }
  // }



  @override
  void onClose() {
    // 确保清理所有资源
    try {
      hideTooltip(); // 清理overlay
    } catch (e) {
      debugPrint('清理tooltip时出错: $e');
    }
    
    // AMapController 无需手动dispose
    super.onClose();
  }
}

/// 位置记录数据模型
class LocationRecord {
  final String? time;
  final String? locationName;
  final String? distance;
  final String? duration;    // 停留时长
  final String? startTime;   // 开始时间
  final String? endTime;     // 结束时间
  final String? status;      // 状态: "staying", "ended"
  final double? latitude;    // 纬度
  final double? longitude;   // 经度

  LocationRecord({
    this.time,
    this.locationName,
    this.distance,
    this.duration,
    this.startTime,
    this.endTime,
    this.status,
    this.latitude,
    this.longitude,
  });
}

