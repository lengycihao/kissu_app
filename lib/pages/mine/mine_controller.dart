 

import 'package:get/get.dart';
import 'package:kissu_app/pages/mine/sub_pages/question_page.dart';
import 'package:kissu_app/pages/mine/sub_pages/system_permission_page.dart';


class MineController extends GetxController {
  // 用户信息
  var nickname = "小可爱".obs;
  var matchCode = "1000000".obs;
  var bindDate = "2025.06.12".obs;
  var days = "100天".obs;

  // 设置项
  final List<SettingItem> settingItems = [
    SettingItem(
      icon: "assets/kissu_mine_item_syst.webp",
      title: "首页视图",
      onTap: () => Get.snackbar("点击", "首页视图"),
    ),
    SettingItem(
      icon: "assets/kissu_mine_item_xtqx.webp",
      title: "系统权限",
      onTap: () => Get.to(SystemPermissionPage())
    ),
    SettingItem(
      icon: "assets/kissu_mine_item_gywm.webp",
      title: "关于我们",
      onTap: () => Get.snackbar("点击", "关于我们"),
    ),
    SettingItem(
      icon: "assets/kissu_mine_item_cjwt.webp",
      title: "常见问题",
      onTap: () => Get.to(QuestionPage()),
    ),
    SettingItem(
      icon: "assets/kissu_mine_item_lxwm.webp",
      title: "联系我们",
      onTap: () => Get.snackbar("点击", "联系我们"),
    ),
    SettingItem(
      icon: "assets/kissu_mine_item_yjfk.webp",
      title: "意见反馈",
      onTap: () => Get.snackbar("点击", "意见反馈"),
    ),
    SettingItem(
      icon: "assets/kissu_mine_item_ysaq.webp",
      title: "账号及隐私安全",
      onTap: () => Get.snackbar("点击", "账号及隐私安全"),
    ),
  ];

  // 顶部返回
  void onBackTap() {
    Get.back();
  }

  // 点击标签
  void onLabelTap() {
    Get.snackbar("提示", "点击了标签");
  }

  // 会员续费
  void onRenewTap() {
    Get.snackbar("提示", "去续费");
  }
}


class SettingItem {
  final String icon;
  final String title;
  final void Function()? onTap;

  SettingItem({
    required this.icon,
    required this.title,
    this.onTap,
  });
}