import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/services/analytics/analytics_page_ids.dart';
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
  
  // 🔥 腾讯云IM推送服务客户端密钥（从IM控制台 > 推送服务Push > 接入设置 获取）
  // 注意：这个appKey是腾讯云IM推送专用的，不是极光推送的appKey
  static const String pushAppKey = "4M2JkNNiZkZslXJyw0YsmudcMw42THgiRtSud5H5iTRsT3GuHEXhQnzlQaYkjPrp";
  
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
        logger.info('腾讯IM SDK初始化成功', tag: 'TencentIMService');
        
        // 🔥 修复：等待SDK内部初始化完成
        // initSDK返回成功只是表示调用成功，需要等待一小段时间让SDK内部完成初始化
        await Future.delayed(const Duration(milliseconds: 500));
        logger.info('IM SDK初始化等待完成', tag: 'TencentIMService');
        
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
      logger.info('IM已登录该用户: ${user.uniqueId}', tag: 'TencentIMService');
      
      // 确保消息监听器已设置（应对应用重启或热重载的情况）
      _setupMessageListener();
      
      // 🔥 重新注册推送服务（应对App被杀后重启的情况）
      // 即使已经登录，每次App启动时都需要重新注册推送，确保设备token有效
      await _registerPushService();
      logger.info('已重新注册推送服务（App重启场景）', tag: 'TencentIMService');
      
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
        // 🔥 修复：登录成功后重置用户切换标志位
        _isUserSwitching = false;
        logger.info(
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
          logger.info('SDK重新初始化成功，再次尝试登录', tag: 'TencentIMService');
          V2TimCallback retryResult = await TencentImSDKPlugin.v2TIMManager.login(
            userID: user.uniqueId!,
            userSig: user.imSign!,
          );
          if (retryResult.code == 0) {
            _isLoggedIn = true;
            _currentUserID = user.uniqueId;
            // 🔥 修复：登录成功后重置用户切换标志位
            _isUserSwitching = false;
            logger.info('IM重新登录成功: userID=${user.uniqueId}', tag: 'TencentIMService');
            
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
        await _registerPushService();
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
      logger.info('用户切换账号，设置切换标志位', tag: 'TencentIMService');
    }
    
    if (!_isLoggedIn) {
      logger.info('IM未登录，无需退出', tag: 'TencentIMService');
      return true;
    }

    try {
      logger.info('开始退出IM登录...', tag: 'TencentIMService');
      
      // 移除消息监听器
      _removeMessageListener();

      // 移除好友关系监听器
      _removeFriendshipListener();

      // 清除回调
      clearCallbacks();
      
      // 🔥 反注册推送服务
      await _unRegisterPushService();
      
      V2TimCallback result = await TencentImSDKPlugin.v2TIMManager.logout();
      
      if (result.code == 0) {
        _isLoggedIn = false;
        _currentUserID = null;
        // 🔥 修复：logout后SDK会自动InternalUninit，必须重置初始化状态
        _isInitialized = false;
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

  // 🔥 重连控制变量
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  static const Duration _reconnectDelay = Duration(seconds: 2);

  /// 🔥 新增：尝试重新连接 IM（带重试机制）
  Future<void> _attemptReconnect() async {
    // 🔥 修复：如果用户正在切换账号，跳过自动重连
    if (_isUserSwitching) {
      logger.info('用户正在切换账号，跳过自动重连', tag: 'TencentIMService');
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
        logger.info('IM SDK未初始化，尝试重新初始化', tag: 'TencentIMService');
        final initSuccess = await initIM();
        if (!initSuccess) {
          logger.error('IM SDK重新初始化失败，放弃重连', tag: 'TencentIMService');
          return;
        }
      }
      
      while (_reconnectAttempts < _maxReconnectAttempts) {
        _reconnectAttempts++;
        logger.info('开始尝试重新连接IM (第$_reconnectAttempts次)...', tag: 'TencentIMService');
        
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
        
        logger.info('尝试重新登录IM: ${latestUser.uniqueId}', tag: 'TencentIMService');
        
        // 重新登录
        final success = await loginIM(latestUser);
        if (success) {
          logger.info('IM自动重新登录成功 (第$_reconnectAttempts次尝试)', tag: 'TencentIMService');
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
          logger.info('IM登录被踢下线，等待$waitSeconds秒后第${attempt + 1}次尝试...', tag: 'TencentIMService');
          await Future.delayed(Duration(seconds: waitSeconds));
          
          // 等待后再次检查是否已登录（可能其他流程已经登录成功）
          if (_isLoggedIn && _currentUserID != null) {
            logger.info('等待期间IM已恢复登录: $_currentUserID', tag: 'TencentIMService');
            return;
          }
        }
        
        // 如果SDK未初始化，先初始化
        if (!_isInitialized) {
          logger.info('IM SDK未初始化，尝试重新初始化', tag: 'TencentIMService');
          final initSuccess = await initIM();
          if (!initSuccess) {
            logger.error('IM SDK重新初始化失败', tag: 'TencentIMService');
            return;
          }
        }
        
        logger.info('检测到IM未登录，尝试重新连接（第${attempt + 1}次）...', tag: 'TencentIMService');
        
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
          logger.info('IM重新连接成功，状态稳定: $_currentUserID', tag: 'TencentIMService');
          return;
        }
        
        // 被踢下线了，继续重试
        logger.warning('IM登录后被踢下线，将重试（第${attempt + 1}/${maxRetries + 1}次）', tag: 'TencentIMService');
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
        logger.info('IM SDK未初始化，尝试重新初始化', tag: 'TencentIMService');
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
      _handleIMNotLoggedIn();
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

      // 发送消息（必须携带 messageInfo，否则会报 message and id are both empty）
      // 🔥 添加离线推送配置，确保对方离线时能收到通知
      // 构建ext字段，携带跳转信息
      final extData = {
        'scene': 'im_chat',
        'conversation_id': 'c2c_$receiverID',
        'sender_id': _currentUserID ?? '',
        'user_id': receiverID,
      };
      
      final offlinePushInfo = OfflinePushInfo(
        title: '你有一条新消息',
        desc: text.length > 50 ? '${text.substring(0, 50)}...' : text,
        disablePush: false,
        iOSSound: 'default',
        ignoreIOSBadge: false,
        // 🔥 各厂商通道配置，确保通知能正确弹出
        androidOPPOChannelID: 'push_oplus_category_service',
        androidOPPOCategory: 'IM',
        androidVIVOClassification: 1, // 1=即时消息（会弹出通知），0=运营消息（静默）
        androidVIVOCategory: 'IM',
        androidSound: 'default',
        androidHuaWeiCategory: 'IM', // 华为消息分类：IM类消息优先级更高
        ext: jsonEncode(extData),
      );
      
      // 🔥 调试日志：确认 offlinePushInfo 已设置
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
    if (!_isLoggedIn) {
      logger.warning('IM未登录，无法发送图片消息', tag: 'TencentIMService');
      _handleIMNotLoggedIn();
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
        'sender_id': _currentUserID ?? '',
        'user_id': receiverID,
      };
      
      final offlinePushInfo = OfflinePushInfo(
        title: '你有一条新消息',
        desc: '[图片]',
        disablePush: false,
        iOSSound: 'default',
        ignoreIOSBadge: false,
        // 🔥 各厂商通道配置，确保通知能正确弹出
        androidOPPOChannelID: 'push_oplus_category_service',
        androidOPPOCategory: 'IM',
        androidVIVOClassification: 1, // 1=即时消息（会弹出通知），0=运营消息（静默）
        androidVIVOCategory: 'IM',
        androidSound: 'default',
        androidHuaWeiCategory: 'IM', // 华为消息分类：IM类消息优先级更高
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
    if (!_isLoggedIn) {
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
    if (!_isLoggedIn) {
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
    if (!_isLoggedIn) {
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
    if (!_isLoggedIn) {
      logger.warning('IM未登录，无法发送自定义消息', tag: 'TencentIMService');
      _handleIMNotLoggedIn();
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
        'sender_id': _currentUserID ?? '',
        'user_id': receiverID,
      };
      
      // 🔥 尝试解析customData并合并到extData中，同时获取消息类型用于自定义推送文案
      String pushDesc = '[消息]';
      try {
        final customDataMap = jsonDecode(customData) as Map<String, dynamic>;
        extData.addAll(customDataMap);
        final msgType = customDataMap['type'] as String?;
        // 🔥 根据消息类型自定义推送文案
        if (msgType == 'lock_screen_command') {
          pushDesc = '[锁机指令来啦~]';
        } else if (msgType == 'unlock_phone_send') {
          pushDesc = '[解锁指令来啦~]';
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
        // 🔥 各厂商通道配置，确保通知能正确弹出
        androidOPPOChannelID: 'push_oplus_category_service',
        androidOPPOCategory: 'IM',
        androidOPPONotifyLevel: 2,
        androidVIVOClassification: 1, // 1=即时消息（会弹出通知），0=运营消息（静默）
        androidVIVOCategory: 'IM',
        androidSound: 'default',
        androidHuaWeiCategory: 'IM', // 华为消息分类：IM类消息优先级更高
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

  /// 发送“正在输入中”在线自定义消息（只发给在线对方，不入库、不漫游）
  Future<void> sendTypingOnlineMessage({
    required String receiverID,
  }) async {
    if (!_isLoggedIn) {
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
    if (!_isLoggedIn) {
      logger.warning('IM未登录，无法拉取历史消息', tag: 'TencentIMService');
      _handleIMNotLoggedIn();
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
    if (!_isLoggedIn) {
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
              _handleRelationshipMessage(custom.data);
              
              // 处理锁机相关指令（对方发来的消息）
              if (!(message.isSelf ?? false)) {
                _handleLockScreenCommand(custom.data);
                _handleUnlockPhoneSend(custom.data);
                _handleUnlockPhoneReceive(custom.data);
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
        // 处理自定义消息，如“一起便便”
        try {
          final dynamic decoded = jsonDecode(message.customElem!.data!);
          if (decoded is Map<String, dynamic>) {
            final String? msgBubble = decoded['msg_bubble'] as String?;
            if (msgBubble == 'defecate' || msgBubble == 'endDefecate') {
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
            _handleBindEvent();
          },
          onFriendListDeleted: (userIDList) {
            logger.debug('📨 检测到好友删除事件', tag: 'TencentIMService');
            for (final userID in userIDList) {
              logger.debug('删除好友: userID=$userID', tag: 'TencentIMService');
            }
            // 触发解绑消息处理逻辑
            _handleUnbindEvent();
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

  /// 处理锁机指令：收到lock_screen_command自定义消息时存储问题数据并启动锁屏
  void _handleLockScreenCommand(String? data) async {
    if (data == null || data.isEmpty) return;
    try {
      final Map<String, dynamic> decoded = jsonDecode(data);
      final String? type = decoded['type'] as String?;
      if (type != 'lock_screen_command') return;

      // 用户未登录时不处理锁机指令
      if (!UserManager.isLoggedIn) {
        logger.info('🔒 收到锁机指令但用户未登录，忽略', tag: 'TencentIMService');
        return;
      }

      logger.info('🔒 收到锁机指令，准备锁屏', tag: 'TencentIMService');

      // 存储锁机发送者ID（用于解锁后发送unlock_phone_receive）
      final partnerId = UserManager.currentUser?.halfUserInfo?.uniqueId;
      if (partnerId != null && partnerId.isNotEmpty) {
        final prefs2 = await SharedPreferences.getInstance();
        await prefs2.setString('lock_sender_id', partnerId);
      }

      // 兼容新旧字段：lock_question/question, lock_answer/answers, lock_prompt/lockText/lock_text
      final question = (decoded['lock_question'] ?? decoded['question']) as String? ?? '';
      final lockAnswerRaw = decoded['lock_answer'] ?? decoded['answers'];
      final minutes = 2000;
      final lockPrompt = (decoded['lock_prompt'] ?? decoded['lock_text'] ?? decoded['lockText']) as String? ?? '';
      final lockBgImage = (decoded['lock_bg_image'] ?? decoded['lock_bg_image_url']) as String? ?? '';
      final defaultBgImageIndex = (decoded['default_bg_image_index']) as String? ?? '';

      logger.info('🔒 IM原始数据: ${decoded.keys.toList()}', tag: 'TencentIMService');
      logger.info('🔒 lock_prompt=$lockPrompt, lock_bg_image=$lockBgImage, default_bg_image_index=$defaultBgImageIndex', tag: 'TencentIMService');

      // 解析答案列表并找出正确答案索引
      List<String> answers = [];
      int correctIndex = decoded['correctIndex'] as int? ?? decoded['answer_index'] as int? ?? -1;
      try {
        List<dynamic> answerList;
        if (lockAnswerRaw is String) {
          answerList = jsonDecode(lockAnswerRaw) as List;
        } else if (lockAnswerRaw is List) {
          answerList = lockAnswerRaw;
        } else {
          answerList = [];
        }
        for (int i = 0; i < answerList.length; i++) {
          final item = answerList[i];
          if (item is Map) {
            answers.add(item['answer'] as String? ?? '');
            // 从 is_answer 字段确定正确答案索引
            if ((item['is_answer'] as int? ?? 0) == 1 && correctIndex < 0) {
              correctIndex = i;
            }
          } else {
            answers.add(item.toString());
          }
        }
      } catch (e) {
        logger.warning('🔒 解析answers失败: $e', tag: 'TencentIMService');
      }
      if (correctIndex < 0) correctIndex = 0; // 兜底

      logger.info('🔒 解析锁机数据: question=$question, answers=$answers, correctIndex=$correctIndex', tag: 'TencentIMService');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lock_question', question);
      await prefs.setString('lock_answers', jsonEncode(answers));
      await prefs.setInt('lock_correct_index', correctIndex);
      // 存储锁屏界面显示信息（新字段 + 旧字段兼容原生端）
      await prefs.setString('lock_text', lockPrompt);
      await prefs.setString('lockText', lockPrompt); // 原生端旧key
      // 背景图逻辑：
      // - default_bg_image_index 有值(kissu_lock_1/2/3) → 本地预设图片，转换为索引 0/1/2
      // - lock_bg_image 有值 → 自定义图片URL，需要下载
      int bgImageIdx = 0;
      if (defaultBgImageIndex.isNotEmpty) {
        if (defaultBgImageIndex == 'kissu_lock_2') {
          bgImageIdx = 1;
        } else if (defaultBgImageIndex == 'kissu_lock_3') {
          bgImageIdx = 2;
        }
      }
      await prefs.setInt('lock_bg_image_index', bgImageIdx);
      // 存储 default_bg_image_index 原始值供原生端读取
      await prefs.setString('lock_default_bg_image_index', defaultBgImageIndex);
      logger.info('🔒 背景图: defaultBgImageIndex=$defaultBgImageIndex -> bgImageIdx=$bgImageIdx, lockBgImage=$lockBgImage', tag: 'TencentIMService');

      // 背景图：在Flutter侧先下载到本地文件，再让原生读取本地文件（避免原生下载延迟）
      String localBgPath = '';
      if (lockBgImage.isNotEmpty) {
        try {
          logger.info('🔒 开始下载背景图到本地: $lockBgImage', tag: 'TencentIMService');
          final httpClient = HttpClient();
          final request = await httpClient.getUrl(Uri.parse(lockBgImage));
          final response = await request.close();
          if (response.statusCode == 200) {
            final bytesList = <List<int>>[];
            await for (final chunk in response) {
              bytesList.add(chunk);
            }
            final bytes = bytesList.expand((x) => x).toList();
            // 保存到应用缓存目录
            final dir = Directory('/data/data/${const String.fromEnvironment('APP_ID', defaultValue: 'com.yuluo.kissu')}/cache');
            if (!await dir.exists()) await dir.create(recursive: true);
            final file = File('${dir.path}/lock_bg_image.jpg');
            await file.writeAsBytes(bytes);
            localBgPath = file.path;
            logger.info('🔒 背景图下载成功, 大小=${bytes.length}B, 路径=$localBgPath', tag: 'TencentIMService');
          } else {
            logger.warning('🔒 背景图下载失败: HTTP ${response.statusCode}', tag: 'TencentIMService');
          }
          httpClient.close();
        } catch (e) {
          logger.warning('🔒 背景图下载异常: $e', tag: 'TencentIMService');
        }
      }
      await prefs.setString('lock_bg_image_local_path', localBgPath);
      logger.info('🔒 已存储锁屏数据: lockPrompt=${lockPrompt}, bgLocalPath=$localBgPath', tag: 'TencentIMService');
      
      // 存储另一半的头像和昵称（供原生锁屏界面使用）
      final user = UserManager.currentUser;
      final half = user?.halfUserInfo;
      final partnerNickname = half?.nickname ?? 'Ta';
      final partnerAvatar = half?.headPortrait ?? '';
      await prefs.setString('lock_partner_nickname', partnerNickname);
      await prefs.setString('lock_partner_avatar', partnerAvatar);

      final result = await LockScreenOverlayService.lockScreen(
        minutes: minutes,
        lockText: lockPrompt,
        bgImagePath: localBgPath,
      );
      if (result) {
        logger.info('🔒 锁屏启动成功', tag: 'TencentIMService');
      } else {
        logger.warning('🔒 锁屏启动失败（可能缺少悬浮窗权限）', tag: 'TencentIMService');
      }
    } catch (e) {
      logger.error('🔒 锁屏指令处理异常: $e', tag: 'TencentIMService');
    }
  }

  /// 处理对方发来的解锁指令（锁机方主动解锁被锁方）
  void _handleUnlockPhoneSend(String? data) async {
    if (data == null || data.isEmpty) return;
    try {
      final Map<String, dynamic> decoded = jsonDecode(data);
      final String? type = decoded['type'] as String?;
      if (type != 'unlock_phone_send') return;

      logger.info('🔓 收到对方发来的解锁指令，立即解锁', tag: 'TencentIMService');

      // 清除锁屏状态
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('lock_sender_id');

      // 调用原生解锁
      await LockScreenOverlayService.unlockScreen();
      await LockScreenOverlayService.stopService();
      logger.info('🔓 已执行解锁操作', tag: 'TencentIMService');
    } catch (e) {
      logger.error('🔓 处理解锁指令异常: $e', tag: 'TencentIMService');
    }
  }

  /// 处理被锁方答题解锁后的通知（被锁方解锁成功，通知锁机方重置页面）
  void _handleUnlockPhoneReceive(String? data) async {
    if (data == null || data.isEmpty) return;
    try {
      final Map<String, dynamic> decoded = jsonDecode(data);
      final String? type = decoded['type'] as String?;
      if (type != 'unlock_phone_receive') return;

      final int attempts = decoded['attempts'] as int? ?? 0;
      logger.info('🔓 收到被锁方解锁通知，答题次数: $attempts', tag: 'TencentIMService');

      // 触发回调通知锁机方页面重置
      if (onUnlockPhoneReceived.value != null) {
        onUnlockPhoneReceived.value!(attempts);
      }

      // 刷新用户信息并更新聊天页/我的页面的锁机状态图标
      await UserManager.refreshUserInfo();
      _refreshPartnerLockStateOnPages();
    } catch (e) {
      logger.error('🔓 处理解锁通知异常: $e', tag: 'TencentIMService');
    }
  }

  /// 刷新聊天页和我的页面的对方锁机状态
  void _refreshPartnerLockStateOnPages() {
    try {
      // 更新聊天页面
      if (Get.isRegistered<ChatController>()) {
        final chatController = Get.find<ChatController>();
        chatController.refreshPartnerLockState();
        logger.info('🔓 已刷新聊天页锁机状态', tag: 'TencentIMService');
      }
      // 更新我的页面
      if (Get.isRegistered<MineController>()) {
        final mineController = Get.find<MineController>();
        mineController.onPageResumed();
        logger.info('🔓 已刷新我的页面锁机状态', tag: 'TencentIMService');
      }
    } catch (e) {
      logger.error('🔓 刷新锁机状态异常: $e', tag: 'TencentIMService');
    }
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

      logger.debug('处理关系消息 - msg_type: $msgType', tag: 'TencentIMService');

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
          logger.debug(
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
            logger.debug('🎉 收到绑定消息 (bindAndroid/bind)，A和B都会收到此消息，统一处理绑定逻辑', tag: 'TencentIMService');
            await _handleBindMessage(animationService);
            break;
          case 'unbind':
            logger.debug('💔 收到解绑关系消息，处理解绑逻辑', tag: 'TencentIMService');
            await _handleUnbindMessage(animationService);
            break;
          case 'refuseRequest':
            logger.debug('💔 收到拒绝绑定消息', tag: 'TencentIMService');
            await _handleRefuseRequestMessage(data);
            break;
          case 'bindRequest':
            logger.debug('💌 收到绑定申请', tag: 'TencentIMService');
            await _handleBindRequestMessage(data);
            break;
          default:
            logger.debug('未知的消息类型: $msgType', tag: 'TencentIMService');
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
      logger.debug('💬 触发绑定消息回调，准备关闭绑定弹窗...', tag: 'TencentIMService');
      if (onBindMessageReceived.value != null) {
        onBindMessageReceived.value!();
        logger.debug('✅ 绑定消息回调已触发', tag: 'TencentIMService');
        // 等待弹窗关闭动画完成
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      // 1. 先刷新用户信息（带重试机制，验证绑定状态是否已更新）
      logger.debug('📥 开始刷新用户信息...', tag: 'TencentIMService');
      final authService = getIt<AuthService>();
      bool refreshSuccess = false;
      bool bindStatusUpdated = false;
      
      // 🔥 修复：刷新用户信息后验证绑定状态是否已更新为"已绑定"
      // 服务器可能在发送绑定消息后还没有完成数据更新，需要重试直到绑定状态正确
      for (int i = 0; i < 5; i++) {
        refreshSuccess = await authService.refreshUserInfoFromServer();
        if (refreshSuccess) {
          // 验证绑定状态是否已更新
          final user = authService.currentUser;
          final bindStatus = user?.bindStatus?.toString();
          bindStatusUpdated = bindStatus == "1";
          
          if (bindStatusUpdated) {
            logger.debug('✅ 用户信息刷新成功，绑定状态已更新: bindStatus=$bindStatus', tag: 'TencentIMService');
            break;
          } else {
            logger.warning('⚠️ 用户信息刷新成功但绑定状态未更新: bindStatus=$bindStatus，第${i + 1}次重试...', tag: 'TencentIMService');
          }
        } else {
          logger.warning('⚠️ 用户信息刷新失败，第${i + 1}次重试...', tag: 'TencentIMService');
        }
        // 等待服务器数据同步
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      if (!bindStatusUpdated) {
        logger.warning('⚠️ 绑定状态未能更新，使用当前缓存数据', tag: 'TencentIMService');
      }
      
      // 2. 刷新当前页面
      animationService.refreshCurrentPage();
      
      // 3. 播放绑定动画，动画完成后根据会员状态决定是否跳转到VIP页面
      logger.debug('🎬 开始播放绑定动画', tag: 'TencentIMService');
      animationService.showBindAnimation(onComplete: () {
        logger.debug('🎯 绑定动画播放完成回调被触发', tag: 'TencentIMService');
        try {
          final isVip = authService.isVip;
          logger.debug('当前用户VIP状态: $isVip', tag: 'TencentIMService');
          if (!isVip) {
            logger.debug('📍 当前为非会员用户，准备跳转到VIP页面...', tag: 'TencentIMService');
            final result = Get.toNamed(
              KissuRoutePath.vip,
              arguments: {'source_page': SourcePageUtilsCaller.home, 'source_event': PageSourceIds.bind},
            );
            logger.debug('✅ VIP页面跳转已触发，返回值: $result', tag: 'TencentIMService');
          } else {
            logger.debug('🎉 当前用户已是VIP，不跳转开通会员页面', tag: 'TencentIMService');
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
      logger.debug('📥 开始刷新用户信息...', tag: 'TencentIMService');
      final authService = getIt<AuthService>();
      await authService.refreshUserInfoFromServer();
      logger.debug('✅ 用户信息刷新成功', tag: 'TencentIMService');

      // 2. 刷新当前页面
      animationService.refreshCurrentPage();

      // 3. 播放解绑动画
      logger.debug('🎬 开始播放解绑动画', tag: 'TencentIMService');
      animationService.showUnbindAnimation();
    } catch (e) {
      logger.error('❌ 处理解绑消息失败: $e', tag: 'TencentIMService');
      // 即使失败也播放动画
      animationService.showUnbindAnimation();
    }
  }

  /// 处理好友添加事件（绑定事件）
  /// 当检测到好友添加时，说明绑定成功
  Future<void> _handleBindEvent() async {
    try {
      logger.debug('🎉 检测到好友添加事件，执行绑定逻辑', tag: 'TencentIMService');

      // 尝试获取动画服务并执行绑定逻辑
      try {
        final animationService = RelationshipAnimationService.instance;

        // 0. 先触发绑定消息回调（关闭可能存在的绑定弹窗）
        logger.debug('💬 触发绑定消息回调，准备关闭绑定弹窗...', tag: 'TencentIMService');
        if (onBindMessageReceived.value != null) {
          onBindMessageReceived.value!();
          logger.debug('✅ 绑定消息回调已触发', tag: 'TencentIMService');
          // 等待弹窗关闭动画完成
          await Future.delayed(const Duration(milliseconds: 300));
        }

        // 1. 先刷新用户信息（带重试机制，验证绑定状态是否已更新）
        logger.debug('📥 开始刷新用户信息...', tag: 'TencentIMService');
        final authService = getIt<AuthService>();
        bool bindStatusUpdated = false;
        
        // 🔥 修复：刷新用户信息后验证绑定状态是否已更新为"已绑定"
        for (int i = 0; i < 5; i++) {
          final refreshSuccess = await authService.refreshUserInfoFromServer();
          if (refreshSuccess) {
            final user = authService.currentUser;
            final bindStatus = user?.bindStatus?.toString();
            bindStatusUpdated = bindStatus == "1";
            
            if (bindStatusUpdated) {
              logger.debug('✅ 用户信息刷新成功，绑定状态已更新: bindStatus=$bindStatus', tag: 'TencentIMService');
              break;
            } else {
              logger.warning('⚠️ 用户信息刷新成功但绑定状态未更新: bindStatus=$bindStatus，第${i + 1}次重试...', tag: 'TencentIMService');
            }
          } else {
            logger.warning('⚠️ 用户信息刷新失败，第${i + 1}次重试...', tag: 'TencentIMService');
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        if (!bindStatusUpdated) {
          logger.warning('⚠️ 绑定状态未能更新，使用当前缓存数据', tag: 'TencentIMService');
        }

        // 2. 刷新当前页面
        animationService.refreshCurrentPage();

        // 3. 播放绑定动画，动画完成后根据会员状态决定是否跳转到VIP页面
        logger.debug('🎬 开始播放绑定动画', tag: 'TencentIMService');
        animationService.showBindAnimation(onComplete: () {
          logger.debug('🎯 绑定动画播放完成回调被触发', tag: 'TencentIMService');
          try {
            final isVip = authService.isVip;
            logger.debug('当前用户VIP状态: $isVip', tag: 'TencentIMService');
            if (!isVip) {
              logger.debug('📍 当前为非会员用户，准备跳转到VIP页面...', tag: 'TencentIMService');
              final result = Get.toNamed(
                KissuRoutePath.vip,
                arguments: {'source_page': SourcePageUtilsCaller.home, 'source_event': PageSourceIds.bind},
              );
              logger.debug('✅ VIP页面跳转已触发，返回值: $result', tag: 'TencentIMService');
            } else {
              logger.debug('🎉 当前用户已是VIP，不跳转开通会员页面', tag: 'TencentIMService');
            }
          } catch (e) {
            logger.error('❌ 处理绑定动画完成后的跳转逻辑失败: $e', tag: 'TencentIMService');
          }
        });
      } catch (e) {
        logger.warning('动画服务未初始化或调用失败: $e', tag: 'TencentIMService');
      }
    } catch (e) {
      logger.error('❌ 处理好友添加事件失败: $e', tag: 'TencentIMService');
    }
  }

  /// 处理好友删除事件（解绑事件）
  /// 当检测到好友删除时，说明解绑成功
  Future<void> _handleUnbindEvent() async {
    try {
      logger.debug('💔 检测到好友删除事件，执行解绑逻辑', tag: 'TencentIMService');

      // 尝试获取动画服务并执行解绑逻辑
      try {
        final animationService = RelationshipAnimationService.instance;

        // 1. 先刷新用户信息
        logger.debug('📥 开始刷新用户信息...', tag: 'TencentIMService');
        final authService = getIt<AuthService>();
        await authService.refreshUserInfoFromServer();
        logger.debug('✅ 用户信息刷新成功', tag: 'TencentIMService');

        // 2. 刷新当前页面
        animationService.refreshCurrentPage();

        // 3. 播放解绑动画
        logger.debug('🎬 开始播放解绑动画', tag: 'TencentIMService');
        animationService.showUnbindAnimation();
      } catch (e) {
        logger.warning('动画服务未初始化或调用失败: $e', tag: 'TencentIMService');
        // 即使失败也尝试播放动画
        try {
          final animationService = RelationshipAnimationService.instance;
          animationService.showUnbindAnimation();
        } catch (e2) {
          logger.error('❌ 播放解绑动画失败: $e2', tag: 'TencentIMService');
        }
      }
    } catch (e) {
      logger.error('❌ 处理好友删除事件失败: $e', tag: 'TencentIMService');
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

      logger.debug(
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
            logger.debug(
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
              logger.debug('✅ 绑定接口调用成功，等待 bindAndroid 消息处理后续逻辑', tag: 'TencentIMService');
            } else {
              logWarning('绑定接口调用失败: ${result.msg}', tag: 'TencentIMService');
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
            logger.debug('用户点击拒绝绑定，展示二次确认弹窗', tag: 'TencentIMService');

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

              logger.debug(
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
                logWarning('拒绝绑定接口调用失败: ${apiResult.msg}', tag: 'TencentIMService');
                CustomToast.show(context, apiResult.msg ?? '操作失败');
              }
            } else {
              logger.debug('用户选择再想想，不执行拒绝绑定接口', tag: 'TencentIMService');
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

      logger.debug(
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
          logger.debug('用户选择再次发起绑定，调用 /start/bind, friend_code=$friendCode', tag: 'TencentIMService');
          final authApi = AuthApi();
          final bindResult = await authApi.bindPartner(friendCode: friendCode);

          if (bindResult.isSuccess) {
            CustomToast.show(context, '已再次发起绑定申请');
          } else {
            logWarning('再次发起绑定失败: ${bindResult.msg}', tag: 'TencentIMService');
            CustomToast.show(context, bindResult.msg ?? '再次发起绑定失败');
          }
        } catch (e) {
          logger.error('再次发起绑定异常: $e', tag: 'TencentIMService');
          CustomToast.show(context, '再次发起绑定失败: $e');
        }
      } else {
        logger.debug('用户点击“知道了”，不再发起绑定', tag: 'TencentIMService');
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
    logger.debug('🔄 手动强制设置消息监听器', tag: 'TencentIMService');
    _setupMessageListener();
  }

  /// 检查IM状态并打印详细信息
  ///
  /// 用于调试，查看当前IM的状态
  void checkIMStatus() {
    logger.debug('====== IM状态检查 ======', tag: 'TencentIMService');
    logger.debug('SDK已初始化: $_isInitialized', tag: 'TencentIMService');
    logger.debug('已登录: $_isLoggedIn', tag: 'TencentIMService');
    logger.debug('当前用户ID: $_currentUserID', tag: 'TencentIMService');
    logger.debug('新消息回调已设置: ${onReceiveNewMessage.value != null}', tag: 'TencentIMService');
    logger.debug('消息撤回回调已设置: ${onRecvMessageRevoked.value != null}', tag: 'TencentIMService');
    logger.debug('========================', tag: 'TencentIMService');
  }

  /// 检查推送状态并打印详细信息
  ///
  /// 用于调试推送功能
  Future<void> checkPushStatus() async {
    logger.debug('====== 推送状态检查 ======', tag: 'TencentIMService');

    try {
      // 检查基础状态
      logger.debug('📱 设备信息: ${await _getDeviceBrand()}', tag: 'TencentIMService');
      logger.debug('🔧 IM服务初始化状态: $_isInitialized', tag: 'TencentIMService');
      logger.debug('🔐 IM登录状态: $_isLoggedIn', tag: 'TencentIMService');
      logger.debug('👤 当前用户ID: $_currentUserID', tag: 'TencentIMService');

      // 检查推送相关配置
      logger.debug('🔑 推送AppKey配置: ${pushAppKey.isNotEmpty ? "已配置" : "未配置"}', tag: 'TencentIMService');
      logger.debug('🆔 SDK AppID: $sdkAppID', tag: 'TencentIMService');

      // 检查消息监听器状态
      logger.debug('📨 消息监听器状态:', tag: 'TencentIMService');
      logger.debug('  - 新消息回调: ${onReceiveNewMessage.value != null ? "已设置" : "未设置"}', tag: 'TencentIMService');
      logger.debug('  - 消息撤回回调: ${onRecvMessageRevoked.value != null ? "已设置" : "未设置"}', tag: 'TencentIMService');

      logger.debug('🔍 推送问题排查建议:', tag: 'TencentIMService');
      logger.debug('1. 📋 检查腾讯云IM控制台推送证书配置', tag: 'TencentIMService');
      logger.debug('2. 📱 检查设备厂商推送服务是否开启', tag: 'TencentIMService');
      logger.debug('3. 🔔 检查应用通知权限是否开启', tag: 'TencentIMService');
      logger.debug('4. 🔋 检查电池优化设置', tag: 'TencentIMService');
      logger.debug('5. 🌐 检查网络连接状态', tag: 'TencentIMService');
      logger.debug('6. 📝 查看推送注册的详细日志', tag: 'TencentIMService');
      logger.debug('7. 🧪 使用推送测试功能验证', tag: 'TencentIMService');

      logger.debug('========================', tag: 'TencentIMService');
    } catch (e) {
      logger.error('检查推送状态失败: $e', tag: 'TencentIMService');
    }
  }

  /// 手动触发推送测试
  ///
  /// 用于测试推送通道是否正常
  Future<void> testPushNotification() async {
    try {
      logger.debug('🔍 开始推送测试...', tag: 'TencentIMService');

      // 发送一条测试消息给自己（会触发离线推送）
      if (_isLoggedIn && _currentUserID != null) {
        await sendCustomMessage(
          receiverID: _currentUserID!,
          customData: '{"type":"push_test","message":"推送测试消息"}',
        );
        logger.debug('✅ 已发送测试消息给自己，请退出应用等待离线推送', tag: 'TencentIMService');
      } else {
        logger.warning('❌ IM未登录，无法进行推送测试', tag: 'TencentIMService');
      }
    } catch (e) {
      logger.error('推送测试失败: $e', tag: 'TencentIMService');
    }
  }

  /// 注册推送服务
  ///
  /// 在IM登录成功后调用，用于启用离线推送功能
  ///
  /// 已配置的厂商通道（Android）：
  /// - 小米推送（证书ID: 45159）
  /// - 华为推送（证书ID: 45160）
  /// - 魅族推送（证书ID: 45161）
  /// - vivo推送（证书ID: 45162）
  /// - OPPO推送（证书ID: 45163）
  /// - 荣耀推送（证书ID: 45164）
  ///
  /// 注意：
  /// - Android端厂商推送配置在timpush-configs.json中，插件会自动读取
  /// - 必须传入sdkAppId参数，让插件关联到正确的配置
  Future<void> _registerPushService() async {
    try {
      logger.debug('开始注册推送服务（sdkAppId: $sdkAppID）', tag: 'TencentIMService');

      // 🔥 检查appKey是否已配置
      if (pushAppKey.isEmpty) {
        logger.error('❌ 腾讯云IM推送appKey未配置！', tag: 'TencentIMService');
        logger.error('请从腾讯云IM控制台获取appKey：', tag: 'TencentIMService');
        logger.error('路径：IM控制台 > 推送服务Push > 接入设置', tag: 'TencentIMService');
        logger.error('获取后填入 TencentIMService.pushAppKey 常量', tag: 'TencentIMService');
        return;
      }

      // 🔥 调试信息：检查设备信息和推送配置
      final loginUser = await TencentImSDKPlugin.v2TIMManager.getLoginUser();
      logger.debug('🔍 推送调试信息:', tag: 'TencentIMService');
      logger.debug('  - 当前登录用户ID (SDK): $loginUser', tag: 'TencentIMService');
      logger.debug('  - 当前登录用户ID (缓存): $_currentUserID', tag: 'TencentIMService');
      logger.debug('  - 设备厂商: ${await _getDeviceBrand()}', tag: 'TencentIMService');
      // 注册推送服务
      // sdkAppId: 必须传入，用于关联timpush-configs.json中的厂商配置
      // appKey: 🔥 必须传入！从IM控制台 > 推送服务Push > 接入设置 获取
      // apnsCertificateID: iOS平台的APNs证书ID，Android平台传null
      final result = await TencentCloudChatPush().registerPush(
        sdkAppId: sdkAppID,
        appKey: pushAppKey, // 🔥 关键！必须传入客户端密钥
        apnsCertificateID: null, // Android平台不需要APNS证书
        onNotificationClicked: ({
          required String ext,
          String? userID,
          String? groupID,
        }) {
          logger.debug('📱 推送通知被点击: ext=$ext, userID=$userID, groupID=$groupID', tag: 'TencentIMService');
          _handlePushNotificationClick(
            ext: ext,
            userID: userID,
            groupID: groupID,
          );
        },
      );

      logger.debug('✅ 推送服务注册完成', tag: 'TencentIMService');
      logger.debug('📊 推送注册结果类型: ${result.runtimeType}', tag: 'TencentIMService');
      logger.debug('📊 推送注册结果详情: $result', tag: 'TencentIMService');

      // 🔥 检查注册结果
      logger.debug('✅ 推送注册成功！结果: $result', tag: 'TencentIMService');

      // 🔥 禁用前台通知（App在前台时不显示通知栏推送）
      // 后台通知由原生层的自定义推送监听器处理
      await TencentCloudChatPush().disablePostNotificationInForeground(disable: true);
      logger.debug('已禁用前台通知显示', tag: 'TencentIMService');
      
      // 🔥 获取推送设备ID（RegistrationID），用于验证推送注册是否成功
      try {
        final registrationID = await TencentCloudChatPush().getRegistrationID();
        logger.debug('📱 推送设备ID (RegistrationID): $registrationID', tag: 'TencentIMService');
      } catch (e) {
        logger.error('获取推送设备ID失败: $e', tag: 'TencentIMService');
      }

      logger.debug('🔧 请按以下步骤检查配置：', tag: 'TencentIMService');
      logger.debug('1. ✅ timpush-configs.json 已放置在 android/app/src/main/assets/ 目录', tag: 'TencentIMService');
      logger.debug('2. ✅ Application类已继承TencentCloudChatPushApplication', tag: 'TencentIMService');
      logger.debug('3. ✅ 厂商SDK依赖已正确添加到build.gradle.kts', tag: 'TencentIMService');
      logger.debug('4. ❓ 腾讯云IM控制台推送证书配置检查：', tag: 'TencentIMService');
      logger.debug('   - 登录腾讯云IM控制台', tag: 'TencentIMService');
      logger.debug('   - 进入 [推送服务Push] > [接入设置]', tag: 'TencentIMService');
      logger.debug('   - 确认客户端密钥(appKey)已正确配置', tag: 'TencentIMService');
      logger.debug('   - 为以下厂商配置推送证书：', tag: 'TencentIMService');
      logger.debug('     * 小米推送 (businessId: 45159)', tag: 'TencentIMService');
      logger.debug('     * 华为推送 (businessId: 45160)', tag: 'TencentIMService');
      logger.debug('     * 魅族推送 (businessId: 45161)', tag: 'TencentIMService');
      logger.debug('     * vivo推送 (businessId: 45162)', tag: 'TencentIMService');
      logger.debug('     * OPPO推送 (businessId: 45163)', tag: 'TencentIMService');
      logger.debug('     * 荣耀推送 (businessId: 45164)', tag: 'TencentIMService');
      logger.debug('     * 鸿蒙推送 (businessId: 305)', tag: 'TencentIMService');
      logger.debug('5. ❓ 设备厂商推送服务检查：', tag: 'TencentIMService');
      logger.debug('   - 华为设备：设置 > 应用 > 应用启动 > 允许自启动', tag: 'TencentIMService');
      logger.debug('   - 小米设备：设置 > 应用设置 > 权限管理 > 允许后台运行', tag: 'TencentIMService');
      logger.debug('   - vivo设备：设置 > 电池 > 高耗电应用 > 允许后台运行', tag: 'TencentIMService');
      logger.debug('   - OPPO设备：设置 > 电池 > 应用快速启动', tag: 'TencentIMService');
      logger.debug('   - 荣耀设备：设置 > 应用 > 权限管理 > 通知权限', tag: 'TencentIMService');
    } catch (e, stackTrace) {
      logger.error('推送服务注册失败: $e', tag: 'TencentIMService');
      logger.error('堆栈信息: $stackTrace', tag: 'TencentIMService');
      // 推送注册失败不影响IM登录，只记录错误
    }
  }

  /// 获取设备厂商信息（用于调试）
  Future<String> _getDeviceBrand() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        // 返回详细的设备信息，帮助调试推送问题
        return 'brand=${androidInfo.brand}, manufacturer=${androidInfo.manufacturer}, model=${androidInfo.model}, SDK=${androidInfo.version.sdkInt}, release=${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        return 'model=${iosInfo.model}, systemVersion=${iosInfo.systemVersion}';
      }
      return 'Unknown platform';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// 反注册推送服务
  /// 
  /// 在IM退出登录时调用
  Future<void> _unRegisterPushService() async {
    try {
      TencentCloudChatPush().unRegisterPush();
      logger.debug('推送服务已反注册', tag: 'TencentIMService');
    } catch (e) {
      logger.error('反注册推送服务失败: $e', tag: 'TencentIMService');
    }
  }

  /// 处理推送通知点击事件
  /// 
  /// [ext] 推送消息携带的扩展信息
  /// [userID] 单聊对方userID（如果可解析）
  /// [groupID] 群聊groupID（如果可解析）
  void _handlePushNotificationClick({
    required String ext,
    String? userID,
    String? groupID,
  }) {
    try {
      logger.debug(
        '推送通知被点击: ext=$ext, userID=$userID, groupID=$groupID',
        tag: 'TencentIMService',
      );

      // 解析ext字段，获取跳转信息
      // ext字段可能包含聊天相关的信息，如对方userID等
      try {
        final extData = jsonDecode(ext);
        logger.debug('推送ext数据: $extData', tag: 'TencentIMService');
      } catch (e) {
        // ext可能不是JSON格式，直接使用字符串
        logger.error('推送ext不是JSON格式: $ext', tag: 'TencentIMService');
      }

      // 跳转到聊天页面
      // 注意：如果当前不在聊天页面，则跳转；如果已在聊天页面，则不重复跳转
      if (Get.currentRoute != KissuRoutePath.chat) {
        Get.toNamed(KissuRoutePath.chat);
        logger.debug('已跳转到聊天页面', tag: 'TencentIMService');
      } else {
        logger.debug('当前已在聊天页面，无需跳转', tag: 'TencentIMService');
      }
    } catch (e) {
      logger.error('处理推送通知点击失败: $e', tag: 'TencentIMService');
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
