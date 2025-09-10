import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/network/public/location_api.dart';
import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:kissu_app/widgets/dialogs/dialog_manager.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';

class LocationController extends GetxController {
  /// 当前查看的用户类型 (1: 自己, 0: 另一半)
  final isOneself = 1.obs;
  
  /// 用户信息
  final myAvatar = "".obs;
  final partnerAvatar = "".obs;
  final isBindPartner = false.obs;
  
  /// 位置信息
  final myLocation = Rx<LatLng?>(null);
  final partnerLocation = Rx<LatLng?>(null);
  
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
  
  /// DraggableScrollableSheet 状态
  final sheetPercent = 0.3.obs;
  
  /// 地图控制器
  late final MapController mapController;
  
  /// 加载状态
  final isLoading = false.obs;
  
  /// 虚拟数据标识
  final isUsingMockData = false.obs;
  
  /// Tooltip相关
  OverlayEntry? _overlayEntry;
  late BuildContext pageContext;

  @override
  void onInit() {
    super.onInit();
    // 初始化地图控制器
    mapController = MapController();
    // 加载用户信息
    _loadUserInfo();
    // 加载位置数据
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
      
      // 根据绑定状态设置虚拟数据标识
      isUsingMockData.value = !isBindPartner.value;
      
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

  /// 地图配置
  MapOptions get mapOptions => MapOptions(
    initialCenter: myLocation.value ?? const LatLng(30.2741, 120.2206), // 杭州默认坐标
    initialZoom: 16.0,
    maxZoom: 18,
    minZoom: 10,
  );

  /// 加载位置数据
  Future<void> loadLocationData() async {
    if (isLoading.value) return;
    
    isLoading.value = true;
    
    try {
      if (isUsingMockData.value) {
        // 未绑定状态，使用虚拟数据
        _loadMockLocationData();
      } else {
        // 已绑定状态，调用真实API获取定位数据
        final result = await LocationApi().getLocation();
        
        if (result.isSuccess && result.data != null) {
          final locationData = result.data!;
          
          // 根据当前查看的用户类型显示对应数据
          UserLocationMobileDevice? currentUser;
          UserLocationMobileDevice? partnerUser;
          
          if (isOneself.value == 1) {
            // 查看自己的数据
            currentUser = locationData.userLocationMobileDevice;
            partnerUser = locationData.halfLocationMobileDevice;
          } else {
            // 查看另一半的数据
            currentUser = locationData.halfLocationMobileDevice;
            partnerUser = locationData.userLocationMobileDevice;
          }
          
          // 更新当前用户位置和设备信息
          if (currentUser != null) {
            _updateCurrentUserData(currentUser);
          }
          
          // 更新另一半位置信息
          if (partnerUser != null) {
            _updatePartnerData(partnerUser);
          }
          
          // 更新位置记录
          _updateLocationRecords(currentUser);
          
          // 移动地图到当前位置
          if (myLocation.value != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              mapController.move(myLocation.value!, 15.0);
            });
          }
          
        } else {
          Get.snackbar('提示', result.msg ?? '获取定位数据失败');
        }
      }
      
    } catch (e) {
      Get.snackbar('错误', '加载位置数据失败: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 更新当前用户数据
  void _updateCurrentUserData(UserLocationMobileDevice userData) {
    // 更新位置
    if (userData.latitude != null && userData.longitude != null) {
      final lat = double.tryParse(userData.latitude!);
      final lng = double.tryParse(userData.longitude!);
      if (lat != null && lng != null) {
        myLocation.value = LatLng(lat, lng);
      }
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
  }
  
  /// 更新另一半数据
  void _updatePartnerData(UserLocationMobileDevice partnerData) {
    // 更新另一半位置
    if (partnerData.latitude != null && partnerData.longitude != null) {
      final lat = double.tryParse(partnerData.latitude!);
      final lng = double.tryParse(partnerData.longitude!);
      if (lat != null && lng != null) {
        partnerLocation.value = LatLng(lat, lng);
      }
    }
  }
  
  /// 更新位置记录
  void _updateLocationRecords(UserLocationMobileDevice? userData) {
    if (userData?.stops != null && userData!.stops!.isNotEmpty) {
      // 使用API返回的停留点数据
      locationRecords.value = userData.stops!.map((stop) {
        return LocationRecord(
          time: stop.startTime,
          locationName: stop.locationName,
          distance: stop.duration, // 使用停留时长作为距离信息
          duration: stop.duration,  // 停留时长
          startTime: stop.startTime, // 开始时间
          endTime: stop.endTime,     // 结束时间
        );
      }).toList();
      } else {
      // 如果没有停留点数据，清空记录
      locationRecords.value = [];
    }
  }
  
  /// 加载虚拟定位数据（未绑定状态下使用）
  void _loadMockLocationData() {
    // 设置虚拟位置（杭州西湖区）
    myLocation.value = const LatLng(30.2741, 120.1551);
    partnerLocation.value = const LatLng(30.2755, 120.1580);
    
    // 设置虚拟设备信息
    myDeviceModel.value = "iPhone 15 Pro";
    myBatteryLevel.value = "87%";
    myNetworkName.value = "ChinaMobile-5G";
    speed.value = "2.3m/s";
    
    // 设置虚拟距离和时间信息
    distance.value = "2.1km";
    updateTime.value = "2分钟前";
    currentLocationText.value = "浙江省杭州市西湖区文三路269号";
    
    // 设置虚拟位置记录
    locationRecords.value = [
      LocationRecord(
        time: "09:30",
        locationName: "杭州西湖风景名胜区",
        distance: "1小时30分钟",
        duration: "1小时30分钟",
        startTime: "09:30",
        endTime: "11:00",
      ),
      LocationRecord(
        time: "11:15",
        locationName: "浙江大学玉泉校区",
        distance: "45分钟",
        duration: "45分钟",
        startTime: "11:15",
        endTime: "12:00",
      ),
      LocationRecord(
        time: "14:30",
        locationName: "杭州市图书馆",
        distance: "2小时15分钟",
        duration: "2小时15分钟",
        startTime: "14:30",
        endTime: "16:45",
      ),
      LocationRecord(
        time: "17:20",
        locationName: "西湖银泰城",
        distance: "1小时10分钟",
        duration: "1小时10分钟",
        startTime: "17:20",
        endTime: "18:30",
      ),
      LocationRecord(
        time: "19:00",
        locationName: "杭州东站",
        distance: "当前",
        duration: "当前",
        startTime: "19:00",
        endTime: "当前",
      ),
    ];
    
    // 移动地图到虚拟位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mapController.move(myLocation.value!, 15.0);
    });
  }
  
  /// 执行绑定操作
  void performBindAction() {
    DialogManager.showBindingInput(
      title: "绑定设备",
      context: pageContext,
      onConfirm: (code) {
        // 绑定完成后会自动刷新数据
        _loadUserInfo(); // 重新加载用户信息更新绑定状态
        // 绑定成功后返回到主页
        Get.offAllNamed(KissuRoutePath.home);
      },
    );
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
                            color: Colors.black.withOpacity(0.1),
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
  
  @override
  void onClose() {
    mapController.dispose();
    hideTooltip(); // 清理overlay
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

  LocationRecord({
    this.time,
    this.locationName,
    this.distance,
    this.duration,
    this.startTime,
    this.endTime,
  });
}
