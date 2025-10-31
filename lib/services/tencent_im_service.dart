import 'dart:convert';
import 'package:get/get.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimSDKListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/log_level_enum.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_callback.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
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
  final Rx<Function(List<V2TimMessage>)?> onReceiveNewMessage = Rx<Function(List<V2TimMessage>)?>(null);
  
  // 消息撤回回调
  final Rx<Function(String)?> onRecvMessageRevoked = Rx<Function(String)?>(null);

  @override
  void onInit() {
    super.onInit();
    _initIM();
  }

  /// 初始化IM SDK
  Future<bool> _initIM() async {
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
      final initSuccess = await _initIM();
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
      V2TimValueCallback createResult = 
          await TencentImSDKPlugin.v2TIMManager
              .getMessageManager()
              .createTextMessage(text: text);

      if (createResult.code != 0) {
        logger.error(
          '创建消息失败: ${createResult.desc}',
          tag: 'TencentIMService',
        );
        return null;
      }

      // 发送消息
      V2TimValueCallback<V2TimMessage> sendResult = 
          await TencentImSDKPlugin.v2TIMManager
              .getMessageManager()
              .sendMessage(
                receiver: isGroup ? '' : receiverID,
                groupID: isGroup ? receiverID : '',
              );

      if (sendResult.code == 0) {
        logger.info('消息发送成功', tag: 'TencentIMService');
      } else {
        logger.error(
          '消息发送失败: ${sendResult.desc}',
          tag: 'TencentIMService',
        );
      }

      return sendResult;
    } catch (e) {
      logger.error('发送消息异常: $e', tag: 'TencentIMService');
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
            
            // 处理自定义消息（在elemList中）
            if (message.elemList.isNotEmpty) {
              logger.info('📋 消息包含 ${message.elemList.length} 个元素', tag: 'TencentIMService');
              for (int i = 0; i < message.elemList.length; i++) {
                final elem = message.elemList[i];
                logger.info(
                  '  元素[$i] - 类型: ${elem.elemType}, 自定义数据: ${elem.data}, 扩展: ${elem.extension}',
                  tag: 'TencentIMService',
                );
                
                // 如果是自定义消息（类型为2），详细打印并处理
                if (elem.elemType == 2 && elem.data != null) {
                  logger.info(
                    '  🎯 自定义消息 - data: ${elem.data}, desc: ${elem.desc}, extension: ${elem.extension}',
                    tag: 'TencentIMService',
                  );
                  
                  // 处理绑定/解绑关系消息
                  _handleRelationshipMessage(elem.data);
                }
              }
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

  /// 清除所有回调
  void clearCallbacks() {
    onReceiveNewMessage.value = null;
    onRecvMessageRevoked.value = null;
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

      // 尝试获取动画服务
      try {
        final animationService = RelationshipAnimationService.instance;
        
        // 根据消息类型播放对应的GIF动画
        switch (msgType) {
          case 'bind':
            logger.info('🎉 收到绑定关系消息，处理绑定逻辑', tag: 'TencentIMService');
            await _handleBindMessage(animationService);
            break;
          case 'unbind':
            logger.info('💔 收到解绑关系消息，处理解绑逻辑', tag: 'TencentIMService');
            await _handleUnbindMessage(animationService);
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

  /// 处理绑定消息
  /// 1. 刷新用户信息
  /// 2. 播放绑定动画
  /// 3. 动画完成后跳转到VIP页面
  /// 4. 刷新当前页面
  Future<void> _handleBindMessage(RelationshipAnimationService animationService) async {
    try {
      // 1. 先刷新用户信息
      logger.info('📥 开始刷新用户信息...', tag: 'TencentIMService');
      final authService = getIt<AuthService>();
      await authService.refreshUserInfoFromServer();
      logger.info('✅ 用户信息刷新成功', tag: 'TencentIMService');
      
      // 2. 刷新当前页面
      animationService.refreshCurrentPage();
      
      // 3. 播放绑定动画，动画完成后跳转到VIP页面
      logger.info('🎬 开始播放绑定动画', tag: 'TencentIMService');
      animationService.showBindAnimation(onComplete: () {
        logger.info('🎯 绑定动画播放完成回调被触发', tag: 'TencentIMService');
        try {
          logger.info('📍 准备跳转到VIP页面...', tag: 'TencentIMService');
          final result = Get.toNamed(
            KissuRoutePath.vip,
            arguments: {
              'previousPageName': 'IM绑定消息',
              'previousPageId': 'im_bind_message',
            },
          );
          logger.info('✅ VIP页面跳转已触发，返回值: $result', tag: 'TencentIMService');
        } catch (e) {
          logger.error('❌ 跳转VIP页面失败: $e', tag: 'TencentIMService');
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
