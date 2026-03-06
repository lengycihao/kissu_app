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
    final bool isPhoneUse = message.type == MessageType.phoneUse;

    String title;
    String description;
    String iconAsset;
    
    if (isLockPhone) {
      title = '开启悬浮窗权限';
      description = '和Ta一起体验一键锁机等有趣功能吧~';
      iconAsset = 'assets/lock/kissu_chat_pre_lock.webp';
    } else if (isPhoneUse) {
      title = '开启应用使用记录权限';
      description = '请授权应用使用情况，共享手机使用报告和设备状态';
      iconAsset = 'assets/lock/kissu_chat_pre_lock.webp';
    } else {
      title = '关联app';
      description = '快去关联app吧，让Ta时刻充满着安全感';
      iconAsset = 'assets/lock/kissu_chat_gl_app.webp';
    }
    
    return GestureDetector(
      onTap: () {
        // 点击卡片跳转到权限设置页面
        if (isLockPhone || isPhoneUse) {
          Get.toNamed(
            KissuRoutePath.systemPermission,
            arguments: {
              'flashOverlay': isLockPhone,
              'flashUsage': isPhoneUse,
            },
          );
        }
      },
      child: message.isSent
          ? Container(
              decoration: BoxDecoration(color: Colors.transparent),
              padding: EdgeInsets.fromLTRB(5, 5, 0, 5),
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
                  // 上半部分：标题 + 图标 + 描述
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 图标
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF999999),
                              width: 0.5,
                            ),
                          ),
                          child: Center(
                            child: Image(
                              image: AssetImage(iconAsset),
                              width: 48,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 标题 + 描述
                        Expanded(
                          child: Text(
                            description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF333333),
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 分割线
                  Container(height: 0.5, color: const Color(0xFFC8C8C8)),
                  // 底部：情侣必要权限 >
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '情侣必要权限',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF777777),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: const Color(0xFF777777),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(color: Colors.transparent),
              padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  // 上半部分：标题 + 图标 + 描述
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题 + 描述
                        Expanded(
                          child: Text(
                            description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF333333),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: 10),
                        // 图标
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF999999),
                              width: 0.5,
                            ),
                          ),
                          child: Center(
                            child: Image(
                              image: AssetImage(iconAsset),
                              width: 48,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 分割线
                  Container(height: 0.5, color: const Color(0xFFC8C8C8)),
                  // 底部：情侣必要权限 >
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '情侣必要权限',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF777777),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: const Color(0xFF777777),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  
}
