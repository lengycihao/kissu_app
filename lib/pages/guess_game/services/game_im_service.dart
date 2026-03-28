import 'dart:async';
import 'dart:convert';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_type.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_member_role_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimAdvancedMsgListener.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member.dart';
import 'package:kissu_app/services/tencent_im_service.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

/// 你说我猜游戏 IM 服务
/// 负责真实的群聊创建/销毁、游戏自定义消息收发
class GameIMService {
  static const String _tag = 'GameIMService';

  // 当前游戏群ID
  String? _groupID;
  String? get groupID => _groupID;

  // 消息监听器ID（用于移除）
  String? _listenerID;

  // 游戏消息回调
  Function(Map<String, dynamic> data, String senderID)? onGameMessage;

  // ===== 用户信息 =====

  /// 获取当前用户 IM ID
  String get myIMUserID {
    return TencentIMService.instance.currentUserID ??
        UserManager.currentUser?.uniqueId ??
        '';
  }

  /// 获取当前用户昵称
  String get myNickname {
    return UserManager.userNickname ?? '我';
  }

  /// 获取当前用户头像
  String get myAvatar {
    return UserManager.userAvatar ?? '';
  }

  /// 获取对方 IM ID
  String get partnerIMUserID {
    return UserManager.currentUser?.halfUserInfo?.uniqueId ?? '';
  }

  /// 获取对方昵称
  String get partnerNickname {
    final user = UserManager.currentUser;
    if (user?.loverInfo?.nickname?.isNotEmpty == true) {
      return user!.loverInfo!.nickname!;
    }
    if (user?.halfUserInfo?.nickname?.isNotEmpty == true) {
      return user!.halfUserInfo!.nickname!;
    }
    return '另一半';
  }

  /// 获取对方头像
  String get partnerAvatar {
    final user = UserManager.currentUser;
    return user?.loverInfo?.headPortrait ??
        user?.halfUserInfo?.headPortrait ??
        '';
  }

  // ===== 群聊管理 =====

  /// 创建游戏群聊房间
  /// 使用 Work 类型群（好友工作群），任何成员可邀请他人进群
  Future<String?> createGameGroup() async {
    if (!TencentIMService.instance.isLoggedIn) {
      logger.error('IM未登录，无法创建游戏群', tag: _tag);
      return null;
    }

    final partnerID = partnerIMUserID;
    if (partnerID.isEmpty) {
      logger.error('未绑定另一半，无法创建游戏群', tag: _tag);
      return null;
    }

    try {
      final groupName = '你说我猜_${DateTime.now().millisecondsSinceEpoch}';

      // 创建 Work 群，同时邀请对方加入
      final result = await TencentImSDKPlugin.v2TIMManager
          .getGroupManager()
          .createGroup(
        groupType: GroupType.Work,
        groupName: groupName,
        notification: '你说我猜游戏房间',
        memberList: [
          V2TimGroupMember(
            userID: partnerID,
            role: GroupMemberRoleTypeEnum.V2TIM_GROUP_MEMBER_ROLE_MEMBER,
          ),
        ],
      );

      if (result.code == 0 && result.data != null) {
        _groupID = result.data!;
        logger.debug('✅ 游戏群创建成功: $_groupID', tag: _tag);

        // 注册群消息监听
        _setupGroupMessageListener();

        return _groupID;
      } else {
        logger.error(
          '❌ 创建游戏群失败: code=${result.code}, desc=${result.desc}',
          tag: _tag,
        );
        return null;
      }
    } catch (e) {
      logger.error('创建游戏群异常: $e', tag: _tag);
      return null;
    }
  }

  /// 加入已有的游戏群（被邀请方）
  /// 返回false表示群已不存在
  Future<bool> joinGameGroup(String groupID) async {
    try {
      // 验证群是否存在：尝试获取群信息
      final infoRes = await TencentImSDKPlugin.v2TIMManager
          .getGroupManager()
          .getGroupsInfo(groupIDList: [groupID]);
      if (infoRes.code != 0 ||
          infoRes.data == null ||
          infoRes.data!.isEmpty ||
          infoRes.data!.first.resultCode != 0) {
        logger.warning('游戏群不存在或已解散: $groupID', tag: _tag);
        return false;
      }
    } catch (e) {
      logger.warning('验证游戏群异常: $e, groupID=$groupID', tag: _tag);
      return false;
    }

    _groupID = groupID;
    _setupGroupMessageListener();
    logger.debug('✅ 已加入游戏群: $groupID', tag: _tag);
    return true;
  }

  /// 解散游戏群（房主调用）
  Future<bool> dismissGameGroup() async {
    if (_groupID == null) return true;

    try {
      final result = await TencentImSDKPlugin.v2TIMManager.dismissGroup(
        groupID: _groupID!,
      );

      if (result.code == 0) {
        logger.debug('✅ 游戏群已解散: $_groupID', tag: _tag);
      } else {
        logger.warning(
          '解散游戏群失败: code=${result.code}, desc=${result.desc}',
          tag: _tag,
        );
      }
    } catch (e) {
      logger.warning('解散游戏群异常: $e', tag: _tag);
    }

    _removeGroupMessageListener();
    _groupID = null;
    return true;
  }

  /// 退出游戏群（非房主调用）
  Future<bool> quitGameGroup() async {
    if (_groupID == null) return true;

    try {
      final result = await TencentImSDKPlugin.v2TIMManager.quitGroup(
        groupID: _groupID!,
      );

      if (result.code == 0) {
        logger.debug('✅ 已退出游戏群: $_groupID', tag: _tag);
      } else {
        logger.warning(
          '退出游戏群失败: code=${result.code}, desc=${result.desc}',
          tag: _tag,
        );
      }
    } catch (e) {
      logger.warning('退出游戏群异常: $e', tag: _tag);
    }

    _removeGroupMessageListener();
    _groupID = null;
    return true;
  }

  // ===== 邀请消息（C2C单聊） =====

  /// 发送你说我猜邀请消息到对方（C2C单聊，非群消息）
  /// 会在聊天页面展示为邀请卡片
  Future<bool> sendInviteMessage() async {
    if (_groupID == null) {
      logger.warning('游戏群未创建，无法发送邀请', tag: _tag);
      return false;
    }

    final partnerID = partnerIMUserID;
    if (partnerID.isEmpty) {
      logger.warning('未绑定另一半，无法发送邀请', tag: _tag);
      return false;
    }

    final payload = <String, dynamic>{
      'msg_type': 'chat_say_guess',
      'group_id': _groupID,
      'sender': myIMUserID,
      'senderName': myNickname,
      'senderAvatar': myAvatar,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final customData = jsonEncode(payload);

    final result = await TencentIMService.instance.sendCustomMessage(
      receiverID: partnerID,
      customData: customData,
      isGroup: false,
    );

    if (result != null && result.code == 0) {
      logger.debug('✅ 邀请消息发送成功: groupID=$_groupID', tag: _tag);
      return true;
    } else {
      logger.error(
        '❌ 邀请消息发送失败: code=${result?.code}, desc=${result?.desc}',
        tag: _tag,
      );
      return false;
    }
  }

  // ===== 游戏消息收发 =====

  /// 发送游戏自定义消息到群
  /// [type] 消息类型: game_text, game_answer, game_hint_request, game_hint_response,
  ///   game_system, game_start, game_role_select, game_question_start, game_privilege,
  ///   game_custom_answer, game_end
  Future<bool> sendGameMessage({
    required String type,
    Map<String, dynamic>? extra,
  }) async {
    if (_groupID == null) {
      logger.warning('游戏群未创建，无法发送消息', tag: _tag);
      return false;
    }

    final payload = <String, dynamic>{
      'game': 'guess_word',
      'type': type,
      'sender': myIMUserID,
      'senderName': myNickname,
      'senderAvatar': myAvatar,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    if (extra != null) {
      payload.addAll(extra);
    }

    final customData = jsonEncode(payload);

    final result = await TencentIMService.instance.sendCustomMessage(
      receiverID: _groupID!,
      customData: customData,
      isGroup: true,
    );

    if (result != null && result.code == 0) {
      logger.debug('✅ 游戏消息发送成功: type=$type', tag: _tag);
      return true;
    } else {
      logger.error(
        '❌ 游戏消息发送失败: type=$type, code=${result?.code}, desc=${result?.desc}',
        tag: _tag,
      );
      return false;
    }
  }

  /// 发送游戏文本消息（描述/答案等展示在聊天区的消息）
  Future<bool> sendGameTextMessage(String text) async {
    return sendGameMessage(type: 'game_text', extra: {'content': text});
  }

  /// 发送答案消息
  Future<bool> sendAnswerMessage(String answer) async {
    return sendGameMessage(type: 'game_answer', extra: {'content': answer});
  }

  /// 发送提示请求
  Future<bool> sendHintRequest() async {
    return sendGameMessage(type: 'game_hint_request');
  }

  /// 发送提示字
  Future<bool> sendHintResponse(String hintChar) async {
    return sendGameMessage(
      type: 'game_hint_response',
      extra: {'hintChar': hintChar},
    );
  }

  /// 发送游戏开始信号
  Future<bool> sendGameStart({
    required List<Map<String, dynamic>> questions,
  }) async {
    return sendGameMessage(
      type: 'game_start',
      extra: {'questions': questions},
    );
  }

  /// 发送角色选择
  Future<bool> sendRoleSelect(String role) async {
    return sendGameMessage(type: 'game_role_select', extra: {'role': role});
  }

  /// 发送特权使用
  Future<bool> sendPrivilegeUse(String privilegeType) async {
    return sendGameMessage(
      type: 'game_privilege',
      extra: {'privilegeType': privilegeType},
    );
  }

  /// 发送自定义答案（第5题）
  Future<bool> sendCustomAnswer(String answer) async {
    return sendGameMessage(
      type: 'game_custom_answer',
      extra: {'answer': answer},
    );
  }

  /// 发送游戏结束
  Future<bool> sendGameEnd() async {
    return sendGameMessage(type: 'game_end');
  }

  /// 发送退出通知（在dismiss/quit之前调用，通知对方）
  Future<bool> sendExitMessage() async {
    return sendGameMessage(type: 'game_exit');
  }

  // ===== 群消息监听 =====

  void _setupGroupMessageListener() {
    _listenerID = 'game_msg_listener_${DateTime.now().millisecondsSinceEpoch}';

    TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .addAdvancedMsgListener(
      listener: V2TimAdvancedMsgListener(
        onRecvNewMessage: _onRecvNewMessage,
      ),
    );

    logger.debug('✅ 游戏消息监听器已注册', tag: _tag);
  }

  void _removeGroupMessageListener() {
    if (_listenerID != null) {
      try {
        TencentImSDKPlugin.v2TIMManager
            .getMessageManager()
            .removeAdvancedMsgListener();
      } catch (e) {
        logger.warning('移除游戏消息监听器失败: $e', tag: _tag);
      }
      _listenerID = null;
      logger.debug('✅ 游戏消息监听器已移除', tag: _tag);
    }
  }

  void _onRecvNewMessage(V2TimMessage message) {
    // 只处理当前游戏群的消息
    if (message.groupID != _groupID) return;
    // 跳过自己发的消息
    if (message.isSelf == true) return;

    // 只处理自定义消息
    if (message.customElem?.data == null) return;

    try {
      final data = jsonDecode(message.customElem!.data!) as Map<String, dynamic>;
      // 只处理游戏消息
      if (data['game'] != 'guess_word') return;

      final senderID = message.sender ?? '';
      logger.debug(
        '📨 收到游戏消息: type=${data['type']}, from=$senderID',
        tag: _tag,
      );

      onGameMessage?.call(data, senderID);
    } catch (e) {
      logger.warning('解析游戏消息失败: $e', tag: _tag);
    }
  }

  /// 清理资源
  void dispose() {
    _removeGroupMessageListener();
    onGameMessage = null;
  }
}
