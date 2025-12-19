import 'dart:async';
import 'package:get/get.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/model/notification_settings_response.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/network/utils/sp_util.dart';

/// IM通知设置控制器（自动报备消息设置）
class ImNotificationSettingsController extends GetxController {
  final isLoading = false.obs;
  
  // 页面标题
  final RxString pageTitle = '敏感信息'.obs;
  
  // 正在更新的field集合，避免重复请求
  final Set<String> _updatingFields = {};
  
  // 缓存相关常量
  static const String _cacheKey = 'im_notification_settings_cache';
  static const String _cacheTimeKey = 'im_notification_settings_cache_time';
  static const Duration _cacheValidDuration = Duration(minutes: 5); // 缓存有效期5分钟
  
  // 位置轨迹通知项
  final locationTrackItems = <ImNotificationItem>[].obs;

  // Kissu通知项
  final kissuItems = <ImNotificationItem>[].obs;

  // 手机状态通知项
  final phoneStatusItems = <ImNotificationItem>[].obs;

  // 系统通知项
  final systemNotificationItems = <ImNotificationItem>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    // 延迟加载，等待页面转场动画完成
    // 先加载缓存数据（快速显示），然后后台更新
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!isClosed) {
        _loadSettingsWithCache();
      }
    });
  }

  /// 切换开关状态
  Future<void> toggleSwitch(ImNotificationItem item) async {
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
      final result = await _updateImNotificationSetting(
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
      } else {
        // 更新成功，刷新缓存（重新加载最新数据）
        _loadSettings(silent: true);
      }
    } finally {
      _updatingFields.remove(item.id);
    }
  }

  /// 在列表中更新项目
  void _updateItemInList(RxList<ImNotificationItem> list, ImNotificationItem item) {
    final index = list.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      final oldItem = list[index];
      list[index] = ImNotificationItem(
        id: oldItem.id,
        title: oldItem.title,
        description: oldItem.description,
        isEnabled: !oldItem.isEnabled,
      );
      list.refresh();
    }
  }

  /// 带缓存的加载设置（先显示缓存，后台更新）
  Future<void> _loadSettingsWithCache() async {
    // 先尝试加载缓存数据
    await _loadFromCache();
    
    // 检查缓存是否过期
    final shouldRefresh = await _shouldRefreshCache();
    
    if (shouldRefresh) {
      // 缓存过期或不存在，显示 loading 并刷新最新数据
      await loadSettings();
    }
  }
  
  /// 从缓存加载设置
  Future<void> _loadFromCache() async {
    try {
      final cacheData = await SpUtil.getJsonMap(_cacheKey);
      if (cacheData != null && cacheData is List) {
        final responses = cacheData
            .map((json) => NotificationSettingsResponse.fromJson(json as Map<String, dynamic>))
            .toList();
        _applyServerSettings(responses);
        print('✅ 从缓存加载IM通知设置成功');
      }
    } catch (e) {
      print('⚠️ 从缓存加载IM通知设置失败: $e');
    }
  }
  
  /// 检查是否需要刷新缓存
  Future<bool> _shouldRefreshCache() async {
    try {
      final cacheTimeStr = await SpUtil.getString(_cacheTimeKey);
      if (cacheTimeStr.isEmpty) {
        return true; // 没有缓存时间，需要刷新
      }
      
      final cacheTime = DateTime.parse(cacheTimeStr);
      final now = DateTime.now();
      final diff = now.difference(cacheTime);
      
      return diff > _cacheValidDuration; // 超过5分钟，需要刷新
    } catch (e) {
      print('⚠️ 检查缓存时间失败: $e');
      return true; // 出错时刷新
    }
  }
  
  /// 保存设置到缓存
  Future<void> _saveToCache(List<NotificationSettingsResponse> responses) async {
    try {
      final jsonList = responses.map((r) => r.toJson()).toList();
      await SpUtil.putJsonMap(_cacheKey, jsonList);
      await SpUtil.putString(_cacheTimeKey, DateTime.now().toIso8601String());
      print('✅ IM通知设置已保存到缓存');
    } catch (e) {
      print('⚠️ 保存IM通知设置到缓存失败: $e');
    }
  }
  
  /// 从服务器加载设置
  /// [silent] 是否静默加载（不显示loading状态）
  Future<void> _loadSettings({bool silent = false}) async {
    if (isLoading.value && !silent) return;
    
    if (!silent) {
      isLoading.value = true;
    }
    
    try {
      final result = await _getImNotificationSettings();
      
      if (result.isSuccess && result.data != null) {
        // 保存到缓存
        await _saveToCache(result.data!);
        
        await Future.microtask(() => _applyServerSettings(result.data!));
      }
    } catch (e) {
      print('加载IM通知设置失败: $e');
    } finally {
      if (!silent) {
        isLoading.value = false;
      }
    }
  }
  
  /// 公开的加载方法（用于外部调用，显示loading）
  Future<void> loadSettings() async {
    await _loadSettings(silent: false);
  }
  
  /// 应用服务器设置到UI
  void _applyServerSettings(List<NotificationSettingsResponse> responses) {
    locationTrackItems.clear();
    kissuItems.clear();
    phoneStatusItems.clear();
    systemNotificationItems.clear();
    
    for (var response in responses) {
      final classifyTitle = response.classifyTitle;
      final items = <ImNotificationItem>[];
      
      for (var statusItem in response.statusList) {
        items.add(ImNotificationItem(
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
  
  /// 获取IM通知设置列表
  Future<HttpResultN<List<NotificationSettingsResponse>>> _getImNotificationSettings() async {
    try {
      final result = await HttpManagerN.instance.executeGet(
        '/v4/im/notification/set/info',
        paramEncrypt: false,
      );

      if (result.isSuccess) {
        final listData = result.getListJson();
        final items = listData
            .map((json) => NotificationSettingsResponse.fromJson(json as Map<String, dynamic>))
            .toList();
        return result.convert(data: items);
      } else {
        return result.convert();
      }
    } catch (e) {
      return HttpResultN<List<NotificationSettingsResponse>>(
        isSuccess: false,
        code: -1,
        msg: '获取IM通知设置失败: $e',
      );
    }
  }

  /// 更新IM通知设置
  Future<HttpResultN<void>> _updateImNotificationSetting({
    required String field,
    required int status,
  }) async {
    try {
      final params = <String, dynamic>{
        'field': field,
        'status': status,
      };
      
      final result = await HttpManagerN.instance.executePost(
        '/v4/set/im/notification',
        jsonParam: params,
        paramEncrypt: false,
      );

      return result.convert();
    } catch (e) {
      return HttpResultN<void>(
        isSuccess: false,
        code: -1,
        msg: '更新IM通知设置失败: $e',
      );
    }
  }
}

/// IM通知项数据模型
class ImNotificationItem {
  final String id;
  final String title;
  final String description;
  final bool isEnabled;

  ImNotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.isEnabled,
  });
}

