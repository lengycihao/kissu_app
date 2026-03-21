part of 'tencent_im_service.dart';

/// 情侣关系消息处理器
/// 负责处理绑定/解绑相关的IM自定义消息和好友关系事件
class _IMRelationshipHandler {
  final TencentIMService _s;
  _IMRelationshipHandler(this._s);

  /// 处理情侣关系绑定/解绑消息
  /// 
  /// [customData] 自定义消息数据（JSON字符串）
  void handleRelationshipMessage(String? customData) async {
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
      if (_s.onBindMessageReceived.value != null) {
        _s.onBindMessageReceived.value!();
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
  Future<void> handleBindEvent() async {
    try {
      logger.debug('🎉 检测到好友添加事件，执行绑定逻辑', tag: 'TencentIMService');

      // 尝试获取动画服务并执行绑定逻辑
      try {
        final animationService = RelationshipAnimationService.instance;

        // 0. 先触发绑定消息回调（关闭可能存在的绑定弹窗）
        logger.debug('💬 触发绑定消息回调，准备关闭绑定弹窗...', tag: 'TencentIMService');
        if (_s.onBindMessageReceived.value != null) {
          _s.onBindMessageReceived.value!();
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
  Future<void> handleUnbindEvent() async {
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
              content: '你确定拒绝"$nickname"绑定申请？',
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

      // 这里约定：true 表示点击"知道了"，false 表示点击"再次发起"
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
        logger.debug('用户点击"知道了"，不再发起绑定', tag: 'TencentIMService');
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
}
