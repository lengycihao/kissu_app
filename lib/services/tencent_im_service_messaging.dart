part of 'tencent_im_service.dart';

/// 消息收发处理器
/// 负责文本/图片/自定义消息的发送、删除、撤回、历史拉取等
class _IMMessageHandler {
  final TencentIMService _s;
  _IMMessageHandler(this._s);

  /// 发送文本消息
  /// 
  /// [receiverID] 接收者ID
  /// [text] 消息文本
  /// [isGroup] 是否是群聊，默认false（单聊）
  Future<V2TimValueCallback<V2TimMessage>?> sendTextMessage({
    required String receiverID,
    required String text,
    bool isGroup = false,
  }) async {
    if (!_s._isLoggedIn) {
      logger.warning('IM未登录，无法发送消息', tag: 'TencentIMService');
      _s._handleIMNotLoggedIn();
      return null;
    }

    try {
      logger.debug(
        '发送文本消息: receiverID=$receiverID, text=$text, isGroup=$isGroup',
        tag: 'TencentIMService',
      );

      // 先创建文本消息
      V2TimValueCallback<V2TimMsgCreateInfoResult> createResult = 
          await TencentImSDKPlugin.v2TIMManager
              .getMessageManager()
              .createTextMessage(text: text);

      if (createResult.code != 0 || createResult.data == null) {
        logger.error(
          '创建消息失败: code=${createResult.code}, desc=${createResult.desc}',
          tag: 'TencentIMService',
        );
        return null;
      }

      final V2TimMsgCreateInfoResult createInfo = createResult.data!;

      // 发送消息
      // 🔥 添加离线推送配置，确保对方离线时能收到通知
      final extData = {
        'scene': 'im_chat',
        'conversation_id': 'c2c_$receiverID',
        'sender_id': _s._currentUserID ?? '',
        'user_id': receiverID,
      };
      
      final offlinePushInfo = OfflinePushInfo(
        title: '你有一条新消息',
        desc: text.length > 50 ? '${text.substring(0, 50)}...' : text,
        disablePush: false,
        iOSSound: 'default',
        ignoreIOSBadge: false,
        // 🔥 各厂商通道配置，确保通知能正确弹出
        androidOPPOChannelID: 'kissu_im_message',
        // androidOPPOCategory: 'IM',
        // androidVIVOClassification: 1,
        androidVIVOCategory: 'IM',
        androidSound: 'default',
        androidHuaWeiCategory: 'IM',
        ext: jsonEncode(extData),
      );
      
      logger.debug('🔔 发送消息携带离线推送配置: title=${offlinePushInfo.title}, desc=${offlinePushInfo.desc}, ext=${offlinePushInfo.ext}', tag: 'TencentIMService');
      
      V2TimValueCallback<V2TimMessage> sendResult = 
          await TencentImSDKPlugin.v2TIMManager
              .getMessageManager()
              .sendMessage(
                id: createInfo.id,
                receiver: isGroup ? '' : receiverID,
                groupID: isGroup ? receiverID : '',
                offlinePushInfo: offlinePushInfo,
              );

      if (sendResult.code == 0) {
        logger.debug('消息发送成功', tag: 'TencentIMService');
      } else {
        logger.error(
          '消息发送失败: code=${sendResult.code}, desc=${sendResult.desc}',
          tag: 'TencentIMService',
        );
      }

      return sendResult;
    } catch (e) {
      logger.error('发送消息异常: $e', tag: 'TencentIMService');
      return null;
    }
  }

  /// 发送图片消息（单聊/群聊）
  /// 
  /// [receiverID] 单聊接收方 userID（群聊时传空字符串）
  /// [imagePath] 本地图片绝对路径
  /// [isGroup] 是否群聊，默认 false 表示单聊
  Future<V2TimValueCallback<V2TimMessage>?> sendImageMessage({
    required String receiverID,
    required String imagePath,
    bool isGroup = false,
  }) async {
    if (!_s._isLoggedIn) {
      logger.warning('IM未登录，无法发送图片消息', tag: 'TencentIMService');
      _s._handleIMNotLoggedIn();
      return null;
    }

    try {
      logger.debug(
        '发送图片消息: receiverID=$receiverID, path=$imagePath, isGroup=$isGroup',
        tag: 'TencentIMService',
      );

      // 先创建图片消息
      final V2TimValueCallback<V2TimMsgCreateInfoResult> createResult =
          await TencentImSDKPlugin.v2TIMManager
              .getMessageManager()
              .createImageMessage(imagePath: imagePath);

      if (createResult.code != 0 || createResult.data == null) {
        logger.error(
          '创建图片消息失败: code=${createResult.code}, desc=${createResult.desc}',
          tag: 'TencentIMService',
        );
        return null;
      }

      final V2TimMsgCreateInfoResult createInfo = createResult.data!;

      // 发送图片消息
      // 🔥 添加离线推送配置
      final extData = {
        'scene': 'im_chat',
        'conversation_id': 'c2c_$receiverID',
        'sender_id': _s._currentUserID ?? '',
        'user_id': receiverID,
      };
      
      final offlinePushInfo = OfflinePushInfo(
        title: '你有一条新消息',
        desc: '[图片]',
        disablePush: false,
        iOSSound: 'default',
        ignoreIOSBadge: false,
        androidOPPOChannelID: 'kissu_im_message',
        // androidOPPOCategory: 'IM',
        // androidVIVOClassification: 1,
        androidVIVOCategory: 'IM',
        androidSound: 'default',
        androidHuaWeiCategory: 'IM',
        ext: jsonEncode(extData),
      );
      
      final V2TimValueCallback<V2TimMessage> sendResult =
          await TencentImSDKPlugin.v2TIMManager
              .getMessageManager()
              .sendMessage(
                id: createInfo.id,
                receiver: isGroup ? '' : receiverID,
                groupID: isGroup ? receiverID : '',
                offlinePushInfo: offlinePushInfo,
              );

      if (sendResult.code == 0) {
        logger.debug('图片消息发送成功', tag: 'TencentIMService');
      } else {
        logger.error(
          '图片消息发送失败: code=${sendResult.code}, desc=${sendResult.desc}',
          tag: 'TencentIMService',
        );
      }

      return sendResult;
    } catch (e) {
      logger.error('发送图片消息异常: $e', tag: 'TencentIMService');
      return null;
    }
  }

  /// 从本地删除单条消息（仅本端）
  Future<V2TimCallback?> deleteMessageFromLocal({
    required String msgID,
  }) async {
    if (!_s._isLoggedIn) {
      logger.warning('IM未登录，无法删除本地消息', tag: 'TencentIMService');
      return null;
    }
    try {
      final res = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .deleteMessageFromLocalStorage(msgID: msgID);
      if (res.code == 0) {
        logger.debug('本地消息删除成功: $msgID', tag: 'TencentIMService');
      } else {
        logger.error(
          '本地消息删除失败: code=${res.code}, desc=${res.desc}',
          tag: 'TencentIMService',
        );
      }
      return res;
    } catch (e) {
      logger.error('本地消息删除异常: $e', tag: 'TencentIMService');
      return null;
    }
  }

  /// 从云端和本地删除多条消息（不可恢复）
  Future<V2TimCallback?> deleteMessagesFromCloud({
    required List<String> msgIDs,
  }) async {
    if (!_s._isLoggedIn) {
      logger.warning('IM未登录，无法删除云端消息', tag: 'TencentIMService');
      return null;
    }
    try {
      final res = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .deleteMessages(msgIDs: msgIDs);
      if (res.code == 0) {
        logger.debug('云端消息删除成功: $msgIDs', tag: 'TencentIMService');
      } else {
        logger.error(
          '云端消息删除失败: code=${res.code}, desc=${res.desc}',
          tag: 'TencentIMService',
        );
      }
      return res;
    } catch (e) {
      logger.error('云端消息删除异常: $e', tag: 'TencentIMService');
      return null;
    }
  }

  /// 撤回一条已发送消息（默认 2 分钟内）
  Future<V2TimCallback?> revokeMessage({required String msgID}) async {
    if (!_s._isLoggedIn) {
      logger.warning('IM未登录，无法撤回消息', tag: 'TencentIMService');
      return null;
    }
    try {
      final res = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .revokeMessage(msgID: msgID);
      if (res.code == 0) {
        logger.debug('撤回消息成功: $msgID', tag: 'TencentIMService');
      } else {
        logger.error(
          '撤回消息失败: code=${res.code}, desc=${res.desc}',
          tag: 'TencentIMService',
        );
      }
      return res;
    } catch (e) {
      logger.error('撤回消息异常: $e', tag: 'TencentIMService');
      return null;
    }
  }

  /// 发送自定义消息（单聊/群聊）
  /// 
  /// [receiverID] 单聊接收方 userID（群聊时传空字符串）
  /// [customData] 自定义消息数据（JSON字符串）
  /// [isGroup] 是否群聊，默认 false 表示单聊
  Future<V2TimValueCallback<V2TimMessage>?> sendCustomMessage({
    required String receiverID,
    required String customData,
    bool isGroup = false,
  }) async {
    if (!_s._isLoggedIn) {
      logger.warning('IM未登录，无法发送自定义消息', tag: 'TencentIMService');
      _s._handleIMNotLoggedIn();
      return null;
    }

    try {
      logger.debug(
        '发送自定义消息: receiverID=$receiverID, data=$customData, isGroup=$isGroup',
        tag: 'TencentIMService',
      );

      // 先创建自定义消息
      final createResult = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .createCustomMessage(data: customData);

      if (createResult.code != 0 || createResult.data == null) {
        logger.error(
          '创建自定义消息失败: code=${createResult.code}, desc=${createResult.desc}',
          tag: 'TencentIMService',
        );
        return null;
      }

      final createInfo = createResult.data!;

      // 发送自定义消息
      // 🔥 添加离线推送配置（自定义消息也需要离线推送）
      // 🔥 关键：将customData解析后合并到extData中，确保离线推送时原生层能获取到完整数据
      Map<String, dynamic> extData = {
        'scene': 'im_chat',
        'conversation_id': 'c2c_$receiverID',
        'sender_id': _s._currentUserID ?? '',
        'user_id': receiverID,
      };
      
      // 🔥 尝试解析customData并合并到extData中，同时获取消息类型用于自定义推送文案
      String pushDesc = '[消息]';
      try {
        final customDataMap = jsonDecode(customData) as Map<String, dynamic>;
        extData.addAll(customDataMap);
        String? msgType = customDataMap['type'] as String?;
        msgType ??= customDataMap['msg_lock'] as String?;
        // 🔥 根据消息类型自定义推送文案
        if (msgType == 'lock_screen_command') {
          pushDesc = '[锁机指令来啦~]';
        } else if (msgType == 'unlock_phone_send') {
          pushDesc = '[解锁指令来啦~]';
        }else if(msgType == 'lock_phone'){
          pushDesc = '[对方提醒您开启悬浮窗权限啦~]';
        }else if(msgType == 'phone_use'){
          pushDesc = '[对方提醒您开启应用使用权限啦~]';
        }else if(msgType == 'connect_app'){
          pushDesc = '[对方提醒您去关联app啦~]';
        }
        logger.debug('🔔 离线推送ext已合并customData: type=$msgType, desc=$pushDesc', tag: 'TencentIMService');
      } catch (e) {
        logger.warning('🔔 customData不是有效JSON，无法合并到ext: $e', tag: 'TencentIMService');
      }
      
      final offlinePushInfo = OfflinePushInfo(
        title: '你有一条新消息',
        desc: pushDesc,
        disablePush: false,
        iOSSound: 'default',
        ignoreIOSBadge: false,
        androidOPPOChannelID: 'kissu_im_message',
        // androidOPPOCategory: 'IM',
        //  androidVIVOClassification: 1,
        androidVIVOCategory: 'IM',
        androidSound: 'default',
        androidHuaWeiCategory: 'IM',
        ext: jsonEncode(extData),
      );
      
      final sendResult = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .sendMessage(
            id: createInfo.id,
            receiver: isGroup ? '' : receiverID,
            groupID: isGroup ? receiverID : '',
            offlinePushInfo: offlinePushInfo,
          );

      if (sendResult.code == 0) {
        logger.debug('自定义消息发送成功', tag: 'TencentIMService');
      } else {
        logger.error(
          '自定义消息发送失败: code=${sendResult.code}, desc=${sendResult.desc}',
          tag: 'TencentIMService',
        );
      }

      return sendResult;
    } catch (e) {
      logger.error('发送自定义消息异常: $e', tag: 'TencentIMService');
      return null;
    }
  }

  /// 发送"正在输入中"在线自定义消息（只发给在线对方，不入库、不漫游）
  Future<void> sendTypingOnlineMessage({
    required String receiverID,
  }) async {
    if (!_s._isLoggedIn) {
      logger.warning('IM未登录，无法发送正在输入提示', tag: 'TencentIMService');
      return;
    }
    try {
      // 统一使用 JSON 文本传递自定义指令，便于扩展
      final typingPayload = jsonEncode(<String, String>{
        'command': 'typing',
      });

      final createRes = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .createCustomMessage(
        data: typingPayload,
      );
      if (createRes.code != 0 || createRes.data == null) {
        logger.error(
          '创建正在输入消息失败: code=${createRes.code}, desc=${createRes.desc}',
          tag: 'TencentIMService',
        );
        return;
      }
      final id = createRes.data!.id;
      await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .sendMessage(
            id: id,
            receiver: receiverID,
            groupID: '',
            onlineUserOnly: true,
          );
      logger.debug('已发送正在输入在线消息给 $receiverID', tag: 'TencentIMService');
    } catch (e) {
      logger.error('发送正在输入消息异常: $e', tag: 'TencentIMService');
    }
  }

  /// 拉取单聊历史消息（最新在前）
  /// 
  /// [userID] 对端用户 ID（即另一半的 IM ID）
  /// [count] 拉取条数，建议 20
  /// [lastMsgID] 上一次拉取结果中的最后一条消息 ID，用于分页；首次拉取传 null
  Future<V2TimValueCallback<List<V2TimMessage>>?> getC2CHistoryMessages({
    required String userID,
    int count = 20,
    String? lastMsgID,
  }) async {
    if (!_s._isLoggedIn) {
      logger.warning('IM未登录，无法拉取历史消息', tag: 'TencentIMService');
      _s._handleIMNotLoggedIn();
      return null;
    }

    try {
      logger.debug(
        '拉取单聊历史消息: userID=$userID, count=$count, lastMsgID=$lastMsgID',
        tag: 'TencentIMService',
      );

      final res = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .getC2CHistoryMessageList(
            userID: userID,
            count: count,
            lastMsgID: lastMsgID,
          );

      if (res.code != 0) {
        logger.error(
          '拉取单聊历史消息失败: code=${res.code}, desc=${res.desc}',
          tag: 'TencentIMService',
        );
      }

      return res;
    } catch (e) {
      logger.error('拉取单聊历史消息异常: $e', tag: 'TencentIMService');
      return null;
    }
  }

  /// 标记单聊会话消息为已读（触发 C2C 已读回执）
  ///
  /// [userID] 对端用户ID（另一半的 IM ID）
  /// [messageIDList] 需要标记为已读的消息ID列表
  Future<V2TimCallback?> markC2CMessageAsRead({
    required String userID,
    List<String>? messageIDList,
  }) async {
    if (!_s._isLoggedIn) {
      logger.warning('IM未登录，无法标记单聊消息已读', tag: 'TencentIMService');
      return null;
    }

    try {
      logger.debug(
        '标记单聊消息已读: userID=$userID, count=${messageIDList?.length ?? 0}',
        tag: 'TencentIMService',
      );

      final res = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .markC2CMessageAsRead(
            userID: userID,
          );

      if (res.code == 0) {
        logger.debug('标记单聊消息已读成功', tag: 'TencentIMService');
      } else {
        logger.error(
          '标记单聊消息已读失败: code=${res.code}, desc=${res.desc}',
          tag: 'TencentIMService',
        );
      }

      return res;
    } catch (e) {
      logger.error('标记单聊消息已读异常: $e', tag: 'TencentIMService');
      return null;
    }
  }
}
