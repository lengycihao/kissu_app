import 'dart:async';
import 'dart:convert';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_type.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_member_role_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimAdvancedMsgListener.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member.dart';
import 'package:tencent_cloud_chat_sdk/enum/offlinePushInfo.dart';
import 'package:kissu_app/services/tencent_im_service.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

/// 你说我猜V2 IM 服务
/// 负责群聊创建/销毁、心跳、在线检测、游戏消息收发
class GameIMServiceV2 {
  static const String _tag = 'GameIMServiceV2';
  static const int _heartbeatIntervalSec = 5;
  static const int _onlineTimeoutSec = 15; // 超过15秒没收到心跳视为离线

  String? _groupID;
  String? get groupID => _groupID;

  // 心跳定时器
  Timer? _heartbeatTimer;
  // 对方最后心跳时间
  DateTime? _partnerLastHeartbeat;

  // 回调
  Function(Map<String, dynamic> data, String senderID)? onGameMessage;
  Function(bool isOnline)? onPartnerOnlineChanged;

  bool _partnerOnline = false;
  bool get isPartnerOnline => _partnerOnline;

  // ===== 用户信息 =====
  String get myIMUserID =>
      TencentIMService.instance.currentUserID ??
      UserManager.currentUser?.uniqueId ??
      '';

  String get myNickname => UserManager.userNickname ?? '我';

  String get myAvatar => UserManager.userAvatar ?? '';

  String get partnerIMUserID =>
      UserManager.currentUser?.halfUserInfo?.uniqueId ?? '';

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

  String get partnerAvatar {
    final user = UserManager.currentUser;
    return user?.loverInfo?.headPortrait ??
        user?.halfUserInfo?.headPortrait ??
        '';
  }

  // ===== 群聊管理 =====

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
        // 注意：不在这里注册监听器，由 joinGameGroup 负责
        return _groupID;
      } else {
        logger.error('❌ 创建游戏群失败: code=${result.code}', tag: _tag);
        return null;
      }
    } catch (e) {
      logger.error('创建游戏群异常: $e', tag: _tag);
      return null;
    }
  }

  Future<bool> joinGameGroup(String groupID) async {
    try {
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
      logger.warning('验证游戏群异常: $e', tag: _tag);
      return false;
    }
    _groupID = groupID;
    _setupGroupMessageListener();
    logger.debug('✅ 已加入游戏群: $groupID', tag: _tag);
    return true;
  }

  Future<bool> dismissGameGroup() async {
    if (_groupID == null) return true;
    try {
      await TencentImSDKPlugin.v2TIMManager.dismissGroup(groupID: _groupID!);
      logger.debug('✅ 游戏群已解散: $_groupID', tag: _tag);
    } catch (e) {
      logger.warning('解散游戏群异常: $e', tag: _tag);
    }
    _removeGroupMessageListener();
    _groupID = null;
    return true;
  }

  Future<bool> quitGameGroup() async {
    if (_groupID == null) return true;
    try {
      await TencentImSDKPlugin.v2TIMManager.quitGroup(groupID: _groupID!);
      logger.debug('✅ 已退出游戏群: $_groupID', tag: _tag);
    } catch (e) {
      logger.warning('退出游戏群异常: $e', tag: _tag);
    }
    _removeGroupMessageListener();
    _groupID = null;
    return true;
  }

  // ===== 心跳 =====

  void startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: _heartbeatIntervalSec),
      (_) => _sendHeartbeat(),
    );
    _sendHeartbeat(); // 立即发一次
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _sendHeartbeat() async {
    await _sendOnlineOnlyGroupMessage(type: 'game_heart');
  }

  /// 发送仅在线消息（不存储、不推送、不计未读）
  /// 用于心跳等高频非关键消息
  Future<bool> _sendOnlineOnlyGroupMessage({required String type}) async {
    if (_groupID == null) return false;
    final payload = <String, dynamic>{
      'game': 'guess_word',
      'type': type,
      'sender': myIMUserID,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    try {
      final createRes = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .createCustomMessage(data: jsonEncode(payload));
      if (createRes.code != 0 || createRes.data == null) return false;
      final sendRes = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .sendMessage(
            id: createRes.data!.id,
            receiver: '',
            groupID: _groupID!,
            onlineUserOnly: true,
          );
      return sendRes.code == 0;
    } catch (e) {
      logger.warning('发送在线消息失败: $e', tag: _tag);
      return false;
    }
  }

  void _onHeartbeatReceived() {
    _partnerLastHeartbeat = DateTime.now();
    if (!_partnerOnline) {
      _partnerOnline = true;
      onPartnerOnlineChanged?.call(true);
    }
  }

  /// 检查对方是否在线（超过 _onlineTimeoutSec 没心跳视为离线）
  bool checkPartnerOnline() {
    if (_partnerLastHeartbeat == null) return false;
    final elapsed = DateTime.now().difference(_partnerLastHeartbeat!).inSeconds;
    final online = elapsed < _onlineTimeoutSec;
    if (_partnerOnline != online) {
      _partnerOnline = online;
      onPartnerOnlineChanged?.call(online);
    }
    return online;
  }

  // ===== 邀请消息（C2C单聊） =====

  Future<bool> sendInviteMessage() async {
    if (_groupID == null) return false;
    final partnerID = partnerIMUserID;
    if (partnerID.isEmpty) return false;

    final payload = <String, dynamic>{
      'msg_type': 'chat_say_guess',
      'group_id': _groupID,
      'sender': myIMUserID,
      'senderName': myNickname,
      'senderAvatar': myAvatar,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    final result = await TencentIMService.instance.sendCustomMessage(
      receiverID: partnerID,
      customData: jsonEncode(payload),
      isGroup: false,
    );
    return result != null && result.code == 0;
  }

  // ===== 游戏消息收发 =====

  /// 发送游戏消息（群聊，不触发离线推送）
  /// 直接调用 SDK 而不经过 TencentIMService.sendCustomMessage，
  /// 避免游戏消息触发推送通知。
  Future<bool> sendGameMessage({
    required String type,
    Map<String, dynamic>? extra,
  }) async {
    if (_groupID == null) return false;
    final payload = <String, dynamic>{
      'game': 'guess_word',
      'type': type,
      'sender': myIMUserID,
      'senderName': myNickname,
      'senderAvatar': myAvatar,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    if (extra != null) payload.addAll(extra);

    try {
      final createRes = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .createCustomMessage(data: jsonEncode(payload));
      if (createRes.code != 0 || createRes.data == null) return false;

      final offlinePush = OfflinePushInfo(disablePush: true);
      final sendRes = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .sendMessage(
            id: createRes.data!.id,
            receiver: '',
            groupID: _groupID!,
            offlinePushInfo: offlinePush,
          );
      return sendRes.code == 0;
    } catch (e) {
      logger.warning('发送游戏消息失败: $e', tag: _tag);
      return false;
    }
  }

  // 便捷方法
  Future<bool> sendGameText(String text) =>
      sendGameMessage(type: 'game_text', extra: {'content': text});

  Future<bool> sendGameAnswer(String answer) =>
      sendGameMessage(type: 'game_answer', extra: {'content': answer});

  Future<bool> sendAnswerState(int state) =>
      sendGameMessage(type: 'game_answer_state', extra: {'state': state});

  Future<bool> sendGameResult({
    required int result,
    required int correctCount,
  }) =>
      sendGameMessage(type: 'game_result', extra: {
        'result': result,
        'correctCount': correctCount,
      });

  Future<bool> sendHintRequest() =>
      sendGameMessage(type: 'game_hint_request');

  Future<bool> sendHintResponse(String hintChar) =>
      sendGameMessage(type: 'game_hint_response', extra: {'hintChar': hintChar});

  Future<bool> sendPrivilegeUse(String privilegeType) =>
      sendGameMessage(type: 'game_privilege', extra: {'privilegeType': privilegeType});

  Future<bool> sendSenderJoined() =>
      sendGameMessage(type: 'game_sender_joined');

  Future<bool> sendSenderAway() =>
      sendGameMessage(type: 'game_sender_away');

  Future<bool> sendReceiverJoined() =>
      sendGameMessage(type: 'game_receiver_joined');

  Future<bool> sendReceiverAway() =>
      sendGameMessage(type: 'game_receiver_away');

  Future<bool> sendGameSync(Map<String, dynamic> syncData) =>
      sendGameMessage(type: 'game_sync', extra: syncData);

  // ===== 群消息监听 =====

  V2TimAdvancedMsgListener? _advancedMsgListener;

  void _setupGroupMessageListener() {
    // 存储监听器实例，确保 remove 时只移除自己的监听器
    _advancedMsgListener = V2TimAdvancedMsgListener(
      onRecvNewMessage: _onRecvNewMessage,
    );
    TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .addAdvancedMsgListener(listener: _advancedMsgListener!);
    logger.debug('✅ V2游戏消息监听器已注册', tag: _tag);
  }

  void _removeGroupMessageListener() {
    if (_advancedMsgListener != null) {
      try {
        TencentImSDKPlugin.v2TIMManager
            .getMessageManager()
            .removeAdvancedMsgListener(listener: _advancedMsgListener);
      } catch (e) {
        logger.warning('移除V2游戏消息监听器失败: $e', tag: _tag);
      }
      _advancedMsgListener = null;
    }
  }

  void _onRecvNewMessage(V2TimMessage message) {
    if (message.groupID != _groupID) return;
    if (message.isSelf == true) return;
    if (message.customElem?.data == null) return;

    try {
      final data = jsonDecode(message.customElem!.data!) as Map<String, dynamic>;
      if (data['game'] != 'guess_word') return;

      final type = data['type'] as String? ?? '';
      final senderID = message.sender ?? '';

      // 心跳消息单独处理，不回调给上层
      if (type == 'game_heart') {
        _onHeartbeatReceived();
        return;
      }

      logger.debug('📨 收到V2游戏消息: type=$type, from=$senderID', tag: _tag);
      onGameMessage?.call(data, senderID);
    } catch (e) {
      logger.warning('解析V2游戏消息失败: $e', tag: _tag);
    }
  }

  void dispose() {
    stopHeartbeat();
    _removeGroupMessageListener();
    onGameMessage = null;
    onPartnerOnlineChanged = null;
  }
}
