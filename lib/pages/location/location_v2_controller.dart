import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:http/http.dart' as http;
import 'package:kissu_app/network/public/location_api.dart';
import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:kissu_app/services/location_permission_manager.dart';
import 'package:kissu_app/services/tracking_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kissu_app/utils/map_zoom_calculator.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/pages/mine/sub_pages/question_page.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/map_preload_service.dart';
import 'widgets/location_tips_manager.dart';

class LocationV2Controller extends GetxController with GetTickerProviderStateMixin {
  final isOneself = 0.obs;
  final myAvatar = "".obs;
  final partnerAvatar = "".obs;
  final myFace = Rx<Face?>(null);
  final partnerFace = Rx<Face?>(null);
  final isBindPartner = false.obs;
  final isVip = false.obs;
  final partnerOnlineStatus = Rx<OnlineStatus?>(null);
  final myLocation = Rx<LatLng?>(null);
  final partnerLocation = Rx<LatLng?>(null);
  final actualMyLocation = Rx<LatLng?>(null);
  final actualPartnerLocation = Rx<LatLng?>(null);
  final isBackButtonRotated = false.obs;
  final isSwitchingView = false.obs;
  final distance = "".obs;
  final updateTime = "".obs;
  final currentLocationText = "位置信息加载中...".obs;
  final myDeviceModel = "未知".obs;
  final myBatteryLevel = "未知".obs;
  final myNetworkName = "WiFi".obs;
  final speed = "0m/s".obs;
  final isWifi = "1".obs;
  final deviceId = "".obs;
  final locationTime = "".obs;
  final weatherIcon = "".obs;
  final weather = "".obs;
  final RxList<LocationRecord> locationRecords = <LocationRecord>[].obs;
  final Rx<LocationResponseModel?> locationData = Rx<LocationResponseModel?>(null);
  final sheetPercent = 0.3.obs;
  final swingAngle = 0.0.obs;
  final isLoading = false.obs;
  final mapType = 1.obs;
  
  // 用于跟踪上一次的滑动状态，避免重复埋点
  String _lastScrollStatus = '';

  late AnimationController backButtonAnimationController;
  late Animation<double> backButtonRotationAnimation;
  late AnimationController switchTransitionController;
  late Animation<double> switchTransitionAnimation;
  late LocationTipsManager tipsManager;
  late SimpleLocationService _locationService;
  late BuildContext pageContext;
  
  DraggableScrollableController? _draggableController;
  AMapController? mapController;
  Timer? _swingTimer;
  OverlayEntry? _overlayEntry;

  BitmapDescriptor? _cachedMyIcon;
  BitmapDescriptor? _cachedPartnerIcon;
  String? _cachedMyAvatar;
  String? _cachedPartnerAvatar;
  Face? _cachedMyFace;
  Face? _cachedPartnerFace;
  bool? _cachedIsBindPartner;
  
  // 🚀 持久化Marker缓存（跨页面访问复用）
  BitmapDescriptor? _persistentMyIcon;
  BitmapDescriptor? _persistentPartnerIcon;
  String? _lastMyCacheKey;
  String? _lastPartnerCacheKey;

  final Map<String, ui.Image> _imageCache = {};
  final RxList<Marker> _trackStartEndMarkers = <Marker>[].obs;
  final RxSet<Polyline> _polylines = <Polyline>{}.obs;

  @override
  void onInit() {
    super.onInit();
    try {
      // 先加载本地用户信息（立即显示）
      _loadUserInfo();
      
      // 然后静默刷新用户信息
      _silentRefreshUserInfo();
      
      _initLocationService();
      tipsManager = LocationTipsManager(this);
      tipsManager.onInit();
      _initBackButtonAnimation();
      _initSwitchTransitionAnimation();
      _listenToSheetChanges();
      _initializePageAsync();
      
      // 开始页面浏览事件计时
      _startPageViewTracking();
    } catch (e) {
      debugPrint('LocationController onInit error: $e');
    }
  }

  @override
  void onReady() {
    super.onReady();
    // 页面准备就绪时，确保已经静默刷新
  }
  
  /// 页面重新获得焦点时的回调（从其他页面返回时会调用）
  void onPageResumed() {
    debugPrint('📍 定位页面重新获得焦点，静默刷新用户信息');
    // 先用本地数据（已经在onInit中加载）
    // 然后静默刷新用户信息
    _silentRefreshUserInfo();
  }
  
  /// 静默刷新用户信息（不阻塞UI）
  Future<void> _silentRefreshUserInfo() async {
    try {
      debugPrint('🔄 定位页面：静默刷新用户信息');
      final success = await UserManager.refreshUserInfo();
      if (success) {
        // 刷新成功后重新加载本地数据到UI
        _loadUserInfo();
      }
    } catch (e) {
      debugPrint('❌ 定位页面：静默刷新用户信息失败: $e');
    }
  }
  
  /// 开始页面浏览事件计时
  Future<void> _startPageViewTracking() async {
    try {
      // 获取位置权限状态
      final locationStatus = await Permission.location.status;
      final hasLocation = locationStatus.isGranted;
      
      await TrackingService.trackLocationPageBegin(
        isBindPartner: isBindPartner.value,
        isVip: isVip.value,
        hasLocation: hasLocation,
      );
    } catch (e) {
      debugPrint('开始页面浏览事件计时失败: $e');
    }
  }
  
  /// 结束页面浏览事件计时
  Future<void> _endPageViewTracking() async {
    try {
      // 获取位置权限状态
      final locationStatus = await Permission.location.status;
      final hasLocation = locationStatus.isGranted;
      
      await TrackingService.trackLocationPageEnd(
        isBindPartner: isBindPartner.value,
        isVip: isVip.value,
        hasLocation: hasLocation,
      );
    } catch (e) {
      debugPrint('结束页面浏览事件计时失败: $e');
    }
  }

  void _initBackButtonAnimation() {
    backButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    backButtonRotationAnimation = Tween<double>(
      begin: 0.0,
      end: -0.25,
    ).animate(CurvedAnimation(
      parent: backButtonAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _initSwitchTransitionAnimation() {
    switchTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    switchTransitionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: switchTransitionController,
      curve: Curves.easeInOut,
    ));
  }

  void _listenToSheetChanges() {
    sheetPercent.listen((percent) {
      final topThreshold = 0.85;
      if (percent >= topThreshold && !isBackButtonRotated.value) {
        isBackButtonRotated.value = true;
        backButtonAnimationController.forward();
      } else if (percent < topThreshold && isBackButtonRotated.value) {
        isBackButtonRotated.value = false;
        backButtonAnimationController.reverse();
      }
      
      // 根据百分比判断当前所处的滑动状态
      _trackScrollStatus(percent);
    });
  }
  
  /// 跟踪下半屏滑动状态埋点
  void _trackScrollStatus(double percent) {
    String currentStatus = _getScrollStatus(percent);
    
    // 只有当状态发生变化时才触发埋点
    if (currentStatus != _lastScrollStatus && currentStatus.isNotEmpty) {
      _lastScrollStatus = currentStatus;
      TrackingService.trackSwipeOperation(
        isVip: isVip.value,
        scrollStatus: currentStatus,
      );
    }
  }
  
  /// 根据百分比获取滑动状态
  String _getScrollStatus(double percent) {
    // 定义三个状态的阈值范围
    // 小屏（底部）：0.15 - 0.35
    // 中屏（中间）：0.45 - 0.65
    // 大屏（顶部）：0.80 - 0.95
    
    if (percent >= 0.15 && percent < 0.35) {
      return '小屏';
    } else if (percent >= 0.45 && percent < 0.65) {
      return '中屏';
    } else if (percent >= 0.80 && percent <= 0.95) {
      return '大屏';
    }
    
    // 处于过渡状态，不触发埋点
    return '';
  }
  

  void handleBackButtonTap([ScrollController? scrollController]) {
    if (isBackButtonRotated.value) {
      _scrollToBottom(scrollController);
    } else {
      Get.back();
    }
  }

  void setDraggableController(DraggableScrollableController controller) {
    _draggableController = controller;
  }

  void _scrollToBottom([ScrollController? scrollController]) {
    if (_draggableController != null) {
      _draggableController!.animateTo(
        0.3,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) {
        if (scrollController != null && scrollController.hasClients) {
          scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  /// 收起底部面板到底部吸顶位置（切换头像时使用）
  void collapseToBottomPosition() {
    if (_draggableController != null) {
      try {
        // 动态计算底部吸顶位置（对应 snapSizes 中的第一个位置）
        const minHeight = 190.0;
        final screenHeight = Get.context != null 
            ? MediaQuery.of(Get.context!).size.height 
            : 800.0;
        final bottomSnapSize = minHeight / screenHeight;
        
        _draggableController!.animateTo(
          bottomSnapSize, // 收起到底部吸顶位置
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        debugPrint('🎯 定位页面：收起底部面板到底部吸顶位置');
      } catch (e) {
        debugPrint('❌ 定位页面：收起底部面板到底部位置失败: $e');
      }
    }
  }

  /// 统一的异步初始化流程（优化：后台静默加载，不阻塞UI）
  void _initializePageAsync() {
    debugPrint('🚀 地图页面异步初始化流程开始（后台静默执行）');
    
    // 立即启动后台数据加载，不等待结果
    // 这样地图可以立即显示，数据到了再更新
    loadLocationData().then((_) {
      debugPrint('📊 位置数据加载完成');
    }).catchError((e) {
      debugPrint('位置数据加载失败: $e');
    });
    
    // 并行检查定位权限
    _checkLocationPermissionOnPageEnter().then((_) {
      debugPrint('📊 定位权限检查完成');
    }).catchError((e) {
      debugPrint('定位权限检查失败: $e');
    });
  }

  void _initLocationService() {
    try {
      _locationService = SimpleLocationService.instance;
    } catch (e) {
      debugPrint('Location service init error: $e');
    }
  }

  Future<void> _checkLocationPermissionOnPageEnter() async {
    try {
      var locationStatus = await Permission.location.status;
      if (locationStatus.isDenied || locationStatus.isPermanentlyDenied) {
        await _requestLocationPermissionAndStartService();
      } else if (locationStatus.isGranted) {
        await _locationService.startLocation();
      }
    } catch (e) {
      debugPrint('Check location permission error: $e');
    }
  }

  Future<void> _requestLocationPermissionAndStartService() async {
    try {
      final permissionManager = LocationPermissionManager.instance;
      bool hasPermission = await permissionManager.requestLocationPermission();
      if (hasPermission) {
        await _checkAndStartLocationService();
      }
    } catch (e) {
      debugPrint('Request location permission error: $e');
    }
  }

  Future<void> _checkAndStartLocationService() async {
    try {
      if (!UserManager.isLoggedIn) return;
      if (!_locationService.isLocationEnabled.value) {
        await _locationService.startLocation();
      }
    } catch (e) {
      debugPrint('Check and start location service error: $e');
    }
  }

  void _loadUserInfo() {
    final user = UserManager.currentUser;
    if (user != null) {
      final bindStatus = user.bindStatus.toString();
      isBindPartner.value = bindStatus.toString() == "1";
      isVip.value = UserManager.isVip;

      if (myAvatar.value.isEmpty) {
        myAvatar.value = user.headPortrait ?? '';
      }

      if (isBindPartner.value && partnerAvatar.value.isEmpty) {
        if (user.loverInfo?.headPortrait?.isNotEmpty == true) {
          partnerAvatar.value = user.loverInfo!.headPortrait!;
        } else if (user.halfUserInfo?.headPortrait?.isNotEmpty == true) {
          partnerAvatar.value = user.halfUserInfo!.headPortrait!;
        }
      }
    }
  }

  Future<BitmapDescriptor> _createAvatarMarkerWithVirtualLabel(
    String avatarUrl, {
    String? defaultAsset,
    required String baseAsset,
    Face? face,
  }) async {
    try {
      final pedestal = await _loadImageFromAsset(baseAsset);
      if (pedestal == null) {
        return BitmapDescriptor.defaultMarker;
      }

      final avatarSize = 180.0;
      final pedestalScale = 0.8;
      final pedestalWidth = pedestal.width.toDouble() * pedestalScale;
      final pedestalHeight = pedestal.height.toDouble() * pedestalScale;
      final labelHeight = 30.0;
      final labelTopMargin = 50.0;

      final emojiBgHeight = (face != null && face.isValid) ? 80.0 : 0.0;
      final emojiBgMargin = (face != null && face.isValid) ? 10.0 : 0.0;

      final canvasWidth = (pedestalWidth > avatarSize ? pedestalWidth : avatarSize) + 20;
      final canvasHeight = labelHeight + labelTopMargin + emojiBgHeight + emojiBgMargin + avatarSize + pedestalHeight / 2 + 10;
      final size = Size(canvasWidth, canvasHeight);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final pedestalBottom = size.height - 10;
      final pedestalTop = pedestalBottom - pedestalHeight;
      final pedestalLeft = (size.width - pedestalWidth) / 2;

      final avatarBottom = pedestalTop + pedestalHeight / 2;
      final avatarTop = avatarBottom - avatarSize;
      final avatarCenterX = size.width / 2;
      final avatarCenterY = avatarTop + avatarSize / 2;

      final emojiBgTop = avatarTop - emojiBgMargin - emojiBgHeight;
      final emojiBgLeft = (size.width - avatarSize) / 2;

      final labelTop = (face != null && face.isValid)
          ? emojiBgTop - labelTopMargin - labelHeight
          : avatarTop - labelTopMargin - labelHeight;

      final srcRect = Rect.fromLTWH(0, 0, pedestal.width.toDouble(), pedestal.height.toDouble());
      final dstRect = Rect.fromLTWH(pedestalLeft, pedestalTop, pedestalWidth, pedestalHeight);
      canvas.drawImageRect(pedestal, srcRect, dstRect, Paint());

      if (face != null && face.isValid) {
        await _drawEmojiBackground(canvas, emojiBgLeft, emojiBgTop, avatarSize, emojiBgHeight, face);
      }

      final avatarCenter = Offset(avatarCenterX, avatarCenterY);
      final avatarRect = Rect.fromCenter(
        center: avatarCenter,
        width: avatarSize,
        height: avatarSize,
      );

      final avatarPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(avatarCenter, avatarSize / 2, avatarPaint);

      final borderPaint = Paint()
        ..color = const Color(0xFFFF9AD8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20;
      canvas.drawCircle(avatarCenter, avatarSize / 2, borderPaint);

      ui.Image? avatarImage;
      if (avatarUrl.isNotEmpty) {
        try {
          if (avatarUrl.startsWith('http')) {
            avatarImage = await _loadImageFromNetwork(avatarUrl);
          } else {
            avatarImage = await _loadImageFromAsset(avatarUrl);
          }
        } catch (e) {
          debugPrint('Load avatar error: $e');
        }
      }

      if (avatarImage == null && defaultAsset != null) {
        avatarImage = await _loadImageFromAsset(defaultAsset);
      }

      if (avatarImage != null) {
        canvas.save();
        final clipPath = Path()..addOval(avatarRect);
        canvas.clipPath(clipPath);
        final srcRect = Rect.fromLTWH(0, 0, avatarImage.width.toDouble(), avatarImage.height.toDouble());
        final dstRect = avatarRect;
        canvas.drawImageRect(avatarImage, srcRect, dstRect, Paint());
        canvas.restore();
      } else {
        final iconPaint = Paint()..color = const Color(0xFFE8B4CB);
        canvas.drawCircle(avatarCenter, avatarSize / 2 - 12.5, iconPaint);
        final textPainter = TextPainter(
          text: TextSpan(
            text: '?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 125,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
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

      final labelWidth = 120.0;
      final labelRect = Rect.fromLTWH(
        (size.width - labelWidth) / 2,
        labelTop,
        labelWidth,
        labelHeight + 15,
      );

      final labelRRect = RRect.fromRectAndRadius(labelRect, const Radius.circular(6));
      final labelBgPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawRRect(labelRRect, labelBgPaint);

      final labelBorderPaint = Paint()
        ..color = const Color(0xFFFF88AA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(labelRRect, labelBorderPaint);

      final labelTextPainter = TextPainter(
        text: const TextSpan(
          text: "虚拟TA",
          style: TextStyle(
            fontSize: 30,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      labelTextPainter.layout();
      labelTextPainter.paint(
        canvas,
        Offset(
          labelRect.center.dx - labelTextPainter.width / 2,
          labelRect.center.dy - labelTextPainter.height / 2,
        ),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      debugPrint('Create virtual label avatar marker error: $e');
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(44, 46)),
        'assets/kissu_location_start.webp',
      );
    }
  }

  Future<BitmapDescriptor> _createAvatarMarker(
    String avatarUrl, {
    String? defaultAsset,
    required String baseAsset,
    Face? face,
  }) async {
    final createStartTime = DateTime.now();
    
    try {
      final pedestal = await _loadImageFromAsset(baseAsset);
      if (pedestal == null) {
        return BitmapDescriptor.defaultMarker;
      }

      final avatarSize = 180.0;
      final pedestalScale = 0.8;
      final pedestalWidth = pedestal.width.toDouble() * pedestalScale;
      final pedestalHeight = pedestal.height.toDouble() * pedestalScale;
      final avatarBorderWidth = 20.0;

      final emojiBgHeight = (face != null && face.isValid) ? 80.0 : 0.0;
      final emojiBgMargin = (face != null && face.isValid) ? 10.0 : 0.0;
      final avatarTopPadding = (face != null && face.isValid) ? 0.0 : avatarBorderWidth + 10;

      final canvasWidth = (pedestalWidth > avatarSize ? pedestalWidth : avatarSize) + 20;
      final canvasHeight = avatarTopPadding + emojiBgHeight + emojiBgMargin + avatarSize + pedestalHeight / 2 + 10;
      final size = Size(canvasWidth, canvasHeight);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final emojiBgTop = avatarTopPadding;
      final emojiBgLeft = (size.width - avatarSize) / 2;

      final avatarTop = (face != null && face.isValid)
          ? emojiBgTop + emojiBgHeight + emojiBgMargin
          : avatarTopPadding;
      final avatarCenterX = size.width / 2;
      final avatarCenterY = avatarTop + avatarSize / 2;

      final avatarBottom = avatarTop + avatarSize;
      final pedestalTop = avatarBottom - pedestalHeight / 2;
      final pedestalLeft = (size.width - pedestalWidth) / 2;

      final srcRect = Rect.fromLTWH(0, 0, pedestal.width.toDouble(), pedestal.height.toDouble());
      final dstRect = Rect.fromLTWH(pedestalLeft, pedestalTop, pedestalWidth, pedestalHeight);
      canvas.drawImageRect(pedestal, srcRect, dstRect, Paint());

      if (face != null && face.isValid) {
        await _drawEmojiBackground(canvas, emojiBgLeft, emojiBgTop, avatarSize, emojiBgHeight, face);
      }

      final avatarCenter = Offset(avatarCenterX, avatarCenterY);
      final avatarRect = Rect.fromCenter(
        center: avatarCenter,
        width: avatarSize,
        height: avatarSize,
      );

      final avatarPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(avatarCenter, avatarSize / 2, avatarPaint);

      final borderPaint = Paint()
        ..color = const Color(0xFFFF9AD8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20;
      canvas.drawCircle(avatarCenter, avatarSize / 2, borderPaint);

      ui.Image? avatarImage;
      if (avatarUrl.isNotEmpty) {
        try {
          if (avatarUrl.startsWith('http')) {
            avatarImage = await _loadImageFromNetwork(avatarUrl);
          } else {
            avatarImage = await _loadImageFromAsset(avatarUrl);
          }
        } catch (e) {
          debugPrint('Load avatar error: $e');
        }
      }

      if (avatarImage == null && defaultAsset != null) {
        avatarImage = await _loadImageFromAsset(defaultAsset);
      }

      if (avatarImage != null) {
        canvas.save();
        final clipPath = Path()..addOval(avatarRect);
        canvas.clipPath(clipPath);
        final srcRect = Rect.fromLTWH(0, 0, avatarImage.width.toDouble(), avatarImage.height.toDouble());
        final dstRect = avatarRect;
        canvas.drawImageRect(avatarImage, srcRect, dstRect, Paint());
        canvas.restore();
      } else {
        final iconPaint = Paint()..color = const Color(0xFFE8B4CB);
        canvas.drawCircle(avatarCenter, avatarSize / 2 - 12.5, iconPaint);
        final textPainter = TextPainter(
          text: TextSpan(
            text: '?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 125,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
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

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final createDuration = DateTime.now().difference(createStartTime);
      debugPrint('📊 创建Marker耗时: ${createDuration.inMilliseconds}ms');
      
      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      debugPrint('Create avatar marker error: $e');
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(44, 46)),
        'assets/kissu_location_start.webp',
      );
    }
  }

  Future<void> _drawEmojiBackground(
    Canvas canvas,
    double left,
    double top,
    double width,
    double height,
    Face face,
  ) async {
    try {
      final emojiBg = await _loadImageFromAsset('assets/3.0/kissu3_emoij_bg.webp');
      if (emojiBg == null) return;

      final bgSrcRect = Rect.fromLTWH(0, 0, emojiBg.width.toDouble(), emojiBg.height.toDouble());
      final bgDstRect = Rect.fromLTWH(left, top, width, height);
      canvas.drawImageRect(emojiBg, bgSrcRect, bgDstRect, Paint());

      if (face.faceUrl != null && face.faceUrl!.isNotEmpty) {
        final emojiIcon = await _loadImageFromNetwork(face.faceUrl!);
        if (emojiIcon != null) {
          final iconSize = height * 0.45;
          TextPainter? textPainter;
          
          if (face.faceText != null && face.faceText!.isNotEmpty) {
            textPainter = TextPainter(
              text: TextSpan(
                text: face.faceText!,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'LiuHuanKaTongShouShu',
                ),
              ),
              textDirection: ui.TextDirection.ltr,
            );
            textPainter.layout();
          }

          final spacing = (textPainter != null) ? 6.0 : 0.0;
          final textWidth = textPainter?.width ?? 0.0;
          final totalWidth = iconSize + spacing + textWidth;
          final startLeft = left + (width - totalWidth) / 2;

          final iconTop = top + (height - iconSize) / 2;
          final iconSrcRect = Rect.fromLTWH(0, 0, emojiIcon.width.toDouble(), emojiIcon.height.toDouble());
          final iconDstRect = Rect.fromLTWH(startLeft, iconTop, iconSize, iconSize);
          canvas.drawImageRect(emojiIcon, iconSrcRect, iconDstRect, Paint());

          if (textPainter != null) {
            final textLeft = startLeft + iconSize + spacing;
            final textTop = top + (height - textPainter.height) / 2;
            textPainter.paint(canvas, Offset(textLeft, textTop));
          }
        }
      }
    } catch (e) {
      debugPrint('Draw emoji background error: $e');
    }
  }

  Future<ui.Image?> _loadImageFromNetwork(String url) async {
    if (_imageCache.containsKey(url)) {
      return _imageCache[url];
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final image = frame.image;
        _imageCache[url] = image;
        return image;
      }
    } catch (e) {
      debugPrint('Load image from network error: $e');
    }
    return null;
  }

  Future<ui.Image?> _loadImageFromAsset(String assetPath) async {
    // 🚀 优化1：先从本地缓存查找
    if (_imageCache.containsKey(assetPath)) {
      return _imageCache[assetPath];
    }

    // 🚀 优化2：尝试从全局预加载服务获取
    final preloadedImage = MapPreloadService.instance.getPreloadedImage(assetPath);
    if (preloadedImage != null) {
      _imageCache[assetPath] = preloadedImage;
      return preloadedImage;
    }

    // 🚀 优化3：如果都没有，才进行加载
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final image = frame.image;
      _imageCache[assetPath] = image;
      return image;
    } catch (e) {
      debugPrint('Load image from asset error: $assetPath, $e');
      return null;
    }
  }

  Future<void> _initTrackStartEndMarkers() async {
    _trackStartEndMarkers.clear();

    if (_needsUpdateIconCache()) {
      await _updateIconCache();
    }

    try {
      final List<Marker> tempMarkers = [];

      final LatLng? myPos = actualMyLocation.value ?? myLocation.value;
      if (myPos != null) {
        try {
          final BitmapDescriptor myIcon = _cachedMyIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);

          final myMarker = Marker(
            position: myPos,
            icon: myIcon,
            anchor: const Offset(0.5, 1.0),
            onTap: (String markerId) {
              _moveMapToLocation(myPos);
            },
          );
          myMarker.setIdForCopy('my_marker');
          tempMarkers.add(myMarker);
        } catch (e) {
          debugPrint('Create my marker error: $e');
        }
      }

      final LatLng? partnerPos = actualPartnerLocation.value ?? partnerLocation.value;
      if (partnerPos != null) {
        try {
          final BitmapDescriptor partnerIcon = _cachedPartnerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

          final partnerMarker = Marker(
            position: partnerPos,
            icon: partnerIcon,
            anchor: const Offset(0.5, 1.0),
            onTap: (String markerId) {
              _moveMapToLocation(partnerPos);
            },
          );
          partnerMarker.setIdForCopy('partner_marker');
          tempMarkers.add(partnerMarker);
        } catch (e) {
          debugPrint('Create partner marker error: $e');
        }
      }

      if (tempMarkers.isNotEmpty) {
        _trackStartEndMarkers.value = tempMarkers;
        _startSwingAnimation();
      } else {
        _trackStartEndMarkers.clear();
      }
    } catch (e) {
      debugPrint('Init track markers error: $e');
    }
  }

  void _moveMapToLocation(LatLng location) {
    if (mapController != null) {
      mapController!.moveCamera(
        CameraUpdate.newLatLngZoom(location, 16.0),
      );
    }
  }

  void _updatePolylines() {
    _polylines.clear();

    if (myLocation.value != null && partnerLocation.value != null) {
      final List<LatLng> connectionPoints = [
        myLocation.value!,
        partnerLocation.value!,
      ];

      _polylines.add(Polyline(
        points: connectionPoints,
        color: const Color(0xFFFF4B99),
        width: 6,
        visible: true,
        alpha: 1.0,
        dashLineType: DashLineType.circle,
        capType: CapType.round,
      ));
    }
  }

  Set<Marker> get markers => _trackStartEndMarkers.toSet();
  Set<Polyline> get polylines => _polylines;
  int get markersLength => _trackStartEndMarkers.length;
  int get polylinesLength => _polylines.length;

  CameraPosition get initialCameraPosition {
    if (myLocation.value != null && partnerLocation.value != null) {
      final myPos = myLocation.value!;
      final partnerPos = partnerLocation.value!;

      final latDiff = (myPos.latitude - partnerPos.latitude).abs();
      final lngDiff = (myPos.longitude - partnerPos.longitude).abs();
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

      double initialZoom;
      if (maxDiff > 10.0) {
        initialZoom = 2.0;
      } else if (maxDiff > 5.0) {
        initialZoom = 3.0;
      } else if (maxDiff > 2.0) {
        initialZoom = 4.0;
      } else if (maxDiff > 1.0) {
        initialZoom = 5.0;
      } else {
        initialZoom = 6.0;
      }

      final centerLat = (myPos.latitude + partnerPos.latitude) / 2;
      final centerLng = (myPos.longitude + partnerPos.longitude) / 2;
      final center = LatLng(centerLat, centerLng);

      return CameraPosition(target: center, zoom: initialZoom);
    } else if (myLocation.value != null) {
      return CameraPosition(target: myLocation.value!, zoom: 16.0);
    } else if (partnerLocation.value != null) {
      return CameraPosition(target: partnerLocation.value!, zoom: 16.0);
    } else {
      return const CameraPosition(
        target: LatLng(30.2741, 120.2206),
        zoom: 16.0,
      );
    }
  }

  void onMapCreated(AMapController controller) {
    mapController = controller;

    if (myLocation.value != null || partnerLocation.value != null) {
      _initTrackStartEndMarkers();
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mapController != null && isClosed == false) {
        _animateMapToShowBothUsersAsync();
      }
    });
  }

  void _animateMapToLocation(LatLng location) {
    if (mapController == null) return;
    try {
      unawaited(mapController!.moveCamera(
        CameraUpdate.newLatLngZoom(location, 16.0),
        animated: true,
        duration: 1500,
      ));
    } catch (e) {
      debugPrint('Animate map to location error: $e');
    }
  }

  Future<void> _animateMapToShowBothUsersAsync() async {
    if (mapController == null) return;
    await Future.microtask(() => _animateMapToShowBothUsersSync());
  }

  Future<void> _animateMapToShowBothUsersSync() async {
    if (myLocation.value != null && partnerLocation.value != null) {
      final myPos = myLocation.value!;
      final partnerPos = partnerLocation.value!;

      final optimalPosition = MapZoomCalculator.calculateOptimalCameraPosition(
        point1: myPos,
        point2: partnerPos,
        defaultZoom: 16.0,
      );

      final latDiff = (myPos.latitude - partnerPos.latitude).abs();
      final lngDiff = (myPos.longitude - partnerPos.longitude).abs();
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

      double extraZoom;
      if (maxDiff < 0.05) {
        extraZoom = 1.5;
      } else if (maxDiff < 0.1) {
        extraZoom = 1.0;
      } else if (maxDiff < 0.2) {
        extraZoom = 0.5;
      } else if (maxDiff < 1.0) {
        extraZoom = 0.0;
      } else if (maxDiff < 5.0) {
        extraZoom = -0.5;
      } else {
        extraZoom = -1.0;
      }

      final enhancedPosition = CameraPosition(
        target: optimalPosition.target,
        zoom: optimalPosition.zoom + extraZoom,
      );

      try {
        await mapController!.moveCamera(
          CameraUpdate.newCameraPosition(enhancedPosition),
          animated: true,
          duration: 500,
        );
      } catch (e) {
        debugPrint('Animate map error: $e');
      }
    } else if (myLocation.value != null) {
      _animateMapToLocation(myLocation.value!);
    } else if (partnerLocation.value != null) {
      _animateMapToLocation(partnerLocation.value!);
    }
  }

  Future<void> onAvatarTapped(bool isMyself) async {
    if (isSwitchingView.value) return;

    // 计算目标用户类型
    final targetUserType = isMyself ? 1 : 0;
    
    // 如果点击的是当前用户，不做任何处理
    if (isOneself.value == targetUserType) {
      debugPrint('🎯 定位页面：点击的是当前用户头像，不切换');
      return;
    }

    // 人物切换按钮埋点
    await TrackingService.trackCharacterSwitch(isMyself: isMyself);

    // 📱 每次切换头像时，将下半屏恢复到底部吸顶位置
    debugPrint('💡 定位页面：切换头像，恢复下半屏到底部吸顶位置');
    collapseToBottomPosition();

    isSwitchingView.value = true;

    Timer? safetyTimer = Timer(const Duration(seconds: 5), () {
      if (isSwitchingView.value) {
        isSwitchingView.value = false;
        try {
          switchTransitionController.reset();
        } catch (e) {}
      }
    });

    try {
      await switchTransitionController.forward().timeout(
        const Duration(seconds: 1),
        onTimeout: () {},
      );

      if (isMyself) {
        isOneself.value = 1;
      } else {
        isOneself.value = 0;
      }

      await loadLocationData().timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );

      await _moveToTargetUserLocationInstant(isMyself);
      await Future.delayed(const Duration(milliseconds: 100));

      await switchTransitionController.reverse().timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          switchTransitionController.reset();
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Avatar tap error: $e\n$stackTrace');
      try {
        await switchTransitionController.reverse().timeout(
          const Duration(milliseconds: 500),
          onTimeout: () {
            switchTransitionController.reset();
          },
        );
      } catch (e2) {
        switchTransitionController.reset();
      }
    } finally {
      safetyTimer.cancel();
      isSwitchingView.value = false;
    }
  }

  Future<void> _moveToTargetUserLocationInstant(bool isMyself) async {
    if (mapController == null) return;

    LatLng? targetLocation;
    if (isMyself) {
      targetLocation = actualMyLocation.value;
    } else {
      targetLocation = actualPartnerLocation.value;
    }

    if (targetLocation == null) return;

    try {
      mapController!.moveCamera(
        CameraUpdate.newLatLngZoom(targetLocation, 16.0),
        animated: false,
      );
    } catch (e) {
      debugPrint('Move map instantly error: $e');
    }
  }

  Future<void> forceRefreshMarkers() async {
    await _initTrackStartEndMarkers();
  }

  void switchMapType(int type) {
    if (mapType.value != type) {
      mapType.value = type;
      // 地图模式切换埋点
      _trackMapModeSwitch(type);
    }
  }
  
  /// 地图模式切换埋点
  Future<void> _trackMapModeSwitch(int mapType) async {
    await TrackingService.trackMapModeSwitch(mapType: mapType);
  }

  Future<void> refreshLocationData() async {
    // 刷新地图按钮埋点
    await _trackRefreshMapButton();
    await loadLocationData();
  }
  
  /// 刷新地图按钮埋点
  Future<void> _trackRefreshMapButton() async {
    await TrackingService.trackRefreshMapButton();
  }

  Future<void> loadLocationData({int retryCount = 0}) async {
    if (isLoading.value && retryCount == 0) return;

    isLoading.value = true;

    try {
      final result = await LocationApi().getLocation();

      if (result.isSuccess && result.data != null) {
        final locationDataResult = result.data!;
        locationData.value = locationDataResult;

        if (locationDataResult.userLocationMobileDevice != null) {
          _updateMyAvatarData(locationDataResult.userLocationMobileDevice!);
          _updateActualMyLocationData(locationDataResult.userLocationMobileDevice!);
        }

        if (locationDataResult.halfLocationMobileDevice != null) {
          _updatePartnerAvatarData(locationDataResult.halfLocationMobileDevice!);
          _updateActualPartnerLocationData(locationDataResult.halfLocationMobileDevice!);
        }

        UserLocationMobileDevice? currentUser;
        UserLocationMobileDevice? partnerUser;

        if (isOneself.value == 1) {
          currentUser = locationDataResult.userLocationMobileDevice;
          partnerUser = locationDataResult.halfLocationMobileDevice;
        } else {
          currentUser = locationDataResult.halfLocationMobileDevice;
          partnerUser = locationDataResult.userLocationMobileDevice;
        }

        if (currentUser != null) {
          _updateCurrentUserData(currentUser);
        }

        if (partnerUser != null) {
          _updatePartnerData(partnerUser);
        }

        _updateLocationRecords(currentUser);
        await _initTrackStartEndMarkers();
      } else {
        if (retryCount < 2 && _shouldRetry(result.msg ?? '')) {
          isLoading.value = false;
          await Future.delayed(Duration(milliseconds: 1000 * (retryCount + 1)));
          return loadLocationData(retryCount: retryCount + 1);
        }
        _showFriendlyError(result.code, result.msg);
      }
    } catch (e, stackTrace) {
      debugPrint('Load location data error: $e\n${stackTrace.toString().split('\n').take(10).join('\n')}');

      if (retryCount < 2) {
        isLoading.value = false;
        await Future.delayed(Duration(milliseconds: 1000 * (retryCount + 1)));
        return loadLocationData(retryCount: retryCount + 1);
      }

      CustomToast.show(Get.context!, '加载位置数据失败，请稍后重试');
    } finally {
      isLoading.value = false;
    }
  }

  bool _shouldRetry(String errorMsg) {
    final msg = errorMsg.toLowerCase();
    return msg.contains('网络') ||
        msg.contains('超时') ||
        msg.contains('连接') ||
        msg.contains('timeout') ||
        msg.contains('connection') ||
        msg.contains('network');
  }

  void _showFriendlyError(int? code, String? msg) {
    String tip;
    final text = (msg ?? '').toLowerCase();

    if (code == 210 || text.contains('repeat')) {
      tip = '操作太频繁啦，请稍后再试';
    } else if (text.contains('网络') ||
        text.contains('超时') ||
        text.contains('timeout') ||
        text.contains('connect') ||
        text.contains('connection')) {
      tip = '网络不太给力，稍等片刻再试试';
    } else if (text.contains('ssl') ||
        text.contains('certificate') ||
        text.contains('handshake')) {
      tip = '网络安全验证失败，请稍后重试';
    } else if (text.contains('host') ||
        text.contains('refused') ||
        text.contains('reset')) {
      tip = '服务器连接异常，请稍后重试';
    } else {
      tip = msg ?? '获取定位数据失败，请稍后重试';
    }

    CustomToast.show(Get.context!, tip);
  }

  void _updateMyAvatarData(UserLocationMobileDevice userData) {
    if (userData.headPortrait != null && userData.headPortrait!.isNotEmpty) {
      myAvatar.value = userData.headPortrait!;
    }
    myFace.value = userData.face;
  }

  void _updatePartnerAvatarData(UserLocationMobileDevice userData) {
    if (userData.headPortrait != null && userData.headPortrait!.isNotEmpty) {
      partnerAvatar.value = userData.headPortrait!;
    }
    partnerFace.value = userData.face;
    partnerOnlineStatus.value = userData.online;
  }

  void _updateActualMyLocationData(UserLocationMobileDevice userData) {
    if (userData.latitude != null && userData.longitude != null) {
      final lat = double.tryParse(userData.latitude!);
      final lng = double.tryParse(userData.longitude!);
      if (lat != null && lng != null) {
        actualMyLocation.value = LatLng(lat, lng);
      }
    }
  }

  void _updateActualPartnerLocationData(UserLocationMobileDevice userData) {
    if (userData.latitude != null && userData.longitude != null) {
      final lat = double.tryParse(userData.latitude!);
      final lng = double.tryParse(userData.longitude!);
      if (lat != null && lng != null) {
        actualPartnerLocation.value = LatLng(lat, lng);
      }
    }
  }

  void _updateCurrentUserData(UserLocationMobileDevice userData) {
    if (userData.latitude != null && userData.longitude != null) {
      final lat = double.tryParse(userData.latitude!);
      final lng = double.tryParse(userData.longitude!);
      if (lat != null && lng != null) {
        myLocation.value = LatLng(lat, lng);
      }
    }

    myDeviceModel.value = (userData.mobileModel?.isEmpty ?? true) ? "未知设备" : userData.mobileModel!;
    myBatteryLevel.value = (userData.power?.isEmpty ?? true) ? "未知" : userData.power!;
    myNetworkName.value = (userData.networkName?.isEmpty ?? true) ? "未知网络" : userData.networkName!;
    speed.value = (userData.speed?.isEmpty ?? true) ? "0m/s" : userData.speed!;
    isWifi.value = userData.isWifi ?? "0";
    locationTime.value = userData.locationTime ?? "";
    distance.value = userData.distance ?? "未知";
    updateTime.value = userData.calculateLocationTime ?? "未知";

    if (userData.lives?.base != null && userData.lives!.base!.isNotEmpty) {
      final baseWeather = userData.lives!.base!.first;
      weatherIcon.value = baseWeather.weatherIcon ?? "";
      weather.value = baseWeather.weather ?? "";
    } else {
      weatherIcon.value = "";
      weather.value = "";
    }

    currentLocationText.value = userData.location ?? "位置信息不可用";
  }

  void _updatePartnerData(UserLocationMobileDevice partnerData) {
    if (partnerData.latitude != null && partnerData.longitude != null) {
      final lat = double.tryParse(partnerData.latitude!);
      final lng = double.tryParse(partnerData.longitude!);
      if (lat != null && lng != null) {
        partnerLocation.value = LatLng(lat, lng);
      }
    }
  }

  void _updateLocationRecords(UserLocationMobileDevice? userData) {
    locationRecords.clear();

    if (userData?.stops != null && userData!.stops!.isNotEmpty) {
      for (int i = 0; i < userData.stops!.length; i++) {
        final stop = userData.stops![i];
        final record = LocationRecord(
          time: _formatTime(stop.startTime, stop.endTime),
          locationName: stop.locationName ?? '未知位置',
          distance: '0km',
          duration: stop.duration ?? '未知',
          startTime: stop.startTime,
          endTime: stop.endTime,
          status: stop.status,
          latitude: stop.latitude != null ? double.tryParse(stop.latitude!) : null,
          longitude: stop.longitude != null ? double.tryParse(stop.longitude!) : null,
        );
        locationRecords.add(record);
      }
    }

    _updatePolylines();
  }

  String _formatTime(String? startTime, String? endTime) {
    if (startTime == null) return '未知时间';

    try {
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

  void performBindAction() {
    // 立即去绑定按钮埋点
    _trackBindNowButton();
    
    if (Get.context != null) {
      CustomBottomDialog.show(context: Get.context!).then((_) {
        refreshUserInfo();
      });
    }
  }
  
  /// 立即去绑定按钮埋点
  Future<void> _trackBindNowButton() async {
    await TrackingService.trackBindNowButton();
  }

  String _getDeviceDetailInfo(String componentText) {
    if (componentText == myDeviceModel.value) {
      return "设备型号：${myDeviceModel.value}";
    } else if (componentText == myBatteryLevel.value) {
      return "当前电量：${myBatteryLevel.value}";
    } else if (componentText == myNetworkName.value) {
      return "网络名称：${myNetworkName.value}";
    }
    return componentText;
  }

  void showTooltip(String text, Offset position) {
    hideTooltip();

    final detailText = _getDeviceDetailInfo(text);
    final screenSize = MediaQuery.of(pageContext).size;
    const padding = 12.0;
    final maxWidth = screenSize.width * 0.75;
    final estimatedHeight = 120.0;

    double left = position.dx;
    double top = position.dy;

    if (left + maxWidth + padding > screenSize.width) {
      left = screenSize.width - maxWidth - padding;
    }

    if (top + estimatedHeight + padding > screenSize.height) {
      top = screenSize.height - estimatedHeight - padding;
    }

    _overlayEntry = OverlayEntry(
      builder: (_) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: hideTooltip,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),
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
                          height: 1.4,
                        ),
                      ),
                    ),
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

  void hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void refreshUserInfo() {
    UserManager.refreshUserInfo().then((_) {
      _loadUserInfo();
      loadLocationData();
    });
  }
  
  /// 开通会员按钮点击
  Future<void> onOpenMembershipButtonTap() async {
    // 开通会员按钮埋点
    await TrackingService.trackOpenMembershipButton();
    
    // 跳转到会员页面
    Get.toNamed(KissuRoutePath.vip)?.then((_) {
      refreshUserInfo();
    });
  }

  void navigateToQuestionPage(int? problemId) {
    // 离线提示"查看原因"埋点
    TrackingService.trackLocationOfflineReason();
    
    if (problemId == null) {
      Get.to(
        () => const QuestionPage(),
        transition: Transition.rightToLeft,
      );
      return;
    }
    Get.to(
      () => QuestionPage(targetProblemId: problemId),
      transition: Transition.rightToLeft,
    );
  }

  void _startSwingAnimation() {
    _stopSwingAnimation();

    if (_cachedMyIcon == null && _cachedPartnerIcon == null) {
      return;
    }

    int timeStep = 0;
    _swingTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      final time = timeStep * 0.08;
      final period = 2 * math.pi;
      final normalizedTime = (time % period) / period;
      final angle = (normalizedTime < 0.5)
          ? (-12.0 + normalizedTime * 48.0)
          : (36.0 - normalizedTime * 48.0);

      swingAngle.value = angle;
      Future.microtask(() => _updateMarkersRotation());
      timeStep++;
    });
  }

  void _stopSwingAnimation() {
    if (_swingTimer == null) return;

    _swingTimer?.cancel();
    _swingTimer = null;

    final currentAngle = swingAngle.value;
    if (currentAngle.abs() > 0.5) {
      int steps = 0;
      const maxSteps = 8;
      Timer.periodic(const Duration(milliseconds: 30), (timer) {
        steps++;
        final progress = steps / maxSteps;
        final easeOut = 1 - math.pow(1 - progress, 3);
        swingAngle.value = currentAngle * (1 - easeOut);

        Future.microtask(() => _updateMarkersRotation());

        if (steps >= maxSteps) {
          timer.cancel();
          swingAngle.value = 0.0;
          _updateMarkersRotation();
        }
      });
    } else {
      swingAngle.value = 0.0;
      _updateMarkersRotation();
    }
  }

  void _updateMarkersRotation() async {
    if (mapController == null) return;

    try {
      if (actualMyLocation.value != null && _cachedMyIcon != null) {
        final myMarker = Marker(
          position: actualMyLocation.value!,
          rotation: swingAngle.value,
          icon: _cachedMyIcon!,
          anchor: const Offset(0.5, 1.0),
        );
        myMarker.setIdForCopy('my_marker');
        await mapController!.updateMarker(myMarker);
      }

      if (actualPartnerLocation.value != null && _cachedPartnerIcon != null) {
        final partnerMarker = Marker(
          position: actualPartnerLocation.value!,
          rotation: -swingAngle.value,
          icon: _cachedPartnerIcon!,
          anchor: const Offset(0.5, 1.0),
        );
        partnerMarker.setIdForCopy('partner_marker');
        await mapController!.updateMarker(partnerMarker);
      }
    } catch (e) {
      debugPrint('Update marker rotation error: $e');
    }
  }

  bool _needsUpdateIconCache() {
    return _cachedMyAvatar != myAvatar.value ||
        _cachedPartnerAvatar != partnerAvatar.value ||
        _cachedMyFace != myFace.value ||
        _cachedPartnerFace != partnerFace.value ||
        _cachedIsBindPartner != isBindPartner.value;
  }

  Future<void> _updateIconCache() async {
    final markerStartTime = DateTime.now();
    
    try {
      // 🚀 优化：我的头像Marker（使用全局缓存）
      if (myAvatar.value.isNotEmpty) {
        final cacheKey = MapPreloadService.generateMarkerCacheKey(
          avatarUrl: myAvatar.value,
          faceUrl: myFace.value?.faceUrl,
          isVirtual: false,
        );
        
        // 检查是否需要重新创建
        if (_lastMyCacheKey != cacheKey || _persistentMyIcon == null) {
          // 先尝试从全局缓存获取
          final globalCached = MapPreloadService.instance.getCachedMarker(cacheKey);
          
          if (globalCached != null) {
            _persistentMyIcon = globalCached;
            debugPrint('🎯 使用全局缓存的我的Marker');
          } else {
            // 创建新的Marker
            _persistentMyIcon = await _createAvatarMarker(
              myAvatar.value,
              defaultAsset: 'assets/kissu3_love_avater.webp',
              baseAsset: 'assets/3.0/kissu3_location_she.webp',
              face: myFace.value,
            );
            
            // 保存到全局缓存
            MapPreloadService.instance.cacheMarker(cacheKey, _persistentMyIcon!);
          }
          
          _lastMyCacheKey = cacheKey;
        }
        
        _cachedMyIcon = _persistentMyIcon;
        _cachedMyAvatar = myAvatar.value;
        _cachedMyFace = myFace.value;
      }

      // 🚀 优化：Ta的头像Marker（使用全局缓存）
      if (partnerAvatar.value.isNotEmpty) {
        final cacheKey = MapPreloadService.generateMarkerCacheKey(
          avatarUrl: partnerAvatar.value,
          faceUrl: partnerFace.value?.faceUrl,
          isVirtual: !isBindPartner.value,
        );
        
        // 检查是否需要重新创建
        if (_lastPartnerCacheKey != cacheKey || _persistentPartnerIcon == null) {
          // 先尝试从全局缓存获取
          final globalCached = MapPreloadService.instance.getCachedMarker(cacheKey);
          
          if (globalCached != null) {
            _persistentPartnerIcon = globalCached;
            debugPrint('🎯 使用全局缓存的Ta的Marker');
          } else {
            // 创建新的Marker
            if (isBindPartner.value) {
              _persistentPartnerIcon = await _createAvatarMarker(
                partnerAvatar.value,
                defaultAsset: 'assets/kissu3_love_avater.webp',
                baseAsset: 'assets/3.0/kissu3_location_she.webp',
                face: partnerFace.value,
              );
            } else {
              _persistentPartnerIcon = await _createAvatarMarkerWithVirtualLabel(
                partnerAvatar.value,
                defaultAsset: 'assets/kissu3_love_avater.webp',
                baseAsset: 'assets/3.0/kissu3_location_she.webp',
                face: partnerFace.value,
              );
            }
            
            // 保存到全局缓存
            MapPreloadService.instance.cacheMarker(cacheKey, _persistentPartnerIcon!);
          }
          
          _lastPartnerCacheKey = cacheKey;
        }
        
        _cachedPartnerIcon = _persistentPartnerIcon;
        _cachedPartnerAvatar = partnerAvatar.value;
        _cachedPartnerFace = partnerFace.value;
        _cachedIsBindPartner = isBindPartner.value;
      }
      
      final markerDuration = DateTime.now().difference(markerStartTime);
      debugPrint('📊 Marker创建/缓存耗时: ${markerDuration.inMilliseconds}ms');
    } catch (e) {
      debugPrint('Update icon cache error: $e');
    }
  }

  @override
  void onClose() {
    // 结束页面浏览事件计时
    _endPageViewTracking();
    
    try {
      hideTooltip();
    } catch (e) {
      debugPrint('Hide tooltip error: $e');
    }

    try {
      tipsManager.onClose();
    } catch (e) {
      debugPrint('Close tips manager error: $e');
    }

    _stopSwingAnimation();

    try {
      backButtonAnimationController.dispose();
    } catch (e) {
      debugPrint('Dispose backButtonAnimationController error: $e');
    }

    try {
      switchTransitionController.dispose();
    } catch (e) {
      debugPrint('Dispose switchTransitionController error: $e');
    }

    _imageCache.clear();
    _cachedMyIcon = null;
    _cachedPartnerIcon = null;
    _cachedMyAvatar = null;
    _cachedPartnerAvatar = null;
    _cachedMyFace = null;
    _cachedPartnerFace = null;
    _cachedIsBindPartner = null;

    super.onClose();
  }
}

class LocationRecord {
  final String? time;
  final String? locationName;
  final String? distance;
  final String? duration;
  final String? startTime;
  final String? endTime;
  final String? status;
  final double? latitude;
  final double? longitude;

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
