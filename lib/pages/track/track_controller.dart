import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amap_map/amap_map.dart';
import 'package:x_amap_base/x_amap_base.dart';
import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:kissu_app/network/public/ltrack_api.dart';
import 'package:kissu_app/pages/track/stay_point.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/widgets/dialogs/dialog_manager.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/services/permission_state_service.dart';
import 'package:permission_handler/permission_handler.dart';

class TrackController extends GetxController {
  /// 当前查看的用户类型 (1: 自己, 0: 另一半)
  final isOneself = 1.obs;
  
  /// 移除了自定义图标，直接使用彩色默认标记
  
  /// 用户信息
  final myAvatar = "".obs;
  final partnerAvatar = "".obs;
  final isBindPartner = false.obs;
  
  /// 播放控制器UI状态 - true显示完整播放器，false显示简单按钮
  final showFullPlayer = false.obs;
  /// 播放期间已行走的距离
  final replayDistance = "0.00km".obs;
  /// 播放时间
  final replayTime = "00:00:00".obs;
  
  /// 当前选择的日期
  final selectedDate = DateTime.now().obs;
  
  /// 位置数据
  final Rx<LocationResponse?> locationData = Rx<LocationResponse?>(null);
  
  /// 停留统计 (从API数据获取)
  final stayCount = 0.obs;
  final stayDuration = "".obs;
  final moveDistance = "".obs;

  /// 最近 7 天
  final recentDays = List.generate(7, (i) {
    final date = DateTime.now().subtract(Duration(days: i));
    return "${date.month}-${date.day}";
  }).obs;

  final selectedDayIndex = 0.obs;
  final sheetPercent = 0.3.obs; // 修正为与页面一致的初始值
  
  /// 加载状态
  final isLoading = false.obs;

  /// 地图控制器 - 延迟初始化
  AMapController? mapController;
  
  /// 防抖定时器
  Timer? _debounceTimer;
  
  /// 轨迹数据缓存 - 基于用户ID和日期缓存
  final Map<String, LocationResponse> _trackDataCache = {};
  
  /// 获取缓存键 - 基于用户ID、日期和查看对象
  String _getCacheKey(DateTime date, int? userId) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return '${userId ?? 'unknown'}_${dateKey}_${isOneself.value}';
  }

  /// 移除了自定义图标加载功能，直接使用彩色默认标记
  
  /// 移除了图标加载函数
  
  
  @override
  void onInit() {
    super.onInit();
    // 初始化地图控制器
    // 地图控制器将在地图创建时初始化
    // 确保初始状态下播放控制器可见
    sheetPercent.value = 0.3;
    // 加载用户信息
    _loadUserInfo();
    // 请求定位权限并加载初始数据
    _requestLocationPermissionAndLoadData();
    
  }
  
  /// 请求定位权限并加载数据
  Future<void> _requestLocationPermissionAndLoadData() async {
    try {
      final permissionService = PermissionStateService.instance;
      
      // 检查是否应该请求权限
      if (permissionService.shouldRequestTrackPagePermission()) {
        print('🗺️ 轨迹页面请求定位权限');
        
        // 标记已请求权限
        await permissionService.markTrackPagePermissionRequested();
        
        final status = await Permission.location.request();
        if (status.isGranted) {
          print('✅ 轨迹页面权限获取成功');
          // 权限获取成功，加载位置数据
          loadLocationData();
        } else if (status.isPermanentlyDenied) {
          print('❌ 轨迹页面权限被永久拒绝');
          await permissionService.markTrackPagePermissionDenied();
          CustomToast.show(
            Get.context!,
            '定位权限被永久拒绝，请在设置中开启定位权限',
          );
        } else {
          print('❌ 轨迹页面权限被拒绝');
          await permissionService.markTrackPagePermissionDenied();
          CustomToast.show(
            Get.context!,
            '需要定位权限来显示轨迹信息',
          );
        }
      } else {
        // 不需要请求权限，直接加载数据
        print('📱 轨迹页面无需请求权限，直接加载数据');
        loadLocationData();
      }
    } catch (e) {
      print('❌ 轨迹页面权限请求失败: $e');
      CustomToast.show(
        Get.context!,
        '定位权限请求失败',
      );
    }
  }

  /// 加载用户信息
  void _loadUserInfo() {
    final user = UserManager.currentUser;
    if (user != null) {
      // 设置我的头像
      myAvatar.value = user.headPortrait ?? '';
      
      // 检查绑定状态
      final bindStatus = user.bindStatus.toString(); //0从未绑定，1绑定中，2已解绑
      isBindPartner.value = bindStatus.toString() == "1";
      
      if (isBindPartner.value) {
        // 已绑定状态，获取伴侣头像
        if (user.loverInfo?.headPortrait?.isNotEmpty == true) {
          partnerAvatar.value = user.loverInfo!.headPortrait!;
        } else if (user.halfUserInfo?.headPortrait?.isNotEmpty == true) {
          partnerAvatar.value = user.halfUserInfo!.headPortrait!;
        }
      }
    }
  }


  /// 地图初始相机位置
  CameraPosition get initialCameraPosition => CameraPosition(
    target: trackPoints.isNotEmpty
        ? trackPoints.first
        : const LatLng(30.2741, 120.2206), // 杭州默认坐标
    zoom: 16.0,
  );

  /// 计算适合所有轨迹点的相机位置
  CameraPosition? _calculateOptimalCameraPosition() {
    if (trackPoints.isEmpty) return null;
    
    // 计算边界
    double minLat = trackPoints.first.latitude;
    double maxLat = trackPoints.first.latitude;
    double minLng = trackPoints.first.longitude;
    double maxLng = trackPoints.first.longitude;
    
    for (final point in trackPoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }
    
    // 添加边距（10%的padding）
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;
    
    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;
    
    // 计算中心点
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    
    // 计算合适的缩放级别
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    
    // 根据距离计算缩放级别
    double zoom;
    if (maxDiff < 0.001) {
      zoom = 18.0; // 非常小的区域
    } else if (maxDiff < 0.01) {
      zoom = 16.0; // 小区域
    } else if (maxDiff < 0.1) {
      zoom = 14.0; // 中等区域
    } else if (maxDiff < 0.5) {
      zoom = 12.0; // 大区域
    } else {
      zoom = 10.0; // 很大区域
    }
    
    return CameraPosition(
      target: LatLng(centerLat, centerLng),
      zoom: zoom,
    );
  }

  /// 自动调整地图视图以显示所有轨迹点
  Future<void> _fitMapToTrackPoints() async {
    if (mapController == null || trackPoints.isEmpty) return;
    
    final optimalPosition = _calculateOptimalCameraPosition();
    if (optimalPosition == null) return;
    
    try {
      await mapController!.moveCamera(
        CameraUpdate.newCameraPosition(optimalPosition),
      );
      print('🗺️ 地图已自动调整到最佳视图');
    } catch (e) {
      print('❌ 调整地图视图失败: $e');
    }
  }

  /// 地图创建完成回调
  void onMapCreated(AMapController controller) {
    mapController = controller;
    print('轨迹页面高德地图创建成功');
  }


  /// 移动地图到指定位置
  void _moveMapToLocation(LatLng location) {
    mapController?.moveCamera(CameraUpdate.newLatLng(location));
  }
  
  /// 移动地图到停留点（公共方法，用于列表点击）
  void moveToStopPoint(double latitude, double longitude) {
    final targetLocation = LatLng(latitude, longitude);
    
    // 移动地图并调整缩放级别以更好地显示该点
    mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: targetLocation,
          zoom: 17.0, // 使用较高的缩放级别以便更清楚地看到该位置
        ),
      ),
    );
    
    print('🗺️ 地图移动到停留点: $latitude, $longitude');
  }

  /// 轨迹点（从API数据获取）
  final RxList<LatLng> trackPoints = <LatLng>[].obs;

  /// 停留点列表（从API数据获取）
  final RxList<TrackStopPoint> stopPoints = <TrackStopPoint>[].obs;

  /// 停留点 marker 列表
  final RxList<Marker> stayMarkers = <Marker>[].obs;

  /// 轨迹回放状态
  final currentReplayIndex = 0.obs;
  final isReplaying = false.obs; // 改为响应式变量
  final replaySpeed = 1.0.obs; // 播放速度倍数
  Timer? _replayTimer;

  /// 平滑动画相关
  final currentPosition = Rx<LatLng?>(null);
  final animationProgress = 0.0.obs;
  static const int animationSteps = 20; // 每两个点之间的插值步数
  int _currentStep = 0;
  
  /// 播放时间跟踪
  DateTime? _replayStartTime;
  double _cumulativeDistance = 0.0; // 累计距离（米）

  /// 停留记录列表（从API数据转换而来）
  final RxList<StopRecord> stopRecords = <StopRecord>[].obs;
  
  /// 是否使用虚拟数据（未绑定状态下使用）
  final isUsingMockData = false.obs;

  /// 加载位置数据 - 添加防抖和缓存优化
  Future<void> loadLocationData() async {
    // 防抖处理，避免频繁请求
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      await _performLoadLocationData();
    });
  }
  
  /// 实际执行数据加载
  Future<void> _performLoadLocationData() async {
    if (isLoading.value) return; // 防止重复加载
    
    // 检查缓存
    final currentUser = UserManager.currentUser;
    if (currentUser?.id != null) {
      final cacheKey = _getCacheKey(selectedDate.value, currentUser!.id);
      final cachedData = _trackDataCache[cacheKey];
      
      if (cachedData != null) {
        print('📦 使用缓存数据: $cacheKey');
        locationData.value = cachedData;
        _updateStatistics();
        _updateStopRecords();
        await _updateTrackDataAsync();
        return;
      }
    }
    
    isLoading.value = true;
    _resetReplayState();
    
    // 检查是否应该使用虚拟数据
    if (!isBindPartner.value) {
      await _loadMockData();
      isLoading.value = false;
      return;
    }
    
    try {
      final dateString = DateFormat('yyyy-MM-dd').format(selectedDate.value);
      print('🌐 请求API数据: $dateString, isOneself=${isOneself.value}');
      
      final result = await TrackApi.getTrack(
        date: dateString,
        isOneself: isOneself.value,
      );
      
      if (result.isSuccess && result.data != null) {
        isUsingMockData.value = false;
        locationData.value = result.data;
        
        // 保存到缓存
        final currentUser = UserManager.currentUser;
        if (currentUser?.id != null) {
          final cacheKey = _getCacheKey(selectedDate.value, currentUser!.id);
          _trackDataCache[cacheKey] = result.data!;
          print('💾 数据已缓存: $cacheKey');
        }
        
        _updateStatistics();
        _updateStopRecords();
        await _updateTrackDataAsync();
        
      } else {
        CustomToast.show(Get.context!, result.msg ?? '获取数据失败');
        _clearData();
      }
    } catch (e, stackTrace) {
      final dateString = DateFormat('yyyy-MM-dd').format(selectedDate.value);
      print('🚨 Track Controller loadLocationData error: $e');
      print('📍 请求参数: date=$dateString, isOneself=${isOneself.value}');
      print('📚 Stack trace: $stackTrace');
      
      String errorMessage;
      if (e.toString().contains('FormatException')) {
        errorMessage = 'JSON数据格式错误，请检查服务器返回的数据格式';
        print('💡 建议检查API返回的JSON格式是否正确');
      } else if (e.toString().contains('is not a subtype')) {
        errorMessage = '数据类型不匹配，请稍后重试';
      } else if (e.toString().contains('Unterminated string')) {
        errorMessage = 'JSON字符串格式错误，可能存在未转义的特殊字符';
        print('💡 建议检查JSON中是否有未正确转义的引号或换行符');
      } else {
        errorMessage = '加载数据失败: ${e.toString().length > 100 ? '${e.toString().substring(0, 100)}...' : e.toString()}';
      }
      
      CustomToast.show(
        Get.context!,
        errorMessage,
      );
      _clearData();
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 重置播放状态
  void _resetReplayState() {
    // 停止当前播放
    _replayTimer?.cancel();
    isReplaying.value = false;
    currentReplayIndex.value = 0;
    _currentStep = 0;
    replaySpeed.value = 1.0;
    currentPosition.value = null;
    animationProgress.value = 0.0;
  }
  
  /// 清空数据
  void _clearData() {
    trackPoints.clear();
    stopPoints.clear();
    stayMarkers.clear();
    stopRecords.clear();
    stayCount.value = 0;
    stayDuration.value = "";
    moveDistance.value = "";
  }

  /// 新的API结构不需要设备数据，直接使用trace数据

  /// 异步更新轨迹数据 - 优化性能
  Future<void> _updateTrackDataAsync() async {
    if (locationData.value == null) {
      print('❌ 位置数据为空，无法更新轨迹');
      return;
    }
    
    final data = locationData.value!;
    print('🔄 更新轨迹数据: isOneself=${isOneself.value}, 位置点=${data.locations?.length ?? 0}个');
    
    // 在后台线程处理数据以避免阻塞UI
    final rawPoints = await compute(_processLocationData, data.locations ?? []);
    
    // 对轨迹点进行平滑处理
    trackPoints.value = _smoothTrackPoints(rawPoints);
    print('📍 轨迹点数量: ${trackPoints.length}');
    
    // 过滤停留点
    stopPoints.value = data.trace?.stops
        .where((stop) => stop.lat != 0.0 && stop.lng != 0.0)
        .toList() ?? [];
    print('📍 停留点数量: ${stopPoints.length}');
    
    // 更新停留点标记
    try {
      await _safeUpdateStayMarkers();
    } catch (e) {
      print('❌ 更新停留点标记失败: $e');
      // 即使失败也继续执行，避免阻塞整个流程
    }
    
    // 自动调整地图视图以显示所有轨迹点
    await _fitMapToTrackPoints();
    
    // 移动地图
    if (trackPoints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _moveMapToLocation(trackPoints.first);
      });
    } else {
      _moveToValidPoint();
    }
  }
  
  /// 在后台线程处理位置数据
  static List<LatLng> _processLocationData(List<TrackLocation> locations) {
    return locations
        .map((location) => LatLng(location.lat, location.lng))
        .where((point) => point.latitude != 0.0 && point.longitude != 0.0)
        .toList();
  }

  /// 更新统计数据
  void _updateStatistics() {
    if (locationData.value == null) {
      print('❌ locationData为空，无法更新统计数据');
      return;
    }
    
    print('🔍 开始更新统计数据');
    
    // 🎯 优先从 trace.stay_collect 获取统计数据（根据实际JSON结构）
    final traceStayCollect = locationData.value!.trace?.stayCollect;
    if (traceStayCollect != null) {
      print('✅ 使用trace.stay_collect的统计数据 (主要数据源)');
      stayCount.value = traceStayCollect.stayCount ?? 0;
      stayDuration.value = traceStayCollect.stayTime ?? '';
      moveDistance.value = traceStayCollect.moveDistance ?? '';
      print('📊 统计数据: 停留次数=${stayCount.value}, 停留时间=${stayDuration.value}, 移动距离=${moveDistance.value}');
      return;
    }
    
    print('📊 userLocationMobileDevice存在: ${locationData.value!.userLocationMobileDevice != null}');
    
    final userDevice = locationData.value!.userLocationMobileDevice;
    if (userDevice == null) {
      print('⚠️ userLocationMobileDevice为空，检查API数据结构');
      print('📊 halfLocationMobileDevice存在: ${locationData.value!.halfLocationMobileDevice != null}');
      
      // 尝试使用halfLocationMobileDevice（查看另一半时）
      final halfDevice = locationData.value!.halfLocationMobileDevice;
      final stayCollect = halfDevice?.stayCollect;
      
      if (stayCollect != null) {
        print('✅ 使用halfLocationMobileDevice的统计数据 (备用数据源)');
        stayCount.value = stayCollect.stayCount ?? 0;
        stayDuration.value = stayCollect.stayTime ?? '';
        moveDistance.value = stayCollect.moveDistance ?? '';
        print('📊 统计数据: 停留次数=${stayCount.value}, 停留时间=${stayDuration.value}, 移动距离=${moveDistance.value}');
      } else {
        print('⚠️ 所有数据源的stayCollect都为空');
        stayCount.value = 0;
        stayDuration.value = '';
        moveDistance.value = '';
      }
      return;
    }
    
    final stayCollect = userDevice.stayCollect;
    print('📊 stayCollect存在: ${stayCollect != null}');
    
    if (stayCollect != null) {
      print('📋 stayCollect数据: ${stayCollect.toJson()}');
      stayCount.value = stayCollect.stayCount ?? 0;
      stayDuration.value = stayCollect.stayTime ?? '';
      moveDistance.value = stayCollect.moveDistance ?? '';
      print('📊 统计数据更新: 停留次数=${stayCount.value}, 停留时间=${stayDuration.value}, 移动距离=${moveDistance.value}');
    } else {
      print('⚠️ stayCollect为空');
      stayCount.value = 0;
      stayDuration.value = '';
      moveDistance.value = '';
    }
  }

  /// 更新停留记录列表
  void _updateStopRecords() {
    if (locationData.value == null) {
      print('❌ locationData为空，无法更新停留记录');
      return;
    }
    
    print('🔍 开始更新停留记录列表');
    print('📊 locationData存在: ${locationData.value != null}');
    
    // 检查各种数据源
    final userStops = locationData.value!.userLocationMobileDevice?.stops ?? [];
    final halfStops = locationData.value!.halfLocationMobileDevice?.stops ?? [];
    final traceStops = locationData.value!.trace?.stops ?? [];
    
    print('📊 userDevice.stops数量: ${userStops.length}');
    print('📊 halfDevice.stops数量: ${halfStops.length}');
    print('📊 🎯 trace.stops数量: ${traceStops.length} (主要数据源)');
    print('📊 trace存在: ${locationData.value!.trace != null}');
    
    List<dynamic> stops = [];
    String dataSource = '';
    
    // 🎯 根据实际JSON结构，优先使用 trace.stops
    if (traceStops.isNotEmpty) {
      stops = traceStops.map((stop) => {
        'lat': stop.lat,
        'lng': stop.lng,
        'location_name': stop.locationName,
        'start_time': stop.startTime,
        'end_time': stop.endTime,
        'duration': stop.duration,
        'status': stop.status,
        'point_type': stop.pointType,
        'serial_number': stop.serialNumber,
      }).toList();
      dataSource = 'trace.stops (主要数据源)';
    } else if (userStops.isNotEmpty) {
      stops = userStops.map((stop) => {
        'lat': double.tryParse(stop.latitude ?? '0') ?? 0.0,
        'lng': double.tryParse(stop.longitude ?? '0') ?? 0.0,
        'location_name': stop.locationName,
        'start_time': stop.startTime,
        'end_time': stop.endTime,
        'duration': stop.duration,
        'status': stop.status,
        'point_type': stop.pointType,
        'serial_number': stop.serialNumber,
      }).toList();
      dataSource = 'userDevice.stops (备用数据源)';
    } else if (halfStops.isNotEmpty) {
      stops = halfStops.map((stop) => {
        'lat': double.tryParse(stop.latitude ?? '0') ?? 0.0,
        'lng': double.tryParse(stop.longitude ?? '0') ?? 0.0,
        'location_name': stop.locationName,
        'start_time': stop.startTime,
        'end_time': stop.endTime,
        'duration': stop.duration,
        'status': stop.status,
        'point_type': stop.pointType,
        'serial_number': stop.serialNumber,
      }).toList();
      dataSource = 'halfDevice.stops';
    }
    
    print('📊 使用数据源: $dataSource, 停留点数量: ${stops.length}');
    
    if (stops.isEmpty) {
      print('⚠️ 所有数据源的stops都为空，检查API数据结构');
      print('📋 完整locationData结构: ${locationData.value!.toJson()}');
    } else {
      print('📋 第一个stop数据: ${stops.first}');
    }
    
    stopRecords.value = stops.map((stop) {
      final record = StopRecord(
        latitude: stop['lat'] is double ? stop['lat'] : (stop['lat'] is String ? double.tryParse(stop['lat']) ?? 0.0 : 0.0),
        longitude: stop['lng'] is double ? stop['lng'] : (stop['lng'] is String ? double.tryParse(stop['lng']) ?? 0.0 : 0.0),
        locationName: stop['location_name']?.toString() ?? '',
        startTime: stop['start_time']?.toString() ?? '',
        endTime: (stop['end_time']?.toString().isNotEmpty == true) ? stop['end_time'].toString() : (stop['start_time']?.toString() ?? ''),
        duration: stop['duration']?.toString() ?? '',
        status: stop['status']?.toString() ?? '',
        pointType: stop['point_type']?.toString() ?? '',
        serialNumber: stop['serial_number']?.toString() ?? '',
      );
      print('📍 转换停留记录: ${record.locationName}, 时间: ${record.time}, 时长: ${record.stayDuration}');
      return record;
    }).toList();
    
    print('✅ 停留记录更新完成，总数量: ${stopRecords.length}');
    if (stopRecords.isNotEmpty) {
      print('📋 第一条记录详情: 位置=${stopRecords.first.locationName}, 时间=${stopRecords.first.time}');
    }
  }

  /// 当没有有效轨迹点时，尝试移动到起点或终点
  void _moveToValidPoint() {
    if (locationData.value == null) return;
    
    final data = locationData.value!;
    
    // 尝试使用起点
    if (data.trace?.startPoint.lat != 0.0 && data.trace?.startPoint.lng != 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _moveMapToLocation(LatLng(data.trace!.startPoint.lat, data.trace!.startPoint.lng));
      });
      return;
    }
    
    // 尝试使用终点
    if (data.trace?.endPoint.lat != 0.0 && data.trace?.endPoint.lng != 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _moveMapToLocation(LatLng(data.trace!.endPoint.lat, data.trace!.endPoint.lng));
      });
      return;
    }
    
    // 如果都没有有效坐标，保持默认杭州坐标（在mapOptions中已设置）
  }

  /// 切换查看用户（自己/另一半）
  void switchUser() {
    isOneself.value = isOneself.value == 1 ? 0 : 1;
    // 切换用户时，缓存是按用户和日期分别存储的，会自动加载对应用户的缓存数据
    loadLocationData();
  }
  
  /// 强制刷新当前用户数据（用于头像点击）
  void refreshCurrentUserData() {
    print('🔄 刷新用户数据: isOneself=${isOneself.value}');
    
    // 清除当前选择日期的所有相关缓存，包括两个用户的数据
    final currentUser = UserManager.currentUser;
    if (currentUser?.id != null) {
      // 清除两个用户的缓存（isOneself=0和isOneself=1）
      final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate.value);
      final cacheKey0 = '${currentUser!.id}_${dateKey}_0';
      final cacheKey1 = '${currentUser.id}_${dateKey}_1';
      
      _trackDataCache.remove(cacheKey0);
      _trackDataCache.remove(cacheKey1);
      print('🧹 清除缓存: $cacheKey0, $cacheKey1');
      
      // 同时清除TrackApi中的缓存
      TrackApi.clearUserCache(currentUser.id.toString(), dateKey);
    }
    
    // 先停止播放和清理状态
    _resetReplayState();
    
    // 清空当前数据，确保UI立即更新
    _clearData();
    
    // 延迟一小段时间确保状态清理完成，然后重新加载数据
    Future.delayed(const Duration(milliseconds: 100), () {
      loadLocationData().then((_) {
        // 数据加载完成后自动调整地图视图
        _fitMapToTrackPoints();
      });
    });
  }
  
  // 移除所有缓存相关方法

  /// 执行绑定操作 - 显示绑定输入弹窗
  void performBindAction() {
    Get.toNamed(KissuRoutePath.share);
    // DialogManager.showBindingInput(
    //   title: "",
    //   context: Get.context!,
    //   onConfirm: (code) {
    //     // 绑定完成后会自动刷新数据，这里不需要额外操作
    //     // 因为BindingInputDialog内部已经会调用UserManager.refreshUserInfo()
    //     // 并且会更新各个页面的数据
    //     _loadUserInfo(); // 重新加载用户信息更新绑定状态
        
    //     // 延迟执行导航，确保弹窗完全关闭后再执行
    //     Future.delayed(const Duration(milliseconds: 300), () {
    //       if (Get.context != null) {
    //         Get.offAllNamed(KissuRoutePath.home);
    //       }
    //     });
    //   },
    // );
  }

  /// 选择日期
  void selectDate(DateTime date) {
    selectedDate.value = date;
    
    print('🔄 选择日期: ${DateFormat('yyyy-MM-dd').format(date)}, 检查缓存或加载数据');
    
    loadLocationData();
  }
  
  /// 清除所有轨迹数据缓存
  void clearTrackDataCache() {
    _trackDataCache.clear();
    print('🧹 轨迹数据缓存已清除');
  }
  
  /// 清除特定用户的轨迹数据缓存
  void clearUserTrackDataCache(int userId) {
    final keysToRemove = _trackDataCache.keys.where((key) => key.startsWith('${userId}_')).toList();
    for (final key in keysToRemove) {
      _trackDataCache.remove(key);
    }
    print('🧹 用户 $userId 的轨迹数据缓存已清除');
  }

  /// 安全地更新停留点 markers
  Future<void> _safeUpdateStayMarkers() async {
    print('🔄 更新停留点 markers...');
    await _updateStayMarkersWithIcons();
  }

  /// 更新停留点 markers（优先使用自定义图标，失败时使用彩色默认图标）
  Future<void> _updateStayMarkersWithIcons() async {
    stayMarkers.clear();
    
    if (stopPoints.isEmpty) {
      print('📍 没有停留点数据');
      return;
    }
    
    print('📍 创建停留点标记: ${stopPoints.length}个点');
    
    // 尝试使用自定义图标，如果不可用则使用彩色默认图标
    
    try {
      final List<Marker> tempMarkers = [];
      
      for (int i = 0; i < stopPoints.length; i++) {
        final stop = stopPoints[i];
        
        // 根据 pointType 和 serialNumber 判断点的类型
        bool isStartPoint = stop.pointType == 'start' || stop.serialNumber == '起';
        bool isEndPoint = stop.pointType == 'end' || stop.serialNumber == '终';
        
        try {
          // 安全创建标记，避免FlutterLoader空指针异常
          String title;
          BitmapDescriptor? icon;
          
          if (isStartPoint) {
            title = '起点';
          } else if (isEndPoint) {
            title = '终点';
          } else {
            title = '停留点 ${stop.serialNumber ?? (i + 1).toString()}';
          }
          
          // 延迟创建BitmapDescriptor，在try-catch中处理可能的异常
          try {
            // 等待一小段时间确保Flutter引擎初始化完成
            await Future.delayed(Duration(milliseconds: 10));
            
            if (isStartPoint) {
              icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
            } else if (isEndPoint) {
              icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
            } else {
              icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
            }
          } catch (iconError) {
            print('⚠️ BitmapDescriptor创建失败，使用默认标记: $iconError');
            icon = null; // 使用系统默认标记
          }
          
          // 创建标记，根据icon是否可用决定是否设置
          final marker = icon != null 
            ? Marker(
                position: LatLng(stop.lat, stop.lng),
                icon: icon,
                infoWindow: InfoWindow(
                  title: title,
                  snippet: '${stop.locationName ?? '未知位置'}\n${stop.startTime ?? ''} ${stop.duration?.isNotEmpty == true ? '停留${stop.duration}' : ''}',
                ),
                onTap: (String markerId) {
                  print('点击了停留点: $title - ${stop.locationName}');
                  // 点击标记时，可以跳转到对应的轨迹回放位置
                  if (trackPoints.isNotEmpty) {
                    _moveMapToLocation(LatLng(stop.lat, stop.lng));
                  }
                },
              )
            : Marker(
                position: LatLng(stop.lat, stop.lng),
                infoWindow: InfoWindow(
                  title: title,
                  snippet: '${stop.locationName ?? '未知位置'}\n${stop.startTime ?? ''} ${stop.duration?.isNotEmpty == true ? '停留${stop.duration}' : ''}',
                ),
                onTap: (String markerId) {
                  print('点击了停留点: $title - ${stop.locationName}');
                  // 点击标记时，可以跳转到对应的轨迹回放位置
                  if (trackPoints.isNotEmpty) {
                    _moveMapToLocation(LatLng(stop.lat, stop.lng));
                  }
                },
              );
          
          tempMarkers.add(marker);
          print('✅ 停留点 $i ($title) 标记创建成功');
        } catch (e) {
          print('❌ 停留点 $i 标记创建失败: $e，尝试降级方案');
          // 降级方案：使用最基本的标记（完全不设置图标）
          try {
            String title;
            if (isStartPoint) {
              title = '起点';
            } else if (isEndPoint) {
              title = '终点';
            } else {
              title = '停留点 ${stop.serialNumber ?? (i + 1).toString()}';
            }
            
            final fallbackMarker = Marker(
              position: LatLng(stop.lat, stop.lng),
              // 完全不设置icon，让系统使用最基础的默认标记
              infoWindow: InfoWindow(
                title: title,
                snippet: '${stop.locationName ?? '未知位置'}\n${stop.startTime ?? ''} ${stop.duration?.isNotEmpty == true ? '停留${stop.duration}' : ''}',
              ),
              onTap: (String markerId) {
                print('点击了停留点: $title - ${stop.locationName}');
                if (trackPoints.isNotEmpty) {
                  _moveMapToLocation(LatLng(stop.lat, stop.lng));
                }
              },
            );
            
            tempMarkers.add(fallbackMarker);
            print('✅ 停留点 $i ($title) 降级标记创建成功');
          } catch (fallbackError) {
            print('❌ 停留点 $i 降级方案也失败: $fallbackError，跳过此点');
            continue;
          }
        }
      }
      
      // 如果至少有一个标记创建成功，就更新列表
      if (tempMarkers.isNotEmpty) {
        stayMarkers.addAll(tempMarkers);
        print('✅ 更新停留点标记成功: ${stayMarkers.length}个');
      } else {
        print('❌ 没有成功创建任何停留点标记');
      }
    } catch (e) {
      print('❌ 停留点标记更新过程失败: $e');
      
      // 最后的降级方案：创建一个基础彩色标记
      try {
        if (stopPoints.isNotEmpty) {
          stayMarkers.add(Marker(
            position: LatLng(stopPoints.first.lat, stopPoints.first.lng),
            // 使用彩色默认图标
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: '位置点',
              snippet: stopPoints.first.locationName ?? '未知位置',
            ),
          ));
          print('✅ 降级方案：成功创建彩色标记');
        }
      } catch (fallbackError) {
        print('❌ 降级方案也失败: $fallbackError');
        // 完全放弃添加标记点，避免崩溃
      }
    }
  }


  /// 获取当前所有 markers
  Future<List<Marker>> get allMarkers async {
    final markers = <Marker>[];
    
    // 安全地添加停留点标记
    try {
      markers.addAll(stayMarkers);
    } catch (e) {
      print('❌ 获取停留点标记失败: $e');
    }
    
    if (currentPosition.value != null) {
      try {
        // 安全创建当前位置标记
        BitmapDescriptor? icon;
        try {
          // 尝试创建彩色标记
          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
        } catch (iconError) {
          print('⚠️ 当前位置标记图标创建失败，使用默认标记: $iconError');
          icon = null; // 使用系统默认标记
        }
        
        // 根据icon是否可用决定如何创建标记
        final currentMarker = icon != null
          ? Marker(
              position: currentPosition.value!,
              icon: icon,
              infoWindow: InfoWindow(
                title: '当前位置',
                snippet: '轨迹回放当前位置',
              ),
              onTap: (String markerId) {
                print('点击了当前位置: $markerId');
              },
            )
          : Marker(
              position: currentPosition.value!,
              infoWindow: InfoWindow(
                title: '当前位置',
                snippet: '轨迹回放当前位置',
              ),
              onTap: (String markerId) {
                print('点击了当前位置: $markerId');
              },
            );
        
        markers.add(currentMarker);
      } catch (e) {
        print('❌ 创建当前位置标记失败: $e');
        // 降级：使用无图标的简单标记
        try {
          markers.add(
            Marker(
              position: currentPosition.value!,
              infoWindow: InfoWindow(
                title: '当前位置',
                snippet: '轨迹回放当前位置',
              ),
              onTap: (String markerId) {
                print('点击了当前位置: $markerId');
              },
            ),
          );
        } catch (fallbackError) {
          print('❌ 简单当前位置标记也失败: $fallbackError');
        }
      }
    }
    return markers;
  }

  /// 计算小人的朝向角度
  double _getRotationAngle() {
    if (trackPoints.length < 2 || currentReplayIndex.value >= trackPoints.length - 1) return 0;

    // 确保索引在有效范围内
    final currentIndex = currentReplayIndex.value.clamp(0, trackPoints.length - 2);
    final current = trackPoints[currentIndex];
    final next = trackPoints[currentIndex + 1];

    final dx = next.longitude - current.longitude;
    final dy = next.latitude - current.latitude;

    // 计算角度，并调整基准方向
    // 由于箭头图片指向正左方，需要加上π/2使其指向正确方向
    final angle = atan2(dx, dy);
    return angle + pi / 2; // 调整90度，因为箭头原本指向左方
  }

  /// 公开的获取旋转角度方法
  double getRotationAngle() {
    return _getRotationAngle();
  }

  /// 在两点之间进行插值
  LatLng _interpolatePosition(LatLng start, LatLng end, double t) {
    // 确保插值参数在0-1之间，避免异常值
    final clampedT = t.clamp(0.0, 1.0);
    final lat = start.latitude + (end.latitude - start.latitude) * clampedT;
    final lng = start.longitude + (end.longitude - start.longitude) * clampedT;
    return LatLng(lat, lng);
  }

  /// 平滑轨迹点处理 - 优化内存使用
  List<LatLng> _smoothTrackPoints(List<LatLng> rawPoints) {
    if (rawPoints.length <= 2) return rawPoints;

    // 预分配容量以减少内存重分配
    final smoothedPoints = <LatLng>[];
    smoothedPoints.add(rawPoints.first);
    
    // 批量处理以减少函数调用开销
    for (int i = 1; i < rawPoints.length - 1; i++) {
      final prev = rawPoints[i - 1];
      final current = rawPoints[i];
      final next = rawPoints[i + 1];
      
      // 快速距离检查（避免开平方运算）
      final distToPrevSq = _calculateDistanceSquared(prev, current);
      final distToNextSq = _calculateDistanceSquared(current, next);
      
      // 100 = 10米的平方，避免开平方运算
      if (distToPrevSq < 100 && distToNextSq < 100) {
        final smoothLat = (prev.latitude + current.latitude + next.latitude) / 3;
        final smoothLng = (prev.longitude + current.longitude + next.longitude) / 3;
        smoothedPoints.add(LatLng(smoothLat, smoothLng));
      } else {
        smoothedPoints.add(current);
      }
    }
    
    smoothedPoints.add(rawPoints.last);
    return smoothedPoints;
  }
  
  /// 计算距离平方（避免开平方运算以提高性能）
  double _calculateDistanceSquared(LatLng point1, LatLng point2) {
    final deltaLat = point2.latitude - point1.latitude;
    final deltaLng = point2.longitude - point1.longitude;
    return deltaLat * deltaLat + deltaLng * deltaLng;
  }
  
  /// 计算两点间距离（米）
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // 地球半径（米）
    final double lat1Rad = point1.latitude * pi / 180;
    final double lat2Rad = point2.latitude * pi / 180;
    final double deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final double deltaLngRad = (point2.longitude - point1.longitude) * pi / 180;
    
    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// 计算累计距离（从startIndex到endIndex）
  double _calculateCumulativeDistance(int startIndex, int endIndex) {
    if (trackPoints.isEmpty || startIndex >= endIndex) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = startIndex; i < endIndex && i < trackPoints.length - 1; i++) {
      totalDistance += _calculateDistance(trackPoints[i], trackPoints[i + 1]);
    }
    return totalDistance;
  }
  
  /// 更新播放状态（距离和时间）
  void _updateReplayStatus() {
    // 更新距离显示
    final distanceKm = _cumulativeDistance / 1000;
    replayDistance.value = "${distanceKm.toStringAsFixed(2)}km";
    
    // 更新时间显示
    if (_replayStartTime != null) {
      final duration = DateTime.now().difference(_replayStartTime!);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      final seconds = duration.inSeconds % 60;
      replayTime.value = "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }
  }
  
  /// 跳转到指定索引（用于进度条拖动）
  void seekToIndex(int newIndex) {
    if (trackPoints.isEmpty) return;
    
    final safeIndex = newIndex.clamp(0, trackPoints.length - 1);
    currentReplayIndex.value = safeIndex;
    
    // 更新当前位置
    currentPosition.value = trackPoints[safeIndex];
    _moveMapToLocation(trackPoints[safeIndex]);
    
    // 更新累计距离
    _cumulativeDistance = _calculateCumulativeDistance(0, safeIndex);
    
    // 如果正在播放，更新时间基准
    if (isReplaying.value && _replayStartTime != null) {
      // 根据当前进度调整开始时间，让时间显示更准确
      final progress = safeIndex / (trackPoints.length - 1);
      final estimatedTotalSeconds = 300; // 假设总时长5分钟，可以根据实际情况调整
      final currentSeconds = (progress * estimatedTotalSeconds).round();
      _replayStartTime = DateTime.now().subtract(Duration(seconds: currentSeconds));
    }
    
    _updateReplayStatus();
  }

  /// 开始回放
  void startReplay() {
    if (trackPoints.isEmpty) {
      CustomToast.show(Get.context!, '暂无轨迹数据可回放');
      return;
    }
    isReplaying.value = true;
    showFullPlayer.value = true; // 显示完整播放器
    _currentStep = 0;

    // 确保currentReplayIndex在有效范围内
    currentReplayIndex.value = currentReplayIndex.value.clamp(0, trackPoints.length - 1);

    // 设置初始位置
    if (currentPosition.value == null && trackPoints.isNotEmpty) {
      currentPosition.value = trackPoints[currentReplayIndex.value];
    }
    
    // 初始化播放时间跟踪
    _replayStartTime = DateTime.now();
    // 计算已经播放过的距离（从开始到当前索引）
    _cumulativeDistance = _calculateCumulativeDistance(0, currentReplayIndex.value);
    _updateReplayStatus();

    _replayTimer?.cancel();
    // 根据播放速度调整定时器间隔，使动画更流畅
    final intervalMs = (30 / replaySpeed.value).round(); // 从50ms改为30ms，让动画更流畅
    _replayTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      // 检查轨迹点是否仍然有效
      if (trackPoints.isEmpty) {
        stopReplay();
        return;
      }
      
      // 确保currentReplayIndex在有效范围内
      if (currentReplayIndex.value >= trackPoints.length) {
        currentReplayIndex.value = trackPoints.length - 1;
        stopReplay();
        return;
      }
      
      if (currentReplayIndex.value < trackPoints.length - 1) {
        final currentIndex = currentReplayIndex.value.clamp(0, trackPoints.length - 2);
        final startPoint = trackPoints[currentIndex];
        final endPoint = trackPoints[currentIndex + 1];

        // 计算插值进度，避免除零
        final progress = animationSteps > 0 ? _currentStep / animationSteps : 0.0;

        // 使用平滑插值算法，让动画更自然
        final smoothProgress = _applySmoothEasing(progress.clamp(0.0, 1.0));

        // 更新当前位置（插值）
        currentPosition.value = _interpolatePosition(
          startPoint,
          endPoint,
          smoothProgress,
        );

        // 平滑移动地图视角，添加一些延迟避免过于频繁
        if (_currentStep % 3 == 0) { // 每3步更新一次地图位置
          _moveMapToLocation(currentPosition.value!);
        }

        _currentStep++;

        // 到达下一个点
        if (_currentStep >= animationSteps) {
          _currentStep = 0;
          currentReplayIndex.value++;
          // 更新累计距离和播放状态
          _cumulativeDistance = _calculateCumulativeDistance(0, currentReplayIndex.value);
          _updateReplayStatus();
          
          // 检查是否经过停留点，给予提示
          _checkPassingStopPoint(currentReplayIndex.value);
        }
      } else {
        // 到达终点
        currentPosition.value = trackPoints.last;
        _showReplayCompleteMessage();
        stopReplay();
      }
    });
  }
  
  /// 应用平滑缓动函数，让动画更自然
  double _applySmoothEasing(double t) {
    // 使用ease-in-out缓动函数
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }
  
  /// 检查是否经过停留点
  void _checkPassingStopPoint(int currentIndex) {
    if (currentIndex >= trackPoints.length || stopPoints.isEmpty) return;
    
    final currentPos = trackPoints[currentIndex];
    
    // 检查当前位置是否靠近任何停留点
    for (final stop in stopPoints) {
      final distance = _calculateDistance(
        currentPos, 
        LatLng(stop.lat, stop.lng)
      );
      
      // 如果距离小于50米，认为经过了停留点
      if (distance < 50) {
        print('🚩 经过停留点: ${stop.locationName}');
        // 可以在这里添加UI提示，比如闪烁标记点或显示toast
        break;
      }
    }
  }
  
  /// 显示回放完成消息
  void _showReplayCompleteMessage() {
    CustomToast.show(
      Get.context!, 
      '轨迹回放完成！总距离：${moveDistance.value}，总停留：${stayDuration.value}'
    );
  }

  /// 暂停
  void pauseReplay() {
    isReplaying.value = false;
    _replayTimer?.cancel();
  }

  /// 停止并重置
  void stopReplay() {
    isReplaying.value = false;
    _replayTimer?.cancel();
    currentReplayIndex.value = 0;
    _currentStep = 0;
    replaySpeed.value = 1.0; // 重置播放速度
    // 重置播放状态
    _replayStartTime = null;
    _cumulativeDistance = 0.0;
    replayDistance.value = "0.00km";
    replayTime.value = "00:00:00";
    // 重置位置
    if (trackPoints.isNotEmpty) {
      currentPosition.value = trackPoints.first;
      _moveMapToLocation(trackPoints.first);
    }
  }
  
  /// 关闭播放器并重置动画
  void closePlayer() {
    stopReplay(); // 停止当前播放
    showFullPlayer.value = false; // 隐藏完整播放器
    currentPosition.value = null; // 清除当前位置标记
    // 重置地图视图到初始状态
    if (trackPoints.isNotEmpty) {
      _moveMapToLocation(trackPoints.first);
    }
  }

  /// 切换播放速度（快进）
  void toggleSpeed() {
    if (replaySpeed.value == 1.0) {
      replaySpeed.value = 2.0;
    } else if (replaySpeed.value == 2.0) {
      replaySpeed.value = 4.0;
    } else {
      replaySpeed.value = 1.0;
    }
    
    // 如果正在播放，重新启动以应用新速度
    if (isReplaying.value) {
      final wasReplaying = isReplaying.value;
      pauseReplay();
      if (wasReplaying) {
        startReplay();
      }
    }
  }

  /// 加载虚拟数据
  Future<void> _loadMockData() async {
    isUsingMockData.value = true;
    print('🎭 加载虚拟数据: isOneself=${isOneself.value}');
    
    // 生成基于日期的虚拟数据
    final mockData = _generateMockDataForDate(selectedDate.value);
    
    // 设置虚拟轨迹点
    trackPoints.value = mockData['trackPoints'];
    print('🎭 虚拟轨迹点数量: ${trackPoints.length}');
    
    // 设置虚拟停留记录
    stopRecords.value = mockData['stopRecords'];
    
    // 从停留记录生成停留点
    stopPoints.value = stopRecords.map((record) => TrackStopPoint(
      lat: record.latitude,
      lng: record.longitude,
      startTime: record.startTime,
      endTime: record.endTime,
      duration: record.duration,
      locationName: record.locationName,
      status: record.status,
    )).toList();
    print('🎭 虚拟停留点数量: ${stopPoints.length}');
    
    // 更新停留点markers
    try {
      await _safeUpdateStayMarkers();
    } catch (e) {
      print('❌ 虚拟数据更新停留点标记失败: $e');
      // 即使失败也继续执行，避免阻塞整个流程
    }
    
    // 设置虚拟统计数据
    stayCount.value = mockData['stayCount'];
    stayDuration.value = mockData['stayDuration'];
    moveDistance.value = mockData['moveDistance'];
    
    // 移动地图到第一个点
    if (trackPoints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _moveMapToLocation(trackPoints.first);
      });
    }
  }
  
  /// 为指定日期生成虚拟数据 - 7天内数据完全一致
  Map<String, dynamic> _generateMockDataForDate(DateTime date) {
    // 不使用日期，改为固定数据确保7天内完全一致
    final List<StopRecord> mockStopRecords = [];
    final List<LatLng> mockTrackPoints = [];
    
    // 固定的虚拟地点和坐标数据
    final List<Map<String, dynamic>> fixedLocations = [
      {
        'name': '杭州西湖风景区',
        'lat': 30.2741,
        'lng': 120.2206,
        'startTime': '09:00',
        'endTime': '',
        'duration': '',
        'pointType': 'start',
        'serialNumber': '起',
        'status': '',
      },
      {
        'name': '浙江省杭州市上城区中豪·湘和国际',
        'lat': 30.2850,
        'lng': 120.2320,
        'startTime': '11:15',
        'endTime': '12:45',
        'duration': '90分钟',
        'pointType': 'stop',
        'serialNumber': '1',
        'status': 'ended',
      },
      {
        'name': '杭州东站',
        'lat': 30.2905,
        'lng': 120.2142,
        'startTime': '13:30',
        'endTime': '14:20',
        'duration': '50分钟',
        'pointType': 'stop',
        'serialNumber': '2',
        'status': 'ended',
      },
      {
        'name': '钱塘江边',
        'lat': 30.2635,
        'lng': 120.2285,
        'startTime': '15:30',
        'endTime': '',
        'duration': '',
        'pointType': 'end',
        'serialNumber': '终',
        'status': '',
      },
    ];
    
    // 创建固定的停留记录
    for (var location in fixedLocations) {
      mockStopRecords.add(StopRecord(
        latitude: location['lat'],
        longitude: location['lng'],
        locationName: location['name'],
        startTime: location['startTime'],
        endTime: location['endTime'],
        duration: location['duration'],
        status: location['status'],
        pointType: location['pointType'],
        serialNumber: location['serialNumber'],
      ));
    }
    
    // 生成固定的轨迹点
    for (int i = 0; i < fixedLocations.length; i++) {
      final location = fixedLocations[i];
      mockTrackPoints.add(LatLng(location['lat'], location['lng']));
      
      // 在点之间生成连接轨迹（除了最后一个点）
      if (i < fixedLocations.length - 1) {
        final nextLocation = fixedLocations[i + 1];
        for (int j = 1; j <= 5; j++) {
          final progress = j / 5.0;
          final trackLat = location['lat'] + (nextLocation['lat'] - location['lat']) * progress;
          final trackLng = location['lng'] + (nextLocation['lng'] - location['lng']) * progress;
          mockTrackPoints.add(LatLng(trackLat, trackLng));
        }
      }
    }
    
    // 固定的统计数据
    return {
      'trackPoints': mockTrackPoints,
      'stopRecords': mockStopRecords,
      'stayCount': 3, // 起点+2个停留点+终点，但统计中只算停留点  
      'stayDuration': '3小时25分钟',
      'moveDistance': '4.2km',
    };
  }

  @override
  void onClose() {
    print('🧹 开始清理轨迹页面资源和缓存...');
    
    // 清理所有定时器和资源
    _replayTimer?.cancel();
    _replayTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    
    // 清理地图控制器
    // AMapController 无需手动dispose
    
    // 清空大型数据结构
    trackPoints.clear();
    stopPoints.clear();
    stayMarkers.clear();
    stopRecords.clear();
    
    // 页面销毁时保留缓存，缓存将在用户退出登录时清除
    
    // 重置所有状态
    isLoading.value = false;
    isReplaying.value = false;
    showFullPlayer.value = false;
    currentReplayIndex.value = 0;
    replaySpeed.value = 1.0;
    animationProgress.value = 0.0;
    currentPosition.value = null;
    
    // 重置统计数据
    stayCount.value = 0;
    stayDuration.value = "";
    moveDistance.value = "";
    replayDistance.value = "0.00km";
    replayTime.value = "00:00:00";
    
    print('✅ 轨迹页面资源清理完成');
    super.onClose();
  }
}
