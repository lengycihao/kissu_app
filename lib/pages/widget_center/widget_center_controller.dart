import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/public/component_info_api.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/pages/mine/love_info/love_info_page.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/utils/source_page_utils.dart';

class WidgetCenterController extends GetxController {
  static const _channel = MethodChannel('com.yuluo.kissu/widget');

  final isLoading = false.obs;

  // 小组件数据
  final selfAvatar = ''.obs;
  final partnerAvatar = ''.obs;
  final selfBattery = ''.obs;
  final partnerBattery = ''.obs;
  final distance = ''.obs;
  final togetherDays = ''.obs;
  final loveTime = ''.obs;
  final isVip = 0.obs;
  final isBind = 0.obs;
  final isSetLoverTime = 0.obs;

  // 轮播当前页
  final currentPage = 0.obs;

  Timer? _periodicTimer;

  @override
  void onInit() {
    super.onInit();
    _setupNavigationHandler();
    _loadData();
    _startPeriodicRefresh();
  }

  @override
  void onClose() {
    _periodicTimer?.cancel();
    super.onClose();
  }

  void _startPeriodicRefresh() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _loadData();
    });
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
      if (!UserManager.isLoggedIn) {
        Get.toNamed(KissuRoutePath.login);
        return;
      }
      switch (page) {
        case 'location':
          Get.toNamed(KissuRoutePath.location);
          break;
        case 'love_info':
          Get.to(LoveInfoPage(), transition: Transition.rightToLeft);
          break;
        case 'show_bind_dialog':
          final ctx = Get.context;
          if (ctx != null) {
            CustomBottomDialog.show(
              context: ctx,
              caller: SourcePageUtilsCaller.home,
            );
          }
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
            if (!UserManager.isLoggedIn) {
              Get.toNamed(KissuRoutePath.login);
              return;
            }
            switch (page) {
              case 'location':
                Get.toNamed(KissuRoutePath.location);
                break;
              case 'love_info':
                Get.to(LoveInfoPage(), transition: Transition.rightToLeft);
                break;
              case 'show_bind_dialog':
                final ctx = Get.context;
                if (ctx != null) {
                  CustomBottomDialog.show(
                    context: ctx,
                    caller: SourcePageUtilsCaller.home,
                  );
                }
                break;
            }
          });
        }
      }
    });
  }

  /// 从 /get/component/info 接口加载小组件数据
  Future<void> _loadData() async {
    isLoading.value = true;
    try {
      final result = await ComponentInfoApi().getComponentInfo();
      if (result.isSuccess && result.data != null) {
        final d = result.data!;
        isVip.value = d.isVip;
        isBind.value = d.isBind;
        selfAvatar.value = d.userHeadPortrait;
        partnerAvatar.value = d.halfHeadPortrait;
        distance.value = d.distance;
        selfBattery.value = d.userPower;
        partnerBattery.value = d.halfPower;
        isSetLoverTime.value = d.isSetLoverTime;
        togetherDays.value = d.loveDays.toString();
        loveTime.value = d.loveTime;
        await _syncWidgetData();
      }
    } catch (e) {
      logError('加载小组件数据失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新所有小组件数据（可从外部调用）
  Future<void> refreshData() async {
    await _loadData();
  }

  /// 同步数据到原生桌面小组件
  Future<void> _syncWidgetData() async {
    try {
      await _channel.invokeMethod('updateWidgetData', {
        'is_vip': isVip.value,
        'is_bind': isBind.value,
        'user_head_portrait': selfAvatar.value,
        'half_head_portrait': partnerAvatar.value,
        'distance': distance.value,
        'user_power': selfBattery.value,
        'half_power': partnerBattery.value,
        'is_set_lover_time': isSetLoverTime.value,
        'love_days': togetherDays.value,
        'love_time': loveTime.value,
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
      final result = await ComponentInfoApi().getComponentInfo();
      if (!result.isSuccess || result.data == null) return;
      final d = result.data!;
      await _channel.invokeMethod('updateWidgetData', {
        'is_vip': d.isVip,
        'is_bind': d.isBind,
        'user_head_portrait': d.userHeadPortrait,
        'half_head_portrait': d.halfHeadPortrait,
        'distance': d.distance,
        'user_power': d.userPower,
        'half_power': d.halfPower,
        'is_set_lover_time': d.isSetLoverTime,
        'love_days': d.loveDays.toString(),
        'love_time': d.loveTime,
      });
    } catch (e) {
      logError('同步小组件数据失败: $e');
    }
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
