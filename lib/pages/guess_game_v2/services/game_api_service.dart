import 'dart:convert';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/public/api_request.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import '../models/game_models.dart';

/// 你说我猜游戏 API 服务
class GameApiService {
  static const String _tag = 'GameApiService';

  // ===== 1. 历史记录列表 =====

  /// 获取历史记录列表
  /// [isOneself] 1=我发起的 0=Ta发起的
  /// [page] 页码，默认1
  /// [pageSize] 每页条数，默认20
  Future<GameRecordListResult?> getRecordList({
    required int isOneself,
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.guessRecordList,
      queryParam: {
        'is_oneself': isOneself,
        'page': page,
        'page_size': pageSize,
      },
    );

    if (!result.isSuccess) {
      logger.error('获取历史记录失败: ${result.msg}', tag: _tag);
      return null;
    }

    try {
      final data = result.getDataJson();

      final rankData = data['rank_data'] as Map<String, dynamic>? ?? {};
      final ranking = rankData['ranking']?.toString() ?? '10000+';
      final starNums = (rankData['star_nums'] as num?)?.toInt() ?? 0;

      final rawAnswerData = data['answer_data'] as List<dynamic>? ?? [];
      final answerData = rawAnswerData.map((e) {
        final item = e as Map<String, dynamic>;
        return CandidateTopic(
          answer: item['answer'] as String? ?? '',
          description: item['desc'] as String? ?? '',
        );
      }).toList();

      final rawList = data['data'] as List<dynamic>? ?? [];
      final records = rawList.map((e) {
        final item = e as Map<String, dynamic>;
        final statusInt = (item['status'] as num?)?.toInt() ?? 1;
        GameRecordStatus status;
        switch (statusInt) {
          case 0:
            status = GameRecordStatus.failed;
            break;
          case 2:
            status = GameRecordStatus.passed;
            break;
          default:
            status = GameRecordStatus.ongoing;
        }

        final rawAnswers = item['answer'] as List<dynamic>? ?? [];
        final correctCount =
            rawAnswers.where((a) => (a as Map)['status'] == 2).length;

        DateTime createTime;
        try {
          createTime = DateTime.parse(
            (item['create_time'] as String).replaceAll(' ', 'T'),
          );
        } catch (_) {
          createTime = DateTime.now();
        }

        return GameRecord(
          id: item['_id'] as String? ?? '',
          groupId: item['_id'] as String? ?? '',
          initiator: '',
          initiatorId: '',
          createTime: createTime,
          status: status,
          correctCount: correctCount,
          isMeInitiator: isOneself == 1,
        );
      }).toList();

      final hasMore = data['has_more'] as bool? ?? false;
      final total = (data['total'] as num?)?.toInt() ?? 0;

      return GameRecordListResult(
        records: records,
        answerData: answerData,
        ranking: ranking,
        starNums: starNums,
        hasMore: hasMore,
        total: total,
      );
    } catch (e) {
      logger.error('解析历史记录失败: $e', tag: _tag);
      return null;
    }
  }

  // ===== 1.1 惩罚记录列表 =====

  /// 获取惩罚记录列表
  /// [isOneself] 1=我的惩罚 0=Ta的惩罚
  Future<GamePenaltyListResult?> getPenaltyList({
    required int isOneself,
    int page = 1,
    int pageSize = 10,
  }) async {
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.guessPenaltyList,
      queryParam: {
        'is_oneself': isOneself,
        'page': page,
        'page_size': pageSize,
      },
    );

    if (!result.isSuccess) {
      logger.error('获取惩罚记录失败: ${result.msg}', tag: _tag);
      return null;
    }

    try {
      final data = result.getDataJson();

      final total = (data['total'] as num?)?.toInt() ?? 0;
      final perPage = (data['per_page'] as num?)?.toInt() ?? pageSize;
      final currentPage = (data['current_page'] as num?)?.toInt() ?? page;
      final lastPage = (data['last_page'] as num?)?.toInt() ?? currentPage;
      final hasMore = data['has_more'] as bool? ?? false;

      final rawList = data['data'] as List<dynamic>? ?? [];
      final records = rawList.map((e) {
        final item = e as Map<String, dynamic>;

        DateTime createTime;
        try {
          createTime = DateTime.parse(
            (item['create_time'] as String? ?? '').replaceAll(' ', 'T'),
          );
        } catch (_) {
          createTime = DateTime.now();
        }

        return GamePenaltyRecordItem(
          id: item['_id'] as String? ?? '',
          status: (item['status'] as num?)?.toInt() ?? 0,
          isPenalty: (item['is_penalty'] as num?)?.toInt() ?? 0,
          penaltyType: (item['penalty_type'] as num?)?.toInt() ?? 0,
          verifyQrCode: item['verify_qr_code'] as String? ?? '',
          penaltyFile: item['penalty_file'] as String? ?? '',
          createTime: createTime,
          createTimeRaw: item['create_time'] as String? ?? '',
        );
      }).toList();

      return GamePenaltyListResult(
        total: total,
        perPage: perPage,
        currentPage: currentPage,
        lastPage: lastPage,
        hasMore: hasMore,
        records: records,
      );
    } catch (e) {
      logger.error('解析惩罚记录失败: $e', tag: _tag);
      return null;
    }
  }

  // ===== 2. 发起游戏 =====

  /// 发起游戏，返回 group_id（服务端生成的群聊ID）
  Future<String?> launchGame(List<CandidateTopic> topics) async {
    final answerList = topics
        .map((t) => {'answer': t.answer, 'desc': t.description})
        .toList();

    final result = await HttpManagerN.instance.executePost(
      ApiRequest.guessLaunchGame,
      jsonParam: {'answer': jsonEncode(answerList)},
    );

    if (!result.isSuccess) {
      logger.error('发起游戏失败: ${result.msg}', tag: _tag);
      return null;
    }

    try {
      final data = result.getDataJson();
      final groupId = data['group_id'] as String?;
      if (groupId == null || groupId.isEmpty) {
        logger.error('发起游戏返回的group_id为空', tag: _tag);
        return null;
      }
      logger.debug('✅ 游戏发起成功 group_id=$groupId', tag: _tag);
      return groupId;
    } catch (e) {
      logger.error('解析发起游戏响应失败: $e', tag: _tag);
      return null;
    }
  }

  // ===== 3. 对局详情（同步用） =====

  /// 获取对局详情，用于同步游戏状态
  /// 内置重试机制：失败时最多重试2次（共3次），每次间隔500ms
  Future<GameInfoResult?> getGameInfo(String groupId) async {
    const maxRetries = 2;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      if (attempt > 0) {
        logger.debug('获取对局详情第${attempt + 1}次重试...', tag: _tag);
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final result = await HttpManagerN.instance.executeGet(
        ApiRequest.guessGetInfo,
        queryParam: {'group_id': groupId},
      );

      if (!result.isSuccess) {
        logger.error('获取对局详情失败(第${attempt + 1}次): ${result.msg}', tag: _tag);
        if (attempt < maxRetries) continue;
        return null;
      }

      try {
        final data = result.getDataJson();
        final answerStage = (data['answer_stage'] as num?)?.toInt() ?? 1;
        final statusInt = (data['status'] as num?)?.toInt() ?? 1;
        final isUsePrivilege = ((data['is_use_privilege'] as num?)?.toInt() ?? 0) == 1;

        final rawAnswers = data['answer'] as List<dynamic>? ?? [];
        final answers = rawAnswers.map((e) {
          final item = e as Map<String, dynamic>;
          return GameAnswerInfo(
            answer: item['answer'] as String? ?? '',
            desc: item['desc'] as String? ?? '',
            status: (item['status'] as num?)?.toInt() ?? 1,
            isUseHint: ((item['is_use_hint'] as num?)?.toInt() ?? 0) == 1,
            answerNums: (item['answer_nums'] as num?)?.toInt() ?? 0,
            limitAnswerNums: (item['limit_answer_nums'] as num?)?.toInt() ?? 4,
          );
        }).toList();

        final correctAnswerNums = (data['correct_answer_nums'] as num?)?.toInt() ?? 0;
        final tacitPercent = data['tacit_percent']?.toString() ?? '0%';
        final starNums = (data['star_nums'] as num?)?.toInt() ?? 0;

        return GameInfoResult(
          answerStage: answerStage,
          status: statusInt,
          isUsePrivilege: isUsePrivilege,
          answers: answers,
          correctAnswerNums: correctAnswerNums,
          tacitPercent: tacitPercent,
          starNums: starNums,
        );
      } catch (e) {
        logger.error('解析对局详情失败(第${attempt + 1}次): $e', tag: _tag);
        if (attempt < maxRetries) continue;
        return null;
      }
    }
    return null;
  }

  // ===== 4. 请求提示 =====

  /// 发起提示请求（接口成功后再发IM消息通知对方）
  Future<bool> requestHint(String groupId) async {
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.guessRequestHint,
      jsonParam: {'group_id': groupId},
    );
    if (!result.isSuccess) {
      logger.error('请求提示失败: ${result.msg}', tag: _tag);
    }
    return result.isSuccess;
  }

  // ===== 5. 使用特权 =====

  /// 使用特权
  /// [privilegeType] 1=跳过本题 2=增加答题次数，默认1
  Future<bool> usePrivilege(String groupId, {int privilegeType = 1}) async {
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.guessUsePrivilege,
      jsonParam: {'group_id': groupId, 'privilege_type': privilegeType},
    );
    if (!result.isSuccess) {
      logger.error('使用特权失败: ${result.msg}', tag: _tag);
    }
    return result.isSuccess;
  }

  // ===== 6. 选择惩罚方式 =====

  /// a 为 b 选择惩罚方式（仅选择，不含凭证上传）
  /// [groupId] 对局ID
  /// [penaltyType] 1=自拍 2=语音 3=吃饭 4=承诺
  Future<bool> selectPenalty({
    required String groupId,
    required int penaltyType,
  }) async {
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.guessSelectPenalty,
      jsonParam: {
        'group_id': groupId,
        'penalty_type': penaltyType,
      },
    );
    if (!result.isSuccess) {
      logger.error('选择惩罚失败: ${result.msg}', tag: _tag);
    }
    return result.isSuccess;
  }

  // ===== 7. 核验惩罚（上传凭证） =====

  /// 核验惩罚，上传惩罚凭证
  /// [groupId] 对局ID
  /// [penaltyFile] penalty_type=1时传图片URL，=2时传音频URL；晚餐/许诺扫码核验时可不传
  Future<bool> verifyPenalty({
    required String groupId,
    String? penaltyFile,
  }) async {
    final params = <String, dynamic>{'group_id': groupId};
    if (penaltyFile != null && penaltyFile.isNotEmpty) {
      params['penalty_file'] = penaltyFile;
    }
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.guessVerifyPenalty,
      jsonParam: params,
    );
    if (!result.isSuccess) {
      logger.error('核验惩罚失败: ${result.msg}', tag: _tag);
    }
    return result.isSuccess;
  }

  // ===== 7. 回答问题 =====

  /// 提交答案（接口成功后再发IM消息通知对方）
  Future<bool> submitAnswer(String groupId, String answer) async {
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.guessSubmitAnswer,
      jsonParam: {'group_id': groupId, 'answer': answer},
    );
    if (!result.isSuccess) {
      logger.error('提交答案失败: ${result.msg}', tag: _tag);
    }
    return result.isSuccess;
  }
}

// ===== 返回数据结构 =====

class GameRecordListResult {
  final List<GameRecord> records;
  final List<CandidateTopic> answerData;
  final String ranking;
  final int starNums;
  final bool hasMore;
  final int total;

  GameRecordListResult({
    required this.records,
    required this.answerData,
    required this.ranking,
    required this.starNums,
    required this.hasMore,
    required this.total,
  });
}

class GameInfoResult {
  final int answerStage;       // 当前第几题（1-based）
  final int status;            // 0=失败 1=进行中 2=成功
  final bool isUsePrivilege;
  final List<GameAnswerInfo> answers;
  final int correctAnswerNums; // 回答正确的数量
  final String tacitPercent;   // 默契度（如 "80%"）
  final int starNums;          // 星星数量

  GameInfoResult({
    required this.answerStage,
    required this.status,
    required this.isUsePrivilege,
    required this.answers,
    this.correctAnswerNums = 0,
    this.tacitPercent = '0%',
    this.starNums = 0,
  });
}

class GameAnswerInfo {
  final String answer;
  final String desc;
  final int status;          // 0=未完成/失败 1=进行中 2=成功
  final bool isUseHint;
  final int answerNums;      // 当前已回答次数
  final int limitAnswerNums; // 每题最大回答次数

  /// 剩余回答次数
  int get remainingAttempts => (limitAnswerNums - answerNums).clamp(0, limitAnswerNums);

  GameAnswerInfo({
    required this.answer,
    required this.desc,
    required this.status,
    required this.isUseHint,
    required this.answerNums,
    this.limitAnswerNums = 4,
  });
}
