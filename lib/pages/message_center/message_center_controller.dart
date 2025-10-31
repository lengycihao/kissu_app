import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/public/api_request.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/services/tracking_service.dart';

class MessageCenterController extends GetxController {
  // 消息列表数据
  var messageList = <MessageGroup>[].obs;
  
  // 加载状态
  var isLoading = false.obs;
  
  // 错误信息
  var errorMessage = ''.obs;

  // 页面浏览埋点相关
  DateTime? _pageEnterTime;
  late ScrollController scrollController;
  var scrollTimes = 0.obs;
  var hasScrolled = false.obs;

  @override
  void onInit() {
    super.onInit();
    
    // 记录进入时间
    _pageEnterTime = DateTime.now();
    
    // 初始化滚动控制器
    scrollController = ScrollController();
    
    loadMessages();
  }

  @override
  void onClose() {
    // 上报页面浏览埋点
    _trackPageView();
    
    // 释放滚动控制器
    scrollController.dispose();
    
    super.onClose();
  }

  /// 处理滚动事件
  bool handleScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta.abs() > 10) {
        if (!hasScrolled.value) {
          hasScrolled.value = true;
        }
        scrollTimes.value++;
      }
    }
    return false;
  }

  /// 上报页面浏览埋点
  Future<void> _trackPageView() async {
    if (_pageEnterTime == null) return;
    
    try {
      final duration = DateTime.now().difference(_pageEnterTime!);
      final seconds = duration.inSeconds;
      final stayDuration = '${seconds}s';
      
      // 获取绑定状态 (bindStatus: 0从未绑定，1绑定中，2已解绑)
      final user = UserManager.currentUser;
      final isBind = (user?.bindStatus.toString() == "1") ? '已绑定' : '未绑定';
      
      await TrackingService.trackMessageCenterPageView(
        stayDuration: stayDuration,
        canScroll: hasScrolled.value,
        isBind: isBind,
      );
      
      debugPrint('✅ 互动消息页面浏览埋点上报成功: 停留时长=$stayDuration, 是否滑动=${hasScrolled.value}, 绑定状态=$isBind');
    } catch (e) {
      debugPrint('❌ 互动消息页面浏览埋点上报失败: $e');
    }
  }

  /// 加载消息列表
  Future<void> loadMessages() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final result = await HttpManagerN.instance.executeGet(
        ApiRequest.systemNotice,
        paramEncrypt: false,
      );
      
      if (result.isSuccess) {
        // 解析数据 - 使用listJson字段
        final dataList = result.getListJson();
        messageList.value = dataList.map((item) => MessageGroup.fromJson(item)).toList();
      } else {
        errorMessage.value = result.msg ?? '加载失败';
      }
    } catch (e) {
      errorMessage.value = '网络错误: ${e.toString()}';
      debugPrint('加载消息列表失败: $e');
    } finally {
      isLoading.value = false;
    }
  }


  /// 刷新消息列表
  Future<void> refreshMessages() async {
    await loadMessages();
  }

  /// 返回上一页
  void onBackTap() {
    Get.back();
  }

  /// 处理消息操作（同意/拒绝绑定等）
  Future<void> handleMessageAction(MessageItem message, String action) async {
    if (action == 'accept') {
      await _affirmBind(message);
    } else if (action == 'reject') {
      await _refuseBind(message);
    }
  }

  /// 同意绑定
  Future<void> _affirmBind(MessageItem message) async {
    try {
      debugPrint('开始同意绑定，消息ID: ${message.id}');
      
      // 上报接收绑定按钮点击埋点
      await TrackingService.trackAcceptBindButton(
        otherId: message.fromUserId.isNotEmpty ? message.fromUserId : message.id,
      );
      
      final result = await HttpManagerN.instance.executePost(
        ApiRequest.affirmBind,
        jsonParam: {'system_notice_id': message.id},
        paramEncrypt: false,
      );
      
      if (result.isSuccess) {
        CustomToast.show(Get.context!, '绑定成功');
        
        // 刷新用户信息并更新缓存
        await _refreshUserInfoAfterBind();
        
        // 重新加载消息列表
        await loadMessages();
        
        debugPrint('✅ 接收绑定按钮埋点上报成功: other_id=${message.fromUserId.isNotEmpty ? message.fromUserId : message.id}');
      } else {
        CustomToast.show(Get.context!, result.msg ?? '绑定失败');
      }
    } catch (e) {
      debugPrint('同意绑定失败: $e');
      CustomToast.show(Get.context!, '绑定失败: $e');
    }
  }

  /// 拒绝绑定
  Future<void> _refuseBind(MessageItem message) async {
    try {
      debugPrint('开始拒绝绑定，消息ID: ${message.id}');
      
      // 上报拒绝绑定按钮点击埋点
      await TrackingService.trackRejectBindButton();
      
      final result = await HttpManagerN.instance.executePost(
        ApiRequest.refuseBind,
        jsonParam: {'system_notice_id': message.id},
        paramEncrypt: false,
      );
      
      if (result.isSuccess) {
        CustomToast.show(Get.context!, '已拒绝绑定');
        
        // 重新加载消息列表
        await loadMessages();
        
        debugPrint('✅ 拒绝绑定按钮埋点上报成功');
      } else {
        CustomToast.show(Get.context!, result.msg ?? '操作失败');
      }
    } catch (e) {
      debugPrint('拒绝绑定失败: $e');
      CustomToast.show(Get.context!, '操作失败: $e');
    }
  }

  /// 绑定成功后刷新用户信息
  Future<void> _refreshUserInfoAfterBind() async {
    try {
      // 获取用户最新信息并更新缓存
      await UserManager.refreshUserInfo();
      
      // 如果首页控制器存在，通知其刷新状态
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        await homeController.refreshUserInfoAndState();
      }
    } catch (e) {
      debugPrint('刷新用户信息失败: $e');
    }
  }

}

/// 消息组数据模型
class MessageGroup {
  final String date;
  final List<MessageItem> list;

  MessageGroup({
    required this.date,
    required this.list,
  });

  factory MessageGroup.fromJson(Map<String, dynamic> json) {
    return MessageGroup(
      date: json['date'] ?? '',
      list: (json['list'] as List<dynamic>?)
          ?.map((item) => MessageItem.fromJson(item))
          .toList() ?? [],
    );
  }
}

/// 消息项数据模型
class MessageItem {
  final String id;
  final String title;
  final String content;
  final String statusText;
  final String date;
  final int isOperate;
  final String fromUserId; // 发送者/情侣的用户ID

  MessageItem({
    required this.id,
    required this.title,
    required this.content,
    required this.statusText,
    required this.date,
    required this.isOperate,
    this.fromUserId = '',
  });

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      statusText: json['status_text'] ?? '',
      date: json['date'] ?? '',
      isOperate: json['is_operate'] ?? 0,
      fromUserId: json['from_user_id']?.toString() ?? json['user_id']?.toString() ?? '',
    );
  }
}
