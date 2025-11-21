import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'message_list_controller.dart';

class MessageListPage extends GetView<MessageListController> {
  const MessageListPage({super.key});

  /// 构建导航栏
  Widget _buildAppBar() {
    return Container(
      height: 88,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F8FF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 返回按钮
              GestureDetector(
                onTap: controller.onBackTap,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/images/kissu_mine_back.webp',
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
              // 标题
              const Text(
                '消息列表',
                style: TextStyle(fontSize: 18, color: Color(0xFF333333)),
              ),
              // 占位空间，保持布局平衡
              const SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建通知开启提示
  Widget _buildNotificationTip() {
    return Obx(() {
      // 如果已经开启通知，不显示提示
      if (controller.hasNotificationPermission.value) {
        return const SizedBox.shrink();
      }

      return GestureDetector(
        onTap: controller.openNotificationSettings,
        child: Container(
          margin: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F8FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // 提示图标
              Image.asset(
                'assets/3.0/kissu3_noti_tip.webp',
                width: 12,
                height: 12,
              ),
              // const SizedBox(width: 4),
              // 提示文字
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    '推送通知未开启，会错过对方重要信息哦~',
                    style: TextStyle(fontSize: 12, color: Color(0xFF819EFF)),
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              // 去开启文字
              const Text(
                '去开启',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4570FF),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Icon(
                Icons.chevron_right,
                size: 16,
                color: Color(0xFF4570FF),
              ),
            ],
          ),
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
        margin: const EdgeInsets.fromLTRB(2, 16, 2, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 图标
            Image.asset(icon, width: 42, height: 42),
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
                  const SizedBox(height: 4),
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 导航栏
          _buildAppBar(),
          // 内容区域
          Expanded(
            child: SingleChildScrollView(
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
                      hasRedDot: controller.hasNewInteractionMessage.value,
                      onTap: controller.goToInteractionMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
