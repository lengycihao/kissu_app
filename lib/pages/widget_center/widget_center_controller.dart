import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/public/location_api.dart';
import 'package:kissu_app/model/location_model/location_model.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/pages/mine/love_info/love_info_page.dart';

class WidgetCenterController extends GetxController {
  static const _channel = MethodChannel('com.yuluo.kissu/widget');

  final isLoading = false.obs;

  // 自己设备信息
  final selfAvatar = ''.obs;
  final selfLocation = ''.obs;
  final selfBattery = ''.obs;

  // 另一半设备信息
  final partnerAvatar = ''.obs;
  final partnerLocation = ''.obs;
  final partnerBattery = ''.obs;
  final distance = ''.obs;

  // 在一起天数 & 绑定日期
  final togetherDays = ''.obs;
  final bindDate = ''.obs;

  // 轮播当前页
  final currentPage = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _setupNavigationHandler();
    _loadUserInfo();
    _loadLocationData();
  }

  /// 设置原生层发来的导航请求监听
  void _setupNavigationHandler() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'navigateToPage') {
        final page = call.arguments as String?;
        if (page != null) {
          _navigateToPage(page);
        }
      }
    });
  }

  /// 根据页面名称跳转到对应页面
  void _navigateToPage(String page) {
    logDebug('小组件点击跳转: $page');
    // 延迟执行，确保 app 已完全启动
    Future.delayed(const Duration(milliseconds: 500), () {
      switch (page) {
        case 'location':
          Get.toNamed(KissuRoutePath.location);
          break;
        case 'love_info':
          Get.to(LoveInfoPage(), transition: Transition.rightToLeft);
          break;
        default:
          logDebug('未知的小组件跳转目标: $page');
      }
    });
  }

  /// 静态方法：初始化小组件导航监听（可在 app 启动时调用）
  static void setupWidgetNavigationHandler() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'navigateToPage') {
        final page = call.arguments as String?;
        if (page != null) {
          logDebug('小组件点击跳转(static): $page');
          Future.delayed(const Duration(milliseconds: 500), () {
            switch (page) {
              case 'location':
                Get.toNamed(KissuRoutePath.location);
                break;
              case 'love_info':
                Get.to(LoveInfoPage(), transition: Transition.rightToLeft);
                break;
            }
          });
        }
      }
    });
  }

  /// 从用户信息获取在一起天数、绑定日期、自己头像
  void _loadUserInfo() {
    final user = UserManager.currentUser;
    if (user?.loverInfo?.loveDays != null) {
      togetherDays.value = '${user!.loverInfo!.loveDays}';
    } else {
      togetherDays.value = '0';
    }
    if (user?.loverInfo?.bindDate != null && user!.loverInfo!.bindDate!.isNotEmpty) {
      bindDate.value = user.loverInfo!.bindDate!;
    }
    // 自己头像
    if (user?.headPortrait != null && user!.headPortrait!.isNotEmpty) {
      selfAvatar.value = user.headPortrait!;
    }
  }

  /// 从定位接口获取双方设备信息
  Future<void> _loadLocationData() async {
    isLoading.value = true;
    try {
      final result = await LocationApi().getLocation();
      if (result.isSuccess && result.data != null) {
        // 自己的设备信息
        final userDevice = result.data!.userLocationMobileDevice;
        if (userDevice != null) {
          _updateSelfInfo(userDevice);
        }
        // 另一半设备信息
        final halfDevice = result.data!.halfLocationMobileDevice;
        if (halfDevice != null) {
          _updatePartnerInfo(halfDevice);
        }
        // 距离信息
        if (userDevice?.distance != null && userDevice!.distance!.isNotEmpty) {
          distance.value = userDevice.distance!;
        } else if (halfDevice?.distance != null && halfDevice!.distance!.isNotEmpty) {
          distance.value = halfDevice.distance!;
        }
      }
      // 同步数据到原生小组件
      _syncWidgetData();
    } catch (e) {
      logError('加载定位数据失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新所有小组件数据（可从外部调用，如 App 回到前台时）
  Future<void> refreshData() async {
    _loadUserInfo();
    await _loadLocationData();
  }

  /// 同步数据到原生桌面小组件
  Future<void> _syncWidgetData() async {
    try {
      final isVip = UserManager.isVip;
      await _channel.invokeMethod('updateWidgetData', {
        'distance': distance.value,
        'together_days': togetherDays.value,
        'bind_date': bindDate.value,
        'is_vip': isVip,
        // 自己
        'self_avatar': selfAvatar.value,
        'self_battery': selfBattery.value,
        'self_location': selfLocation.value,
        // 另一半
        'partner_avatar': partnerAvatar.value,
        'partner_battery': partnerBattery.value,
        'partner_location': partnerLocation.value,
      });
    } catch (e) {
      logError('同步小组件数据失败: $e');
    }
  }

  /// 静态方法：在 App 启动/回到前台时快速同步小组件数据
  /// 不依赖 Controller 实例，可直接从 main.dart 或生命周期回调中调用
  static Future<void> syncWidgetDataOnResume() async {
    if (!Platform.isAndroid) return;
    try {
      final user = UserManager.currentUser;
      if (user == null) return;

      final days = user.loverInfo?.loveDays?.toString() ?? '0';
      final bindDateStr = user.loverInfo?.bindDate ?? '';
      final selfAvatarStr = user.headPortrait ?? '';
      final isVip = UserManager.isVip;

      // 尝试获取定位数据
      String distanceStr = '';
      String selfLocationStr = '';
      String selfBatteryStr = '--%';
      String partnerAvatarStr = '';
      String partnerLocationStr = '';
      String partnerBatteryStr = '--%';

      try {
        final result = await LocationApi().getLocation();
        if (result.isSuccess && result.data != null) {
          final userDevice = result.data!.userLocationMobileDevice;
          final halfDevice = result.data!.halfLocationMobileDevice;

          if (userDevice != null) {
            selfLocationStr = _extractCityStatic(userDevice.location);
            selfBatteryStr = (userDevice.power?.isEmpty ?? true) ? '--%' : '${userDevice.power?.replaceAll('%', '')}';
          }
          if (halfDevice != null) {
            partnerAvatarStr = halfDevice.headPortrait ?? '';
            partnerLocationStr = _extractCityStatic(halfDevice.location);
            partnerBatteryStr = (halfDevice.power?.isEmpty ?? true) ? '--%' : '${halfDevice.power?.replaceAll('%', '')}';
          }
          if (userDevice?.distance != null && userDevice!.distance!.isNotEmpty) {
            distanceStr = userDevice.distance!;
          } else if (halfDevice?.distance != null && halfDevice!.distance!.isNotEmpty) {
            distanceStr = halfDevice.distance!;
          }
        }
      } catch (e) {
        logError('小组件定位数据获取失败: $e');
      }

      await _channel.invokeMethod('updateWidgetData', {
        'distance': distanceStr,
        'together_days': days,
        'bind_date': bindDateStr,
        'is_vip': isVip,
        'self_avatar': selfAvatarStr,
        'self_battery': selfBatteryStr,
        'self_location': selfLocationStr,
        'partner_avatar': partnerAvatarStr,
        'partner_battery': partnerBatteryStr,
        'partner_location': partnerLocationStr,
      });
    } catch (e) {
      logError('App恢复时同步小组件失败: $e');
    }
  }

  void _updateSelfInfo(UserLocationMobileDevice device) {
    selfLocation.value = _extractCity(device.location);
    selfBattery.value = (device.power?.isEmpty ?? true) ? '--%' : '${device.power?.replaceAll('%', '')}';
  }

  void _updatePartnerInfo(UserLocationMobileDevice device) {
    partnerAvatar.value = device.headPortrait ?? '';
    partnerLocation.value = _extractCity(device.location);
    partnerBattery.value = (device.power?.isEmpty ?? true) ? '--%' : '${device.power?.replaceAll('%', '')}';
  }

  /// 从完整地址中提取市级名称
  /// 例如 "广东省深圳市南山区xxx" -> "深圳市"
  String _extractCity(String? location) {
    return _extractCityStatic(location);
  }

  static String _extractCityStatic(String? location) {
    if (location == null || location.isEmpty) return '定位中';
    // 先尝试匹配 "省" 或 "自治区" 后面的 "xx市"（如 "浙江省杭州市" -> "杭州市"）
    final afterProvinceMatch = RegExp(r'(?:省|自治区)([\u4e00-\u9fa5]+?市)').firstMatch(location);
    if (afterProvinceMatch != null) return afterProvinceMatch.group(1)!;
    // 再尝试匹配 "xx市"（无省前缀的情况，如 "杭州市西湖区"）
    final cityMatch = RegExp(r'([\u4e00-\u9fa5]{2,4}?市)').firstMatch(location);
    if (cityMatch != null) return cityMatch.group(1)!;
    // 尝试匹配 "xx州" 格式（如杭州、郑州，无"市"后缀）
    final zhouMatch = RegExp(r'(?:省|自治区)?([\u4e00-\u9fa5]{2,3}州)').firstMatch(location);
    if (zhouMatch != null) return zhouMatch.group(1)!;
    // 无法提取，返回原始位置（截取前6个字符）
    return location.length > 6 ? '${location.substring(0, 6)}...' : location;
  }

  /// 请求添加桌面小组件
  /// [widgetType] 可选值: 'large'(4x2详情), 'info'(2x2信息), 'days'(2x2天数)
  Future<void> requestAddWidget({String widgetType = 'large'}) async {
    try {
      final result = await _channel.invokeMethod('requestPinWidget', {
        'widgetType': widgetType,
      });
      if (result == true) {
        OKToastUtil.show('请在桌面确认添加小组件');
      } else {
        OKToastUtil.show('当前桌面不支持直接添加，请长按桌面手动添加小组件');
      }
    } on PlatformException catch (e) {
      logError('添加小组件失败: $e');
      OKToastUtil.show('添加小组件失败，请长按桌面手动添加');
    } on MissingPluginException {
      OKToastUtil.show('当前设备不支持此功能，请长按桌面手动添加小组件');
    }
  }

  void onPageChanged(int page) {
    currentPage.value = page;
  }
}
