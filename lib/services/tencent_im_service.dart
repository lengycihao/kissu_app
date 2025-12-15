import 'dart:convert';
import 'package:get/get.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimSDKListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/log_level_enum.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_callback.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_msg_create_info_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_receipt.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_value_callback.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimAdvancedMsgListener.dart';
import 'package:kissu_app/model/login_model/login_model.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
import 'package:kissu_app/services/relationship_animation_service.dart';
import 'package:kissu_app/network/public/service_locator.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/network/public/api_request.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/widgets/dialogs/dialog_manager.dart';
import 'package:flutter/material.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/network/public/auth_api.dart';

/// 腾讯IM服务
/// 
/// 功能：
/// - IM SDK初始化
/// - 用户登录/登出
/// - 消息监听
class TencentIMService extends GetxService {
  static TencentIMService get instance => Get.find<TencentIMService>();
  
  // IM SDK AppID
  static const int sdkAppID = 1600095370;
  
  // 是否已初始化
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  // 是否已登录
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  
  // 当前登录的用户ID
  String? _currentUserID;
  String? get currentUserID => _currentUserID;

  // 消息接收回调
  final Rx<Function(List<V2TimMessage>)?> onReceiveNewMessage =
      Rx<Function(List<V2TimMessage>)?>(null);

  // 消息撤回回调
  final Rx<Function(String)?> onRecvMessageRevoked =
      Rx<Function(String)?>(null);

  // 单聊消息已读回执回调
  final Rx<Function(List<V2TimMessageReceipt>)?> onRecvC2CReadReceiptCallback =
      Rx<Function(List<V2TimMessageReceipt>)?>(null);

  // 绑定消息接收回调（当收到绑定消息时触发，用于自动关闭绑定弹窗等操作）
  final Rx<Function()?> onBindMessageReceived = Rx<Function()?>(null);

  @override
  void onInit() {
    super.onInit();
    // 🔥 修复：延迟初始化IM SDK，等待用户同意隐私政策后再初始化
    // 不在 onInit 中立即初始化，避免在用户未同意隐私政策前获取设备信息
    // IM SDK 将在用户同意隐私政策后，由 PrivacyComplianceManager 调用初始化
  }

  /// 初始化IM SDK
  /// 🔥 修复：公开此方法，供 PrivacyComplianceManager 在用户同意隐私政策后调用
  Future<bool> initIM() async {
    if (_isInitialized) {
      logger.info('IM SDK 已经初始化', tag: 'TencentIMService');
      return true;
    }

    try {
      logger.info('开始初始化腾讯IM SDK...', tag: 'TencentIMService');
      
      // 初始化SDK
      V2TimValueCallback<bool> initResult = await TencentImSDKPlugin.v2TIMManager.initSDK(
        sdkAppID: sdkAppID,
        loglevel: LogLevelEnum.V2TIM_LOG_DEBUG,
        listener: V2TimSDKListener(
          onConnecting: () {
            logger.info('IM正在连接...', tag: 'TencentIMService');
          },
          onConnectSuccess: () {
            logger.info('IM连接成功', tag: 'TencentIMService');
          },
          onConnectFailed: (code, error) {
            logger.error('IM连接失败: code=$code, error=$error', tag: 'TencentIMService');
          },
          onKickedOffline: () {
            logger.warning('IM账号被踢下线', tag: 'TencentIMService');
            _isLoggedIn = false;
            _currentUserID = null;
          },
          onUserSigExpired: () {
            logger.warning('IM UserSig已过期', tag: 'TencentIMService');
            _isLoggedIn = false;
            _currentUserID = null;
          },
          onSelfInfoUpdated: (info) {
            logger.info('IM个人资料更新', tag: 'TencentIMService');
          },
        ),
      );

      if (initResult.code == 0) {
        _isInitialized = true;
        logger.info('腾讯IM SDK初始化成功', tag: 'TencentIMService');
        return true;
      } else {
        logger.error(
          'IM SDK初始化失败: ${initResult.desc}',
          tag: 'TencentIMService',
        );
        return false;
      }
    } catch (e) {
      logger.error('IM SDK初始化异常: $e', tag: 'TencentIMService');
      return false;
    }
  }

  /// 用户登录IM
  /// 
  /// [user] 登录用户信息，需要包含uniqueId和imSign
  Future<bool> loginIM(LoginModel user) async {
    if (!_isInitialized) {
      logger.warning('IM SDK未初始化，尝试先初始化', tag: 'TencentIMService');
      final initSuccess = await initIM();
      if (!initSuccess) {
        logger.error('IM SDK初始化失败，无法登录', tag: 'TencentIMService');
        return false;
      }
    }

    // 检查必要参数
    if (user.uniqueId == null || user.uniqueId!.isEmpty) {
      logger.error('IM登录失败: uniqueId为空', tag: 'TencentIMService');
      return false;
    }

    if (user.imSign == null || user.imSign!.isEmpty) {
      logger.error('IM登录失败: imSign为空', tag: 'TencentIMService');
      return false;
    }

    // 如果已经登录同一个用户，不需要重复登录，但要确保监听器已设置
    if (_isLoggedIn && _currentUserID == user.uniqueId) {
      logger.info('IM已登录该用户: ${user.uniqueId}', tag: 'TencentIMService');
      
      // 确保消息监听器已设置（应对应用重启或热重载的情况）
      _setupMessageListener();
      
      return true;
    }

    try {
      logger.info(
        '开始登录腾讯IM: userID=${user.uniqueId}',
        tag: 'TencentIMService',
      );

      V2TimCallback loginResult = await TencentImSDKPlugin.v2TIMManager.login(
        userID: user.uniqueId!,
        userSig: user.imSign!,
      );

      if (loginResult.code == 0) {
        _isLoggedIn = true;
        _currentUserID = user.uniqueId;
        logger.info(
          'IM登录成功: userID=${user.uniqueId}',
          tag: 'TencentIMService',
        );
        
        // 设置用户资料
        if (user.nickname != null || user.headPortrait != null) {
          await _updateUserProfile(
            nickname: user.nickname,
            avatarUrl: user.headPortrait,
          );
        }

        // 设置消息监听器
        _setupMessageListener();
        
        return true;
      } else {
        logger.error(
          'IM登录失败: code=${loginResult.code}, desc=${loginResult.desc}',
          tag: 'TencentIMService',
        );
        return false;
      }
    } catch (e) {
      logger.error('IM登录异常: $e', tag: 'TencentIMService');
      return false;
    }
  }

  /// 更新用户资料
  Future<void> _updateUserProfile({
    String? nickname,
    String? avatarUrl,
  }) async {
    if (!_isLoggedIn) return;

    try {
      await TencentImSDKPlugin.v2TIMManager.setSelfInfo(
        userFullInfo: V2TimUserFullInfo(
          nickName: nickname,
          faceUrl: avatarUrl,
        ),
      );
      logger.info('IM用户资料更新成功', tag: 'TencentIMService');
    } catch (e) {
      logger.error('IM用户资料更新失败: $e', tag: 'TencentIMService');
    }
  }

  /// 退出登录IM
  Future<bool> logoutIM() async {
    if (!_isLoggedIn) {
      logger.info('IM未登录，无需退出', tag: 'TencentIMService');
      return true;
    }

    try {
      logger.info('开始退出IM登录...', tag: 'TencentIMService');
      
      // 移除消息监听器
      _removeMessageListener();
      
      // 清除回调
      clearCallbacks();
      
      V2TimCallback result = await TencentImSDKPlugin.v2TIMManager.logout();
      
      if (result.code == 0) {
        _isLoggedIn = false;
        _currentUserID = null;
        logger.info('IM退出登录成功', tag: 'TencentIMService');
        return true;
      } else {
        logger.error(
          'IM退出登录失败: ${result.desc}',
          tag: 'TencentIMService',
        );
        return false;
      }
    } catch (e) {
      logger.error('IM退出登录异常: $e', tag: 'TencentIMService');
      return false;
    }
  }

  /// 卸载IM SDK
  Future<void> unInitIM() async {
    if (!_isInitialized) return;

    try {
      await TencentImSDKPlugin.v2TIMManager.unInitSDK();
      _isInitialized = false;
      _isLoggedIn = false;
      _currentUserID = null;
      logger.info('IM SDK已卸载', tag: 'TencentIMService');
    } catch (e) {
      logger.error('IM SDK卸载失败: $e', tag: 'TencentIMService');
    }
  }

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
    if (!_isLoggedIn) {
      logger.warning('IM未登录，无法发送消息', tag: 'TencentIMService');
      return null;
    }

    try {
      logger.info(
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

      // 发送消息（必须携带 messageInfo，否则会报 message and id are both empty）
      V2TimValueCallback<V2TimMessage> sendResult = 
          await TencentImSDKPlugin.v2TIMManager
              .getMessageManager()
              .sendMessage(
                id: createInfo.id,
                receiver: isGroup ? '' : receiverID,
                groupID: isGroup ? receiverID : '',
              );

      if (sendResult.code == 0) {
        logger.info('消息发送成功', tag: 'TencentIMService');
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
    if (!_isLoggedIn) {
      logger.warning('IM未登录，无法发送图片消息', tag: 'TencentIMService');
      return null;
    }

    try {
      logger.info(
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
      final V2TimValueCallback<V2TimMessage> sendResult =
          await TencentImSDKPlugin.v2TIMManager
              .getMessageManager()
              .sendMessage(
                id: createInfo.id,
                receiver: isGroup ? '' : receiverID,
                groupID: isGroup ? receiverID : '',
              );

      if (sendResult.code == 0) {
        logger.info('图片消息发送成功', tag: 'TencentIMService');
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
    if (!_isLoggedIn) {
      logger.warning('IM未登录，无法删除本地消息', tag: 'TencentIMService');
      return null;
    }
    try {
      final res = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .deleteMessageFromLocalStorage(msgID: msgID);
      if (res.code == 0) {
        logger.info('本地消息删除成功: $msgID', tag: 'TencentIMService');
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
    if (!_isLoggedIn) {
      logger.warning('IM未登录，无法删除云端消息', tag: 'TencentIMService');
      return null;
    }
    try {
      final res = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .deleteMessages(msgIDs: msgIDs);
      if (res.code == 0) {
        logger.info('云端消息删除成功: $msgIDs', tag: 'TencentIMService');
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
    if (!_isLoggedIn) {
      logger.warning('IM未登录，无法撤回消息', tag: 'TencentIMService');
      return null;
    }
    try {
      final res = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .revokeMessage(msgID: msgID);
      if (res.code == 0) {
        logger.info('撤回消息成功: $msgID', tag: 'TencentIMService');
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

  /// 发送“正在输入中”在线自定义消息（只发给在线对方，不入库、不漫游）
  Future<void> sendTypingOnlineMessage({
    required String receiverID,
  }) async {
    if (!_isLoggedIn) {
      logger.warning('IM未登录，无法发送正在输入提示', tag: 'TencentIMService');
      return;
    }
    try {
      final createRes = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .createCustomMessage(
        data: 'typing', // 简单标识
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
      logger.info('已发送正在输入在线消息给 $receiverID', tag: 'TencentIMService');
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
    if (!_isLoggedIn) {
      logger.warning('IM未登录，无法拉取历史消息', tag: 'TencentIMService');
      return null;
    }

    try {
      logger.info(
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
    if (!_isLoggedIn) {
      logger.warning('IM未登录，无法标记单聊消息已读', tag: 'TencentIMService');
      return null;
    }

    try {
      logger.info(
        '标记单聊消息已读: userID=$userID, count=${messageIDList?.length ?? 0}',
        tag: 'TencentIMService',
      );

      final res = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .markC2CMessageAsRead(
            userID: userID,
          );

      if (res.code == 0) {
        logger.info('标记单聊消息已读成功', tag: 'TencentIMService');
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

  /// 设置消息监听器
  void _setupMessageListener() {
    if (!_isInitialized) {
      logger.warning('IM SDK未初始化，无法添加监听器', tag: 'TencentIMService');
      return;
    }

    try {
      // 先移除旧的监听器（避免重复添加）
      try {
        TencentImSDKPlugin.v2TIMManager.getMessageManager().removeAdvancedMsgListener();
      } catch (e) {
        // 忽略移除失败的错误
      }
      
      // 添加新的监听器
      TencentImSDKPlugin.v2TIMManager.getMessageManager().addAdvancedMsgListener(
        listener: V2TimAdvancedMsgListener(
          onRecvNewMessage: (message) {
            logger.info('📨 收到新消息', tag: 'TencentIMService');
            logger.info(
              '消息基本信息 - ID: ${message.msgID}, 发送者: ${message.sender}, 类型: ${message.elemType}',
              tag: 'TencentIMService',
            );
            
            // 处理文本消息
            if (message.textElem != null && message.textElem!.text != null) {
              logger.info('📝 文本消息: ${message.textElem!.text}', tag: 'TencentIMService');
            }
            
            // 处理自定义消息（customElem）
            if (message.customElem != null && message.customElem!.data != null) {
              final custom = message.customElem!;
              logger.info(
                '🎯 自定义消息 - data: ${custom.data}, desc: ${custom.desc}, extension: ${custom.extension}',
                tag: 'TencentIMService',
              );

              // 处理绑定/解绑关系消息
              _handleRelationshipMessage(custom.data);
            }
            
            // 触发回调（将单个消息包装成列表）
            if (onReceiveNewMessage.value != null) {
              onReceiveNewMessage.value!([message]);
            }
          },
          onRecvMessageRevoked: (msgID) {
            logger.info('🔙 消息被撤回: $msgID', tag: 'TencentIMService');
            
            // 触发回调
            if (onRecvMessageRevoked.value != null) {
              onRecvMessageRevoked.value!(msgID);
            }
          },
          onRecvC2CReadReceipt: (receiptList) {
            logger.info('✅ 收到单聊消息已读回执', tag: 'TencentIMService');
            for (final receipt in receiptList) {
              logger.info(
                'C2C已读 - userID: ${receipt.userID}, msgID: ${receipt.msgID}, isPeerRead: ${receipt.isPeerRead}, timestamp: ${receipt.timestamp}',
                tag: 'TencentIMService',
              );
            }

            // 转发给业务层
            if (onRecvC2CReadReceiptCallback.value != null) {
              onRecvC2CReadReceiptCallback.value!(receiptList);
            }
          },
          onRecvMessageModified: (message) {
            logger.info('✏️ 消息被修改: ${message.msgID}', tag: 'TencentIMService');
          },
        ),
      );
      
      logger.info('✅ 消息监听器已成功设置', tag: 'TencentIMService');
    } catch (e) {
      logger.error('❌ 设置消息监听器失败: $e', tag: 'TencentIMService');
    }
  }

  /// 移除消息监听器
  void _removeMessageListener() {
    if (!_isInitialized) return;

    try {
      TencentImSDKPlugin.v2TIMManager.getMessageManager().removeAdvancedMsgListener();
      logger.info('消息监听器已移除', tag: 'TencentIMService');
    } catch (e) {
      logger.error('移除消息监听器失败: $e', tag: 'TencentIMService');
    }
  }

  /// 设置新消息接收回调
  /// 
  /// [callback] 接收到新消息时的回调函数
  /// 
  /// 示例：
  /// ```dart
  /// TencentIMService.instance.setOnReceiveNewMessage((messages) {
  ///   for (var msg in messages) {
  ///     print('收到消息: ${msg.textElem?.text}');
  ///   }
  /// });
  /// ```
  void setOnReceiveNewMessage(Function(List<V2TimMessage>) callback) {
    onReceiveNewMessage.value = callback;
    logger.info('已设置新消息接收回调', tag: 'TencentIMService');
  }

  /// 设置单聊消息已读回执回调
  void setOnRecvC2CReadReceipt(
      Function(List<V2TimMessageReceipt>) callback) {
    onRecvC2CReadReceiptCallback.value = callback;
    logger.info('已设置单聊消息已读回执回调', tag: 'TencentIMService');
  }

  /// 设置消息撤回回调
  /// 
  /// [callback] 消息被撤回时的回调函数
  /// 
  /// 示例：
  /// ```dart
  /// TencentIMService.instance.setOnRecvMessageRevoked((msgID) {
  ///   print('消息被撤回: $msgID');
  /// });
  /// ```
  void setOnRecvMessageRevoked(Function(String) callback) {
    onRecvMessageRevoked.value = callback;
    logger.info('已设置消息撤回回调', tag: 'TencentIMService');
  }

  /// 设置绑定消息接收回调
  /// 
  /// [callback] 收到绑定消息时的回调函数
  /// 
  /// 示例：
  /// ```dart
  /// TencentIMService.instance.setOnBindMessageReceived(() {
  ///   print('收到绑定消息，准备关闭绑定弹窗');
  /// });
  /// ```
  void setOnBindMessageReceived(Function() callback) {
    onBindMessageReceived.value = callback;
    logger.info('已设置绑定消息接收回调', tag: 'TencentIMService');
  }

  /// 清除所有回调
  void clearCallbacks() {
    onReceiveNewMessage.value = null;
    onRecvMessageRevoked.value = null;
    onBindMessageReceived.value = null;
    onRecvC2CReadReceiptCallback.value = null;
    logger.info('已清除所有回调', tag: 'TencentIMService');
  }

  /// 处理情侣关系绑定/解绑消息
  /// 
  /// [customData] 自定义消息数据（JSON字符串）
  void _handleRelationshipMessage(String? customData) async {
    if (customData == null || customData.isEmpty) {
      return;
    }

    try {
      // 解析JSON数据
      final Map<String, dynamic> data = jsonDecode(customData);
      final String? msgType = data['msg_type'];

      logger.info('处理关系消息 - msg_type: $msgType', tag: 'TencentIMService');

      if (msgType == null) {
        return;
      }

      // 已绑定用户不再处理绑定申请/拒绝类消息，避免重复弹窗/干扰
      try {
        final authService = getIt<AuthService>();
        final user = authService.currentUser;
        final bindStatus = user?.bindStatus?.toString();
        final bool isBound = bindStatus == "1";

        if (isBound && (msgType == 'bindRequest' || msgType == 'refuseRequest')) {
          logger.info(
            '当前用户已绑定，忽略关系消息: $msgType',
            tag: 'TencentIMService',
          );
          return;
        }
      } catch (e) {
        logger.warning('检查绑定状态失败，继续按默认逻辑处理关系消息: $e', tag: 'TencentIMService');
      }

      // 尝试获取动画服务并按消息类型处理
      try {
        final animationService = RelationshipAnimationService.instance;
        
        // 根据消息类型播放对应的GIF动画
        switch (msgType) {
          case 'bindAndroid':
          // 兼容服务端可能返回的 msg_type = "bind"
          case 'bind':
            logger.info('🎉 收到绑定消息 (bindAndroid/bind)，A和B都会收到此消息，统一处理绑定逻辑', tag: 'TencentIMService');
            await _handleBindMessage(animationService);
            break;
          case 'unbind':
            logger.info('💔 收到解绑关系消息，处理解绑逻辑', tag: 'TencentIMService');
            await _handleUnbindMessage(animationService);
            break;
          case 'refuseRequest':
            logger.info('💔 收到拒绝绑定消息', tag: 'TencentIMService');
            await _handleRefuseRequestMessage(data);
            break;
          case 'bindRequest':
            logger.info('💌 收到绑定申请', tag: 'TencentIMService');
            await _handleBindRequestMessage(data);
            break;
          default:
            logger.info('未知的消息类型: $msgType', tag: 'TencentIMService');
        }
      } catch (e) {
        logger.warning('动画服务未初始化或调用失败: $e', tag: 'TencentIMService');
      }
    } catch (e) {
      logger.error('解析关系消息失败: $e, 原始数据: $customData', tag: 'TencentIMService');
    }
  }

  /// 处理绑定消息（bindAndroid 类型）
  /// 当A给B发绑定申请，B点击确认后，服务器会发送 bindAndroid 消息给A和B
  /// 无论A还是B，收到该消息后都会执行以下逻辑：
  /// 1. 触发绑定消息回调（用于关闭绑定弹窗）
  /// 2. 刷新用户信息
  /// 3. 刷新当前页面
  /// 4. 播放绑定动画
  /// 5. 动画完成后判断自己是否是会员，如果不是则跳转到VIP页面
  Future<void> _handleBindMessage(RelationshipAnimationService animationService) async {
    try {
      // 0. 先触发绑定消息回调（关闭可能存在的绑定弹窗）
      logger.info('💬 触发绑定消息回调，准备关闭绑定弹窗...', tag: 'TencentIMService');
      if (onBindMessageReceived.value != null) {
        onBindMessageReceived.value!();
        logger.info('✅ 绑定消息回调已触发', tag: 'TencentIMService');
        // 等待弹窗关闭动画完成
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      // 1. 先刷新用户信息
      logger.info('📥 开始刷新用户信息...', tag: 'TencentIMService');
      final authService = getIt<AuthService>();
      await authService.refreshUserInfoFromServer();
      logger.info('✅ 用户信息刷新成功', tag: 'TencentIMService');
      
      // 2. 刷新当前页面
      animationService.refreshCurrentPage();
      
      // 3. 播放绑定动画，动画完成后根据会员状态决定是否跳转到VIP页面
      logger.info('🎬 开始播放绑定动画', tag: 'TencentIMService');
      animationService.showBindAnimation(onComplete: () {
        logger.info('🎯 绑定动画播放完成回调被触发', tag: 'TencentIMService');
        try {
          final isVip = authService.isVip;
          logger.info('当前用户VIP状态: $isVip', tag: 'TencentIMService');
          if (!isVip) {
            logger.info('📍 当前为非会员用户，准备跳转到VIP页面...', tag: 'TencentIMService');
            final result = Get.toNamed(
              KissuRoutePath.vip,
              arguments: {
                'previousPageName': 'IM绑定消息',
                'previousPageId': 'im_bind_message',
              },
            );
            logger.info('✅ VIP页面跳转已触发，返回值: $result', tag: 'TencentIMService');
          } else {
            logger.info('🎉 当前用户已是VIP，不跳转开通会员页面', tag: 'TencentIMService');
          }
        } catch (e) {
          logger.error('❌ 处理绑定动画完成后的跳转逻辑失败: $e', tag: 'TencentIMService');
        }
      });
    } catch (e) {
      logger.error('❌ 处理绑定消息失败: $e', tag: 'TencentIMService');
      // 即使失败也播放动画
      animationService.showBindAnimation();
    }
  }

  /// 处理解绑消息
  /// 1. 刷新用户信息
  /// 2. 播放解绑动画
  /// 3. 刷新当前页面
  Future<void> _handleUnbindMessage(RelationshipAnimationService animationService) async {
    try {
      // 1. 先刷新用户信息
      logger.info('📥 开始刷新用户信息...', tag: 'TencentIMService');
      final authService = getIt<AuthService>();
      await authService.refreshUserInfoFromServer();
      logger.info('✅ 用户信息刷新成功', tag: 'TencentIMService');
      
      // 2. 刷新当前页面
      animationService.refreshCurrentPage();
      
      // 3. 播放解绑动画
      logger.info('🎬 开始播放解绑动画', tag: 'TencentIMService');
      animationService.showUnbindAnimation();
    } catch (e) {
      logger.error('❌ 处理解绑消息失败: $e', tag: 'TencentIMService');
      // 即使失败也播放动画
      animationService.showUnbindAnimation();
    }
  }

  /// 处理绑定申请消息（bindRequest）
  /// 显示绑定申请弹窗，使用到的字段：
  /// - nickname: 对方昵称
  /// - head_portrait: 头像 URL（可能为空）
  /// - ext.system_notice_id: 系统通知ID（用于同意/拒绝接口）
  Future<void> _handleBindRequestMessage(Map<String, dynamic> data) async {
    try {
      final nickname = (data['nickname'] ?? '') as String;
      final headPortrait = (data['head_portrait'] ?? '') as String;
      final ext = (data['ext'] ?? {}) as Map<String, dynamic>;
      final systemNoticeId = (ext['system_notice_id'] ?? '') as String;

      logger.info(
        '处理绑定申请消息: nickname=$nickname, headPortrait=$headPortrait, systemNoticeId=$systemNoticeId',
        tag: 'TencentIMService',
      );

      if (Get.context == null) {
        logger.warning('当前没有可用的 BuildContext，无法显示绑定申请弹窗', tag: 'TencentIMService');
        return;
      }

      // 构造头像 ImageProvider
      ImageProvider avatarImage;
      if (headPortrait.isNotEmpty) {
        avatarImage = NetworkImage(headPortrait);
      } else {
        avatarImage = const AssetImage('assets/3.0/kissu3_love_avater.webp');
      }

      final context = Get.context!;

      await DialogManager.showBindRequest(
        context: context,
        avatarImage: avatarImage,
        nickname: nickname.isNotEmpty ? nickname : 'Ta',
        onAccept: () async {
          // 点击同意 -> 调用 /affirm/bind
          try {
            logger.info(
              '用户点击同意绑定，开始调用 affirmBind, system_notice_id=$systemNoticeId',
              tag: 'TencentIMService',
            );
            if (systemNoticeId.isEmpty) {
              logger.error('system_notice_id 为空，无法调用 affirmBind', tag: 'TencentIMService');
              CustomToast.show(context, '操作失败，缺少必要参数');
              return;
            }

            final result = await HttpManagerN.instance.executePost(
              ApiRequest.affirmBind,
              jsonParam: {'system_notice_id': systemNoticeId},
              paramEncrypt: false,
            );

            if (result.isSuccess) {
              CustomToast.show(context, result.msg ?? '申请成功');
              // 注意：不再在这里执行刷新用户信息、刷新页面、播放动画和跳转会员页面的逻辑
              // 这些逻辑统一由 bindAndroid 消息类型来处理，A和B都会收到该消息
              logger.info('✅ 绑定接口调用成功，等待 bindAndroid 消息处理后续逻辑', tag: 'TencentIMService');
            } else {
              CustomToast.show(context, result.msg ?? '绑定失败');
            }
          } catch (e) {
            logger.error('调用 affirmBind 接口异常: $e', tag: 'TencentIMService');
            CustomToast.show(context, '绑定失败: $e');
          }
        },
        onReject: () async {
          // 点击拒绝按钮 -> 先弹确认拒绝的小弹窗，再决定是否真正调用 /refuse/bind
          try {
            logger.info('用户点击拒绝绑定，展示二次确认弹窗', tag: 'TencentIMService');

            final result = await _showSmallConfirmDialog(
              content: '你确定拒绝“$nickname”绑定申请？',
              confirmText: '确定',
              cancelText: '再想想',
              barrierDismissible: false,
            );

            if (result == true) {
              // 确认拒绝 -> 调用 /refuse/bind
              if (systemNoticeId.isEmpty) {
                logger.error('system_notice_id 为空，无法调用 refuseBind', tag: 'TencentIMService');
                CustomToast.show(context, '操作失败，缺少必要参数');
                return;
              }

              logger.info(
                '用户确认拒绝绑定，开始调用 refuseBind, system_notice_id=$systemNoticeId',
                tag: 'TencentIMService',
              );

              final apiResult = await HttpManagerN.instance.executePost(
                ApiRequest.refuseBind,
                jsonParam: {'system_notice_id': systemNoticeId},
                paramEncrypt: false,
              );

              if (apiResult.isSuccess) {
                CustomToast.show(context, '已拒绝绑定');
              } else {
                CustomToast.show(context, apiResult.msg ?? '操作失败');
              }
            } else {
              logger.info('用户选择再想想，不执行拒绝绑定接口', tag: 'TencentIMService');
            }
          } catch (e) {
            logger.error('处理拒绝绑定确认流程异常: $e', tag: 'TencentIMService');
          }
        },
        barrierDismissible: false,
      );
    } catch (e) {
      logger.error('处理绑定申请消息失败: $e, data=$data', tag: 'TencentIMService');
    }
  }

  /// 处理拒绝绑定通知消息（refuseRequest）
  /// 使用到的字段：
  /// - friend_code: 好友邀请码（再次发起绑定时使用）
  Future<void> _handleRefuseRequestMessage(Map<String, dynamic> data) async {
    try {
      final friendCode = (data['friend_code'] ?? '') as String;

      logger.info(
        '处理拒绝绑定通知消息: friend_code=$friendCode',
        tag: 'TencentIMService',
      );

      if (Get.context == null) {
        logger.warning('当前没有可用的 BuildContext，无法显示拒绝绑定提示弹窗', tag: 'TencentIMService');
        return;
      }

      final context = Get.context!;

      final result = await _showSmallConfirmDialog(
        content: '很遗憾，对方拒绝了你的绑定申请！',
        confirmText: '知道了',
        cancelText: '再次发起',
      );

      // 这里约定：true 表示点击“知道了”，false 表示点击“再次发起”
      if (result == false) {
        // 再次发起绑定
        if (friendCode.isEmpty) {
          logger.error('friend_code 为空，无法再次发起绑定', tag: 'TencentIMService');
          CustomToast.show(context, '无法再次发起绑定，缺少好友码');
          return;
        }

        try {
          logger.info('用户选择再次发起绑定，调用 /start/bind, friend_code=$friendCode', tag: 'TencentIMService');
          final authApi = AuthApi();
          final bindResult = await authApi.bindPartner(friendCode: friendCode);

          if (bindResult.isSuccess) {
            CustomToast.show(context, '已再次发起绑定申请');
          } else {
            CustomToast.show(context, bindResult.msg ?? '再次发起绑定失败');
          }
        } catch (e) {
          logger.error('再次发起绑定异常: $e', tag: 'TencentIMService');
          CustomToast.show(context, '再次发起绑定失败: $e');
        }
      } else {
        logger.info('用户点击“知道了”，不再发起绑定', tag: 'TencentIMService');
      }
    } catch (e) {
      logger.error('处理拒绝绑定通知消息失败: $e, data=$data', tag: 'TencentIMService');
    }
  }

  /// 使用小背景图 kisuu4_dialog_small_bg 的二次确认弹窗
  /// 返回 true 表示点击右侧粉色按钮（confirmText），false 表示点击左侧灰色按钮（cancelText），null 表示关闭
  Future<bool?> _showSmallConfirmDialog({
    required String content,
    required String confirmText,
    required String cancelText,
    bool barrierDismissible = true,
  }) {
    return Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/dialog/kissu4_dialog_small_bg.webp'),
              fit: BoxFit.fill,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Get.back(result: true);
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFffffff),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF999999),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            confirmText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xff999999),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),const SizedBox(width: 12),Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Get.back(result: false);
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9AD9),
                            borderRadius: BorderRadius.circular(20),
                            
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cancelText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFffffff),
                              fontWeight: FontWeight.w500,
                            ),
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
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  /// 手动强制设置消息监听器
  /// 
  /// 如果发现收不到消息，可以调用此方法手动设置监听器
  /// 
  /// 示例：
  /// ```dart
  /// TencentIMService.instance.forceSetupMessageListener();
  /// ```
  void forceSetupMessageListener() {
    logger.info('🔄 手动强制设置消息监听器', tag: 'TencentIMService');
    _setupMessageListener();
  }

  /// 检查IM状态并打印详细信息
  /// 
  /// 用于调试，查看当前IM的状态
  void checkIMStatus() {
    logger.info('====== IM状态检查 ======', tag: 'TencentIMService');
    logger.info('SDK已初始化: $_isInitialized', tag: 'TencentIMService');
    logger.info('已登录: $_isLoggedIn', tag: 'TencentIMService');
    logger.info('当前用户ID: $_currentUserID', tag: 'TencentIMService');
    logger.info('新消息回调已设置: ${onReceiveNewMessage.value != null}', tag: 'TencentIMService');
    logger.info('消息撤回回调已设置: ${onRecvMessageRevoked.value != null}', tag: 'TencentIMService');
    logger.info('========================', tag: 'TencentIMService');
  }

  @override
  void onClose() {
    _removeMessageListener();
    clearCallbacks();
    unInitIM();
    super.onClose();
  }
}
