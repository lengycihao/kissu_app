import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/services/analytics/analytics_manager.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/services/analytics/analytics_params.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';

/// App图标选择控制器
class AppIconSelectorController extends GetxController {
  static const platform = MethodChannel('app_icon_channel');
  
  // 当前选中的图标
  var currentIcon = 'default'.obs;
  var isLoading = false.obs;

  // 埋点相关
  int? _pageEnterTime;
  int _exitType = ExitTypeValue.back;
  bool _hasTrackedExit = false;
  
  // 页面离开回调
  VoidCallback? onNavigateToNextPage;

  // 可用的图标列表
  final List<AppIconItem> iconItems = [
    AppIconItem(
      id: 'default',
      name: '默认',
      logoName: '最美时光',
      previewPath: 'assets/setting/kissu_icon.webp',
      description: '最美时光',
    ),
    AppIconItem(
      id: 'logo_2',
      name: '幸福加马',
      logoName: '幸福加马',
      previewPath: 'assets/setting/kissu_logo_2.png',
      description: '幸福加马',
    ),
    AppIconItem(
      id: 'logo_3',
      name: 'YEAH哥',
      logoName: 'YEAH哥',
      previewPath: 'assets/setting/kissu_logo_3.png',
      description: 'YEAH哥',
    ),
    AppIconItem(
      id: 'logo_4',
      name: '好运来',
      logoName: '好运来',
      previewPath: 'assets/setting/kissu_logo_4.png',
      description: '好运来',
    ),
    AppIconItem(
      id: 'logo_5',
      name: '怦然心动',
      logoName: '怦然心动',
      previewPath: 'assets/setting/kissu_logo_5.png',
      description: '怦然心动',
    ),
    AppIconItem(
      id: 'logo_6',
      name: '缠绵',
      logoName: '缠绵',
      previewPath: 'assets/setting/kissu_logo_6.png',
      description: '缠绵',
    ),
    AppIconItem(
      id: 'logo_7',
      name: '情书',
      logoName: '情书',
      previewPath: 'assets/setting/kissu_logo_7.png',
      description: '情书',
    ),
    AppIconItem(
      id: 'logo_8',
      name: '心跳频率',
      logoName: '心跳频率',
      previewPath: 'assets/setting/kissu_logo_8.png',
      description: '心跳频率',
    ),
    AppIconItem(
      id: 'logo_9',
      name: '初恋',
      logoName: '初恋',
      previewPath: 'assets/setting/kissu_logo_9.png',
      description: '初恋',
    ),
    AppIconItem(
      id: 'logo_10',
      name: 'Wink仔',
      logoName: 'Wink仔',
      previewPath: 'assets/setting/kissu_logo_10.png',
      description: 'Wink仔',
    ),
    AppIconItem(
      id: 'logo_11',
      name: 'Kissu酱',
      logoName: 'Kissu酱',
      previewPath: 'assets/setting/kissu_logo_11.png',
      description: 'Kissu酱',
    ),
    AppIconItem(
      id: 'logo_12',
      name: '心动讯号',
      logoName: '心动讯号',
      previewPath: 'assets/setting/kissu_logo_12.png',
      description: '心动讯号',
    ),
    AppIconItem(
      id: 'logo_13',
      name: '晕晕菇',
      logoName: '晕晕菇',
      previewPath: 'assets/setting/kissu_logo_13.png',
      description: '晕晕菇',
    ),
    AppIconItem(
      id: 'logo_14',
      name: '闪闪菇',
      logoName: '闪闪菇',
      previewPath: 'assets/setting/kissu_logo_14.png',
      description: '闪闪菇',
    ),
    AppIconItem(
      id: 'logo_15',
      name: '想见你',
      logoName: '想见你',
      previewPath: 'assets/setting/kissu_logo_15.png',
      description: '想见你',
    ),
    AppIconItem(
      id: 'logo_16',
      name: '一见钟情',
      logoName: '一见钟情',
      previewPath: 'assets/setting/kissu_logo_16.png',
      description: '一见钟情',
    ),
    AppIconItem(
      id: 'logo_17',
      name: '初心悸动',
      logoName: '初心悸动',
      previewPath: 'assets/setting/kissu_logo_17.png',
      description: '初心悸动',
    ),
    AppIconItem(
      id: 'logo_18',
      name: '浪漫挚爱',
      logoName: '浪漫挚爱',
      previewPath: 'assets/setting/kissu_logo_18.png',
      description: '浪漫挚爱',
    ),
   
  ];

  @override
  void onInit() {
    super.onInit();
    
    // 埋点：记录页面进入时间（十位时间戳）
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // 注册页面离开回调
    onNavigateToNextPage = () {
      _trackPageExit(ExitTypeValue.nextPage);
    };
    
    getCurrentIcon();
  }

  /// 获取当前使用的图标
  Future<void> getCurrentIcon() async {
    try {
      final String result = await platform.invokeMethod('getCurrentIcon');
      currentIcon.value = result;
    } catch (e) {
      logError('获取当前图标失败: $e');
    }
  }

  /// 切换图标
  Future<void> changeIcon(String iconId, String logoName) async {
    if (currentIcon.value == iconId) {
      OKToastUtil.show('当前已是该图标');
      return;
    }

    // 埋点：在调用原生方法前立即上报（因为切换logo后app会被杀掉）
    await AnalyticsHelper.trackChangeLogoItemBtn(logoName: logoName);
    
    isLoading.value = true;

    try {
      final bool success = await platform.invokeMethod('changeIcon', {'iconId': iconId});
      
      if (success) {
        currentIcon.value = iconId;
        OKToastUtil.show('切换成功，稍等几秒后重启生效');
      } else {
        OKToastUtil.show('图标切换失败，请重试');
      }
    } catch (e) {
      logError('切换图标失败: $e');
      OKToastUtil.show('切换失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 上报页面离开埋点
  void _trackPageExit(int exitType) {
    if (_hasTrackedExit || _pageEnterTime == null) return;
    _hasTrackedExit = true;
    
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final duration = currentTime - _pageEnterTime!;
    
    AnalyticsManager.instance.trackPageView(
      pageId: ChangeLogoEvents.pageId,
      eventId: ChangeLogoEvents.page,
      enterTime: _pageEnterTime!,
      duration: duration,
      exitType: exitType,
    );
    
    // 如果是进入下一页，立即重置状态
    if (exitType == ExitTypeValue.nextPage) {
      _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _hasTrackedExit = false;
      _exitType = ExitTypeValue.back;
    }
  }
  
  /// 应用切换到后台
  void onAppPaused() {
    _exitType = ExitTypeValue.toBackground;
    _trackPageExit(ExitTypeValue.toBackground);
  }
  
  /// 应用从后台返回
  void onAppResumed() {
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _hasTrackedExit = false;
    _exitType = ExitTypeValue.back;
  }
  
  @override
  void onClose() {
    // 埋点：记录页面离开事件（返回）
    _trackPageExit(_exitType);
    
    super.onClose();
  }
}

/// 图标项数据模型
class AppIconItem {
  final String id;
  final String name;
  final String logoName; // 埋点用的logo名称（最美时光-初恋）
  final String previewPath;
  final String description;

  AppIconItem({
    required this.id,
    required this.name,
    required this.logoName,
    required this.previewPath,
    required this.description,
  });
}
