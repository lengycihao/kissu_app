import 'package:flutter/material.dart';
import '../models/game_models.dart';

/// 游戏内聊天消息气泡
class GameChatBubble extends StatelessWidget {
  final GameChatMessage message;
  // 出题者端：是否显示答案拆字选择器（仅在收到对方的提示请求时显示）
  final bool showAnswerChars;
  // 答案拆解后的字符列表（出题者端使用）
  final List<String>? answerChars;
  // 出题者选择提示字的回调
  final ValueChanged<int>? onHintCharSelected;

  const GameChatBubble({
    super.key,
    required this.message,
    this.showAnswerChars = false,
    this.answerChars,
    this.onHintCharSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 系统消息居中
    if (message.type == GameChatMessageType.system) {
      return _buildSystemMessage();
    }

    // 提示请求（红色字体 + 可选的答案拆字选择器）
    if (message.type == GameChatMessageType.hintRequest) {
      return _buildHintRequestMessage();
    }

    // 提示回复
    if (message.type == GameChatMessageType.hintResponse) {
      return _buildHintResponseMessage();
    }

    // 普通消息和答案消息
    return _buildNormalMessage(context);
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF999999),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHintRequestMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        crossAxisAlignment: message.isSelf
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // 请求提示气泡
          Row(
            mainAxisAlignment:
                message.isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isSelf) ...[
                _buildAvatar(),
                const SizedBox(width: 8),
              ],
              Container(
                constraints: const BoxConstraints(maxWidth: 230),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: message.isSelf
                      ? const Color(0xFFFFE4E9)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '请求提示',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFFF6A68),
                   ),
                ),
              ),
              if (message.isSelf) ...[
                const SizedBox(width: 8),
                _buildAvatar(),
              ],
            ],
          ),

          // 出题者端：对方请求提示时，在消息下方显示答案拆字选择器
          if (showAnswerChars && answerChars != null && !message.isSelf)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 答案拆字圆圈
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(answerChars!.length, (index) {
                      return GestureDetector(
                        onTap: () => onHintCharSelected?.call(index),
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E0FF),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF8B5CF6),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              answerChars![index],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '选择提示字给对方',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHintResponseMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            message.isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isSelf) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: const BoxConstraints(maxWidth: 230),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: message.isSelf
                  ? const Color(0xFFFFE4E9)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (message.isSelf) ...[
            const SizedBox(width: 8),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildNormalMessage(BuildContext context) {
    final isAnswer = message.type == GameChatMessageType.answer;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            message.isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isSelf) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 230, minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.isSelf
                    ? const Color(0xFFFFE4E9)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(message.isSelf ? 12 : 2),
                  bottomRight: Radius.circular(message.isSelf ? 2 : 12),
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isAnswer
                      ? const Color(0xFFFF6B00)
                      : const Color(0xFF333333),
                  fontWeight: isAnswer ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
          if (message.isSelf) ...[
            const SizedBox(width: 8),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: message.isSelf
            ? const Color(0xFFFFD4E5)
            : const Color(0xFFE8E8E8),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          message.senderName.isNotEmpty ? message.senderName[0] : '?',
          style: TextStyle(
            fontSize: 14,
            color: message.isSelf
                ? const Color(0xFFFF90CA)
                : const Color(0xFF999999),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
