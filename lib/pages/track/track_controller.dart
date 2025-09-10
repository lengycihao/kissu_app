import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:kissu_app/network/public/ltrack_api.dart';
import 'package:kissu_app/pages/track/stay_point.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/widgets/dialogs/dialog_manager.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:intl/intl.dart';

class TrackController extends GetxController {
  /// 当前查看的用户类型 (1: 自己, 0: 另一半)
  final isOneself = 1.obs;
  
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
  late final MapController mapController;
  
  /// 防抖定时器
  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    // 初始化地图控制器
    mapController = MapController();
    // 确保初始状态下播放控制器可见
    sheetPercent.value = 0.3;
    // 加载用户信息
    _loadUserInfo();
    // 加载初始数据
    loadLocationData();
  }
  
  /// 加载用户信息
  void _loadUserInfo() {
    final user = UserManager.currentUser;
    if (user != null) {
      // 设置我的头像
      myAvatar.value = user.headPortrait ?? '';
      
      // 检查绑定状态
      final bindStatus = user.bindStatus ?? "1";
      isBindPartner.value = bindStatus == "2";
      
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

  /// 轨迹点（从API数据获取）
  final RxList<LatLng> trackPoints = <LatLng>[].obs;

  /// 停留点列表（从API数据获取）
  final RxList<TrackStopPoint> stopPoints = <TrackStopPoint>[].obs;

  /// 停留点 marker 列表
  final RxList<Marker> stayMarkers = <Marker>[].obs;

  /// 地图配置
  MapOptions get mapOptions => MapOptions(
    initialCenter: trackPoints.isNotEmpty
        ? trackPoints.first
        : const LatLng(30.2741, 120.2206), // 杭州默认坐标
    initialZoom: 16.0,
    maxZoom: 18, // 最大缩放
    minZoom: 10, // 最小缩放
  );

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
    
    isLoading.value = true;
    _resetReplayState();
    
    // 检查是否应该使用虚拟数据
    if (!isBindPartner.value) {
      _loadMockData();
      isLoading.value = false;
      return;
    }
    
    try {
      final dateString = DateFormat('yyyy-MM-dd').format(selectedDate.value);
      final result = await TrackApi.getTrack(
        date: dateString,
        isOneself: isOneself.value,
      );
      
      if (result.isSuccess && result.data != null) {
        isUsingMockData.value = false;
        locationData.value = result.data;
        await _updateTrackDataAsync();
        _updateStatistics();
        _updateStopRecords();
      } else {
        Get.snackbar('错误', result.msg ?? '获取数据失败');
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
        errorMessage = '加载数据失败: ${e.toString().length > 100 ? e.toString().substring(0, 100) + '...' : e.toString()}';
      }
      
      Get.snackbar(
        '错误', 
        errorMessage,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
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
    if (locationData.value == null) return;
    
    final data = locationData.value!;
    
    // 在后台线程处理数据以避免阻塞UI
    final rawPoints = await compute(_processLocationData, data.locations ?? []);
    
    // 对轨迹点进行平滑处理
    trackPoints.value = _smoothTrackPoints(rawPoints);
    
    // 过滤停留点
    stopPoints.value = data.trace?.stops
        .where((stop) => stop.lat != 0.0 && stop.lng != 0.0)
        .toList() ?? [];
    
    // 更新停留点markers
    _updateStayMarkers();
    
    // 移动地图
    if (trackPoints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mapController.move(trackPoints.first, 16.0);
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
    if (locationData.value == null) return;
    
    final stayCollect = locationData.value!.userLocationMobileDevice?.stayCollect;
    stayCount.value = stayCollect?.stayCount ?? 0;
    stayDuration.value = stayCollect?.stayTime ?? '';
    moveDistance.value = stayCollect?.moveDistance ?? '';
  }

  /// 更新停留记录列表
  void _updateStopRecords() {
    if (locationData.value == null) return;
    
    final stops = locationData.value!.trace?.stops ?? [];
    stopRecords.value = stops.map((stop) {
      return StopRecord(
        latitude: stop.lat,
        longitude: stop.lng,
        locationName: stop.locationName ?? '',
        startTime: stop.startTime ?? '',
        endTime: (stop.endTime?.isNotEmpty == true) ? stop.endTime! : (stop.startTime ?? ''), // 如果endTime为空，使用startTime
        duration: stop.duration ?? '',
        status: stop.status ?? '',
        pointType: stop.pointType ?? '', // 需要确保API数据包含这个字段
        serialNumber: stop.serialNumber ?? '', // 需要确保API数据包含这个字段
      );
    }).toList();
  }

  /// 当没有有效轨迹点时，尝试移动到起点或终点
  void _moveToValidPoint() {
    if (locationData.value == null) return;
    
    final data = locationData.value!;
    
    // 尝试使用起点
    if (data.trace?.startPoint.lat != 0.0 && data.trace?.startPoint.lng != 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mapController.move(LatLng(data.trace!.startPoint.lat, data.trace!.startPoint.lng), 16.0);
      });
      return;
    }
    
    // 尝试使用终点
    if (data.trace?.endPoint.lat != 0.0 && data.trace?.endPoint.lng != 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mapController.move(LatLng(data.trace!.endPoint.lat, data.trace!.endPoint.lng), 16.0);
      });
      return;
    }
    
    // 如果都没有有效坐标，保持默认杭州坐标（在mapOptions中已设置）
  }

  /// 切换查看用户（自己/另一半）
  void switchUser() {
    isOneself.value = isOneself.value == 1 ? 0 : 1;
    loadLocationData();
  }

  /// 执行绑定操作 - 显示绑定输入弹窗
  void performBindAction() {
    DialogManager.showBindingInput(
      title: "",
      context: Get.context!,
      onConfirm: (code) {
        // 绑定完成后会自动刷新数据，这里不需要额外操作
        // 因为BindingInputDialog内部已经会调用UserManager.refreshUserInfo()
        // 并且会更新各个页面的数据
        _loadUserInfo(); // 重新加载用户信息更新绑定状态
        
        // 延迟执行导航，确保弹窗完全关闭后再执行
        Future.delayed(const Duration(milliseconds: 300), () {
          if (Get.context != null) {
            Get.offAllNamed(KissuRoutePath.home);
          }
        });
      },
    );
  }

  /// 选择日期
  void selectDate(DateTime date) {
    selectedDate.value = date;
    loadLocationData();
  }

  /// 更新停留点markers
  void _updateStayMarkers() {
    stayMarkers.value = stopPoints.asMap().entries.map((entry) {
      final index = entry.key;
      final stop = entry.value;
      final stopIndex = index + 1;
      final isStartPoint = index == 0;
      final isEndPoint = index == stopPoints.length - 1;
      
      return Marker(
        point: LatLng(stop.lat, stop.lng),
        width: (isStartPoint || isEndPoint) ? 46 : 24, // 起点终点用46px，普通标记用24px
        height: (isStartPoint || isEndPoint) ? 46 : 24,
        child: _buildStopMarker(stopIndex, isStartPoint, isEndPoint),
      );
    }).toList();
  }

  /// 构建停留点标记
  Widget _buildStopMarker(int index, bool isStartPoint, bool isEndPoint) {
    // 如果是起点或终点，使用特殊图标
    if (isStartPoint) {
      return Image.asset(
        'assets/kissu_location_start.webp',
        width: 46,
        height: 46,
        fit: BoxFit.contain,
      );
    }
    
    if (isEndPoint) {
      return Image.asset(
        'assets/kissu_location_end.webp',
        width: 46,
        height: 46,
        fit: BoxFit.contain,
      );
    }
    
    // 普通停留点，根据性别设置颜色
    final markerColor = isOneself.value == 1 
        ? const Color(0xFF3B96FF)  // 男性蓝色
        : const Color(0xFFFF88AA); // 女性粉色
    
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: markerColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2), // 白色边框
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  /// 获取当前所有 markers
  List<Marker> get allMarkers {
    final markers = List<Marker>.from(stayMarkers);
    if (currentPosition.value != null) {
      // 创建一个新的 marker 在当前位置
      markers.add(
        Marker(
          point: currentPosition.value!,
          width: 40,
          height: 40,
          child: Transform.rotate(
            angle: _getRotationAngle(),
            child: const Icon(
              Icons.directions_walk, // 改为行走的小人图标
              color: Colors.blue,
              size: 32,
            ),
          ),
        ),
      );
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
    mapController.move(trackPoints[safeIndex], mapController.camera.zoom);
    
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
      Get.snackbar('提示', '暂无轨迹数据可回放');
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
    // 根据播放速度调整定时器间隔
    final intervalMs = (50 / replaySpeed.value).round();
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

        // 更新当前位置（插值）
        currentPosition.value = _interpolatePosition(
          startPoint,
          endPoint,
          progress.clamp(0.0, 1.0),
        );

        // 平滑移动地图视角
        mapController.move(currentPosition.value!, mapController.camera.zoom);

        _currentStep++;

        // 到达下一个点
        if (_currentStep >= animationSteps) {
          _currentStep = 0;
          currentReplayIndex.value++;
          // 更新累计距离和播放状态
          _cumulativeDistance = _calculateCumulativeDistance(0, currentReplayIndex.value);
          _updateReplayStatus();
        }
      } else {
        // 到达终点
        currentPosition.value = trackPoints.last;
        stopReplay();
      }
    });
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
      mapController.move(trackPoints.first, mapController.camera.zoom);
    }
  }
  
  /// 关闭播放器并重置动画
  void closePlayer() {
    stopReplay(); // 停止当前播放
    showFullPlayer.value = false; // 隐藏完整播放器
    currentPosition.value = null; // 清除当前位置标记
    // 重置地图视图到初始状态
    if (stayMarkers.isNotEmpty) {
      final firstMarker = stayMarkers.first;
      mapController.move(firstMarker.point, 15.0);
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
  void _loadMockData() {
    isUsingMockData.value = true;
    
    // 生成基于日期的虚拟数据
    final mockData = _generateMockDataForDate(selectedDate.value);
    
    // 设置虚拟轨迹点
    trackPoints.value = mockData['trackPoints'];
    
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
    
    // 更新停留点markers
    _updateStayMarkers();
    
    // 设置虚拟统计数据
    stayCount.value = mockData['stayCount'];
    stayDuration.value = mockData['stayDuration'];
    moveDistance.value = mockData['moveDistance'];
    
    // 移动地图到第一个点
    if (trackPoints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mapController.move(trackPoints.first, 16.0);
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
    // 清理所有定时器和资源
    _replayTimer?.cancel();
    _replayTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    
    // 清理地图控制器
    mapController.dispose();
    
    // 清空大型数据结构
    trackPoints.clear();
    stopPoints.clear();
    stayMarkers.clear();
    stopRecords.clear();
    
    super.onClose();
  }
}
