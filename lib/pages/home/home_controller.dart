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

class HomeController extends GetxController {
  // 后面可以加逻辑，比如当前选中的按钮索引
  var selectedIndex = 0.obs;
  
  // 绑定状态
  var isBound = false.obs;
  
  // 头像信息
  var userAvatar = "assets/kissu_icon.webp".obs;
  var partnerAvatar = "assets/kissu_home_add_avair.webp".obs;

  @override
  void onInit() {
    super.onInit();
    loadUserInfo();
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
      final bindStatus = user.bindStatus ?? "1";
      isBound.value = bindStatus == "2";
      
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
      
      print('首页绑定状态已刷新');
    } catch (e) {
      print('刷新首页绑定状态失败: $e');
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
    print("通知按钮被点击");
  }

  // 点击钱包按钮
  void onMoneyTap() {
    // 示例逻辑：跳转到钱包/充值页面

    // 或者增加调试打印
    print("钱包按钮被点击");
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
}
