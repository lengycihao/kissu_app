import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../state/game_state.dart';

/// 角色选择视图
class RoleSelectionView extends StatelessWidget {
  final GameState gameState;

  const RoleSelectionView({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final room = gameState.room;
    if (room == null) return const SizedBox.shrink();

    return Column(
      children: [
        // 顶部导航
        _buildAppBar(context),
        const SizedBox(height: 30),

        // 双方头像
        _buildPlayersRow(room),
        const SizedBox(height: 20),

        // 提示文字
        const Text(
          '双方已准备就绪，请选择你的本轮角色',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 40),

        // 我要猜
        _buildRoleCard(
          title: '我要猜',
          subtitle: '读懂Ta的心',
          icon: Icons.psychology,
          color: const Color(0xFFFFE4EC),
          iconColor: const Color(0xFFFF90CA),
          onTap: () => gameState.selectRole(GameRole.guesser),
        ),
        const SizedBox(height: 20),

        // 我要描述
        _buildRoleCard(
          title: '我要描述',
          subtitle: '用默契的语言引导Ta',
          icon: Icons.edit_note,
          color: const Color(0xFFE8E0FF),
          iconColor: const Color(0xFF8B5CF6),
          onTap: () => gameState.selectRole(GameRole.describer),
        ),
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
          // 帮助按钮
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF999999)),
            ),
            child: const Center(
              child: Text('?', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersRow(GameRoom room) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPlayerAvatar(room.host.nickname, room.host.avatarUrl),
          const Icon(Icons.favorite, size: 24, color: Color(0xFFFF90CA)),
          _buildPlayerAvatar(
            room.guest?.nickname ?? '等待中',
            room.guest?.avatarUrl ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerAvatar(String name, String avatarUrl) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
          ),
          child: Center(
            child: avatarUrl.isNotEmpty
                ? ClipOval(child: Image.network(avatarUrl, fit: BoxFit.cover))
                : const Icon(Icons.person, size: 28, color: Color(0xFFCCCCCC)),
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

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: iconColor),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF333333).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
