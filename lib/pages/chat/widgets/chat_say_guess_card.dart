import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import '../models/chat_message.dart';

/// 你说我猜邀请消息组件
class ChatSayGuessCard extends StatelessWidget {
  final ChatMessage message;

  const ChatSayGuessCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: message.isSent ? null : () => _onCardTap(),
      child: Image.asset(
        'assets/say_guess/kissu_say_guess-invite.webp',
        width: 190,
        height: 140,
        fit: BoxFit.contain,
      ),
    );
  }

  void _onCardTap() {
    final groupId = message.groupId;
    if (groupId == null || groupId.isEmpty) return;

    Get.toNamed(
      KissuRoutePath.guessGameV2Play,
      arguments: {
        'groupId': groupId,
        'isInitiator': false,
      },
    );
  }
}
