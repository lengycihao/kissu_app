import 'package:get/get.dart';
import 'package:kissu_app/model/notification_item.dart';
import 'package:kissu_app/network/public/notification_settings_api.dart';

class UsageSettingsController extends GetxController {
  final _api = NotificationSettingsApi();
  
  // 通知列表
  var notificationList = <NotificationItem>[].obs;
  
  // 加载状态
  var isLoading = false.obs;
  
  // 错误信息
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotificationSettings();
  }

  /// 加载通知设置
  Future<void> loadNotificationSettings() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final result = await _api.getNotificationSettings();
      
      if (result.isSuccess && result.data != null) {
        notificationList.value = result.data!;
      } else {
        errorMessage.value = result.msg ?? '加载失败';
      }
    } catch (e) {
      errorMessage.value = '加载失败: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// 切换通知状态
  Future<void> toggleNotification(int index) async {
    if (index < 0 || index >= notificationList.length) return;
    
    final item = notificationList[index];
    final newStatus = item.isChecked == 1 ? 0 : 1;
    
    // 乐观更新UI
    notificationList[index] = item.copyWith(isChecked: newStatus);
    
    try {
      final result = await _api.updateNotificationSetting(
        field: item.field,
        isChecked: newStatus,
      );
      
      if (!result.isSuccess) {
        // 更新失败，回滚状态
        notificationList[index] = item;
        errorMessage.value = result.msg ?? '更新失败';
      }
    } catch (e) {
      // 发生异常，回滚状态
      notificationList[index] = item;
      errorMessage.value = '更新失败: $e';
    }
  }
}
