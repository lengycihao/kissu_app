import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/services/analytics/analytics_page_ids.dart';
import 'package:kissu_app/constants/app_constants.dart';
import 'package:kissu_app/utils/source_page_utils.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimSDKListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/log_level_enum.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_callback.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_msg_create_info_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_receipt.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_value_callback.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_info.dart';
import 'package:tencent_cloud_chat_sdk/enum/offlinePushInfo.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimAdvancedMsgListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimFriendshipListener.dart';
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
import 'package:kissu_app/widgets/chat_new_message_banner.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/network/public/auth_api.dart';
import 'package:tencent_cloud_chat_push/tencent_cloud_chat_push.dart';
import 'package:kissu_app/services/lock_screen_overlay_service.dart';
import 'package:kissu_app/pages/chat/chat_controller.dart';
import 'package:kissu_app/pages/mine/mine_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'tencent_im_service_messaging.dart';
part 'tencent_im_service_lock.dart';
part 'tencent_im_service_relationship.dart';
part 'tencent_im_service_push.dart';

/// 腾讯IM服务
/// 
/// 功能：
/// - IM SDK初始化
/// - 用户登录/登出
/// - 消息监听
class TencentIMService extends GetxService {
  static TencentIMService get instance => Get.find<TencentIMService>();
  
  // IM SDK AppID
  static const int sdkAppID = AppConstants.tencentIMSdkAppID;
  
  // 🔥 腾讯云IM推送服务客户端密钥（从IM控制台 > 推送服务Push > 接入设置 获取）
  // 注意：这个appKey是腾讯云IM推送专用的，不是极光推送的appKey
  static const String pushAppKey = AppConstants.tencentIMPushAppKey;
  
  // 是否已初始化
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  // 是否已登录
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  
  // 当前登录的用户ID
  String? _currentUserID;
  String? get currentUserID => _currentUserID;
  
  // 🔥 修复：用户切换标志位，防止切换账号时自动重连干扰新用户登录
  bool _isUserSwitching = false;

  // 消息接收回调
  final Rx<Function(List<V2TimMessage>)?> onReceiveNewMessage =
      Rx<Function(List<V2TimMessage>)?>(null);

  /// 单聊未读消息数量（当前应用只支持另一半的单聊，会话未读总数）
  final RxInt c2cUnreadCount = 0.obs;
  
  // 消息撤回回调
  final Rx<Function(String)?> onRecvMessageRevoked =
      Rx<Function(String)?>(null);

  // 单聊消息已读回执回调
  final Rx<Function(List<V2TimMessageReceipt>)?> onRecvC2CReadReceiptCallback =
      Rx<Function(List<V2TimMessageReceipt>)?>(null);

  // 绑定消息接收回调（当收到绑定消息时触发，用于自动关闭绑定弹窗等操作）
  final Rx<Function()?> onBindMessageReceived = Rx<Function()?>(null);

  // 🔥 被锁方解锁通知回调（锁机方收到后重置锁机页面，参数为答题次数）
  final Rx<Function(int)?> onUnlockPhoneReceived = Rx<Function(int)?>(null);

  // ===== 模块化处理器 =====
  late final _IMMessageHandler _messageHandler = _IMMessageHandler(this);
  late final _IMLockScreenHandler _lockHandler = _IMLockScreenHandler(this);
  late final _IMRelationshipHandler _relationshipHandler = _IMRelationshipHandler(this);
  late final _IMPushHandler _pushHandler = _IMPushHandler(this);

  @override
  void onInit() {
    super.onInit();
    // 🔥 修复：延迟初始化IM SDK，等待用户同意隐私政策后再初始化
    // 不在 onInit 中立即初始化，避免在用户未同意隐私政策前获取设备信息
    // IM SDK 将在用户同意隐私政策后，由 PrivacyComplianceManager 调用初始化
  }

  // 🔥 用于等待SDK初始化完成的Completer
  Completer<bool>? _initCompleter;

  // 🔥 用于防止并发调用 ensureIMLoginStatus 的Completer
  Completer<void>? _ensureLoginCompleter;

  // 🔥 记录SDK Listener是否已注册，避免重复注册导致回调触发多次
  bool _sdkListenerRegistered = false;
  
  /// 初始化IM SDK
  /// 🔥 修复：公开此方法，供 PrivacyComplianceManager 在用户同意隐私政策后调用
  Future<bool> initIM() async {
    if (_isInitialized) {
      logger.info('IM SDK 已经初始化', tag: 'TencentIMService');
      return true;
    }
    
    // 🔥 如果正在初始化中，等待初始化完成
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      logger.info('IM SDK正在初始化中，等待完成...', tag: 'TencentIMService');
      return await _initCompleter!.future;
    }
    
    _initCompleter = Completer<bool>();

    try {
      logger.info('开始初始化腾讯IM SDK...', tag: 'TencentIMService');
      
      // 🔥 修复：先调用unInitSDK重置Flutter插件内部缓存状态
      // 否则Flutter插件认为已初始化，initSDK会返回成功但不会真正调用native层
      try {
        await TencentImSDKPlugin.v2TIMManager.unInitSDK();
        logger.debug('已重置Flutter插件SDK状态', tag: 'TencentIMService');
      } catch (e) {
        logger.debug('重置Flutter插件SDK状态(忽略错误): $e', tag: 'TencentIMService');
      }
      
      // 🔥 修复：只在首次注册SDK Listener，避免重复注册导致回调触发多次
      // 每次initIM都会被调用（因为被踢下线后_isInitialized=false），
      // 如果每次都传新的listener，会导致onKickedOffline被调用N次
      V2TimSDKListener? sdkListener;
      if (!_sdkListenerRegistered) {
        sdkListener = V2TimSDKListener(
          onConnecting: () {
            logger.debug('IM正在连接...', tag: 'TencentIMService');
          },
          onConnectSuccess: () {
            logger.debug('IM连接成功', tag: 'TencentIMService');
          },
          onConnectFailed: (code, error) {
            logger.error('IM连接失败: code=$code, error=$error', tag: 'TencentIMService');
          },
          onKickedOffline: () {
            logger.warning('IM账号被踢下线', tag: 'TencentIMService');
            _isLoggedIn = false;
            _currentUserID = null;
            // 🔥 重要：被踢下线时SDK会被内部卸载，需要重置初始化状态
            _isInitialized = false;
            // 🔥 修复：如果是用户主动切换账号，不要自动重连，避免干扰新用户登录
            if (_isUserSwitching) {
              logger.info('用户正在切换账号，跳过自动重连', tag: 'TencentIMService');
              return;
            }
            // 🔥 修复：被踢下线（多设备登录）时不自动重连
            // 因为同一账号在多设备登录会导致互相踢下线形成死循环
            // 用户需要手动刷新或重新进入聊天页面来触发重新登录
            logger.info('账号在其他设备登录，不自动重连', tag: 'TencentIMService');
          },
          onUserSigExpired: () {
            logger.warning('IM UserSig已过期', tag: 'TencentIMService');
            _isLoggedIn = false;
            _currentUserID = null;
            // 🔥 修复：签名过期后尝试自动重新登录
            Future.microtask(() => _attemptReconnect());
          },
          onSelfInfoUpdated: (info) {
            logger.debug('IM个人资料更新', tag: 'TencentIMService');
          },
        );
        _sdkListenerRegistered = true;
      }

      // 初始化SDK
      V2TimValueCallback<bool> initResult = await TencentImSDKPlugin.v2TIMManager.initSDK(
        sdkAppID: sdkAppID,
        loglevel: LogLevelEnum.V2TIM_LOG_DEBUG,
        listener: sdkListener,
      );

      if (initResult.code == 0) {
        _isInitialized = true;
        logger.debug('腾讯IM SDK初始化成功', tag: 'TencentIMService');
        
        // 🔥 修复：等待SDK内部初始化完成
        // initSDK返回成功只是表示调用成功，需要等待一小段时间让SDK内部完成初始化
        await Future.delayed(const Duration(milliseconds: 500));
        logger.debug('IM SDK初始化等待完成', tag: 'TencentIMService');
        
        _initCompleter?.complete(true);
        return true;
      } else {
        logger.error(
          'IM SDK初始化失败: ${initResult.desc}',
          tag: 'TencentIMService',
        );
        _initCompleter?.complete(false);
        return false;
      }
    } catch (e) {
      logger.error('IM SDK初始化异常: $e', tag: 'TencentIMService');
      _initCompleter?.complete(false);
      return false;
    }
  }

  /// 用户登录IM
  /// 
  /// [user] 登录用户信息，需要包含uniqueId和imSign
  Future<bool> loginIM(LoginModel user) async {
    // 🔥 增强日志：记录登录参数状态
    logger.info(
      'IM登录请求 - uniqueId: ${user.uniqueId ?? "null"}, hasImSign: ${user.imSign != null && user.imSign!.isNotEmpty}, userId: ${user.id}',
      tag: 'TencentIMService',
    );
    
    // 🔥 修复：强制重新初始化SDK，确保SDK状态正确
    // 因为SDK可能被内部卸载（如被踢下线后），但_isInitialized变量没有更新
    if (!_isInitialized) {
      logger.warning('IM SDK未初始化，尝试先初始化', tag: 'TencentIMService');
      final initSuccess = await initIM();
      if (!initSuccess) {
        logger.error('IM SDK初始化失败，无法登录', tag: 'TencentIMService');
        return false;
      }
    } else {
      // 🔥 即使_isInitialized为true，也尝试重新初始化以确保SDK状态正确
      // initIM内部会检查是否已初始化，如果已初始化会直接返回true
      // 但如果SDK被内部卸载了，重新初始化可以修复状态
      logger.debug('IM SDK标记为已初始化，验证SDK状态...', tag: 'TencentIMService');
    }

    // 检查必要参数
    if (user.uniqueId == null || user.uniqueId!.isEmpty) {
      logger.error('IM登录失败: uniqueId为空, userId=${user.id}', tag: 'TencentIMService');
      return false;
    }

    if (user.imSign == null || user.imSign!.isEmpty) {
      logger.error('IM登录失败: imSign为空, uniqueId=${user.uniqueId}, userId=${user.id}', tag: 'TencentIMService');
      return false;
    }

    // 如果已经登录同一个用户，不需要重复登录，但要确保监听器已设置
    if (_isLoggedIn && _currentUserID == user.uniqueId) {
      logger.debug('IM已登录该用户: ${user.uniqueId}', tag: 'TencentIMService');
      
      // 确保消息监听器已设置（应对应用重启或热重载的情况）
      _setupMessageListener();
      
      // 🔥 重新注册推送服务（应对App被杀后重启的情况）
      // 即使已经登录，每次App启动时都需要重新注册推送，确保设备token有效
      await _pushHandler.registerPushService();
      logger.debug('已重新注册推送服务（App重启场景）', tag: 'TencentIMService');
      
      return true;
    }

    try {
      logger.debug(
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
        // 🔥 修复：登录成功后重置用户切换标志位
        _isUserSwitching = false;
        logger.debug(
          'IM登录成功: userID=${user.uniqueId}',
          tag: 'TencentIMService',
        );
        
        // 🔥 保存IM凭证到SharedPreferences供原生层保活锁屏使用
        _saveImCredentialsForNative(user.uniqueId!, user.imSign!);
        
        // 设置消息监听器（同步操作，立即完成）
        _setupMessageListener();

        // 设置好友关系监听器（同步操作，立即完成）
        _setupFriendshipListener();

        // 🔥 修复：推送注册和用户资料更新改为异步不等待
        // 避免在await期间被其他设备踢下线导致登录状态丢失
        _postLoginAsyncTasks(user);
        
        return true;
      } else if (loginResult.code == 6013) {
        // 🔥 修复：SDK未初始化错误，强制重新初始化后重试
        logger.warning('IM登录失败(6013: not initialized)，强制重新初始化SDK', tag: 'TencentIMService');
        _isInitialized = false; // 重置初始化状态
        final reinitSuccess = await initIM();
        if (reinitSuccess) {
          // 重新初始化成功，再次尝试登录
          logger.debug('SDK重新初始化成功，再次尝试登录', tag: 'TencentIMService');
          V2TimCallback retryResult = await TencentImSDKPlugin.v2TIMManager.login(
            userID: user.uniqueId!,
            userSig: user.imSign!,
          );
          if (retryResult.code == 0) {
            _isLoggedIn = true;
            _currentUserID = user.uniqueId;
            // 🔥 修复：登录成功后重置用户切换标志位
            _isUserSwitching = false;
            logger.debug('IM重新登录成功: userID=${user.uniqueId}', tag: 'TencentIMService');
            
            // 🔥 保存IM凭证到SharedPreferences供原生层保活锁屏使用
            _saveImCredentialsForNative(user.uniqueId!, user.imSign!);
            
            _setupMessageListener();
            _setupFriendshipListener();
            // 🔥 修复：推送注册和用户资料更新改为异步不等待
            _postLoginAsyncTasks(user);
            return true;
          } else {
            logger.error('IM重新登录失败: code=${retryResult.code}, desc=${retryResult.desc}', tag: 'TencentIMService');
            return false;
          }
        } else {
          logger.error('SDK重新初始化失败', tag: 'TencentIMService');
          return false;
        }
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

  /// 🔥 保存IM凭证到SharedPreferences供原生层使用（保活状态下原生IM登录）
  void _saveImCredentialsForNative(String userId, String userSig) {
    Future(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('im_user_id', userId);
        await prefs.setString('im_user_sig', userSig);
        logger.debug('IM凭证已保存供原生层使用', tag: 'TencentIMService');
      } catch (e) {
        logger.warning('保存IM凭证失败: $e', tag: 'TencentIMService');
      }
    });
  }

  /// 🔥 修复：登录成功后的异步任务（不阻塞loginIM返回）
  /// 包括用户资料更新和推送服务注册，这些操作耗时较长
  /// 如果在这些操作期间被踢下线，不影响loginIM已经返回true的结果
  void _postLoginAsyncTasks(LoginModel user) {
    Future(() async {
      try {
        // 更新用户资料
        if (user.nickname != null || user.headPortrait != null) {
          await _updateUserProfile(
            nickname: user.nickname,
            avatarUrl: user.headPortrait,
          );
        }
        // 注册推送服务
        await _pushHandler.registerPushService();
      } catch (e) {
        logger.error('登录后异步任务异常: $e', tag: 'TencentIMService');
      }
    });
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
      logger.debug('IM用户资料更新成功', tag: 'TencentIMService');
    } catch (e) {
      logger.error('IM用户资料更新失败: $e', tag: 'TencentIMService');
    }
  }

  /// 获取用户信息（包含昵称、头像等）
  Future<V2TimUserFullInfo?> getUsersInfo(String userID) async {
    if (!_isInitialized) return null;
    try {
      final res = await TencentImSDKPlugin.v2TIMManager.getUsersInfo(userIDList: [userID]);
      if (res.code == 0 && res.data != null && res.data!.isNotEmpty) {
        return res.data![0];
      }
    } catch (e) {
      logger.error('获取IM用户信息失败: $e', tag: 'TencentIMService');
    }
    return null;
  }

  /// 获取好友资料（包含备注）
  Future<V2TimFriendInfo?> getFriendInfo(String userID) async {
    if (!_isInitialized) return null;
    try {
      final res = await TencentImSDKPlugin.v2TIMManager.getFriendshipManager().getFriendsInfo(userIDList: [userID]);
      if (res.code == 0 && res.data != null && res.data!.isNotEmpty) {
        return res.data![0].friendInfo;
      }
    } catch (e) {
      logger.error('获取IM好友信息失败: $e', tag: 'TencentIMService');
    }
    return null;
  }

  /// 设置好友备注
  Future<bool> setFriendRemark(String userID, String remark) async {
    if (!_isInitialized) return false;
    try {
      final res = await TencentImSDKPlugin.v2TIMManager.getFriendshipManager().setFriendInfo(
        userID: userID,
        friendRemark: remark,
      );
      return res.code == 0;
    } catch (e) {
      logger.error('设置IM好友备注失败: $e', tag: 'TencentIMService');
    }
    return false;
  }

  /// 对外暴露的“仅更新昵称”方法（供设置页等调用）
  Future<void> updateSelfNickname(String nickname) async {
    // 直接复用内部资料更新逻辑，只传入昵称
    await _updateUserProfile(nickname: nickname);
  }

  /// 退出登录IM
  /// [isUserSwitching] 是否是用户主动切换账号，如果是则设置标志位防止自动重连
  Future<bool> logoutIM({bool isUserSwitching = false}) async {
    // 🔥 修复：设置用户切换标志位，防止被踢下线时自动重连干扰新用户登录
    if (isUserSwitching) {
      _isUserSwitching = true;
      logger.debug('用户切换账号，设置切换标志位', tag: 'TencentIMService');
    }
    
    if (!_isLoggedIn) {
      logger.debug('IM未登录，无需退出', tag: 'TencentIMService');
      return true;
    }

    try {
      logger.debug('开始退出IM登录...', tag: 'TencentIMService');
      
      // 移除消息监听器
      _removeMessageListener();

      // 移除好友关系监听器
      _removeFriendshipListener();

      // 清除回调
      clearCallbacks();
      
      // 🔥 反注册推送服务
      await _pushHandler.unRegisterPushService();
      
      V2TimCallback result = await TencentImSDKPlugin.v2TIMManager.logout();
      
      if (result.code == 0) {
        _isLoggedIn = false;
        _currentUserID = null;
        // 🔥 修复：logout后SDK会自动InternalUninit，必须重置初始化状态
        _isInitialized = false;
        logger.debug('IM退出登录成功', tag: 'TencentIMService');
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

  // 🔥 重连控制变量
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  static const Duration _reconnectDelay = Duration(seconds: 2);

  /// 🔥 新增：尝试重新连接 IM（带重试机制）
  Future<void> _attemptReconnect() async {
    // 🔥 修复：如果用户正在切换账号，跳过自动重连
    if (_isUserSwitching) {
      logger.debug('用户正在切换账号，跳过自动重连', tag: 'TencentIMService');
      return;
    }
    
    // 防止重复重连
    if (_isReconnecting) {
      logger.debug('IM正在重连中，跳过重复调用', tag: 'TencentIMService');
      return;
    }
    
    _isReconnecting = true;
    _reconnectAttempts = 0;
    
    try {
      // 🔥 修复：如果SDK未初始化，先初始化
      if (!_isInitialized) {
        logger.debug('IM SDK未初始化，尝试重新初始化', tag: 'TencentIMService');
        final initSuccess = await initIM();
        if (!initSuccess) {
          logger.error('IM SDK重新初始化失败，放弃重连', tag: 'TencentIMService');
          return;
        }
      }
      
      while (_reconnectAttempts < _maxReconnectAttempts) {
        _reconnectAttempts++;
        logger.debug('开始尝试重新连接IM (第$_reconnectAttempts次)...', tag: 'TencentIMService');
        
        // 🔥 修复：AuthService 是通过 GetIt 注册的，不是 GetX
        if (!getIt.isRegistered<AuthService>()) {
          logger.warning('AuthService未注册，无法重新登录IM', tag: 'TencentIMService');
          break;
        }
        
        final authService = getIt<AuthService>();
        if (!authService.isLoggedIn || authService.currentUser == null) {
          logger.info('无已登录用户，跳过IM自动重新登录', tag: 'TencentIMService');
          break;
        }
        
        // 检查本地缓存的 imSign 是否存在
        final user = authService.currentUser!;
        if (user.imSign == null || user.imSign!.isEmpty) {
          logger.warning('本地缓存的imSign为空，尝试刷新用户信息', tag: 'TencentIMService');
          final refreshSuccess = await authService.refreshUserInfoFromServer();
          if (!refreshSuccess) {
            logger.error('刷新用户信息失败', tag: 'TencentIMService');
            // 等待后重试
            if (_reconnectAttempts < _maxReconnectAttempts) {
              await Future.delayed(_reconnectDelay);
              continue;
            }
            break;
          }
        }
        
        // 使用最新的用户信息重新登录
        final latestUser = authService.currentUser!;
        
        // 再次检查 imSign
        if (latestUser.imSign == null || latestUser.imSign!.isEmpty) {
          logger.error('imSign仍然为空，无法登录IM', tag: 'TencentIMService');
          if (_reconnectAttempts < _maxReconnectAttempts) {
            await Future.delayed(_reconnectDelay);
            continue;
          }
          break;
        }
        
        logger.debug('尝试重新登录IM: ${latestUser.uniqueId}', tag: 'TencentIMService');
        
        // 重新登录
        final success = await loginIM(latestUser);
        if (success) {
          logger.debug('IM自动重新登录成功 (第$_reconnectAttempts次尝试)', tag: 'TencentIMService');
          break;
        } else {
          logger.warning('IM自动重新登录失败 (第$_reconnectAttempts次尝试)', tag: 'TencentIMService');
          if (_reconnectAttempts < _maxReconnectAttempts) {
            await Future.delayed(_reconnectDelay);
          }
        }
      }
      
      if (_reconnectAttempts >= _maxReconnectAttempts && !_isLoggedIn) {
        logger.error('IM重连已达最大尝试次数($_maxReconnectAttempts)，放弃重连', tag: 'TencentIMService');
      }
    } catch (e) {
      logger.error('IM自动重新登录异常: $e', tag: 'TencentIMService');
    } finally {
      _isReconnecting = false;
    }
  }

  /// 🔥 新增：确保 IM 登录状态（App 恢复前台时 / 聊天页面调用）
  /// 检查当前 IM 状态，如果未登录则尝试重新登录
  /// 包含重试机制：如果登录后被其他设备踢下线，等待后重试
  /// 🔥 使用 Completer 防止多个调用方并发执行，避免重复登录
  Future<void> ensureIMLoginStatus() async {
    // 防止重复调用（_attemptReconnect正在执行）
    if (_isReconnecting) {
      logger.debug('IM正在重连中，跳过ensureIMLoginStatus', tag: 'TencentIMService');
      return;
    }
    
    // 🔥 修复：如果已有ensureLogin正在执行，等待它完成而不是重复执行
    if (_ensureLoginCompleter != null && !_ensureLoginCompleter!.isCompleted) {
      logger.debug('ensureIMLoginStatus已在执行中，等待完成...', tag: 'TencentIMService');
      await _ensureLoginCompleter!.future;
      return;
    }
    
    // 如果已经登录，不需要处理
    if (_isLoggedIn && _currentUserID != null) {
      logger.debug('IM已登录，无需重新连接: $_currentUserID', tag: 'TencentIMService');
      return;
    }
    
    _ensureLoginCompleter = Completer<void>();
    
    try {
      // 🔥 修复：AuthService 是通过 GetIt 注册的，不是 GetX
      if (!getIt.isRegistered<AuthService>()) {
        logger.debug('AuthService未注册，跳过IM状态检查', tag: 'TencentIMService');
        return;
      }
      
      final authService = getIt<AuthService>();
      if (!authService.isLoggedIn || authService.currentUser == null) {
        logger.debug('用户未登录，跳过IM状态检查', tag: 'TencentIMService');
        return;
      }
      
      // 🔥 修复：增加重试次数和等待时间
      // 场景：A手机运行旧代码会在被踢后自动重连，导致互踢循环
      // 旧代码_attemptReconnect最多重试3次，每次间隔约3秒，总计~9秒
      // 所以B手机需要更持久：5次重试，每次间隔3秒，总计~15秒
      const int maxRetries = 4;
      for (int attempt = 0; attempt <= maxRetries; attempt++) {
        if (attempt > 0) {
          // 🔥 递增等待时间：第2次3秒，第3次3秒，第4次4秒，第5次5秒
          final waitSeconds = attempt <= 2 ? 3 : attempt + 1;
          logger.debug('IM登录被踢下线，等待$waitSeconds秒后第${attempt + 1}次尝试...', tag: 'TencentIMService');
          await Future.delayed(Duration(seconds: waitSeconds));
          
          // 等待后再次检查是否已登录（可能其他流程已经登录成功）
          if (_isLoggedIn && _currentUserID != null) {
            logger.debug('等待期间IM已恢复登录: $_currentUserID', tag: 'TencentIMService');
            return;
          }
        }
        
        // 如果SDK未初始化，先初始化
        if (!_isInitialized) {
          logger.debug('IM SDK未初始化，尝试重新初始化', tag: 'TencentIMService');
          final initSuccess = await initIM();
          if (!initSuccess) {
            logger.error('IM SDK重新初始化失败', tag: 'TencentIMService');
            return;
          }
        }
        
        logger.debug('检测到IM未登录，尝试重新连接（第${attempt + 1}次）...', tag: 'TencentIMService');
        
        // 获取最新用户信息
        var user = authService.currentUser!;
        if (user.imSign == null || user.imSign!.isEmpty) {
          logger.warning('本地imSign为空，尝试刷新用户信息', tag: 'TencentIMService');
          await authService.refreshUserInfoFromServer();
          user = authService.currentUser!;
        }
        
        if (user.imSign == null || user.imSign!.isEmpty) {
          logger.error('imSign为空，无法登录IM', tag: 'TencentIMService');
          return;
        }
        
        // 使用最新的用户信息登录
        final success = await loginIM(user);
        if (!success) {
          logger.error('IM重新连接失败', tag: 'TencentIMService');
          return;
        }
        
        // 🔥 关键：登录成功后等待一小段时间，检查是否被其他设备踢下线
        // 因为loginIM现在不等待推送注册，所以很快返回
        // 但其他设备的自动重连可能在几百毫秒内把我们踢下线
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (_isLoggedIn && _currentUserID != null) {
          logger.debug('IM重新连接成功，状态稳定: $_currentUserID', tag: 'TencentIMService');
          return;
        }
        
        // 被踢下线了，继续重试
        logger.debug('IM登录后被踢下线，将重试（第${attempt + 1}/${maxRetries + 1}次）', tag: 'TencentIMService');
      }
      
      logger.error('IM重新连接最终失败，已重试${maxRetries + 1}次', tag: 'TencentIMService');
    } catch (e) {
      logger.error('确保IM登录状态异常: $e', tag: 'TencentIMService');
    } finally {
      _ensureLoginCompleter?.complete();
      _ensureLoginCompleter = null;
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
      logger.debug('IM SDK已卸载', tag: 'TencentIMService');
    } catch (e) {
      logger.error('IM SDK卸载失败: $e', tag: 'TencentIMService');
    }
  }

  /// 🔥 兜底：IM未登录时尝试重新初始化和登录
  /// 不直接退出到登录页，而是尝试重新连接
  void _handleIMNotLoggedIn() {
    logger.warning('🔥 IM未登录，尝试重新初始化和登录', tag: 'TencentIMService');
    
    // 尝试重新连接IM（异步执行，不阻塞当前操作）
    Future.microtask(() async {
      // 如果SDK未初始化，先初始化
      if (!_isInitialized) {
        logger.debug('IM SDK未初始化，尝试重新初始化', tag: 'TencentIMService');
        final initSuccess = await initIM();
        if (!initSuccess) {
          logger.error('IM SDK重新初始化失败', tag: 'TencentIMService');
          return;
        }
      }
      
      // 尝试重新登录
      await _attemptReconnect();
    });
  }

  // ===== 消息收发（委托给 _IMMessageHandler） =====

  Future<V2TimValueCallback<V2TimMessage>?> sendTextMessage({
    required String receiverID,
    required String text,
    bool isGroup = false,
  }) => _messageHandler.sendTextMessage(receiverID: receiverID, text: text, isGroup: isGroup);

  Future<V2TimValueCallback<V2TimMessage>?> sendImageMessage({
    required String receiverID,
    required String imagePath,
    bool isGroup = false,
  }) => _messageHandler.sendImageMessage(receiverID: receiverID, imagePath: imagePath, isGroup: isGroup);

  Future<V2TimCallback?> deleteMessageFromLocal({required String msgID}) =>
      _messageHandler.deleteMessageFromLocal(msgID: msgID);

  Future<V2TimCallback?> deleteMessagesFromCloud({required List<String> msgIDs}) =>
      _messageHandler.deleteMessagesFromCloud(msgIDs: msgIDs);

  Future<V2TimCallback?> revokeMessage({required String msgID}) =>
      _messageHandler.revokeMessage(msgID: msgID);

  Future<V2TimValueCallback<V2TimMessage>?> sendCustomMessage({
    required String receiverID,
    required String customData,
    bool isGroup = false,
  }) => _messageHandler.sendCustomMessage(receiverID: receiverID, customData: customData, isGroup: isGroup);

  Future<void> sendTypingOnlineMessage({required String receiverID}) =>
      _messageHandler.sendTypingOnlineMessage(receiverID: receiverID);

  Future<V2TimValueCallback<List<V2TimMessage>>?> getC2CHistoryMessages({
    required String userID,
    int count = 20,
    String? lastMsgID,
  }) => _messageHandler.getC2CHistoryMessages(userID: userID, count: count, lastMsgID: lastMsgID);

  Future<V2TimCallback?> markC2CMessageAsRead({
    required String userID,
    List<String>? messageIDList,
  }) => _messageHandler.markC2CMessageAsRead(userID: userID, messageIDList: messageIDList);

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
            logger.debug('📨 收到新消息', tag: 'TencentIMService');
            logger.debug(
              '消息基本信息 - ID: ${message.msgID}, 发送者: ${message.sender}, 类型: ${message.elemType}',
              tag: 'TencentIMService',
            );
            
            // 处理文本消息
            if (message.textElem != null && message.textElem!.text != null) {
              logger.debug('📝 文本消息: ${message.textElem!.text}', tag: 'TencentIMService');
            }
            
            // 处理自定义消息（customElem）
            if (message.customElem != null && message.customElem!.data != null) {
              final custom = message.customElem!;
                logger.debug(
                '🎯 自定义消息 - data: ${custom.data}, desc: ${custom.desc}, extension: ${custom.extension}',
                    tag: 'TencentIMService',
                  );
                  
                  // 处理绑定/解绑关系消息
              _relationshipHandler.handleRelationshipMessage(custom.data);
              
              // 处理锁机相关指令（对方发来的消息）
              if (!(message.isSelf ?? false)) {
                _lockHandler.handleLockScreenCommand(custom.data);
                _lockHandler.handleUnlockPhoneSend(custom.data);
                _lockHandler.handleUnlockPhoneReceive(custom.data);
              }
            }
            
            // 收到对方的聊天消息时，显示顶部全局新消息 Banner（不在聊天页时才弹）
            _showGlobalChatBannerIfNeeded(message);

            // 触发回调（将单个消息包装成列表）
            if (onReceiveNewMessage.value != null) {
              onReceiveNewMessage.value!([message]);
            }
          },
          onRecvMessageRevoked: (msgID) {
            logger.debug('🔙 消息被撤回: $msgID', tag: 'TencentIMService');
            
            // 触发回调
            if (onRecvMessageRevoked.value != null) {
              onRecvMessageRevoked.value!(msgID);
            }
          },
          onRecvC2CReadReceipt: (receiptList) {
            logger.debug('✅ 收到单聊消息已读回执', tag: 'TencentIMService');
            for (final receipt in receiptList) {
              logger.debug(
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
            logger.debug('✏️ 消息被修改: ${message.msgID}', tag: 'TencentIMService');
          },
        ),
      );
      
      logger.debug('✅ 消息监听器已成功设置', tag: 'TencentIMService');
    } catch (e) {
      logger.error('❌ 设置消息监听器失败: $e', tag: 'TencentIMService');
    }
  }

  /// 收到 C2C 聊天消息时，在非聊天页面展示顶部 Banner
  void _showGlobalChatBannerIfNeeded(V2TimMessage message) {
    try {
      // 仅处理单聊消息
      if ((message.groupID ?? '').isNotEmpty) return;

      // 没有全局 context 时无法展示
      final context = Get.context;
      if (context == null) return;

      // 当前就在聊天页面时不展示
      if (Get.currentRoute == KissuRoutePath.chat) return;

      // 只处理对方发来的消息（排除自己发送回调）
      final currentId = _currentUserID;
      if (message.sender == null || message.sender == currentId) return;

      // 仅处理文本、图片和特定自定义消息，其它类型暂不展示
      String preview;
      if (message.textElem != null &&
          message.textElem!.text != null &&
          message.textElem!.text!.isNotEmpty) {
        preview = '对方发来一条新消息，点击查看';
      } else if (message.imageElem != null) {
        preview = '对方发来一条新消息，点击查看';
      } else if (message.customElem != null &&
          message.customElem!.data != null &&
          message.customElem!.data!.isNotEmpty) {
        // 处理自定义消息，如"一起便便"、锁机提醒等
        try {
          final dynamic decoded = jsonDecode(message.customElem!.data!);
          if (decoded is Map<String, dynamic>) {
            final String? msgBubble = decoded['msg_bubble'] as String?;
            final String? msgLock = decoded['msg_lock'] as String?;
            if (msgBubble == 'defecate' || msgBubble == 'endDefecate') {
              preview = '对方发来一条新消息，点击查看';
            } else if (msgLock == 'lock_phone' || msgLock == 'phone_use' || msgLock == 'connect_app') {
              // 🔥 锁机提醒消息也要增加未读数和显示Banner
              preview = '对方发来一条新消息，点击查看';
            } else {
              return; // 其它自定义消息暂不展示
            }
          } else {
            return;
          }
        } catch (_) {
          return;
        }
      } else {
        // 其他类型暂不展示
        return;
      }

      // 非聊天页收到对方消息时，增加未读计数
      c2cUnreadCount.value = c2cUnreadCount.value + 1;

      // 从用户信息中获取另一半昵称和头像
      final user = UserManager.currentUser;
      final half = user?.halfUserInfo;
      final nickname = (half?.nickname ?? '').isNotEmpty
          ? half!.nickname!
          : 'Ta';
      final avatarUrl = (half?.headPortrait ?? '').isNotEmpty
          ? half!.headPortrait!
          : 'assets/3.0/kissu3_love_avater.webp';

      // 使用 Overlay 弹出 2 秒自动消失的 Banner
      // 优先使用 Get.overlayContext 获取全局 Overlay，避免 Overlay.of 抛异常
      OverlayState? overlay;
      final overlayContext = Get.overlayContext;
      if (overlayContext != null) {
        overlay = overlayContext.findAncestorStateOfType<OverlayState>();
      }
      if (overlay == null) return;

      late OverlayEntry entry;
      bool removed = false;

      void removeEntry() {
        if (removed) return;
        removed = true;
        try {
          entry.remove();
        } catch (_) {}
      }

      entry = OverlayEntry(
        builder: (ctx) {
          return Stack(
            children: [
              ChatNewMessageBanner(
                avatarUrl: avatarUrl,
                nickname: nickname,
                messagePreview: preview,
                onTapNavigate: () {
                  removeEntry();
                  if (Get.currentRoute != KissuRoutePath.chat) {
                    Get.toNamed(KissuRoutePath.chat);
                  }
                },
                onAutoDismiss: removeEntry,
              ),
            ],
          );
        },
      );

      overlay.insert(entry);
    } catch (e) {
      logger.error('显示聊天新消息 Banner 失败: $e', tag: 'TencentIMService');
    }
  }

  /// 移除消息监听器
  void _removeMessageListener() {
    if (!_isInitialized) return;

    try {
      TencentImSDKPlugin.v2TIMManager.getMessageManager().removeAdvancedMsgListener();
      logger.debug('消息监听器已移除', tag: 'TencentIMService');
    } catch (e) {
      logger.error('移除消息监听器失败: $e', tag: 'TencentIMService');
    }
  }

  /// 设置好友关系监听器
  void _setupFriendshipListener() {
    if (!_isInitialized) {
      logger.warning('IM SDK未初始化，无法添加好友关系监听器', tag: 'TencentIMService');
      return;
    }

    try {
      // 先移除旧的监听器（避免重复添加）
      try {
        TencentImSDKPlugin.v2TIMManager.getFriendshipManager().removeFriendListener();
      } catch (e) {
        // 忽略移除失败的错误
      }

      // 添加新的好友关系监听器
      TencentImSDKPlugin.v2TIMManager.getFriendshipManager().addFriendListener(
        listener: V2TimFriendshipListener(
          onFriendListAdded: (friendInfoList) {
            logger.debug('📨 检测到好友添加事件', tag: 'TencentIMService');
            for (final friendInfo in friendInfoList) {
              logger.debug(
                '新好友: userID=${friendInfo.userID}, nickname=${friendInfo.userProfile?.nickName}',
                tag: 'TencentIMService',
              );
            }
            // 触发绑定消息处理逻辑
            _relationshipHandler.handleBindEvent();
          },
          onFriendListDeleted: (userIDList) {
            logger.debug('📨 检测到好友删除事件', tag: 'TencentIMService');
            for (final userID in userIDList) {
              logger.debug('删除好友: userID=$userID', tag: 'TencentIMService');
            }
            // 触发解绑消息处理逻辑
            _relationshipHandler.handleUnbindEvent();
          },
          onFriendApplicationListAdded: (applicationList) {
            logger.debug('📨 收到好友申请', tag: 'TencentIMService');
            // 这里可以处理好友申请的通知，但当前主要关注绑定/解绑事件
          },
        ),
      );

      logger.debug('✅ 好友关系监听器已成功设置', tag: 'TencentIMService');
    } catch (e) {
      logger.error('❌ 设置好友关系监听器失败: $e', tag: 'TencentIMService');
    }
  }

  /// 移除好友关系监听器
  void _removeFriendshipListener() {
    if (!_isInitialized) return;

    try {
      TencentImSDKPlugin.v2TIMManager.getFriendshipManager().removeFriendListener();
      logger.debug('好友关系监听器已移除', tag: 'TencentIMService');
    } catch (e) {
      logger.error('移除好友关系监听器失败: $e', tag: 'TencentIMService');
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
    logger.debug('已设置新消息接收回调', tag: 'TencentIMService');
  }

  /// 设置单聊消息已读回执回调
  void setOnRecvC2CReadReceipt(
      Function(List<V2TimMessageReceipt>) callback) {
    onRecvC2CReadReceiptCallback.value = callback;
    logger.debug('已设置单聊消息已读回执回调', tag: 'TencentIMService');
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
    logger.debug('已设置消息撤回回调', tag: 'TencentIMService');
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
    logger.debug('已设置绑定消息接收回调', tag: 'TencentIMService');
  }

  /// 清除所有回调
  void clearCallbacks() {
    onReceiveNewMessage.value = null;
    onRecvMessageRevoked.value = null;
    onBindMessageReceived.value = null;
    onRecvC2CReadReceiptCallback.value = null;
    logger.debug('已清除所有回调', tag: 'TencentIMService');
  }

  /// 清空单聊未读数（进入聊天页面或手动清零时调用）
  void clearC2CUnreadCount() {
    c2cUnreadCount.value = 0;
    // 同步将当前情侣单聊会话标记为已读，避免服务端未读数与本地角标不同步
    try {
      if (!_isLoggedIn) {
        return;
      }
      final partnerId = UserManager.currentUser?.halfUserInfo?.uniqueId;
      if (partnerId == null || partnerId.isEmpty) {
        return;
      }
      // 异步调用即可，不需要阻塞当前流程
      markC2CMessageAsRead(userID: partnerId);
    } catch (e) {
      logger.warning('清空单聊未读数时标记已读失败: $e', tag: 'TencentIMService');
    }
  }

  /// 主动同步单聊未读数（处理离线消息或首次进入首页时）
  Future<void> syncC2CUnreadCount() async {
    try {
      if (!_isLoggedIn) return;

      // 只关注情侣单聊会话：c2c_{partnerId}
      final partnerId = UserManager.currentUser?.halfUserInfo?.uniqueId;
      if (partnerId == null || partnerId.isEmpty) return;

      final conversationId = 'c2c_$partnerId';
      final res = await TencentImSDKPlugin.v2TIMManager
          .getConversationManager()
          .getConversation(conversationID: conversationId);

      if (res.code == 0 && res.data != null) {
        final unread = res.data!.unreadCount ?? 0;
        c2cUnreadCount.value = unread;
        logger.debug('✅ 同步未读数成功: $unread', tag: 'TencentIMService');
      } else {
        logger.warning(
          '同步未读数失败: code=${res.code}, desc=${res.desc}',
          tag: 'TencentIMService',
        );
      }
    } catch (e) {
      logger.error('同步未读数异常: $e', tag: 'TencentIMService');
    }
  }

  @override
  void onClose() {
    _removeMessageListener();
    clearCallbacks();
    unInitIM();
    super.onClose();
  }
}
