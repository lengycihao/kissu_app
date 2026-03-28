import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../state/game_state.dart';
import '../widgets/tv_display_widget.dart';
import '../widgets/game_chat_bubble.dart';
import '../widgets/privilege_popup.dart';

/// 游戏进行中视图（含倒计时、答题、聊天）
class GamePlayView extends StatefulWidget {
  final GameState gameState;

  const GamePlayView({super.key, required this.gameState});

  @override
  State<GamePlayView> createState() => _GamePlayViewState();
}

class _GamePlayViewState extends State<GamePlayView> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _customAnswerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showPrivilegePopup = false;

  GameState get gs => widget.gameState;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _lastMessageCount = gs.messages.length;
    gs.addListener(_onGameStateChanged);
  }

  void _onGameStateChanged() {
    if (mounted) {
      final newCount = gs.messages.length;
      final hasNewMessages = newCount > _lastMessageCount;
      _lastMessageCount = newCount;

      setState(() {});

      // 只在有新消息时才自动滚动到底部，倒计时等不触发滚动
      if (hasNewMessages) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  @override
  void dispose() {
    gs.removeListener(_onGameStateChanged);
    _inputController.dispose();
    _customAnswerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // 顶部导航
            _buildAppBar(context),
            const SizedBox(height: 8),

            // TV显示区域
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTvArea(),
            ),

            // 自定义答案输入区（出题者第5题）
            if (gs.waitingForCustomAnswer && gs.myRole == GameRole.describer)
              _buildCustomAnswerInput()
            else ...[
              const SizedBox(height: 12),
              // 聊天消息列表（提示信息作为第一条消息在列表内滚动）
              Expanded(child: _buildChatArea()),
              // 底部操作区（猜题者的特权/提示按钮 + 输入框）
              if (gs.phase == GamePhase.playing && !gs.waitingForCustomAnswer)
                _buildBottomArea(),
            ],
          ],
        ),

        // 特权弹窗（覆盖层）
        if (_showPrivilegePopup)
          PrivilegePopup(
            remainingCount: gs.privilegeCount,
            onAddTime: () {
              gs.usePrivilegeAddTime();
              setState(() => _showPrivilegePopup = false);
            },
            onSkip: () {
              gs.usePrivilegeSkip();
              setState(() => _showPrivilegePopup = false);
            },
            onDismiss: () {
              setState(() => _showPrivilegePopup = false);
            },
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
            onTap: () => _showExitConfirmDialog(context),
            child: const Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF333333)),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Kissu你说我猜',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF90CA),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF999999)),
            ),
            child: const Center(
              child: Text('?', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTvArea() {
    final isCountdown = gs.phase == GamePhase.countdown;
    final isCustomInput = gs.waitingForCustomAnswer && gs.myRole == GameRole.describer;

    String displayText;
    if (isCountdown) {
      displayText = gs.countdownValue > 0 ? '${gs.countdownValue}' : '开始游戏';
    } else if (isCustomInput) {
      displayText = '';
    } else {
      // 游戏进行中：出题者看答案，猜题者看???
      if (gs.myRole == GameRole.describer) {
        displayText = gs.currentQuestion?.answer ?? '???';
      } else {
        displayText = '???';
      }
    }

    // 构建每题状态列表: 0=pending, 1=correct, 2=wrong/timeout, 3=skipped
    final statuses = gs.questions.map((q) {
      switch (q.status) {
        case QuestionStatus.correct:
          return 1;
        case QuestionStatus.wrong:
        case QuestionStatus.timeout:
          return 2;
        case QuestionStatus.skipped:
          return 3;
        case QuestionStatus.pending:
          return 0;
      }
    }).toList();

    return TvDisplayWidget(
      displayText: displayText,
      isCountdown: isCountdown,
      questionIndex: gs.currentQuestionIndex,
      totalQuestions: 5,
      timer: (isCountdown || isCustomInput) ? null : gs.questionTimer,
      hintChar: gs.currentHint,
      isCustomInput: isCustomInput,
      onRandomTap: isCustomInput ? () => gs.randomizeCustomAnswer() : null,
      questionStatuses: statuses,
    );
  }

  /// 自定义答案输入区（出题者第5题输入自定义答案）
  Widget _buildCustomAnswerInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const Text(
            '请输入你想让对方猜的词语',
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: TextField(
                    controller: _customAnswerController,
                    decoration: const InputDecoration(
                      hintText: '输入自定义答案',
                      hintStyle: TextStyle(fontSize: 14, color: Color(0xFFCCCCCC)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                    onSubmitted: (_) => _submitCustomAnswer(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _submitCustomAnswer,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF90CA),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Center(
                    child: Text(
                      '确定',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitCustomAnswer() {
    final text = _customAnswerController.text.trim();
    if (text.isEmpty) return;
    gs.setCustomAnswer(text);
    _customAnswerController.clear();
  }

  Widget _buildChatArea() {
    final isDescriber = gs.myRole == GameRole.describer;
    // 提示信息作为列表头部，跟着聊天内容滚动
    final tipCount = 1; // 一个提示区块
    final totalCount = tipCount + gs.messages.length;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        // 第0项：角色提示信息
        if (index == 0) {
          return _buildTipsInChat();
        }

        final msgIndex = index - tipCount;
        final msg = gs.messages[msgIndex];
        // 出题者端：对方发来的提示请求消息 → 显示答案拆字选择器
        final bool showChars = isDescriber &&
            msg.type == GameChatMessageType.hintRequest &&
            !msg.isSelf &&
            gs.waitingForHintSelection &&
            gs.currentQuestion != null;

        return GameChatBubble(
          message: msg,
          showAnswerChars: showChars,
          answerChars: showChars ? gs.currentQuestion!.answerChars : null,
          onHintCharSelected: showChars
              ? (charIndex) {
                  gs.sendHintChar(charIndex);
                }
              : null,
        );
      },
    );
  }

  /// 提示信息（在聊天列表内滚动）
  Widget _buildTipsInChat() {
    final isDescriber = gs.myRole == GameRole.describer;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: isDescriber
            ? [
                const Text(
                  '请根据上方答案进行描述',
                  style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  '描述中不能出现答案内任一字',
                  style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                  textAlign: TextAlign.center,
                ),
              ]
            : [
                const Text(
                  '请等待对方描述答案',
                  style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  '你则根据对方的描述在下方提交答案',
                  style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                  textAlign: TextAlign.center,
                ),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                    children: [
                      TextSpan(text: '每轮可使用一次'),
                      TextSpan(
                        text: '特权',
                        style: TextStyle(
                          color: Color(0xFFFF90CA),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: '（+30秒或跳过这道题）'),
                    ],
                  ),
                ),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                    children: [
                      TextSpan(text: '每道题可使用一次'),
                      TextSpan(
                        text: '提示请求',
                        style: TextStyle(
                          color: Color(0xFFFF6B00),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildBottomArea() {
    final isGuesser = gs.myRole == GameRole.guesser;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? 8
            : MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 猜题者：特权和提示按钮
          if (isGuesser)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: Icons.flash_on,
                    label: '使用特权${gs.privilegeCount}次',
                    color: const Color(0xFFFFD700),
                    onTap: () {
                      setState(() => _showPrivilegePopup = !_showPrivilegePopup);
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.lightbulb_outline,
                    label: '提示请求${gs.hintRequestCount}次',
                    color: const Color(0xFFFF6B00),
                    onTap: gs.hintRequestedThisQuestion
                        ? null
                        : () => gs.requestHint(),
                  ),
                ],
              ),
            ),

          // 输入框 + 发送按钮
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: isGuesser
                          ? '输入你的答案'
                          : '描述词不能包含答案任一个字',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFCCCCCC),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                    onSubmitted: (_) => _onSend(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _onSend,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF90CA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      isGuesser ? '发送答案' : '发送',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDisabled
              ? const Color(0xFFF5F5F5)
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDisabled ? const Color(0xFFE0E0E0) : color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isDisabled ? const Color(0xFFCCCCCC) : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDisabled ? const Color(0xFFCCCCCC) : const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSend() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    if (gs.myRole == GameRole.guesser) {
      gs.submitAnswer(text);
    } else {
      gs.sendDescription(text);
    }
    _inputController.clear();
  }

  void _showExitConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出游戏'),
        content: const Text('游戏正在进行中，确定要退出吗？'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('继续', style: TextStyle(color: Color(0xFFFF90CA))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await gs.exitGame();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('退出', style: TextStyle(color: Color(0xFF999999))),
          ),
        ],
      ),
    );
  }
}
