import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/public/notification_settings_api.dart';
import 'package:kissu_app/model/notification_settings_response.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/services/permission_service.dart';
import 'package:kissu_app/utils/permission_helper.dart';

/// 通知设置控制器
class NotificationSettingsController extends GetxController {
  final _api = NotificationSettingsApi();
  final _permissionService = PermissionService();
  final isLoading = false.obs;
  
  // 页面标题
  final RxString pageTitle = '推送设置'.obs;
  
  // 防抖Timer
  Timer? _debounceTimer;
  
  // 正在更新的field集合，避免重复请求
  final Set<String> _updatingFields = {};
  
  // 是否已检查过通知权限（避免重复弹窗）
  bool _hasCheckedNotificationPermission = false;
  
  // 位置轨迹通知项（初始为空，显示骨架屏）
  final locationTrackItems = <NotificationItem>[].obs;

  // Kissu通知项
  final kissuItems = <NotificationItem>[].obs;

  // 手机状态通知项
  final phoneStatusItems = <NotificationItem>[].obs;

  // 系统通知项
  final systemNotificationItems = <NotificationItem>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    // 获取传递的标题参数
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      final title = arguments['title'] as String?;
      if (title != null && title.isNotEmpty) {
        pageTitle.value = title;
      }
    }
    // 延迟加载，等待页面转场动画完成（约300ms）
    // loadSettings内部会设置isLoading状态
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!isClosed) {
        loadSettings();
        // 检查通知权限
        _checkNotificationPermission();
      }
    });
  }
  
  /// 检查通知权限
  Future<void> _checkNotificationPermission() async {
    // 避免重复检查
    if (_hasCheckedNotificationPermission) {
      return;
    }
    
    try {
      final hasPermission = await _permissionService.isNotificationPermissionGranted();
      if (!hasPermission) {
        _hasCheckedNotificationPermission = true;
        // 延迟一下，等待页面完全加载
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!isClosed) {
            _showNotificationPermissionDialog();
          }
        });
      }
    } catch (e) {
      print('检查通知权限失败: $e');
    }
  }
  
  /// 显示通知权限提示弹窗
  Future<void> _showNotificationPermissionDialog() async {
    final context = Get.context;
    if (context == null) {
      return;
    }
    
    final result = await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/dialog/kissu4_dialog_small_bg.webp'),
              fit: BoxFit.fill,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Text(
                  '目前未开启系统通知，可能会错过重要消息，建议前往设置开启哦',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // 左边：取消按钮（灰色）
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Get.back(result: false);
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFffffff),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF999999),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '取消',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xff999999),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 右边：开启按钮（粉色）
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Get.back(result: true);
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9AD9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '开启',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFFFFFFF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
    
    // 如果用户点击了"开启"，跳转到通知设置页面
    if (result == true) {
      try {
        await PermissionHelper.openNotificationSettings();
      } catch (e) {
        print('跳转通知设置失败: $e');
        OKToastUtil.showError('跳转通知设置失败');
      }
    }
  }

  /// 切换开关状态
  Future<void> toggleSwitch(NotificationItem item) async {
    // 防止重复请求
    if (_updatingFields.contains(item.id)) {
      return;
    }
    
    _updatingFields.add(item.id);
    
    // 乐观更新UI
    _updateItemInList(locationTrackItems, item);
    _updateItemInList(kissuItems, item);
    _updateItemInList(phoneStatusItems, item);
    _updateItemInList(systemNotificationItems, item);
    
    try {
      // 调用接口保存
      final newStatus = item.isEnabled ? 0 : 1;
      final result = await _api.updateNotificationSetting(
        field: item.id,
        status: newStatus,
      );
      
      if (!result.isSuccess) {
        // 失败回滚
        _updateItemInList(locationTrackItems, item);
        _updateItemInList(kissuItems, item);
        _updateItemInList(phoneStatusItems, item);
        _updateItemInList(systemNotificationItems, item);
        
        OKToastUtil.showError(result.msg ?? '更新失败');
      }
    } finally {
      _updatingFields.remove(item.id);
    }
  }

  /// 在列表中更新项目
  void _updateItemInList(RxList<NotificationItem> list, NotificationItem item) {
    final index = list.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      // 直接修改对象，减少对象创建
      final oldItem = list[index];
      list[index] = NotificationItem(
        id: oldItem.id,
        title: oldItem.title,
        description: oldItem.description,
        isEnabled: !oldItem.isEnabled,
      );
      // 只刷新当前列表
      list.refresh();
    }
  }

  /// 从服务器加载设置
  Future<void> loadSettings() async {
    // 防止重复加载
    if (isLoading.value) return;
    
    isLoading.value = true;
    
    try {
      final result = await _api.getNotificationSettings();
      
      if (result.isSuccess && result.data != null) {
        // 使用微任务延迟UI更新，避免阻塞
        await Future.microtask(() => _applyServerSettings(result.data!));
      }
    } catch (e) {
      print('加载通知设置失败: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 应用服务器设置到UI
  void _applyServerSettings(List<NotificationSettingsResponse> responses) {
    // 先清空所有列表
    locationTrackItems.clear();
    kissuItems.clear();
    phoneStatusItems.clear();
    systemNotificationItems.clear();
    
    // 批量构建数据，减少刷新次数
    for (var response in responses) {
      final classifyTitle = response.classifyTitle;
      final items = <NotificationItem>[];
      
      for (var statusItem in response.statusList) {
        items.add(NotificationItem(
          id: statusItem.field,
          title: statusItem.title,
          description: statusItem.subTitle,
          isEnabled: statusItem.isEnabled,
        ));
      }
      
      // 根据classify_title分配到对应列表
      if (classifyTitle == '位置轨迹') {
        locationTrackItems.addAll(items);
      } else if (classifyTitle == 'Kissu') {
        kissuItems.addAll(items);
      } else if (classifyTitle == '手机状态') {
        phoneStatusItems.addAll(items);
      } else if (classifyTitle == 'APP使用统计') {
        systemNotificationItems.addAll(items);
      }
    }
  }
  
  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }
}

/// 通知项数据模型
class NotificationItem {
  final String id;
  final String title;
  final String description;
  final bool isEnabled;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.isEnabled,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? description,
    bool? isEnabled,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
