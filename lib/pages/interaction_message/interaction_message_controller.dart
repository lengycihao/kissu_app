 
import 'package:get/get.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/public/api_request.dart';
import 'package:kissu_app/network/tools/logging/logging.dart'; 
import 'package:kissu_app/routers/kissu_route_path.dart';

class InteractionMessageController extends GetxController {
  // 消息列表数据
  var messageList = <InteractionMessageGroup>[].obs;
  
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
        ApiRequest.interactionNotice,
        paramEncrypt: false,
      );
      
      if (result.isSuccess) {
        // 解析数据 - 使用listJson字段
        final dataList = result.getListJson();
        messageList.value = dataList.map((item) => InteractionMessageGroup.fromJson(item)).toList();
        logDebug('✅ 互动消息加载成功，共 ${messageList.length} 组');
      } else {
        errorMessage.value = result.msg ?? '加载失败';
        logError('❌ 互动消息加载失败: ${result.msg}');
      }
    } catch (e) {
      errorMessage.value = '网络错误: ${e.toString()}';
      logError('❌ 加载互动消息列表失败: $e');
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

  /// 查看消息详情
  void onViewMessage(InteractionMessageItem message) {
    logDebug('查看消息: ${message.title}');
    if (message.eventType == 2) {
      Get.toNamed(KissuRoutePath.location);
    }
  }
}

/// 互动消息组数据模型
class InteractionMessageGroup {
  final String date;
  final List<InteractionMessageItem> list;

  InteractionMessageGroup({
    required this.date,
    required this.list,
  });

  factory InteractionMessageGroup.fromJson(Map<String, dynamic> json) {
    return InteractionMessageGroup(
      date: json['date'] ?? '',
      list: (json['list'] as List<dynamic>?)
          ?.map((item) => InteractionMessageItem.fromJson(item))
          .toList() ?? [],
    );
  }
}

/// 互动消息项数据模型
class InteractionMessageItem {
  final String id;
  final String title;
  final String content;
  final String date;
  final int eventType;

  InteractionMessageItem({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.eventType,
  });

  factory InteractionMessageItem.fromJson(Map<String, dynamic> json) {
    return InteractionMessageItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      date: json['date'] ?? '', eventType: json['event_type'] ?? 0,
    );
  }

  /// 判断是否是"Ta的消息"类型（需要显示查看按钮）
  bool get isTaMessage => eventType == 2;
}

