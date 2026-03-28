import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../state/game_state.dart';

/// 游戏结果视图
class GameResultView extends StatelessWidget {
  final GameState gameState;

  const GameResultView({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部导航
        _buildAppBar(context),
        const SizedBox(height: 30),

        // 结果标题
        const Text(
          '🎉 游戏结束！',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 20),

        // 成绩卡片
        _buildScoreCard(),
        const SizedBox(height: 20),

        // 题目回顾列表
        Expanded(child: _buildQuestionReview()),

        // 底部按钮
        _buildBottomButtons(context),
        const SizedBox(height: 20),
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
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE4EC), Color(0xFFFFF0F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF90CA).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '答对',
            '${gameState.correctCount}',
            '/ 5',
            const Color(0xFF4CAF50),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFFFD4E5)),
          _buildStatItem(
            '得分',
            '${gameState.totalScore}',
            '分',
            const Color(0xFFFF90CA),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFFFD4E5)),
          _buildStatItem(
            '角色',
            gameState.myRole == GameRole.describer ? '描述者' : '猜题者',
            '',
            const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String suffix, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              TextSpan(
                text: suffix,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionReview() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: gameState.questions.length,
      itemBuilder: (context, index) {
        final q = gameState.questions[index];
        return _buildQuestionItem(q);
      },
    );
  }

  Widget _buildQuestionItem(GameQuestion question) {
    final statusIcon = _getStatusIcon(question.status);
    final statusColor = _getStatusColor(question.status);
    final statusText = _getStatusText(question.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          // 题号
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${question.index + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 答案
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.answer,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                if (question.category != null)
                  Text(
                    question.category!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                  ),
              ],
            ),
          ),
          // 状态
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(fontSize: 12, color: statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.correct:
        return Icons.check_circle;
      case QuestionStatus.wrong:
        return Icons.cancel;
      case QuestionStatus.skipped:
        return Icons.skip_next;
      case QuestionStatus.timeout:
        return Icons.timer_off;
      case QuestionStatus.pending:
        return Icons.radio_button_unchecked;
    }
  }

  Color _getStatusColor(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.correct:
        return const Color(0xFF4CAF50);
      case QuestionStatus.wrong:
        return const Color(0xFFFF4444);
      case QuestionStatus.skipped:
        return const Color(0xFFFF9800);
      case QuestionStatus.timeout:
        return const Color(0xFF999999);
      case QuestionStatus.pending:
        return const Color(0xFFCCCCCC);
    }
  }

  String _getStatusText(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.correct:
        return '正确';
      case QuestionStatus.wrong:
        return '错误';
      case QuestionStatus.skipped:
        return '跳过';
      case QuestionStatus.timeout:
        return '超时';
      case QuestionStatus.pending:
        return '未答';
    }
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // 再来一局
          Expanded(
            child: GestureDetector(
              onTap: () => gameState.restartGame(),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF90CA),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF90CA).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '再来一局',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 退出
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await gameState.exitGame();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: const Center(
                  child: Text(
                    '退出',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
