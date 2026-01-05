import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'message_list_controller.dart';

class MessageListPage extends GetView<MessageListController> {
  const MessageListPage({super.key});

  /// 构建通知开启提示
  Widget _buildNotificationTip() {
    return Obx(() {
      // 如果已经开启通知，不显示提示
      if (controller.hasNotificationPermission.value) {
        return const SizedBox.shrink();
      }

      // 如果用户手动关闭了提示，不显示
      if (!controller.showNotificationTip.value) {
        return const SizedBox.shrink();
      }

      return GestureDetector(
        onTap: controller.openNotificationSettings,
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              padding: const EdgeInsets.only(right: 12),
              height: 40,
              // padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12).copyWith(left: 50,top: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFFFE5FB),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 50),
                  // 提示文字
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        '开启推送通知，重要消息不错过',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xcc000000),
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  // 去开启文字
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Color(0xffFF93D2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '去开启',
                      style: TextStyle(fontSize: 10, color: Color(0xFFffffff)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: controller.hideNotificationTip,
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF777777),
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: Offset(16, -20),
              child: Image.asset(
                "assets/images/kissu_mine_noti_tip.webp",
                width: 45,
                height: 60,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 构建消息列表项
  Widget _buildMessageItem({
    required String icon,
    required String title,
    required String subtitle,
    required bool hasRedDot,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(2, 0, 2, 16),
        padding: const EdgeInsets.all(16).copyWith(bottom: 0),
        color: Color(0xffF6F6F6),
        child: Row(
          children: [
            // 图标
            Image.asset(icon, width: 55, height: 55),
            const SizedBox(width: 12),
            // 文字内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 副标题
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 红点（预留）
            if (hasRedDot)
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B6B),
                  shape: BoxShape.circle,
                ),
              ),
            // 箭头
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF6F6F6),
      body: Stack(
        children: [
          // 背景参考设置页面
          Positioned.fill(
            child: Image.asset(
              "assets/4.0/kissu4_new_use_bg.webp",
              fit: BoxFit.fitWidth,
              height: 140,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 导航栏 - 参考关于我们页面的设置
                SizedBox(
                  height: 44,
                  child: Stack(
                    children: [
                      // 返回按钮
                      Positioned(
                        left: 5,
                        top: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: controller.onBackTap,
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/images/kissu_mine_back.webp',
                              width: 22,
                              height: 22,
                            ),
                          ),
                        ),
                      ),

                      // 标题 - 绝对居中
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            '消息',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xcc000000),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      // 清空按钮
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: controller.clearAllMessages,
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/images/kissu_message_clear.webp',
                              width: 22,
                              height: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10), // 减少间距，避免标题距离顶部太远
                // 内容区域
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    child: Column(
                      children: [
                        // 通知开启提示
                        _buildNotificationTip(),
                        // 系统消息
                        Obx(
                          () => _buildMessageItem(
                            icon: 'assets/3.0/kissu3_noti_noti.webp',
                            title: '系统消息',
                            subtitle: '您有一条新的系统消息',
                            hasRedDot: controller.hasNewSystemMessage.value,
                            onTap: controller.goToSystemMessage,
                          ),
                        ),
                        // 互动消息
                        Obx(
                          () => _buildMessageItem(
                            icon: 'assets/3.0/kissu3_noti_message.webp',
                            title: '互动消息',
                            subtitle: '您有一条新的互动消息',
                            hasRedDot:
                                controller.hasNewInteractionMessage.value,
                            onTap: controller.goToInteractionMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
