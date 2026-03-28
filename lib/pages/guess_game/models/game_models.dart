/// 游戏阶段
enum GamePhase {
  lobby,          // 大厅等待
  roleSelection,  // 角色选择
  countdown,      // 倒计时 3-2-1
  playing,        // 游戏进行中
  roundResult,    // 单题结果
  gameResult,     // 游戏结束结算
}

/// 游戏角色
enum GameRole {
  describer,  // 出题者/描述者
  guesser,    // 猜题者
}

/// 题目状态
enum QuestionStatus {
  pending,    // 待回答
  correct,    // 回答正确
  wrong,      // 回答错误
  skipped,    // 跳过
  timeout,    // 超时
}

/// 游戏房间
class GameRoom {
  final String roomId;
  final String groupId;        // 群聊ID
  final GamePlayer host;       // 房主
  final GamePlayer? guest;     // 被邀请者
  final bool isHostReady;
  final bool isGuestReady;
  final int totalScore;        // 历史得分
  final int ranking;           // 排名
  final int weeklyCleared;     // 本周通关轮数

  GameRoom({
    required this.roomId,
    required this.groupId,
    required this.host,
    this.guest,
    this.isHostReady = true,
    this.isGuestReady = false,
    this.totalScore = 0,
    this.ranking = 10000,
    this.weeklyCleared = 0,
  });

  GameRoom copyWith({
    String? roomId,
    String? groupId,
    GamePlayer? host,
    GamePlayer? guest,
    bool? isHostReady,
    bool? isGuestReady,
    int? totalScore,
    int? ranking,
    int? weeklyCleared,
  }) {
    return GameRoom(
      roomId: roomId ?? this.roomId,
      groupId: groupId ?? this.groupId,
      host: host ?? this.host,
      guest: guest ?? this.guest,
      isHostReady: isHostReady ?? this.isHostReady,
      isGuestReady: isGuestReady ?? this.isGuestReady,
      totalScore: totalScore ?? this.totalScore,
      ranking: ranking ?? this.ranking,
      weeklyCleared: weeklyCleared ?? this.weeklyCleared,
    );
  }

  bool get bothReady => isHostReady && isGuestReady && guest != null;
}

/// 玩家信息
class GamePlayer {
  final String userId;
  final String nickname;
  final String avatarUrl;
  final GameRole? role;

  GamePlayer({
    required this.userId,
    required this.nickname,
    this.avatarUrl = '',
    this.role,
  });

  GamePlayer copyWith({
    String? userId,
    String? nickname,
    String? avatarUrl,
    GameRole? role,
  }) {
    return GamePlayer(
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
    );
  }
}

/// 游戏题目
class GameQuestion {
  final int index;             // 题目序号 0-4
  final String answer;         // 答案
  final String? category;      // 分类
  final bool isCustom;         // 是否自定义题目（第5题可选）
  final QuestionStatus status;
  final List<String> answerChars; // 答案拆分为单字（用于提示）

  GameQuestion({
    required this.index,
    required this.answer,
    this.category,
    this.isCustom = false,
    this.status = QuestionStatus.pending,
    List<String>? answerChars,
  }) : answerChars = answerChars ?? answer.split('');

  GameQuestion copyWith({
    int? index,
    String? answer,
    String? category,
    bool? isCustom,
    QuestionStatus? status,
    List<String>? answerChars,
  }) {
    return GameQuestion(
      index: index ?? this.index,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      isCustom: isCustom ?? this.isCustom,
      status: status ?? this.status,
      answerChars: answerChars ?? this.answerChars,
    );
  }
}

/// 游戏内聊天消息
class GameChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final DateTime time;
  final bool isSelf;
  final GameChatMessageType type;
  final Map<String, dynamic>? extra; // 扩展字段

  GameChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar = '',
    required this.content,
    required this.time,
    required this.isSelf,
    this.type = GameChatMessageType.text,
    this.extra,
  });
}

/// 游戏聊天消息类型
enum GameChatMessageType {
  text,           // 普通文字
  hintRequest,    // 请求提示（红色字体）
  hintResponse,   // 提示回复（含拆字）
  system,         // 系统消息（居中）
  answer,         // 发送答案
}

/// 游戏轮次结果
class GameRoundResult {
  final List<GameQuestion> questions;
  final int correctCount;
  final int totalScore;

  GameRoundResult({
    required this.questions,
    required this.correctCount,
    required this.totalScore,
  });
}
