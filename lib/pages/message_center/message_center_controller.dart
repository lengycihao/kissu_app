import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/public/api_request.dart';

class MessageCenterController extends GetxController {
  // 消息列表数据
  var messageList = <MessageGroup>[].obs;
  
  // 加载状态
  var isLoading = false.obs;
  
  // 错误信息
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadMessages();
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
  void handleMessageAction(MessageItem message, String action) {
    // TODO: 实现具体的操作逻辑
    debugPrint('处理消息操作: ${message.id}, 操作: $action');
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

  MessageItem({
    required this.id,
    required this.title,
    required this.content,
    required this.statusText,
    required this.date,
    required this.isOperate,
  });

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      statusText: json['status_text'] ?? '',
      date: json['date'] ?? '',
      isOperate: json['is_operate'] ?? 0,
    );
  }
}
