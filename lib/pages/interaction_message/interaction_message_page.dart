import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'interaction_message_controller.dart';

class InteractionMessagePage extends GetView<InteractionMessageController> {
  const InteractionMessagePage({super.key});


  /// 构建日期分组标题
  Widget _buildDateHeader(String date) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        date,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xff999999),
        ),
      ),
    );
  }

  /// 构建消息列表项
  Widget _buildMessageItem(InteractionMessageItem message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8), // 半透明背景，让背景图片透出来
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和时间行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  message.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff333333),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                message.date,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xff999999),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 内容
          Text(
            message.content,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xff666666),
              height: 1.5,
            ),
          ),
          // 如果是"Ta的消息"，显示查看按钮
          if (message.isTaMessage) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => controller.onViewMessage(message),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      '查看',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xff4570FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Color(0xff4570FF),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建消息列表
  Widget _buildMessageList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xffFF6B6B)),
          ),
        );
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                controller.errorMessage.value,
                style: const TextStyle(fontSize: 14, color: Color(0xff69686F)),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: controller.refreshMessages,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffFF6B6B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '重试',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      if (controller.messageList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/kissu_notice_empty.webp",
                width: 128,
                height: 128,
              ),
              const SizedBox(height: 16),
              const Text(
                '目前还没有互动消息哦~',
                style: TextStyle(fontSize: 14, color: Color(0xff666666)),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        itemCount: controller.messageList.length,
        itemBuilder: (context, index) {
          final messageGroup = controller.messageList[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildDateHeader(messageGroup.date),
              ...messageGroup.list.map((message) => _buildMessageItem(message)),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6f6f6), // 和消息页面保持一致的灰色背景
      body: Stack(
        children: [
          // 背景图片 - 和消息页面保持一致
          Positioned.fill(
            child: Image.asset(
              "assets/4.0/kissu4_new_use_bg.webp",
              fit: BoxFit.fitWidth,
              height: 140,
              alignment: Alignment.topCenter,
            ),
          ),
          Column(
              children: [
                // 顶部导航栏 - 调整结构和消息页面保持一致
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 6,
                    right: 16,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: controller.onBackTap,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            "assets/images/kissu_mine_back.webp",
                            width: 22,
                            height: 22,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "互动消息",
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xcc000000),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 22),
                    ],
                  ),
                ),
                const SizedBox(height: 10), // 减少间距，避免标题距离顶部太远
                // 消息列表
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.refreshMessages,
                    color: const Color(0xffFF6B6B),
                    child: _buildMessageList(),
                  ),
                ),
              ],
            ),
         
        ],
      ),
    );
  }
}

