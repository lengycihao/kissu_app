import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/game_play_controller.dart';
import 'models/game_models.dart';
import 'widgets/privilege_popup.dart';
import 'widgets/answer_dialog.dart';

/// 你说我猜V2 游戏进行页面
class GamePlayPage extends GetView<GamePlayController> {
  const GamePlayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog(context);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: !controller.isAnswerDialogOpen.value,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/say_guess/kissu_say_guess_bg.webp'),
                alignment: AlignmentGeometry.topCenter,
              ),
              color: Colors.white,
            ),
            child: SafeArea(
              child: Obx(
              () => Stack(
                children: [
                  Column(
                    children: [
                      _buildAppBar(context),
                      const SizedBox(height: 4),
                      _buildProgressBar(),
                      // 键盘弹起时平滑折叠电视机，聊天区自动扩张
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        child: MediaQuery.of(context).viewInsets.bottom > 0 &&
                              !controller.isAnswerDialogOpen.value
                            ? const SizedBox.shrink()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: _buildTvArea(),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                      ),
                      Expanded(child: _buildChatArea()),
                      _buildBottomArea(context),
                    ],
                  ),
                  // 特权弹窗
                  if (controller.showPrivilegePopup.value)
                    PrivilegePopupV2(
                      remainingCount: controller.privilegeCount.value,
                      onExtraAttempt: () =>
                          controller.usePrivilegeExtraAttempt(),
                      onSkip: () => controller.usePrivilegeSkip(),
                      onDismiss: () =>
                          controller.showPrivilegePopup.value = false,
                    ),
                  // 提示字选择弹窗（出题者用）
                  if (controller.waitingForHintSelection.value &&
                      controller.isInitiator)
                    _buildHintSelectionPopup(),
                  // // 结果动画覆盖层
                  // if (controller.showResultAnimation.value)
                  //   _buildResultOverlay(),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 2,
      ).copyWith(left: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showExitDialog(context),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Image.asset(
                "assets/images/kissu_mine_back.webp",
                width: 22,
                height: 22,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Image(
                image: AssetImage(
                  'assets/say_guess/kissu_say_guess_title.webp',
                ),
                width: 102,
                height: 24,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showRulesDialog(context),
            child: Align(
              alignment: AlignmentGeometry.topRight,
              child: Image(
                image: AssetImage('assets/say_guess/kissu_say_guess_tips.webp'),
                width: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 进度条：答对绿色、答错红色、未答灰色
  Widget _buildProgressBar() {
    return Obx(() {
      final idx = controller.currentIndex.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "本轮进度  ${idx + 1}/",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: "5",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFaaaaaa),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),
            Row(
              children: List.generate(5, (i) {
                Color color;
                final status = i < controller.questionStatuses.length
                    ? controller.questionStatuses[i]
                    : QuestionStatus.pending;
                switch (status) {
                  case QuestionStatus.correct:
                    color = const Color(0xFF4CAF50);
                    break;
                  case QuestionStatus.wrong:
                    color = const Color(0xFFFF4444);
                    break;
                  case QuestionStatus.skipped:
                    color = const Color(0xFFFF9800);
                    break;
                  case QuestionStatus.pending:
                    color = const Color(0xFFffffff);
                    break;
                }
                return Container(
                  height: 6,
                  width: 15,
                  margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  /// 电视机展示区
  Widget _buildTvArea() {
    return Obx(() {
      final topic = controller.currentTopic;
      final hint = controller.currentHint.value;

      // 出题者看答案，答题者看提示词或???
      final displayText = controller.isInitiator
          ? (topic?.answer ?? '???')
          : (hint != null ? '提示字：$hint' : '???');
      final descText = topic?.description ?? '';

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: 200,
            // constraints: const BoxConstraints(minHeight: 150),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/say_guess/kissu_say_guess_tv.webp'),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                // 接收方显示剩余答题次数
                if (!controller.isInitiator) ...[
                  Text(
                    '剩余答题次数：${controller.maxAttempts.value - controller.wrongAttempts.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF9AD9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                // 主显示内容
                Text(
                  displayText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                if (descText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E0FF).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '描述词:$descText',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }

  /// 聊天区域
  Widget _buildChatArea() {
    return Obx(() {
      final msgs = controller.messages;
      return Align(
        alignment: Alignment.topCenter,
        child: ListView.builder(
          controller: controller.scrollController,
          reverse: true,
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          itemCount: msgs.length,
          itemBuilder: (context, index) {
            final msg = msgs[msgs.length - 1 - index];
            if (msg.type == GameChatMessageType.system) {
              return _buildSystemMsg(msg);
            }
            return _buildChatBubble(msg);
          },
        ),
      );
    });
  }

  Widget _buildSystemMsg(GameChatMessage msg) {
    // 特殊处理：回答者提示消息（包含关键词高亮）
    if (msg.content.contains('特权') && msg.content.contains('提示请求')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text.rich(
            textAlign: TextAlign.center,
            TextSpan(
              style: const TextStyle(fontSize: 11, height: 1.5),
              children: _buildHighlightedTextSpans(msg.content),
            ),
          ),
        ),
      );
    }

    // 普通系统消息
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            msg.content,
            style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(GameChatMessage msg) {
    final isAnswer = msg.type == GameChatMessageType.answer;
    final isHintReq = msg.type == GameChatMessageType.hintRequest;
    final isHintResp = msg.type == GameChatMessageType.hintResponse;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: msg.isSelf
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isSelf) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE8E8E8),
              backgroundImage: msg.senderAvatar.isNotEmpty
                  ? NetworkImage(msg.senderAvatar)
                  : null,
              child: msg.senderAvatar.isEmpty
                  ? Text(
                      msg.senderName.isNotEmpty ? msg.senderName[0] : '?',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 57,
                minHeight: 50,
                maxWidth: 230,
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      msg.isSelf
                          ? 'assets/chat/kissu_chat_bubble_self_1.webp'
                          : 'assets/chat/kissu_chat_bubble_other_1.webp',
                      fit: BoxFit.fill,
                      centerSlice: const Rect.fromLTRB(23, 28, 30, 30),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ).copyWith(bottom: 8, top: 20),
                    child: Text(
                      msg.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: isHintReq || isHintResp
                            ? const Color(0xFFFF6A68)
                            : isAnswer
                            ? const Color(0xFFFF6B00)
                            : const Color(0xFF333333),
                        fontWeight: (isAnswer || isHintReq || isHintResp)
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (msg.isSelf) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFFFD4E5),
              backgroundImage: msg.senderAvatar.isNotEmpty
                  ? NetworkImage(msg.senderAvatar)
                  : null,
              child: msg.senderAvatar.isEmpty
                  ? Text(
                      msg.senderName.isNotEmpty ? msg.senderName[0] : '?',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF90CA),
                      ),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  /// 底部操作区：特权/提示按钮 + 答案按钮 + 输入框 + 发送按钮
  Widget _buildBottomArea(BuildContext context) {
    final isGuesser = !controller.isInitiator; // 接收方=答题者（不变，plain bool）

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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 答题者：特权/提示按钮（包含observable，用Obx单独包裹）
          if (isGuesser)
            Obx(() => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  _buildActionBtn(
                    icon: 'assets/say_guess/kissu_say_guess_hat.webp',
                    label: '使用特权${controller.privilegeCount.value}次',
                    color: const Color(0xFFF9E2FF),
                    onTap: controller.privilegeCount.value > 0
                        ? () => controller.showPrivilegePopup.value = true
                        : null,
                  ),
                  const SizedBox(width: 8),
                  _buildActionBtn(
                    icon: 'assets/say_guess/kissu_say_guess_light.webp',
                    label: '提示请求${controller.hintRequestedThisQ.value ? 0 : 1}次',
                    color: const Color(0xFFDCF0FF),
                    onTap: controller.hintRequestedThisQ.value
                        ? null
                        : () => controller.requestHint(),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showAnswerDialog(context),
                    child: Container(
                      height: 28,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: const Center(
                        child: Text(
                          '填写答案',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFffffff),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),

          // 聊天输入框（发送按钮在内部）
          _buildInputRow(),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFF000000)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.inputController,
              decoration: const InputDecoration(
                hintText: '输入消息内容...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFFCCCCCC)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
              onSubmitted: (text) {
                _handleSendChat(text);
                controller.inputController.clear();
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              _handleSendChat(controller.inputController.text);
              controller.inputController.clear();
            },
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: const Text(
                '发送',
                style: TextStyle(color: Color(0xFF000000), fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSendChat(String text) {
    if (text.trim().isEmpty) return;
    controller.sendChatText(text);
  }

  void _showAnswerDialog(BuildContext context) {
    controller.isAnswerDialogOpen.value = true;
    showDialog(
      context: context,
      builder: (ctx) => AnswerDialog(
        remainingAttempts: controller.maxAttempts.value - controller.wrongAttempts.value,
        onSubmit: (answer) => controller.submitAnswer(answer),
      ),
    ).then((_) {
      controller.isAnswerDialogOpen.value = false;
      FocusScope.of(context).unfocus();
    });
  }

  Widget _buildActionBtn({
    required String icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            height: 28,
            decoration: BoxDecoration(
              color: disabled ? const Color(0xFFF5F5F5) : color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 25),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: disabled
                        ? const Color(0xFFCCCCCC)
                        : const Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: Offset(0, -5),
            child: Image(image: AssetImage(icon), width: 30, height: 30),
          ),
        ],
      ),
    );
  }

  /// 结果动画覆盖层
  Widget _buildResultOverlay() {
    final isSuccess = controller.resultAnimationType.value == 1;
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/say_guess/kissu_say_guess_failed.webp',
                width: 160,
                height: 160,
                errorBuilder: (_, __, ___) => Icon(
                  isSuccess ? Icons.check_circle : Icons.cancel,
                  size: 80,
                  color: isSuccess
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF4444),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSuccess ? '挑战成功！' : '挑战失败',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 提示字选择弹窗（出题者用）
  Widget _buildHintSelectionPopup() {
    final topic = controller.currentTopic;
    if (topic == null) return const SizedBox.shrink();

    final chars = topic.answerChars;
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {}, // 阻止穿透
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '选择一个字作为提示',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(chars.length, (i) {
                      return GestureDetector(
                        onTap: () => controller.sendHintChar(i),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFF90CA)),
                          ),
                          child: Center(
                            child: Text(
                              chars[i],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建高亮文本片段（用于系统提示消息）
  List<TextSpan> _buildHighlightedTextSpans(String text) {
    final List<TextSpan> spans = [];
    final keywords = ['特权', '提示请求'];

    int lastIndex = 0;
    for (final keyword in keywords) {
      final index = text.indexOf(keyword, lastIndex);
      if (index != -1) {
        // 添加关键词前的普通文本
        if (index > lastIndex) {
          spans.add(
            TextSpan(
              text: text.substring(lastIndex, index),
              style: const TextStyle(color: Color(0xFFaaaaaa), fontSize: 11),
            ),
          );
        }
        // 添加高亮关键词
        spans.add(
          TextSpan(
            text: keyword,
            style: const TextStyle(
              color: Color(0xFFFFA9E0),
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        );
        lastIndex = index + keyword.length;
      }
    }

    // 添加剩余的普通文本
    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: const TextStyle(color: Color(0xFFaaaaaa), fontSize: 11),
        ),
      );
    }

    return spans;
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Center(
        child: Container(
          width: 270,
          height: 145,
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/dialog/kissu4_dialog_small_bg.webp'),
              fit: BoxFit.fill,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '确定要退出游戏吗？',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Get.back();
                    },
                    child: Container(
                      width: 106,
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF999999), width: 1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          '确认',
                          style: TextStyle(fontSize: 14, color: Color(0xFF999999), decoration: TextDecoration.none),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      width: 106,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(0xffFFA9E0),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          '继续游戏',
                          style: TextStyle(fontSize: 14, color: Color(0xFFffffff), decoration: TextDecoration.none),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRulesDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text(
                    '游戏规则',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff333333),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    physics: const BouncingScrollPhysics(),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: '基本规则\n',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xff333333),
                              fontWeight: FontWeight.w500,
                              height: 2.5,
                            ),
                          ),
                          const TextSpan(
                            text:
                                '每轮游戏由5道题组成，支持发起者自定义题目和描述\n'
                                '每轮游戏通过定义：每轮总答题数≥3题即通过本轮\n'
                                '游戏组合难度采用逐轮进行制，通过一轮+1⭐，每轮全部答对+2⭐（不含特权跳过的），由简单到难；难度逐步增加；如失败下次进入游戏仍为上次停留难度，成功下次进入为下一轮难度\n'
                                '\n'
                                '本次游戏支持双人/单人模式，单人模式即一方出完题，另一方根据已出题的描述语进行猜题\n',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xff777777),
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                         
                          const TextSpan(
                            text: '游戏玩法\n',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xff333333),
                              fontWeight: FontWeight.w500,
                              height: 2.5,
                            ),
                          ),
                          const TextSpan(
                            text:
                                '我要猜一方根据对方的描述进行回答，每道题有4次答案提交机会（聊天不占用机会），到指定次数仍未答对则本题失败，自动进入下一题；每道题可使用一次提示'
                                '每轮可使用一次特权，可选择直接跳过本题（按答对计算）或增加一次答题机会\n'
                                '每轮失败即进入情侣惩罚，描述者可选择不同惩罚给猜题者完成，需线下完成的会产生二维码，需双方线下扫码核验\n',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xff777777),
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 8,
              top: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/lock/kissu_lock_close.webp',
                    width: 16,
                    height: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
