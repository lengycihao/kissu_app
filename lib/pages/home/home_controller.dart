import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/mine/mine_binding.dart';
import 'package:kissu_app/pages/mine/mine_page.dart';
import 'package:kissu_app/pages/phone_history/phone_history_binding.dart';
import 'package:kissu_app/pages/phone_history/phone_history_page.dart';

class HomeController extends GetxController {
  // 后面可以加逻辑，比如当前选中的按钮索引
  var selectedIndex = 0.obs;

  void onButtonTap(int index) {
    selectedIndex.value = index;
    debugPrint("按钮 $index 被点击");
    
    switch (index) {
      case 2:
        // 用机记录
        Get.to(
          () => const PhoneHistoryPage(),
          binding: PhoneHistoryBinding(),
        );
        break;
      case 3:
        // 我的
        Get.to(
          () => MinePage(),
          binding: MineBinding(),
        );
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