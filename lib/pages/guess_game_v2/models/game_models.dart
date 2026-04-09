/// ==================== 游戏阶段 ====================
enum GamePhase {
  home,            // 首页（开始游戏+历史记录）
  topicSelection,  // 选题
  playing,         // 游戏进行中
  result,          // 游戏结果
}

/// ==================== 题目状态 ====================
enum QuestionStatus {
  pending,   // 待回答
  correct,   // 回答正确
  wrong,     // 回答错误
  skipped,   // 跳过
}

/// ==================== 聊天消息模式 ====================
enum InputMode {
  answer,  // 发送答案
  chat,    // 聊天
}

/// ==================== 游戏题目 ====================
class GameTopic {
  final String answer;       // 答案
  final String description;  // 描述词（展示在电视机上）
  final bool isCustom;       // 是否自定义题目
  QuestionStatus status;
  int wrongAttempts;          // 错误次数（最多4次）

  GameTopic({
    required this.answer,
    this.description = '',
    this.isCustom = false,
    this.status = QuestionStatus.pending,
    this.wrongAttempts = 0,
  });

  /// 答案拆分为单字（用于提示）
  List<String> get answerChars => answer.split('');

  GameTopic copyWith({
    String? answer,
    String? description,
    bool? isCustom,
    QuestionStatus? status,
    int? wrongAttempts,
  }) {
    return GameTopic(
      answer: answer ?? this.answer,
      description: description ?? this.description,
      isCustom: isCustom ?? this.isCustom,
      status: status ?? this.status,
      wrongAttempts: wrongAttempts ?? this.wrongAttempts,
    );
  }
}

/// ==================== 游戏记录（历史列表用） ====================
class GameRecord {
  final String id;          // 记录ID（也是groupId）
  final String groupId;     // 群聊ID
  final String initiator;   // 发起者名称
  final String initiatorId; // 发起者ID
  final DateTime createTime;
  final GameRecordStatus status;
  final int correctCount;   // 答对题数
  final bool isMeInitiator; // 是否是我发起的

  GameRecord({
    required this.id,
    required this.groupId,
    required this.initiator,
    required this.initiatorId,
    required this.createTime,
    this.status = GameRecordStatus.ongoing,
    this.correctCount = 0,
    this.isMeInitiator = true,
  });
}

enum GameRecordStatus {
  ongoing,   // 进行中（该我回答/该Ta回答）
  passed,    // 通过
  failed,    // 失败
}

/// ==================== 游戏内聊天消息 ====================
class GameChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final DateTime time;
  final bool isSelf;
  final GameChatMessageType type;
  final Map<String, dynamic>? extra;

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
  text,           // 普通聊天文字 (game_text)
  answer,         // 发送答案 (game_answer)
  hintRequest,    // 请求提示
  hintResponse,   // 提示回复
  system,         // 系统消息（居中）
  joined,         // 进入房间
  away,           // 离开房间
  answerState,    // 答题状态 (game_answer_state)
  gameResult,     // 游戏结果 (game_result)
}

/// ==================== 惩罚记录（惩罚列表用） ====================
class GamePenaltyRecordItem {
  final String id;
  final int status;        // 游戏状态
  final int isPenalty;     // 0=未完成 1=已完成
  final int penaltyType;   // 1=自拍 2=语音 3=吃饭 4=承诺
  final String verifyQrCode;
  final String penaltyFile;
  final DateTime createTime;
  final String createTimeRaw;

  GamePenaltyRecordItem({
    required this.id,
    required this.status,
    required this.isPenalty,
    required this.penaltyType,
    required this.verifyQrCode,
    required this.penaltyFile,
    required this.createTime,
    required this.createTimeRaw,
  });
}

class GamePenaltyListResult {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final bool hasMore;
  final List<GamePenaltyRecordItem> records;

  GamePenaltyListResult({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.hasMore,
    required this.records,
  });
}

/// ==================== 候选题目（选题页面用） ====================
class CandidateTopic {
  final String answer;
  final String description;
  bool isSelected;

  CandidateTopic({
    required this.answer,
    this.description = '',
    this.isSelected = false,
  });
}
