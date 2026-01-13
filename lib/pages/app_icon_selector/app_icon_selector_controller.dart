import 'package:flutter/services.dart';
import 'package:get/get.dart';
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

  // 可用的图标列表
  final List<AppIconItem> iconItems = [
    AppIconItem(
      id: 'default',
      name: '默认',
      logoName: '最美时光',
      previewPath: 'assets/setting/kissu_icon.webp',
      description: '默认图标',
    ),
    AppIconItem(
      id: 'logo_two',
      name: '暖心',
      logoName: '心跳频率',
      previewPath: 'assets/setting/kissu_logo_2.png',
      description: '暖心图标',
    ),
    AppIconItem(
      id: 'logo_three',
      name: '手绘',
      logoName: '情书',
      previewPath: 'assets/setting/kissu_logo_3.png',
      description: '手绘图标',
    ),
    AppIconItem(
      id: 'logo_four',
      name: '简约',
      logoName: '缠绵',
      previewPath: 'assets/setting/kissu_logo_4.png',
      description: '简约图标',
    ),
    AppIconItem(
      id: 'logo_five',
      name: '霓虹',
      logoName: '怦然心动',
      previewPath: 'assets/setting/kissu_logo_5.png',
      description: '霓虹图标',
    ),
    AppIconItem(
      id: 'logo_six',
      name: '爱意灼灼',
      logoName: '初恋',
      previewPath: 'assets/setting/kissu_logo_6.png',
      description: '爱意灼灼图标',
    ),
    AppIconItem(
      id: 'logo_seven',
      name: '叶柔甜伴',
      logoName: '想见你',
      previewPath: 'assets/setting/kissu_logo_7.png',
      description: '叶柔甜伴图标',
    ),
    AppIconItem(
      id: 'logo_eight',
      name: '甜邻少年',
      logoName: '一见钟情',
      previewPath: 'assets/setting/kissu_logo_8.png',
      description: '甜邻少年图标',
    ),
    AppIconItem(
      id: 'logo_nine',
      name: '糖绒甜崽',
      logoName: '初心悸动',
      previewPath: 'assets/setting/kissu_logo_9.png',
      description: '糖绒甜崽图标',
    ),
    AppIconItem(
      id: 'logo_ten',
      name: '甜煦少年',
      logoName: '浪漫挚爱',
      previewPath: 'assets/setting/kissu_logo_10.png',
      description: '甜煦少年图标',
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    
    // 埋点：记录页面进入时间（十位时间戳）
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    getCurrentIcon();
  }

  /// 获取当前使用的图标
  Future<void> getCurrentIcon() async {
    try {
      final String result = await platform.invokeMethod('getCurrentIcon');
      currentIcon.value = result;
    } catch (e) {
      print('获取当前图标失败: $e');
    }
  }

  /// 切换图标
  Future<void> changeIcon(String iconId, String logoName) async {
    if (currentIcon.value == iconId) {
      OKToastUtil.show('当前已是该图标');
      return;
    }

    isLoading.value = true;

    try {
      final bool success = await platform.invokeMethod('changeIcon', {'iconId': iconId});
      
      if (success) {
        currentIcon.value = iconId;
        OKToastUtil.show('切换成功，稍等几秒后重启生效');
        
        // 埋点：记录图标点击
        AnalyticsHelper.trackChangeLogoItemBtn(logoName: logoName);
      } else {
        OKToastUtil.show('图标切换失败，请重试');
      }
    } catch (e) {
      print('切换图标失败: $e');
      OKToastUtil.show('切换失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    // 埋点：记录页面离开事件
    if (_pageEnterTime != null) {
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final duration = currentTime - _pageEnterTime!;
      
      AnalyticsManager.instance.trackPageView(
        pageId: ChangeLogoEvents.pageId,
        eventId: ChangeLogoEvents.page,
        enterTime: _pageEnterTime!,
        duration: duration,
        exitType: _exitType,
      );
    }
    
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
