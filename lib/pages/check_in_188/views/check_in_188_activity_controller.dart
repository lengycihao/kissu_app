import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/check_in_188/widgets/check_in_188_share_bottom_sheet.dart';

/// 参与活动获得补签卡页面控制器
class CheckIn188ActivityController extends GetxController {
  /// 导航栏透明度
  final RxDouble navBarOpacity = 0.0.obs;
  
  /// 活动列表
  final RxList<ActivityItem> activities = <ActivityItem>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    _initMockData();
  }
  
  /// 初始化模拟数据
  void _initMockData() {
    activities.value = [
      ActivityItem(
        id: 1,
        title: '活动1：',
        description: '邀请好友通过专属链接下载注册，成功绑定情侣关系后，只要其中一人连续登录3天，即可获得1张补签卡(2/5人)。',
        buttonText: '邀请好友',
      ),
      ActivityItem(
        id: 2,
        title: '活动2：',
        description: '邀请好友通过专属链接下载注册，成功绑定情侣关系后，且参与188打卡活动，即可获得1张补签卡。(0/5人)',
        buttonText: '邀请好友',
      ),
    ];
  }
  
  /// 更新导航栏透明度
  void updateNavBarOpacity(double offset) {
    final opacity = (offset / 100).clamp(0.0, 1.0);
    navBarOpacity.value = opacity;
  }
  
  /// 邀请好友
  void onInviteFriend(int activityId) {
    // 显示分享弹窗
    Get.bottomSheet(
      CheckIn188ShareBottomSheet(activityId: activityId),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }
  
  /// 返回上一页
  void goBack() {
    Get.back();
  }
}

/// 活动项数据模型
class ActivityItem {
  final int id;
  final String title;
  final String description;
  final String buttonText;
  
  ActivityItem({
    required this.id,
    required this.title,
    required this.description,
    required this.buttonText,
  });
}