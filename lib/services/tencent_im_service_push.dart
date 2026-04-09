part of 'tencent_im_service.dart';

/// 推送服务处理器
/// 负责推送服务的注册、反注册和通知点击处理
class _IMPushHandler {
  final TencentIMService _s;
  _IMPushHandler(this._s);

  /// 注册推送服务
  /// 注意：
  /// - Android端厂商推送配置在timpush-configs.json中，插件会自动读取
  /// - 必须传入sdkAppId参数，让插件关联到正确的配置
  Future<void> registerPushService() async {
    try {
      logger.debug('开始注册推送服务（sdkAppId: ${TencentIMService.sdkAppID}）', tag: 'TencentIMService');

      // 🔥 检查appKey是否已配置
      if (TencentIMService.pushAppKey.isEmpty) {
        logger.error('❌ 腾讯云IM推送appKey未配置！', tag: 'TencentIMService');
        return;
      }

      // 注册推送服务
      // sdkAppId: 必须传入，用于关联timpush-configs.json中的厂商配置
      // appKey: 🔥 必须传入！从IM控制台 > 推送服务Push > 接入设置 获取
      // apnsCertificateID: iOS平台的APNs证书ID，Android平台传null
      final result = await TencentCloudChatPush().registerPush(
        sdkAppId: TencentIMService.sdkAppID,
        appKey: TencentIMService.pushAppKey,
        apnsCertificateID: null,
        onNotificationClicked: ({
          required String ext,
          String? userID,
          String? groupID,
        }) {
          logger.debug('📱 推送通知被点击: ext=$ext, userID=$userID, groupID=$groupID', tag: 'TencentIMService');
          handlePushNotificationClick(
            ext: ext,
            userID: userID,
            groupID: groupID,
          );
        },
      );

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
    } catch (e, stackTrace) {
      logger.error('推送服务注册失败: $e', tag: 'TencentIMService');
      logger.error('堆栈信息: $stackTrace', tag: 'TencentIMService');
      // 推送注册失败不影响IM登录，只记录错误
    }
  }

  /// 反注册推送服务
  /// 
  /// 在IM退出登录时调用
  Future<void> unRegisterPushService() async {
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
  void handlePushNotificationClick({
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
      try {
        final extData = jsonDecode(ext);
        logger.debug('推送ext数据: $extData', tag: 'TencentIMService');
      } catch (e) {
        // ext可能不是JSON格式，直接使用字符串
        logger.error('推送ext不是JSON格式: $ext', tag: 'TencentIMService');
      }

      // 跳转到聊天页面
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
}
