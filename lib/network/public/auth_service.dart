import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kissu_app/model/login_model/login_model.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/auth_api.dart';
import 'package:kissu_app/network/utils/device_util.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
// 🔥 已废弃：极光推送（推送现在走腾讯IM）
// import 'package:kissu_app/services/jpush_service.dart';
import 'package:kissu_app/services/openinstall_service.dart';
import 'package:kissu_app/services/native_location_report_service.dart';
import 'package:kissu_app/services/tencent_im_service.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/home/services/home_popup_service.dart';

class AuthService {
  // ✅ 公开构造函数，GetIt 可以直接 new 出来
  AuthService();

  static const String _currentUserKey = 'current_user';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  final AuthApi _authApi = AuthApi();

  LoginModel? _currentUser;
  // List<WaiterLoginModel> _userAccounts = [];

  LoginModel? get currentUser => _currentUser;

  // 便捷访问用户信息的getter方法
  String? get userId => _currentUser?.id?.toString();
  String? get userPhone => _currentUser?.phone;
  String? get userNickname => _currentUser?.nickname;
  String? get userAvatar => _currentUser?.headPortrait;
  String? get userToken => _currentUser?.token;
  int? get userGender => _currentUser?.gender;
  String? get userBirthday => _currentUser?.birthday;
  bool get isVip => _currentUser?.isVip == 1;
  bool get isForeverVip => _currentUser?.isForEverVip == 1;
  String? get vipEndDate => _currentUser?.vipEndDate;
  String? get provinceName => _currentUser?.provinceName;
  String? get cityName => _currentUser?.cityName;
  String? get friendCode => _currentUser?.friendCode;

  // 获取完整的用户显示名称
  String get displayName {
    if (_currentUser?.nickname?.isNotEmpty == true) {
      return _currentUser!.nickname!;
    } else if (_currentUser?.phone?.isNotEmpty == true) {
      // 手机号脱敏显示
      final phone = _currentUser!.phone!;
      if (phone.length >= 11) {
        return '${phone.substring(0, 3)}****${phone.substring(7)}';
      }
      return phone;
    }
    return '未知用户';
  }

  // 获取性别描述
  String get genderText {
    switch (_currentUser?.gender) {
      case 1:
        return '男';
      case 2:
        return '女';
      default:
        return '未知';
    }
  }
  // List<WaiterLoginModel> get userAccounts => _userAccounts;

  /// 初始化服务，读取缓存
  Future<void> init() async {
    _currentUser = await _loadCurrentUser();
    
    // 注意：不在这里登录IM，因为此时TencentIMService可能还没注册
    // IM登录会在main.dart中所有服务注册完成后进行
  }

  Future<HttpResultN<LoginModel>> loginWithCode({
    required String phoneNumber,
    required String code,
    String? friendCode,
  }) async {
    // 如果没有提供friendCode，尝试从OpenInstall获取
    String finalFriendCode = friendCode ?? "545452"; // 默认值
    
    if (friendCode == null) {
      try {
        final inviteCode = await OpenInstallService.getCachedInviteCode();
        if (inviteCode != null && inviteCode.isNotEmpty) {
          finalFriendCode = inviteCode;
          logger.info(
            '使用OpenInstall邀请码登录',
            tag: 'AuthService',
            extra: {'inviteCode': inviteCode, 'phone': phoneNumber},
          );
        } else {
          logger.info(
            '未找到OpenInstall邀请码，使用默认邀请码',
            tag: 'AuthService',
            extra: {'defaultFriendCode': finalFriendCode, 'phone': phoneNumber},
          );
        }
      } catch (e) {
        logger.warning(
          '获取OpenInstall邀请码失败，使用默认邀请码',
          tag: 'AuthService',
          extra: {'error': e.toString(), 'defaultFriendCode': finalFriendCode, 'phone': phoneNumber},
        );
      }
    } else {
      logger.info(
        '使用手动提供的邀请码登录',
        tag: 'AuthService',
        extra: {'friendCode': friendCode, 'phone': phoneNumber},
      );
    }

    final result = await _authApi.loginWithCode(
      phone: phoneNumber,
      captcha: code,
      friendCode: finalFriendCode,
    );

    if (result.isSuccess && result.data != null) {
      await _handleLoginSuccess(result.data!);
    }

    return result;
  }

  /// 同步授权应用（首页进入时调用）
  Future<HttpResultN> syncAuthApp() async {
    try {
      final result = await _authApi.syncAuthApp();
      if (!result.isSuccess) {
        logger.warning('同步授权应用失败: ${result.msg}', tag: 'AuthService');
      }
      return result;
    } catch (e) {
      logger.error('同步授权应用异常: $e', tag: 'AuthService', error: e);
      return HttpResultN.failure(-1, '同步授权应用失败: $e');
    }
  }

  Future<void> _handleLoginSuccess(LoginModel user) async {
    _currentUser = user;
    await _saveCurrentUser(user);

    logger.info(
      '登录成功',
      tag: 'AuthService',
      extra: {'userId': user.id, 'nickname': user.nickname},
    );

    // 🔥 登录成功后初始化真实的设备ID（隐私政策已同意）
    try {
      await DeviceUtil.instance.initializeDeviceId();
      logger.info('设备ID初始化完成', tag: 'AuthService');
    } catch (e) {
      logger.warning('设备ID初始化失败: $e', tag: 'AuthService');
    }

    // 🔥 保存用户 Token 到 Native（供后台定位上报使用）
    try {
      final success = await NativeLocationReportService.saveUserToken();
      if (success) {
        logger.info('用户Token已同步到Native端', tag: 'AuthService');
      } else {
        logger.error('同步Token到Native失败', tag: 'AuthService');
      }
    } catch (e) {
      logger.error('同步Token到Native失败: $e', tag: 'AuthService');
    }

    // 🔥 已废弃：极光推送（推送现在走腾讯IM）
    // _setJPushAlias(user);

    // 🔥 修复：等待IM登录完成，避免进入聊天页面时IM还未登录
    await _loginTencentIM(user);

    // 定位服务将在首页启动，这里不再自动启动

    // Get.offAll(() => ScreenNavPage());
  }
  
  /// 🔥 已废弃：设置极光推送别名（推送现在走腾讯IM）
  // void _setJPushAlias(LoginModel user) {
  //   // 极光推送已废弃，推送功能现在统一走腾讯IM离线推送
  // }

  /// 登录腾讯IM
  /// 🔥 修复：改为异步方法，确保IM登录完成后再继续
  /// 🔥 增强：添加重试机制，最多重试2次
  Future<void> _loginTencentIM(LoginModel user) async {
    logger.info('🔄 准备登录腾讯IM...', tag: 'AuthService');
    
    const int maxRetries = 2;
    int retryCount = 0;
    
    while (retryCount <= maxRetries) {
      try {
        // 检查IM服务是否已注册
        final isRegistered = Get.isRegistered<TencentIMService>();
        if (!isRegistered) {
          logger.warning('腾讯IM服务未注册，跳过IM登录', tag: 'AuthService');
          return;
        }
        
        final imService = Get.find<TencentIMService>();
        
        // 🔥 检查用户IM登录所需参数
        logger.info(
          'IM登录参数检查 - uniqueId: ${user.uniqueId != null ? "有值" : "空"}, hasImSign: ${user.imSign != null && user.imSign!.isNotEmpty}',
          tag: 'AuthService',
        );
        
        // 检查必要参数
        if (user.uniqueId == null || user.uniqueId!.isEmpty) {
          logger.error('IM登录失败: uniqueId为空', tag: 'AuthService');
          return;
        }
        
        if (user.imSign == null || user.imSign!.isEmpty) {
          logger.error('IM登录失败: imSign为空', tag: 'AuthService');
          return;
        }
        
        logger.info('开始登录腾讯IM (第${retryCount + 1}次尝试)', tag: 'AuthService');
        
        // 🔥 等待IM登录完成，避免状态不一致
        bool success = await imService.loginIM(user);
        if (success) {
          logger.info('腾讯IM登录成功', tag: 'AuthService');
          return; // 成功则退出
        } else {
          logger.warning('腾讯IM登录失败 (第${retryCount + 1}次尝试)', tag: 'AuthService');
          retryCount++;
          if (retryCount <= maxRetries) {
            // 等待1秒后重试
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      } catch (e, stackTrace) {
        logger.error('登录腾讯IM异常: $e', tag: 'AuthService', error: e, stackTrace: stackTrace);
        retryCount++;
        if (retryCount <= maxRetries) {
          // 等待1秒后重试
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
    
    logger.error('腾讯IM登录最终失败，已重试$maxRetries次', tag: 'AuthService');
  }

  /// 🔥 已废弃：清除极光推送别名（推送现在走腾讯IM）
  void _clearJPushAlias() {
    // 极光推送已废弃，推送功能现在统一走腾讯IM离线推送
    logger.info('极光推送已废弃，跳过别名清除');
  }

  /// 退出腾讯IM
  /// 🔥 修复：改为异步方法，确保IM退出完成后再继续
  Future<void> _logoutTencentIM() async {
    try {
      // 检查IM服务是否已注册
      if (Get.isRegistered<TencentIMService>()) {
        final imService = Get.find<TencentIMService>();
        
        logger.info('开始退出腾讯IM', tag: 'AuthService');
        
        // 🔥 等待IM退出完成，避免账号切换时状态混乱
        bool success = await imService.logoutIM();
        if (success) {
          logger.info('腾讯IM退出成功', tag: 'AuthService');
        } else {
          logger.w('腾讯IM退出失败', tag: 'AuthService');
        }
      } else {
        logger.w('腾讯IM服务未注册，跳过IM退出', tag: 'AuthService');
      }
    } catch (e) {
      logger.e('退出腾讯IM失败: $e', tag: 'AuthService');
    }
  }


  Future<void> _saveCurrentUser(LoginModel user) async {
    try {
      final jsonData = jsonEncode(user.toJson());
      DebugUtil.info(' 开始保存用户数据，用户ID: ${user.id}, 数据长度: ${jsonData.length}');
      
      await _storage.write(
        key: _currentUserKey,
        value: jsonData,
      );
      
      DebugUtil.success(' 用户数据保存成功');
      
      // 验证保存是否成功
      final savedData = await _storage.read(key: _currentUserKey);
      if (savedData != null) {
        DebugUtil.success(' 验证保存成功，数据长度: ${savedData.length}');
      } else {
        DebugUtil.error(' 验证保存失败，读取到null');
      }
    } catch (e) {
      DebugUtil.error(' 保存用户数据失败: $e');
      throw e;
    }
  }

  /// 读取缓存用户
  Future<LoginModel?> _loadCurrentUser() async {
    try {
      DebugUtil.check(' 开始读取用户缓存数据...');
      final userString = await _storage.read(key: _currentUserKey);
      
      if (userString != null) {
        DebugUtil.success(' 找到用户缓存数据，长度: ${userString.length}');
        final user = LoginModel.fromJson(jsonDecode(userString));
        DebugUtil.success(' 用户数据解析成功，用户ID: ${user.id}, token存在: ${user.token != null}');
        return user;
      } else {
        DebugUtil.warning(' 未找到用户缓存数据');
      }
    } catch (e) {
      DebugUtil.error(' 读取缓存用户失败: $e');
      debugPrint('读取缓存用户失败: $e');
    }
    return null;
  }

  Future<void> loadCurrentUser() async {
    final userString = await _storage.read(key: _currentUserKey);
    if (userString != null) {
      _currentUser = LoginModel.fromJson(jsonDecode(userString));
    }
  }

  bool get isLoggedIn => _currentUser != null && _currentUser!.token != null;

  /// 更新用户信息
  Future<void> updateUserInfo(LoginModel updatedUser) async {
    _currentUser = updatedUser;
    await _saveCurrentUser(updatedUser);

    logger.info(
      '用户信息已更新',
      tag: 'AuthService',
      extra: {'userId': updatedUser.id, 'nickname': updatedUser.nickname},
    );
  }

  /// 更新用户头像
  Future<void> updateUserAvatar(String avatarUrl) async {
    if (_currentUser != null) {
      _currentUser!.headPortrait = avatarUrl;
      await _saveCurrentUser(_currentUser!);

      logger.info(
        '用户头像已更新',
        tag: 'AuthService',
        extra: {'userId': _currentUser!.id, 'avatar': avatarUrl},
      );
    }
  }

  /// 更新用户昵称
  Future<void> updateUserNickname(String nickname) async {
    if (_currentUser != null) {
      _currentUser!.nickname = nickname;
      await _saveCurrentUser(_currentUser!);

      logger.info(
        '用户昵称已更新',
        tag: 'AuthService',
        extra: {'userId': _currentUser!.id, 'nickname': nickname},
      );
    }
  }

  /// 清除用户数据并登出
  Future<void> logout() async {
    if (_currentUser != null) {
      logger.info(
        '用户登出',
        tag: 'AuthService',
        extra: {'userId': _currentUser!.id},
      );

      // 清除极光推送别名
      _clearJPushAlias();

      // 🔥 修复：等待IM退出完成
      await _logoutTencentIM();

      // 调用退出登录API
      try {
        final authApi = AuthApi();
        final result = await authApi.logout();
        if (result.isSuccess) {
          logger.info('退出登录API调用成功', tag: 'AuthService');
        } else {
          logger.warning('退出登录API调用失败: ${result.msg}', tag: 'AuthService');
        }
      } catch (e) {
        logger.error('退出登录API调用异常: $e', tag: 'AuthService');
      }
    }

    // 重置首页弹窗会话标志位，确保重新登录时能正常显示弹窗
    try {
      HomePopupService.resetSessionFlags();
      logger.info('首页弹窗会话标志位已重置', tag: 'AuthService');
    } catch (e) {
      logger.warning('重置首页弹窗标志位失败: $e', tag: 'AuthService');
    }

    // 清除本地数据
    _currentUser = null;
    await _storage.delete(key: _currentUserKey);

    logger.info('用户数据已清除', tag: 'AuthService');
  }

  /// 只清除本地用户数据（用于注销后的数据清理，不调用退出登录API）
  Future<void> clearLocalUserData() async {
    if (_currentUser != null) {
      logger.info(
        '清除本地用户数据',
        tag: 'AuthService',
        extra: {'userId': _currentUser!.id},
      );
      
      // 清除极光推送别名（保留广播推送能力）
      _clearJPushAlias();

      // 🔥 修复：等待IM退出完成
      await _logoutTencentIM();
    }

    // 只清除本地数据
    _currentUser = null;
    await _storage.delete(key: _currentUserKey);

    // 🔥 清除 Native 端的用户 Token
    try {
      await NativeLocationReportService.clearUserToken();
      logger.info('Native端Token已清除', tag: 'AuthService');
    } catch (e) {
      logger.error('清除Native端Token失败: $e', tag: 'AuthService');
    }

    logger.info('本地用户数据已清除', tag: 'AuthService');
  }

  /// 刷新用户Token（如果需要）
  Future<void> refreshToken(String newToken) async {
    if (_currentUser != null) {
      _currentUser!.token = newToken;
      await _saveCurrentUser(_currentUser!);

      logger.info(
        'Token已刷新',
        tag: 'AuthService',
        extra: {'userId': _currentUser!.id},
      );
    }
  }

  /// 检查用户是否需要完善信息
  bool get needsPerfectInfo => _currentUser?.isPerfectInformation != 0;

  /// 更新当前用户数据
  Future<void> updateCurrentUser(LoginModel user) async {
    _currentUser = user;
    await _saveCurrentUser(user);

    logger.info(
      '用户信息已更新',
      tag: 'AuthService',
      extra: {'userId': user.id, 'nickname': user.nickname},
    );
  }

  /// 刷新用户信息（从服务器获取最新数据并缓存）
  /// 只在用户信息更新后调用，不要频繁调用
  /// 🔥 修复：保留本地的 token 和 imSign，因为 getUserInfo API 可能不返回这些字段
  Future<bool> refreshUserInfoFromServer() async {
    try {
      final authApi = AuthApi();
      final result = await authApi.getUserInfo();

      logger.info(
        '调用getUserInfo API',
        tag: 'AuthService',
        extra: {'isSuccess': result.isSuccess, 'msg': result.msg},
      );

      if (result.isSuccess && result.data != null) {
        // 检查用户数据是否有效（至少要有ID）
        if (result.data!.id != null && result.data!.id! > 0) {
          final newUser = result.data!;
          
          // 🔥 关键修复：如果服务器没有返回 token 或 imSign，保留本地缓存的值
          // 因为 getUserInfo API 通常不返回这些敏感字段，只有登录时才返回
          if (_currentUser != null) {
            if (newUser.token == null || newUser.token!.isEmpty) {
              newUser.token = _currentUser!.token;
              logger.debug('保留本地缓存的token', tag: 'AuthService');
            }
            if (newUser.imSign == null || newUser.imSign!.isEmpty) {
              newUser.imSign = _currentUser!.imSign;
              logger.debug('保留本地缓存的imSign', tag: 'AuthService');
            }
          }
          
          // 使用合并后的用户对象更新缓存
          await updateCurrentUser(newUser);

          logger.info(
            '用户信息已从服务器刷新',
            tag: 'AuthService',
            extra: {
              'userId': newUser.id, 
              'nickname': newUser.nickname,
              'hasToken': newUser.token != null && newUser.token!.isNotEmpty,
              'hasImSign': newUser.imSign != null && newUser.imSign!.isNotEmpty,
            },
          );

          return true;
        } else {
          logger.warning(
            '服务器返回的用户数据无效（ID为空或为0），保留本地缓存',
            tag: 'AuthService',
            extra: {'data': result.data?.toJson()},
          );
          return false;
        }
      } else {
        logger.error(
          '从服务器刷新用户信息失败',
          tag: 'AuthService',
          extra: {'error': result.msg, 'code': result.code},
        );
        return false;
      }
    } catch (e) {
      logger.error(
        '从服务器刷新用户信息异常',
        tag: 'AuthService',
        extra: {
          'error': e.toString(),
          'stackTrace': e is Error ? e.stackTrace.toString() : 'No stack trace',
        },
      );
      return false;
    }
  }

  /// 获取用户缓存数据的摘要信息（用于调试）
  Map<String, dynamic> getUserSummary() {
    if (_currentUser == null) {
      return {'status': 'not_logged_in'};
    }

    return {
      'status': 'logged_in',
      'userId': _currentUser!.id,
      'phone': _currentUser!.phone,
      'nickname': _currentUser!.nickname,
      'isVip': isVip,
      'hasToken': _currentUser!.token?.isNotEmpty == true,
      'cacheTime': DateTime.now().toIso8601String(),
    };
  }
}
