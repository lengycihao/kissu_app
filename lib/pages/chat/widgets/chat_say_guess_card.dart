import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/pages/guess_game_v2/services/game_api_service.dart';
import '../models/chat_message.dart';

/// 你说我猜邀请消息组件
class ChatSayGuessCard extends StatelessWidget {
  final ChatMessage message;

  const ChatSayGuessCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onCardTap(),
      child: Image.asset(
        'assets/say_guess/kissu_say_guess-invite.webp',
        width: 190,
        height: 140,
        fit: BoxFit.contain,
      ),
    );
  }

  Future<void> _onCardTap() async {
    final groupId = message.groupId;
    if (groupId == null || groupId.isEmpty) return;

    final info = await GameApiService().getGameInfo(groupId);
    if (info == null) {
      showToast('获取对局信息失败');
      return;
    }

    // status: 0=失败 1=进行中 2=成功
    if (info.status == 2) {
      showToast('对局已经结束');
    } else if (info.status == 0) {
      Get.toNamed(KissuRoutePath.guessGameV2PenaltyRecord);
    } else {
      // 进行中：isSent=true表示我是发起方（出题者）
      Get.toNamed(
        KissuRoutePath.guessGameV2Play,
        arguments: {
          'groupId': groupId,
          'isInitiator': message.isSent,
        },
      );
    }
  }
}
