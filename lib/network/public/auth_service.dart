import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kissu_app/model/login_model/login_model.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/public/auth_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
import 'package:kissu_app/services/jpush_service.dart';
import 'package:kissu_app/services/openinstall_service.dart';
import 'package:get/get.dart';

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

  Future<void> _handleLoginSuccess(LoginModel user) async {
    _currentUser = user;
    await _saveCurrentUser(user);

    logger.info(
      '登录成功',
      tag: 'AuthService',
      extra: {'userId': user.id, 'nickname': user.nickname},
    );

    // 设置极光推送别名
    _setJPushAlias(user);


    // 定位服务将在首页启动，这里不再自动启动

    // Get.offAll(() => ScreenNavPage());
  }
  
  /// 设置极光推送别名
  void _setJPushAlias(LoginModel user) {
    try {
      // 检查极光推送服务是否已注册
      if (Get.isRegistered<JPushService>()) {
        final jpushService = Get.find<JPushService>();
        // 使用用户的unique_id作为别名
        String alias = user.uniqueId ?? 'user_${user.id}';
        
        // 在后台设置别名，不阻塞登录流程
        Future.microtask(() async {
          bool success = await jpushService.setAlias(alias);
          if (success) {
            logger.info('极光推送别名设置成功: $alias');
          } else {
            logger.w('极光推送别名设置失败: $alias');
          }
        });
        
        logger.info('开始设置极光推送别名: $alias');
      } else {
        logger.w('极光推送服务未注册，跳过别名设置');
      }
    } catch (e) {
      logger.e('设置极光推送别名失败: $e');
    }
  }

  /// 清除极光推送别名
  void _clearJPushAlias() {
    try {
      // 检查极光推送服务是否已注册
      if (Get.isRegistered<JPushService>()) {
        final jpushService = Get.find<JPushService>();
        
        // 在后台清除别名，不阻塞退出流程
        Future.microtask(() async {
          bool success = await jpushService.deleteAlias();
          if (success) {
            logger.info('极光推送别名清除成功');
          } else {
            logger.w('极光推送别名清除失败');
          }
        });
        
        logger.info('开始清除极光推送别名');
      } else {
        logger.w('极光推送服务未注册，跳过别名清除');
      }
    } catch (e) {
      logger.e('清除极光推送别名失败: $e');
    }
  }



  Future<void> _saveCurrentUser(LoginModel user) async {
    try {
      final jsonData = jsonEncode(user.toJson());
      print('💾 开始保存用户数据，用户ID: ${user.id}, 数据长度: ${jsonData.length}');
      
      await _storage.write(
        key: _currentUserKey,
        value: jsonData,
      );
      
      print('✅ 用户数据保存成功');
      
      // 验证保存是否成功
      final savedData = await _storage.read(key: _currentUserKey);
      if (savedData != null) {
        print('✅ 验证保存成功，数据长度: ${savedData.length}');
      } else {
        print('❌ 验证保存失败，读取到null');
      }
    } catch (e) {
      print('❌ 保存用户数据失败: $e');
      throw e;
    }
  }

  /// 读取缓存用户
  Future<LoginModel?> _loadCurrentUser() async {
    try {
      print('🔍 开始读取用户缓存数据...');
      final userString = await _storage.read(key: _currentUserKey);
      
      if (userString != null) {
        print('✅ 找到用户缓存数据，长度: ${userString.length}');
        final user = LoginModel.fromJson(jsonDecode(userString));
        print('✅ 用户数据解析成功，用户ID: ${user.id}, token存在: ${user.token != null}');
        return user;
      } else {
        print('⚠️ 未找到用户缓存数据');
      }
    } catch (e) {
      print('❌ 读取缓存用户失败: $e');
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
    }

    // 只清除本地数据
    _currentUser = null;
    await _storage.delete(key: _currentUserKey);

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
        // 直接使用服务器返回的用户对象更新缓存
        await updateCurrentUser(result.data!);

        logger.info(
          '用户信息已从服务器刷新',
          tag: 'AuthService',
          extra: {'userId': result.data!.id, 'nickname': result.data!.nickname},
        );

        return true;
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
