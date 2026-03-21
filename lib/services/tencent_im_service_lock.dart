part of 'tencent_im_service.dart';

/// 锁屏指令处理器
/// 负责处理锁机、解锁相关的IM自定义消息
class _IMLockScreenHandler {
  final TencentIMService _s;
  _IMLockScreenHandler(this._s);

  /// 处理锁机指令：收到lock_screen_command自定义消息时存储问题数据并启动锁屏
  void handleLockScreenCommand(String? data) async {
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

      logger.debug('🔒 收到锁机指令，准备锁屏', tag: 'TencentIMService');

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

      logger.debug('🔒 IM原始数据: ${decoded.keys.toList()}', tag: 'TencentIMService');
      logger.debug('🔒 lock_prompt=$lockPrompt, lock_bg_image=$lockBgImage, default_bg_image_index=$defaultBgImageIndex', tag: 'TencentIMService');

      // 解析答案列表并找出正确答案索引（只以 is_answer 字段为准）
      List<String> answers = [];
      int correctIndex = -1;
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
            // 只从 is_answer 字段确定正确答案索引
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

      logger.debug('🔒 解析锁机数据: question=$question, answers=$answers, correctIndex=$correctIndex', tag: 'TencentIMService');

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
      logger.debug('🔒 背景图: defaultBgImageIndex=$defaultBgImageIndex -> bgImageIdx=$bgImageIdx, lockBgImage=$lockBgImage', tag: 'TencentIMService');

      // 背景图：在Flutter侧先下载到本地文件，再让原生读取本地文件（避免原生下载延迟）
      String localBgPath = '';
      if (lockBgImage.isNotEmpty) {
        try {
          logger.debug('🔒 开始下载背景图到本地: $lockBgImage', tag: 'TencentIMService');
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
            logger.debug('🔒 背景图下载成功, 大小=${bytes.length}B, 路径=$localBgPath', tag: 'TencentIMService');
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
        logger.debug('🔒 锁屏启动成功', tag: 'TencentIMService');
      } else {
        logger.warning('🔒 锁屏启动失败（可能缺少悬浮窗权限）', tag: 'TencentIMService');
      }
    } catch (e) {
      logger.error('🔒 锁屏指令处理异常: $e', tag: 'TencentIMService');
    }
  }

  /// 处理对方发来的解锁指令（锁机方主动解锁被锁方）
  void handleUnlockPhoneSend(String? data) async {
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
      logger.debug('🔓 已执行解锁操作', tag: 'TencentIMService');
    } catch (e) {
      logger.error('🔓 处理解锁指令异常: $e', tag: 'TencentIMService');
    }
  }

  /// 处理被锁方答题解锁后的通知（被锁方解锁成功，通知锁机方重置页面）
  void handleUnlockPhoneReceive(String? data) async {
    if (data == null || data.isEmpty) return;
    try {
      final Map<String, dynamic> decoded = jsonDecode(data);
      final String? type = decoded['type'] as String?;
      if (type != 'unlock_phone_receive') return;

      final int attempts = decoded['attempts'] as int? ?? 0;
      logger.debug('🔓 收到被锁方解锁通知，答题次数: $attempts', tag: 'TencentIMService');

      // 触发回调通知锁机方页面重置
      if (_s.onUnlockPhoneReceived.value != null) {
        _s.onUnlockPhoneReceived.value!(attempts);
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
        logger.debug('🔓 已刷新我的页面锁机状态', tag: 'TencentIMService');
      }
    } catch (e) {
      logger.error('🔓 刷新锁机状态异常: $e', tag: 'TencentIMService');
    }
  }
}
