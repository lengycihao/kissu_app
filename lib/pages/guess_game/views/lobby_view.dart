import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../state/game_state.dart';

/// 游戏大厅视图（等待对方加入）
class LobbyView extends StatelessWidget {
  final GameState gameState;

  const LobbyView({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final room = gameState.room;
    if (room == null) return const SizedBox.shrink();

    return Column(
      children: [
        // 顶部导航栏
        _buildAppBar(context),
        const SizedBox(height: 20),

        // 得分图标区
        _buildScoreArea(room),
        const SizedBox(height: 30),

        // 双方头像
        _buildPlayersArea(room),
        const SizedBox(height: 40),

        // 开始游戏按钮（仅房主显示）/ 等待提示（被邀请方）
        if (gameState.isHost)
          _buildStartButton(room)
        else if (gameState.partnerJoined)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              '等待房主开始游戏...',
              style: TextStyle(fontSize: 15, color: Color(0xFF999999)),
              textAlign: TextAlign.center,
            ),
          ),

        const Spacer(),

        // 底部通关提示
        _buildWeeklyStats(room),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF333333)),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Kissu 你说我猜',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          // 惩罚记录 & 分享
          GestureDetector(
            onTap: () {
              // TODO: 惩罚记录
            },
            child: const Text(
              '惩罚记录',
              style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              // TODO: 分享
            },
            child: const Icon(Icons.ios_share, size: 20, color: Color(0xFF666666)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              // TODO: 帮助
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF999999)),
              ),
              child: const Center(
                child: Text('?', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreArea(GameRoom room) {
    return Column(
      children: [
        // 成绩图标
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.assignment_turned_in,
            size: 40,
            color: Color(0xFFFF90CA),
          ),
        ),
        const SizedBox(height: 8),
        // 得分
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, size: 20, color: Color(0xFFFFD700)),
            const SizedBox(width: 4),
            Text(
              'X${room.totalScore}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '排名:${room.ranking}+',
          style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
        ),
      ],
    );
  }

  Widget _buildPlayersArea(GameRoom room) {
    final gs = gameState;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 房主
          _buildPlayerSlot(
            name: '房主',
            avatarUrl: room.host.avatarUrl,
            isReady: room.isHostReady,
            isEmpty: false,
          ),

          // 连接心形
          const Icon(
            Icons.favorite,
            size: 28,
            color: Color(0xFFFF90CA),
          ),

          // 右侧：根据状态显示不同内容
          if (gs.partnerJoined && room.guest != null)
            // 对方已加入：显示头像
            _buildPlayerSlot(
              name: room.guest!.nickname,
              avatarUrl: room.guest!.avatarUrl,
              isReady: room.isGuestReady,
              isEmpty: false,
            )
          else if (gs.inviteSent)
            // 已发送邀请，等待对方
            _buildWaitingSlot()
          else if (gs.isHost)
            // 房主端：显示邀请按钮
            _buildInviteButton()
          else
            // 被邀请方（不应到这里，但兜底）
            _buildEmptySlot(),
        ],
      ),
    );
  }

  Widget _buildPlayerSlot({
    required String name,
    required String avatarUrl,
    required bool isReady,
    required bool isEmpty,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            shape: BoxShape.circle,
            border: Border.all(
              color: isReady ? const Color(0xFFFF90CA) : const Color(0xFFE0E0E0),
              width: 2,
            ),
          ),
          child: Center(
            child: avatarUrl.isNotEmpty
                ? ClipOval(child: Image.network(avatarUrl, fit: BoxFit.cover))
                : Icon(
                    Icons.person,
                    size: 30,
                    color: isReady ? const Color(0xFFFF90CA) : const Color(0xFFCCCCCC),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildInviteButton() {
    return GestureDetector(
      onTap: () => gameState.sendInvite(),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
            ),
            child: const Center(
              child: Icon(Icons.person_add, size: 26, color: Color(0xFFFF90CA)),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '邀请',
            style: TextStyle(fontSize: 12, color: Color(0xFFFF90CA), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingSlot() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFF90CA),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '等待加入...',
          style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
        ),
      ],
    );
  }

  Widget _buildEmptySlot() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
          ),
          child: const Center(
            child: Icon(Icons.hourglass_empty, size: 28, color: Color(0xFFCCCCCC)),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '等待加入...',
          style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
        ),
      ],
    );
  }

  Widget _buildStartButton(GameRoom room) {
    final canStart = gameState.partnerJoined;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GestureDetector(
        onTap: canStart ? () => gameState.startGame() : null,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: canStart ? const Color(0xFFFF90CA) : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(25),
            boxShadow: canStart
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF90CA).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              '开始游戏',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: canStart ? Colors.white : const Color(0xFF999999),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyStats(GameRoom room) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, size: 24, color: Color(0xFFFFD700)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '本周你们已经默契通关${room.weeklyCleared}轮！',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '默契度已经超过了38%的情侣，继续爱意满满',
                  style: TextStyle(fontSize: 11, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
