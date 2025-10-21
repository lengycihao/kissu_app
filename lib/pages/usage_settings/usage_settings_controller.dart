import 'package:get/get.dart';
import 'package:kissu_app/model/notification_item.dart';
import 'package:kissu_app/network/public/notification_settings_api.dart';
import 'package:kissu_app/utils/oktoast_util.dart';

class UsageSettingsController extends GetxController {
  final _api = NotificationSettingsApi();
  
  // 通知列表（原始数据）
  var notificationList = <NotificationItem>[].obs;
  
  // 临时通知列表（用户修改的数据）
  var tempNotificationList = <NotificationItem>[].obs;
  
  // 加载状态
  var isLoading = false.obs;
  
  // 保存状态
  var isSaving = false.obs;
  
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
        // 初始化临时列表
        tempNotificationList.value = result.data!.map((item) => item.copyWith()).toList();
      } else {
        errorMessage.value = result.msg ?? '加载失败';
      }
    } catch (e) {
      errorMessage.value = '加载失败: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// 切换通知状态（只修改临时状态，不保存）
  void toggleNotification(int index) {
    if (index < 0 || index >= tempNotificationList.length) return;
    
    final item = tempNotificationList[index];
    final newStatus = item.isChecked == 1 ? 0 : 1;
    
    // 更新临时状态
    tempNotificationList[index] = item.copyWith(isChecked: newStatus);
  }

  /// 检查是否有未保存的更改
  bool get hasUnsavedChanges {
    if (notificationList.length != tempNotificationList.length) return true;
    
    for (int i = 0; i < notificationList.length; i++) {
      if (notificationList[i].isChecked != tempNotificationList[i].isChecked) {
        return true;
      }
    }
    return false;
  }

  /// 保存所有设置
  Future<void> saveSettings() async {
    if (!hasUnsavedChanges) return;
    
    try {
      isSaving.value = true;
      errorMessage.value = '';
      
      // 构建批量更新的数据
      final batchSettings = <String, int>{};
      
      for (int i = 0; i < notificationList.length; i++) {
        if (notificationList[i].isChecked != tempNotificationList[i].isChecked) {
          final item = tempNotificationList[i];
          batchSettings[item.field] = item.isChecked;
        }
      }
      
      if (batchSettings.isNotEmpty) {
        print("📤 准备批量保存设置: $batchSettings");
        
        // 批量保存
        final result = await _api.batchUpdateNotificationSettings(batchSettings);
        
        if (result.isSuccess) {
          // 保存成功，更新原始数据
          notificationList.value = tempNotificationList.map((item) => item.copyWith()).toList();
          OKToastUtil.show('设置已保存');
          print("✅ 批量保存成功");
          
          // 延迟返回上一页，让用户看到成功提示
          Future.delayed(const Duration(milliseconds: 800), () {
            Get.back();
          });
        } else {
          errorMessage.value = result.msg ?? '保存失败';
          print("❌ 批量保存失败: ${result.msg}");
        }
      }
      
    } catch (e) {
      errorMessage.value = '保存失败: $e';
      print("❌ 批量保存异常: $e");
    } finally {
      isSaving.value = false;
    }
  }

  /// 重置为原始设置
  void resetSettings() {
    tempNotificationList.value = notificationList.map((item) => item.copyWith()).toList();
  }

  /// 显示返回确认弹窗的回调（由页面设置）
  Function()? onShowBackDialog;
  
  
  /// 返回时的确认处理
  void handleBack() {
    if (hasUnsavedChanges) {
      _showBackConfirmDialog();
    } else {
      Get.back();
    }
  }
  
  /// 显示返回确认弹窗
  void _showBackConfirmDialog() {
    onShowBackDialog?.call();
  }
  
  /// 确认返回（放弃更改）
  void confirmBack() {
    // 重置为原始设置
    resetSettings();
    Get.back();
  }
  
  /// 取消返回（继续编辑）
  void cancelBack() {
    // 不做任何操作，继续停留在当前页面
  }
  
  /// 处理返回操作（保持原有方法兼容性）
  Future<bool> handleBackPressed() async {
    handleBack();
    return false; // 阻止默认返回，由handleBack处理
  }
}
