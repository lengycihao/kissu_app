import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import '../models/chat_message.dart';

/// 权限提醒卡片消息组件（lock_phone / connect_app）
/// 卡片样式：标题 + 图标 + 描述 + 底部"情侣必要权限 >"
class ChatPermissionCard extends StatelessWidget {
  final ChatMessage message;

  const ChatPermissionCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isLockPhone = message.type == MessageType.lockPhone;

    final String title = isLockPhone ? '开启悬浮窗权限' : '关联app';
    final String description = isLockPhone
        ? '和Ta一起体验一键锁机等有趣功能吧~'
        : '快去关联app吧，让Ta时刻充满着安全感';
    return GestureDetector(
      onTap: () {
        // 点击卡片跳转到权限设置页面
        Get.toNamed(KissuRoutePath.systemPermission);
      },
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0A000000),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 上半部分：标题 + 图标 + 描述
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图标
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        isLockPhone ? Icons.lock_outline : Icons.link,
                        size: 22,
                        color: const Color(0xFFFF7ECE),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 标题 + 描述
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF999999),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 分割线
            Container(
              height: 0.5,
              color: const Color(0xFFEEEEEE),
            ),
            // 底部：情侣必要权限 >
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    '情侣必要权限',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFF7ECE),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: const Color(0xFFFF7ECE),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
