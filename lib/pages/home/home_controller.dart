import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/location/location_binding.dart';
import 'package:kissu_app/pages/location/location_page.dart';
import 'package:kissu_app/pages/mine/mine_binding.dart';
import 'package:kissu_app/pages/mine/mine_page.dart';
import 'package:kissu_app/pages/phone_history/phone_history_binding.dart';
import 'package:kissu_app/pages/phone_history/phone_history_page.dart';
import 'package:kissu_app/pages/track/track_binding.dart';
import 'package:kissu_app/pages/track/track_page.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/widgets/dialogs/binding_input_dialog.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeController extends GetxController {
  // 后面可以加逻辑，比如当前选中的按钮索引
  var selectedIndex = 0.obs;
  
  // 绑定状态
  var isBound = false.obs;
  
  // 头像信息
  var userAvatar = "assets/kissu_icon.webp".obs;
  var partnerAvatar = "assets/kissu_home_add_avair.webp".obs;
  
  // 定位服务相关
  late SimpleLocationService _locationService;
  var isLocationPermissionRequested = false.obs;
  var isLocationServiceStarted = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeLocationService();
    loadUserInfo();
  }
  
  /// 初始化定位服务
  void _initializeLocationService() {
    try {
      // 获取定位服务实例
      _locationService = SimpleLocationService.instance;
      
      // 只检查权限状态，不自动启动服务
      _checkLocationPermissionStatusOnly();
    } catch (e) {
      debugPrint('初始化定位服务失败: $e');
    }
  }
  
  /// 只检查定位权限状态，不自动启动服务
  Future<void> _checkLocationPermissionStatusOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRequested = prefs.getBool('location_permission_requested') ?? false;
      
      if (hasRequested) {
        // 已经请求过权限，检查服务状态（但不自动启动）
        debugPrint('已请求过定位权限，检查服务状态');
        if (_locationService.isLocationEnabled.value) {
          isLocationServiceStarted.value = true;
        }
      }
    } catch (e) {
      debugPrint('检查定位权限状态失败: $e');
    }
  }

  
  /// 请求定位权限并启动服务
  Future<void> _requestLocationPermissionAndStartService() async {
    try {
      isLocationPermissionRequested.value = true;
      
      // 请求定位权限
      bool hasPermission = await _locationService.requestLocationPermission();
      
      if (hasPermission) {
        // 权限获取成功，启动定位服务
        debugPrint('定位权限获取成功，启动定位服务');
        bool started = await _locationService.startLocation();
        
        if (started) {
          isLocationServiceStarted.value = true;
          debugPrint('定位服务启动成功，开始记录和上报位置');
          
          // 保存已请求权限的状态
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('location_permission_requested', true);
          
          // 显示成功提示
          CustomToast.show(
            Get.context!,
            '定位服务已启动，开始记录您的足迹',
          );
        } else {
          debugPrint('定位服务启动失败');
          CustomToast.show(
            Get.context!,
            '定位服务启动失败，请检查定位设置',
          );
        }
      } else {
        debugPrint('定位权限被拒绝');
        CustomToast.show(
          Get.context!,
          '需要定位权限来记录您的足迹',
        );
      }
    } catch (e) {
      debugPrint('请求定位权限并启动服务失败: $e');
      CustomToast.show(
        Get.context!,
        '定位服务初始化失败',
      );
    }
  }
  
  /// 加载用户信息和绑定状态
  void loadUserInfo() {
    final user = UserManager.currentUser;
    if (user != null) {
      // 用户头像
      if (user.headPortrait?.isNotEmpty == true) {
        userAvatar.value = user.headPortrait!;
      }
      
      // 绑定状态处理 (1未绑定，2绑定)
      final bindStatus = user.bindStatus.toString();
      isBound.value = bindStatus.toString() == "1";
      
      if (isBound.value) {
        // 已绑定状态，获取伴侣头像
        _loadPartnerAvatar(user);
      } else {
        // 未绑定状态，重置伴侣头像
        partnerAvatar.value = "assets/kissu_home_add_avair.webp";
      }
    }
  }
  
  /// 加载伴侣头像
  void _loadPartnerAvatar(user) {
    // 优先使用loverInfo中的头像
    if (user.loverInfo?.headPortrait?.isNotEmpty == true) {
      partnerAvatar.value = user.loverInfo!.headPortrait!;
    } 
    // 其次使用halfUserInfo中的头像
    else if (user.halfUserInfo?.headPortrait?.isNotEmpty == true) {
      partnerAvatar.value = user.halfUserInfo!.headPortrait!;
    }
    // 否则使用默认头像
    else {
      partnerAvatar.value = "assets/kissu_icon.webp";
    }
  }
  
  /// 点击未绑定提示组件
  void onUnbindTipTap() {
    // 弹出绑定输入弹窗
    BindingInputDialog.show(
      context: Get.context!,
      title: '',
      hintText: '输入对方匹配码',
      confirmText: '确认绑定',
      onConfirm: (String code) {
        // 延迟执行刷新，确保弹窗完全关闭后再执行
        Future.delayed(const Duration(milliseconds: 300), () {
          _refreshAfterBinding();
        });
      },
    );
  }
  
  /// 绑定成功后刷新数据
  Future<void> _refreshAfterBinding() async {
    try {
      // 刷新用户信息
      await UserManager.refreshUserInfo();
      
      // 重新加载当前页面数据
      loadUserInfo();
      
      // 首页绑定状态已刷新
    } catch (e) {
      // 刷新首页绑定状态失败
    }
  }

  void onButtonTap(int index) {
    selectedIndex.value = index;
    debugPrint("按钮 $index 被点击");

    switch (index) {
      case 0:
        // 定位
        Get.to(() => LocationPage(), binding: LocationBinding());
        break;
      case 1:
        // 足迹
        Get.to(() => TrackPage(), binding: TrackBinding());
        break;
      case 2:
        // 用机记录
        Get.to(() => const PhoneHistoryPage(), binding: PhoneHistoryBinding());
        break;
      case 3:
        // 我的
        Get.to(() => MinePage(), binding: MineBinding());
        break;
      default:
        // 其他功能待实现
        break;
    }
  }

  // 点击通知按钮
  void onNotificationTap() {
    // 示例逻辑：跳转到通知页面

    // 或者增加调试打印
    // 通知按钮被点击
  }

  // 点击钱包按钮
  void onMoneyTap() {
    // 示例逻辑：跳转到钱包/充值页面

    // 或者增加调试打印
    // 钱包按钮被点击
  }

  /// 获取顶部图标路径
  String getTopIconPath(int index) {
    switch (index) {
      case 0:
        return "assets/kissu_home_tab_location.webp";
      case 1:
        return "assets/kissu_home_tab_foot.webp";
      case 2:
        return "assets/kissu_home_tab_history.webp";
      case 3:
        return "assets/kissu_home_tab_mine.webp";
      default:
        return "assets/kissu_home_tab_location.webp";
    }
  }

  /// 获取底部图标路径
  String getBottomIconPath(int index) {
    switch (index) {
      case 0:
        return "assets/kissu_home_tab_locationT.webp";
      case 1:
        return "assets/kissu_home_tab_footT.webp";
      case 2:
        return "assets/kissu_home_tab_historyT.webp";
      case 3:
        return "assets/kissu_home_tab_mineT.webp";
      default:
        return "assets/kissu_home_tab_locationT.webp";
    }
  }
  
  /// 手动启动定位服务
  Future<void> startLocationService() async {
    await _requestLocationPermissionAndStartService();
  }
  
  /// 停止定位服务
  void stopLocationService() {
    try {
      _locationService.stopLocation();
      isLocationServiceStarted.value = false;
      debugPrint('定位服务已停止');
      CustomToast.show(
        Get.context!,
        '定位服务已停止',
      );
    } catch (e) {
      debugPrint('停止定位服务失败: $e');
    }
  }
  
  /// 获取定位服务状态
  Map<String, dynamic> getLocationServiceStatus() {
    return _locationService.serviceStatus;
  }
  
  /// 手动上报当前位置
  Future<bool> reportCurrentLocation() async {
    return await _locationService.reportCurrentLocation();
  }
  
  /// 强制上报所有待上报数据
  Future<bool> forceReportAllPending() async {
    return await _locationService.forceReportAllPending();
  }
}
