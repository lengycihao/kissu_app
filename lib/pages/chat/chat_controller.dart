import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/network/utils/sp_util.dart';
import 'package:kissu_app/pages/chat/models/chat_message.dart';
import 'package:kissu_app/pages/chat/widgets/chat_more_menu.dart';
// import 'package:kissu_app/pages/chat/widgets/location_picker_page.dart';
// import 'package:kissu_app/services/simple_location_service.dart';
import 'package:kissu_app/utils/media_picker_util.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/tencent_im_service.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_receipt.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_elem_type.dart';
import 'package:kissu_app/services/analytics/analytics_manager.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/services/analytics/analytics_params.dart';

class ChatController extends GetxController {
  // 滚动控制器
  final ScrollController scrollController = ScrollController();
  
  // 输入框焦点控制器
  final FocusNode inputFocusNode = FocusNode();

  // 面板显示状态
  final RxBool showEmojiPanel = false.obs;

  // 聊天消息列表
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;

  // 对端是否已把当前会话消息全部读过（收到 isPeerRead=true 的回执后置为 true）
  bool _peerHasReadAll = false;

  // 聊天背景图片路径
  final RxString backgroundImage = ''.obs;

  // 聊天气泡样式（1-4）
  final RxInt bubbleStyle = 1.obs;

  // 聊天主题（1-4，默认1）
  final RxInt chatTheme = 1.obs;

  // 敏感消息折叠开关（默认关闭）
  final RxBool sensitiveCollapseEnabled = false.obs;

  // 顶部“对方正在输入”提示
  final RxBool isPartnerTyping = false.obs;

  // 对方昵称/备注
  final RxString chatName = '聊天对象'.obs;

  // 对方头像URL
  final RxString avatarUrl = ''.obs;

  // 用户会员状态（用于表情面板）
  final RxBool isVip = false.obs;

  // 设备信息展开状态：null表示未展开，其他值表示当前展开的项类型
  final selectedDeviceInfoType = Rxn<String>(); // 'distance', 'mobileModel', 'network', 'power'

  // 设备信息悬浮提示的自动隐藏定时器
  Timer? _deviceInfoTooltipTimer;

  // 是否已经执行过初始化滚动
  bool _hasScrolledOnInit = false;

  // 对方IM唯一ID（用于腾讯IM单聊会话）
  String? _partnerImId;
  String? get partnerImId => _partnerImId;

  // 历史消息分页相关
  String? _lastHistoryMsgId; // 最近一次拉取结果中最旧消息的ID
  bool _isLoadingHistory = false;
  bool _hasMoreHistory = true;

  // 新消息提示：当不在底部且有新消息时显示
  final RxBool hasNewMessageWhenNotAtBottom = false.obs;
  
  // 埋点相关
  int? _pageEnterTime;
  int _exitType = ExitTypeValue.back;
  bool _hasTrackedExit = false; // 是否已上报离开埋点
  int _sendMessageCount = 0; // 单方主动发送消息次数（不包含系统发送的）
  
  // 页面离开回调（由Widget或其他组件注册）
  VoidCallback? onNavigateToNextPage;
  
  /// App进入后台时调用
  void onAppPaused() {
    _exitType = ExitTypeValue.toBackground;
    _trackPageExit(ExitTypeValue.toBackground);
  }
  
  /// App从后台恢复时调用
  void onAppResumed() {
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _hasTrackedExit = false;
    _exitType = ExitTypeValue.back;
  }

  /// 是否需要在当前消息上方显示时间（类似微信的时间气泡）
  /// [index] 为按时间顺序的索引（0 为最早的一条）
  bool shouldShowTimestampForIndex(int index) {
    if (index <= 0 || index >= messages.length) return index == 0;

    final current = messages[index];
    final prev = messages[index - 1];
    final currentTime = current.time;
    final prevTime = prev.time;

    // 跨天：一定显示
    final isSameDay = currentTime.year == prevTime.year &&
        currentTime.month == prevTime.month &&
        currentTime.day == prevTime.day;
    if (!isSameDay) {
      return true;
    }

    // 同一天：间隔超过 5 分钟才显示
    final diff = currentTime.difference(prevTime);
    return diff > const Duration(minutes: 5);
  }

  /// 将当前列表中自己发送且未读的消息全部标记为已读，返回是否有更新
  bool _markAllSelfMessagesRead() {
    bool updated = false;
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      if (!m.isSent || m.isRead) continue;

      messages[i] = ChatMessage(
        id: m.id,
        content: m.content,
        type: m.type,
        isSent: m.isSent,
        time: m.time,
        avatarUrl: m.avatarUrl,
        imageUrl: m.imageUrl,
        imageWidth: m.imageWidth,
        imageHeight: m.imageHeight,
        locationName: m.locationName,
        latitude: m.latitude,
        longitude: m.longitude,
        isRead: true,
        iconUrl: m.iconUrl,
        vipIcon: m.vipIcon,
        crapDuration: m.crapDuration,
        jumpPage: m.jumpPage,
      );
      updated = true;
    }
    return updated;
  }

  // 初始化对方IM相关信息（昵称、头像、IM ID）
  void _initPartnerInfo() {
    final user = UserManager.currentUser;
    final half = user?.halfUserInfo;
    if (half != null) {
      _partnerImId = half.uniqueId;
      if ((half.nickname ?? '').isNotEmpty) {
        chatName.value = half.nickname!;
      }
      if ((half.headPortrait ?? '').isNotEmpty) {
        avatarUrl.value = half.headPortrait!;
      }
      logDebug('💬 初始化聊天对象: imId=$_partnerImId, name=${chatName.value}');
      
      // 异步从 IM SDK 获取最新资料（包括备注）
      _updatePartnerInfoFromIM();
    } else {
      logDebug('💬 未找到halfUserInfo，暂无法确定聊天对象IM ID');
    }
  }

  /// 从 IM SDK 更新对方信息（昵称、头像、备注）
  Future<void> _updatePartnerInfoFromIM() async {
    final partnerId = _partnerImId;
    if (partnerId == null || partnerId.isEmpty) return;

    try {
      final im = TencentIMService.instance;
      // 1. 优先获取好友信息（包含备注）
      final friendInfo = await im.getFriendInfo(partnerId);
      if (friendInfo != null) {
        // 备注名优先
        final remark = friendInfo.friendRemark;
        final nick = friendInfo.userProfile?.nickName;
        final face = friendInfo.userProfile?.faceUrl;

        if (remark != null && remark.isNotEmpty) {
          chatName.value = remark;
        } else if (nick != null && nick.isNotEmpty) {
          chatName.value = nick;
        }

        if (face != null && face.isNotEmpty) {
          avatarUrl.value = face;
        }
        logDebug('💬 从IM SDK更新好友信息成功: name=${chatName.value}');
      } else {
        // 2. 如果不是好友，尝试获取普通用户信息
        final userInfo = await im.getUsersInfo(partnerId);
        if (userInfo != null) {
          if (userInfo.nickName != null && userInfo.nickName!.isNotEmpty) {
            chatName.value = userInfo.nickName!;
          }
          if (userInfo.faceUrl != null && userInfo.faceUrl!.isNotEmpty) {
            avatarUrl.value = userInfo.faceUrl!;
          }
          logDebug('💬 从IM SDK更新用户信息成功: name=${chatName.value}');
        }
      }
    } catch (e) {
      logError('💬 从IM SDK更新对方信息失败: $e');
    }
  }

  /// 绑定滚动监听，用于上拉加载更多历史消息和检测是否在底部
  void _setupScrollForHistory() {
    scrollController.addListener(() {
      if (!scrollController.hasClients) return;

      final pos = scrollController.position;
      
      // reverse:true时，pixels=0是底部（最新消息），maxScrollExtent是顶部（最旧消息）
      // 判断是否在底部（距离底部50像素内认为在底部）
      final isAtBottom = pos.pixels <= 50;
      
      // 如果滚动到底部，清除新消息提示
      if (isAtBottom && hasNewMessageWhenNotAtBottom.value) {
        hasNewMessageWhenNotAtBottom.value = false;
      }

      // 仅在接近顶部时分页加载历史（pixels接近maxScrollExtent）
      final nearTop = pos.pixels >= pos.maxScrollExtent - 80;
      if (nearTop && !_isLoadingHistory && _hasMoreHistory) {
        _loadMoreHistoryMessages();
      }
    });
  }

  /// 检查是否在底部
  bool _isAtBottom() {
    if (!scrollController.hasClients) return true;
    final pos = scrollController.position;
    // reverse:true时，pixels=0是底部，距离底部50像素内认为在底部
    return pos.pixels <= 50;
  }

  /// 首次进入聊天页加载一页历史消息
  Future<void> _loadInitialHistoryMessages() async {
    await _loadMoreHistoryMessages(initialLoad: true);

    // 首次进入聊天页后，如果存在未读消息，主动对整个会话发送已读回执
    final im = TencentIMService.instance;
    final partnerId = _partnerImId;
    if (partnerId != null &&
        partnerId.isNotEmpty &&
        im.isInitialized &&
        im.isLoggedIn) {
      im.markC2CMessageAsRead(userID: partnerId);
    }
  }

  /// 拉取更多历史消息（向上翻页）
  Future<void> _loadMoreHistoryMessages({bool initialLoad = false}) async {
    final im = TencentIMService.instance;
    final partnerId = _partnerImId;

    if (partnerId == null || partnerId.isEmpty) {
      logDebug('💬 无法拉取历史消息：未找到另一半IM ID');
      return;
    }
    if (!im.isInitialized || !im.isLoggedIn) {
      logDebug('💬 IM未初始化或未登录，无法拉取历史消息');
      return;
    }
    if (_isLoadingHistory || !_hasMoreHistory) {
      return;
    }

    _isLoadingHistory = true;

    try {
      // 初始加载时拉取更多消息（50条），避免折叠后消息不够一屏幕
      // 后续分页加载保持20条
      final fetchCount = initialLoad ? 50 : 30;
      final res = await im.getC2CHistoryMessages(
        userID: partnerId,
        count: fetchCount,
        lastMsgID: _lastHistoryMsgId,
      );

      if (res == null || res.code != 0 || res.data == null) {
        logInfo('💬 拉取历史消息失败: code=${res?.code}, desc=${res?.desc}');
        _isLoadingHistory = false;
        return;
      }

      final historyList = res.data!;
      if (historyList.isEmpty) {
        // 没有更多历史消息
        _hasMoreHistory = false;
        _isLoadingHistory = false;
        return;
      }

      // SDK 返回列表通常是“越新的越靠前”，我们需要从旧到新插入到列表前面
      final currentUserId = im.currentUserID;
      final partner = _partnerImId;

      final toInsert = <ChatMessage>[];
      for (final msg in historyList.reversed) {
        final chatMsg = _convertIMMessageToChatMessage(
          msg,
          currentUserId: currentUserId,
          partnerId: partner,
        );
        if (chatMsg == null) continue;

        // 避免和当前列表重复（根据 msgID 去重）
        final exists = messages.any((m) => m.id == chatMsg.id);
        if (!exists) {
          toInsert.add(chatMsg);
        }
      }

      if (toInsert.isNotEmpty) {
        // 在列表头部插入更旧的消息
        messages.insertAll(0, toInsert);

        // 如果之前已收到"对端全部已读"回执，补齐新插入的历史消息为已读状态
        if (_peerHasReadAll) {
          _markAllSelfMessagesRead();
        }

        messages.refresh();

        // 记录当前拉取到的最旧一条消息ID，作为下一次分页的起点
        _lastHistoryMsgId = historyList.last.msgID;

        if (initialLoad) {
          // 首次加载后滚动到底部，显示最新消息
          _scrollToBottomWithDelay();
          // 检查内容是否不够一屏幕，如果不够则继续加载更多
          _checkAndLoadMoreIfNeeded();
        }
      } else {
        // 说明已经没有更旧的消息
        _hasMoreHistory = false;
      }
    } catch (e) {
      logError('💬 拉取历史消息异常: $e');
    } finally {
      _isLoadingHistory = false;
    }
  }

  /// 检查内容是否不够一屏幕，如果不够则继续加载更多历史消息
  void _checkAndLoadMoreIfNeeded() {
    // 延迟执行，等待ListView渲染完成
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!scrollController.hasClients || !_hasMoreHistory) return;
      
      final pos = scrollController.position;
      // 如果maxScrollExtent很小（内容不够一屏幕），继续加载更多
      // reverse:true时，maxScrollExtent是可滚动的最大距离
      if (pos.maxScrollExtent < 100) {
        logDebug('💬 内容不够一屏幕，自动加载更多历史消息');
        _loadMoreHistoryMessages().then((_) {
          // 递归检查，直到内容够一屏幕或没有更多历史
          _checkAndLoadMoreIfNeeded();
        });
      }
    });
  }

  // 从缓存加载背景
  Future<void> _loadBackgroundFromCache() async {
    final savedBackground = await SpUtil.getString('chat_background_path');
    if (savedBackground.isNotEmpty) {
      backgroundImage.value = savedBackground;
      logDebug('💬 加载缓存的聊天背景: $savedBackground');
    } else {
      // 如果没有保存的背景，默认使用第一套主题的背景
      const defaultThemeBackground = 'assets/chat/kissu_chat_theme_bg1.webp';
      backgroundImage.value = defaultThemeBackground;
      logDebug('💬 使用默认主题背景（第一套主题）: $defaultThemeBackground');
    }
  }

  // 从缓存加载气泡样式
  Future<void> _loadBubbleStyleFromCache() async {
    final savedStyle = await SpUtil.getInteger('chat_bubble_style', 1);
    if (savedStyle > 0 && savedStyle <= 4) {
      bubbleStyle.value = savedStyle;
      logDebug('💬 加载缓存的气泡样式: $savedStyle');
    } else {
      // 如果缓存中没有或值无效，使用默认样式1
      bubbleStyle.value = 1;
      // 同时保存默认值到缓存
      await SpUtil.putInteger('chat_bubble_style', 1);
      logDebug('💬 使用默认气泡样式: 1');
    }
  }

  // 从缓存加载主题
  Future<void> _loadThemeFromCache() async {
    final savedTheme = await SpUtil.getInteger('chat_theme', 1);
    if (savedTheme > 0 && savedTheme <= 4) {
      chatTheme.value = savedTheme;
      logDebug('💬 加载缓存的主题: $savedTheme');
    } else {
      chatTheme.value = 1;
      await SpUtil.putInteger('chat_theme', 1);
      logDebug('💬 使用默认主题: 1');
    }
  }

  // 从缓存加载敏感消息折叠开关状态
  Future<void> _loadSensitiveCollapseFromCache() async {
    final enabled = await SpUtil.getBool('sensitive_collapse_enabled', false);
    sensitiveCollapseEnabled.value = enabled;
    logDebug('💬 加载敏感消息折叠开关状态: $enabled');
  }

  // 更新气泡样式（由 ChatBubbleController 调用）
  void updateBubbleStyle(int style) {
    if (style >= 1 && style <= 4) {
      bubbleStyle.value = style;
      // 持久化到本地，确保返回聊天页后重新加载依然生效
      SpUtil.putInteger('chat_bubble_style', style);
      // 刷新消息列表以触发气泡重建
      messages.refresh();
      logDebug('💬 更新并保存气泡样式: $style');
    }
  }

  // 更新主题（由 ChatThemeController 调用）
  void updateTheme(int theme) {
    if (theme >= 1 && theme <= 4) {
      chatTheme.value = theme;
      logDebug('💬 更新主题: $theme');
    }
  }

  // 获取主题对应的按钮颜色（用于前三个图标）
  Color getThemeButtonColor() {
    switch (chatTheme.value) {
      case 1:
        return const Color(0xffFF90CA);
      case 2:
        return const Color(0xffA6D7FF);
      case 3:
        return const Color(0xffFF90CA);
      case 4:
        return const Color(0xffAD7D63);
      default:
        return const Color(0xffFF90CA);
    }
  }

  // 获取第四个图标的主题图片路径
  String getThemeLocationIconPath() {
    switch (chatTheme.value) {
      case 1:
        return 'assets/chat/kissu3_chat_location1.webp';
      case 2:
        return 'assets/chat/kissu3_chat_location2.webp';
      case 3:
        return 'assets/chat/kissu3_chat_location1.webp';
      case 4:
        return 'assets/chat/kissu3_chat_location3.webp';
      default:
        return 'assets/chat/kissu3_chat_location1.webp';
    }
  }

  /// 上报页面离开埋点
  void _trackPageExit(int exitType) {
    if (_hasTrackedExit || _pageEnterTime == null) return;
    _hasTrackedExit = true;
    
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final duration = currentTime - _pageEnterTime!;
    
    AnalyticsManager.instance.trackPageView(
      pageId: ChatEvents.pageId,
      eventId: ChatEvents.page,
      enterTime: _pageEnterTime!,
      duration: duration,
      exitType: exitType,
      params: {
        AnalyticsParams.sendSum: _sendMessageCount,
      },
    );
    
    // 如果是进入下一页，立即重置状态，为从下一页返回后的埋点做准备
    if (exitType == ExitTypeValue.nextPage) {
      _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _hasTrackedExit = false;
      _exitType = ExitTypeValue.back;
    }
  }
  
  @override
  void onInit() {
    super.onInit();
    logDebug('💬 ChatController 初始化');
    
    // 埋点：记录页面进入时间（十位时间戳）
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // 注册页面离开回调
    onNavigateToNextPage = () {
      _trackPageExit(ExitTypeValue.nextPage);
    };
    
    // 初始化用户VIP状态
    _initUserVipStatus();
    
    // 使用真实IM聊天，关闭本地mock消息
    _initPartnerInfo();
    _setupIMMessageListener();
    _setupIMReadReceiptListener();
    _setupScrollForHistory();
    _loadInitialHistoryMessages();
    _setupFocusListener();
    _loadBackgroundFromCache();
    _loadBubbleStyleFromCache();
    _loadThemeFromCache();
    _loadSensitiveCollapseFromCache();
    // 进入聊天页面时，将未读消息数清零
    try {
      final im = TencentIMService.instance;
      im.clearC2CUnreadCount();
    } catch (_) {}
  }
  
  /// 初始化用户VIP状态
  void _initUserVipStatus() {
    try {
      final userVipStatus = UserManager.isVip;
      isVip.value = userVipStatus;
      logDebug('💬 用户VIP状态: $userVipStatus');
    } catch (e) {
      logError('获取用户VIP状态失败: $e');
      isVip.value = false;
    }
  }
  
  @override
  void onClose() {
    // 埋点：记录页面离开事件（返回）
    _trackPageExit(_exitType);
    
    scrollController.dispose();
    inputFocusNode.dispose();
    _deviceInfoTooltipTimer?.cancel();
    logDebug('💬 ChatController 销毁');
    super.onClose();
  }

  /// 清除设备信息提示（手动关闭 tip）
  void clearSelectedDeviceInfo() {
    _deviceInfoTooltipTimer?.cancel();
    selectedDeviceInfoType.value = null;
  }

  /// 切换设备信息展开状态（并启动 2 秒自动隐藏计时）
  void toggleDeviceInfo(String? type) {
    // 先取消之前的定时器
    _deviceInfoTooltipTimer?.cancel();

    // 如果点击的是当前已展开的项，则收起并直接返回
    if (selectedDeviceInfoType.value == type) {
      selectedDeviceInfoType.value = null;
      return;
    }

    // 切换到新的类型
    selectedDeviceInfoType.value = type;

    // 启动 2 秒自动隐藏
    if (type != null) {
      _deviceInfoTooltipTimer = Timer(const Duration(seconds: 2), () {
        // 只在当前仍然是同一个类型时才隐藏，避免抢掉后续点击
        if (selectedDeviceInfoType.value == type) {
          selectedDeviceInfoType.value = null;
        }
      });
    }
  }

  // 设置输入框焦点监听器
  void _setupFocusListener() {
    inputFocusNode.addListener(() {
      // 当输入框获得焦点时（键盘抬起），关闭所有面板
      if (inputFocusNode.hasFocus) {
        showEmojiPanel.value = false;
        logDebug('💬 键盘抬起，关闭所有面板');
        // 键盘抬起时，延迟滚动到底部
        _scrollToBottomWithDelay();
      }
    });
  }

  // 发送文字消息（走腾讯IM SDK）
  void sendTextMessage(String text) {
    if (text.trim().isEmpty) return;
    
    // 埋点：增加发送消息计数
    _sendMessageCount++;

    final localId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    final message = ChatMessage(
      id: localId,
      content: text,
      type: MessageType.text,
      isSent: true,
      time: now,
      // 本地临时消息也使用当前用户头像，避免返回再进才变成真实头像
      avatarUrl: UserManager.userAvatar,
    );

    // 添加消息到列表
    messages.add(message);
    
    // 强制刷新UI（确保 RxList 触发更新）
    messages.refresh();
    
    // 延迟滚动到底部，确保UI更新完成
    Future.microtask(() => _scrollToBottom());

    // 通过腾讯IM发送真实消息，并在拿到 SDK msgID 后回写到本地消息
    _sendTextMessageToIM(text, localId: localId, localTime: now);
  }

  Future<void> _sendTextMessageToIM(
    String text, {
    required String localId,
    required DateTime localTime,
  }) async {
    final partnerId = _partnerImId;
    if (partnerId == null || partnerId.isEmpty) {
      logDebug('💬 未找到另一半IM ID，暂时只本地显示消息: $text');
      return;
    }

    final im = TencentIMService.instance;
    if (!im.isInitialized || !im.isLoggedIn) {
      logDebug('💬 IM未初始化或未登录，暂时只本地显示消息: $text');
      return;
    }

    final res =
        await im.sendTextMessage(receiverID: partnerId, text: text, isGroup: false);

    // 使用 SDK 返回的 msgID + 服务器时间，更新本地临时消息，保证撤回 / 已读 能按 msgID 正常工作
    if (res != null && res.code == 0 && res.data != null) {
      final sdkMsg = res.data!;
      final sdkMsgId = sdkMsg.msgID;
      final tsSeconds =
          sdkMsg.timestamp ?? (localTime.millisecondsSinceEpoch ~/ 1000);
      final sdkTime =
          DateTime.fromMillisecondsSinceEpoch(tsSeconds * 1000);

      if (sdkMsgId != null && sdkMsgId.isNotEmpty) {
        final index =
            messages.lastIndexWhere((m) => m.id == localId && m.isSent);
        if (index != -1) {
          final old = messages[index];
          messages[index] = ChatMessage(
            id: sdkMsgId,
            content: old.content,
            type: old.type,
            isSent: old.isSent,
            time: sdkTime,
            avatarUrl: old.avatarUrl,
            imageUrl: old.imageUrl,
            imageWidth: old.imageWidth,
            imageHeight: old.imageHeight,
            locationName: old.locationName,
            latitude: old.latitude,
            longitude: old.longitude,
            isRead: old.isRead,
            iconUrl: old.iconUrl,
            vipIcon: old.vipIcon,
            crapDuration: old.crapDuration,
            jumpPage: old.jumpPage,
          );
          messages.refresh();
        }
      }
    }
  }

  /// 监听IM新消息，实时刷新聊天列表
  void _setupIMMessageListener() {
    try {
      final im = TencentIMService.instance;
      im.setOnReceiveNewMessage((List<V2TimMessage> imMessages) {
        final currentUserId = im.currentUserID;
        final partnerId = _partnerImId;
        final readMsgIDs = <String>[];

        for (final msg in imMessages) {
          // 对方“正在输入”在线消息：解析自定义 JSON，仅更新顶部提示，不进消息列表
          if (msg.elemType == MessageElemType.V2TIM_ELEM_TYPE_CUSTOM) {
            final customData = msg.customElem?.data;
            String? command;
            if (customData != null && customData.isNotEmpty) {
              // 新格式：{"command":"typing"}
              try {
                final decoded = jsonDecode(customData);
                if (decoded is Map && decoded['command'] is String) {
                  command = decoded['command'] as String;
                }
              } catch (_) {
                // 兼容旧格式纯字符串
                if (customData == 'typing') {
                  command = 'typing';
                }
              }
            }

            if (command == 'typing') {
              if (partnerId != null &&
                  partnerId.isNotEmpty &&
                  msg.sender == partnerId) {
                isPartnerTyping.value = true;
                Future.delayed(const Duration(seconds: 2), () {
                  if (!isClosed) {
                    isPartnerTyping.value = false;
                  }
                });
              }
              continue;
            }
          }

          final chatMsg = _convertIMMessageToChatMessage(
            msg,
            currentUserId: currentUserId,
            partnerId: partnerId,
          );
          if (chatMsg == null) continue;

          // 先看是否已有同 msgID 的消息（历史/回调重复）
          final existingByIdIndex =
              messages.indexWhere((m) => m.id == chatMsg.id);
          if (existingByIdIndex != -1) {
            messages[existingByIdIndex] = chatMsg;
          } else if (chatMsg.isSent) {
            // 自己发送的消息：可能先本地插入了一条临时消息，这里用类型+内容+时间范围去匹配并替换为带 msgID 的正式消息
            final nowMsgTime = chatMsg.time;
            int replaceIndex = -1;
            if (chatMsg.type == MessageType.text) {
              replaceIndex = messages.lastIndexWhere((m) =>
                  m.isSent &&
                  m.type == MessageType.text &&
                  m.content == chatMsg.content &&
                  (nowMsgTime.difference(m.time)).inSeconds.abs() <= 5);
            } else if (chatMsg.type == MessageType.image) {
              replaceIndex = messages.lastIndexWhere((m) =>
                  m.isSent &&
                  m.type == MessageType.image &&
                  m.content == chatMsg.content &&
                  (nowMsgTime.difference(m.time)).inSeconds.abs() <= 10);
            }

            if (replaceIndex != -1) {
              // 用带真实 msgID 的消息替换本地临时消息
              messages[replaceIndex] = chatMsg;
            } else {
              messages.add(chatMsg);
            }
          } else {
            // 对方发来的消息，直接追加
            messages.add(chatMsg);
          }

          // 如果是收到的对方消息，记录下来用于发送已读回执
          if (!chatMsg.isSent && msg.msgID != null && msg.msgID!.isNotEmpty) {
            readMsgIDs.add(msg.msgID!);
          }
        }

        if (imMessages.isNotEmpty) {
          // 检查是否有对方发来的新消息（不是自己发送的）
          final hasReceivedNewMessage = imMessages.any((msg) {
            final chatMsg = _convertIMMessageToChatMessage(
              msg,
              currentUserId: currentUserId,
              partnerId: partnerId,
            );
            return chatMsg != null && !chatMsg.isSent;
          });
          
          // 如果不在底部且有对方发来的新消息，显示提示
          if (hasReceivedNewMessage && !_isAtBottom()) {
            hasNewMessageWhenNotAtBottom.value = true;
          }

          // 刷新列表，触发UI更新
          messages.refresh();

          // 如果就在底部，或者是自己发的，自动滚动到底部
          if (_isAtBottom() || imMessages.any((m) => m.isSelf ?? false)) {
            _scrollToBottomWithDelay();
          }

          // 对刚收到的对方消息发送已读回执（单聊）
          if (readMsgIDs.isNotEmpty &&
              partnerId != null &&
              partnerId.isNotEmpty) {
            im.markC2CMessageAsRead(
              userID: partnerId,
              messageIDList: readMsgIDs,
            );
          }
        }
      });
    } catch (e) {
      logError('💬 设置IM消息监听失败: $e');
    }
  }

  /// 监听IM单聊消息已读回执，更新自己发送消息的已读状态
  void _setupIMReadReceiptListener() {
    try {
      final im = TencentIMService.instance;
      im.setOnRecvC2CReadReceipt(
        (List<V2TimMessageReceipt> receiptList) {
          final partnerId = _partnerImId;
          bool updated = false;

          for (final receipt in receiptList) {
            // 只处理当前会话（对端用户ID匹配另一半）
            if (partnerId != null &&
                partnerId.isNotEmpty &&
                receipt.userID != partnerId) {
              continue;
            }

            // 只有当对端真实把这段会话标记为已读（isPeerRead == true）时，才更新本地已读状态
            // 如果 SDK 回调里 isPeerRead 为 false，则说明对端并未真正读取，不能把消息标记为已读
            if (receipt.isPeerRead != true) {
              continue;
            }

          // 记录对端已读整段会话，用于后续加载的历史消息也同步标记为已读
          _peerHasReadAll = true;

          // 对端已读整段会话时（isPeerRead == true），将当前列表里所有自己发送且未读的消息标记为已读。
          updated = _markAllSelfMessagesRead() || updated;
          }

          if (updated) {
            messages.refresh();
          }
        },
      );
    } catch (e) {
      logError('💬 设置IM已读回执监听失败: $e');
    }
  }


  /// 当自己正在输入时，向对方发送提示（由输入框 onChanged 调用节流即可）
  Timer? _typingDebounce;
  void notifyTyping() {
    final partnerId = _partnerImId;
    final im = TencentIMService.instance;
    if (partnerId == null || partnerId.isEmpty) return;
    if (!im.isInitialized || !im.isLoggedIn) return;

    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 800), () {
      im.sendTypingOnlineMessage(receiverID: partnerId);
    });
  }

  // 插入表情到输入框（不直接发送）
  void insertEmojiToInput(String emoji) {
    // 这个方法会被 ChatPage 中的 GlobalKey 调用
    // 实际实现在 ChatPage 中
  }

  // 切换表情面板
  void toggleEmojiPanel() {
    showEmojiPanel.value = !showEmojiPanel.value;
    if (showEmojiPanel.value) {
      // 展开表情面板时，收起键盘
      inputFocusNode.unfocus();
      logDebug('💬 表情面板展开，收起键盘');
      // 延迟滚动到底部，确保面板完全展开后再滚动
      _scrollToBottomWithDelay();
    }
  }

  // 隐藏所有面板
  void hideAllPanels() {
    showEmojiPanel.value = false;
    // 收起键盘
    inputFocusNode.unfocus();
    // 清除设备信息详情tip
    clearSelectedDeviceInfo();
  }

  /// 功能区：相册
  Future<void> onAlbumTap() async {
    hideAllPanels();
    await _pickImageFromGallery();
  }

  /// 功能区：拍照
  Future<void> onCameraTap() async {
    hideAllPanels();
    await _takePhoto();
  }

  /// 功能区：位置 - 跳转到定位页面
  Future<void> onLocationTap() async {
    hideAllPanels();
    
    // 埋点：页面离开（进入下一页）
    onNavigateToNextPage?.call();
    
    Get.toNamed(KissuRoutePath.location);
  }

  // 从相册选择图片
  Future<void> _pickImageFromGallery() async {
    final imageFile = await MediaPickerUtil.pickImageFromGallery(
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (imageFile != null) {
      await _sendImageMessage(imageFile);
    }
  }

  // 拍照
  Future<void> _takePhoto() async {
    final imageFile = await MediaPickerUtil.takePhoto(
      imageQuality: 85,
    );

    if (imageFile != null) {
      await _sendImageMessage(imageFile);
    }
  }

  // 发送图片消息
  Future<void> _sendImageMessage(File imageFile) async {
    try {
      // 埋点：增加发送消息计数
      _sendMessageCount++;
      
      final partnerId = _partnerImId;
      final im = TencentIMService.instance;

      if (partnerId == null || partnerId.isEmpty) {                                                                                                                                                                                                                                                                                                           
        logDebug('💬 未找到另一半IM ID，暂时本地显示图片: ${imageFile.path}');
      }

      // 先尝试读取图片原始宽高，用于前端按 1:1 / 16:9 / 9:16 展示
      double? imgWidth;
      double? imgHeight;
      try {
        final bytes = await imageFile.readAsBytes();
        final completer = Completer<ui.Image>();
        ui.decodeImageFromList(bytes, (ui.Image img) {
          completer.complete(img);
        });
        final uiImage = await completer.future;
        imgWidth = uiImage.width.toDouble();
        imgHeight = uiImage.height.toDouble();
      } catch (e) {
        logError('💬 解析图片宽高失败，使用默认比例展示: $e');
      }

      // 本地先上屏一条图片消息，提升体验
      final localId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();
      final localMsg = ChatMessage(
        id: localId,
        content: '[图片]',
        type: MessageType.image,
        isSent: true,
        time: now,
        // 使用当前用户头像
        avatarUrl: UserManager.userAvatar,
        imageUrl: imageFile.path,
        imageWidth: imgWidth,
        imageHeight: imgHeight,
      );

      messages.add(localMsg);
      messages.refresh();
      Future.microtask(() => _scrollToBottom());

      // 如果 IM 可用，则通过 SDK 发送真实图片消息
      if (partnerId != null &&
          partnerId.isNotEmpty &&
          im.isInitialized &&
          im.isLoggedIn) {
        final res = await im.sendImageMessage(
          receiverID: partnerId,
          imagePath: imageFile.path,
          isGroup: false,
        );
        logDebug('💬 发送图片消息到IM: ${imageFile.path}');

        // 使用 SDK 返回的 msgID + 服务器时间，更新本地临时图片消息
        if (res != null && res.code == 0 && res.data != null) {
          final sdkMsg = res.data!;
          final sdkMsgId = sdkMsg.msgID;
          final tsSeconds =
              sdkMsg.timestamp ?? (now.millisecondsSinceEpoch ~/ 1000);
          final sdkTime =
              DateTime.fromMillisecondsSinceEpoch(tsSeconds * 1000);

          if (sdkMsgId != null && sdkMsgId.isNotEmpty) {
            final index =
                messages.lastIndexWhere((m) => m.id == localId && m.isSent);
            if (index != -1) {
              final old = messages[index];
              messages[index] = ChatMessage(
                id: sdkMsgId,
                content: old.content,
                type: old.type,
                isSent: old.isSent,
                time: sdkTime,
                avatarUrl: old.avatarUrl,
                imageUrl: old.imageUrl,
                imageWidth: old.imageWidth,
                imageHeight: old.imageHeight,
                locationName: old.locationName,
                latitude: old.latitude,
                longitude: old.longitude,
                isRead: old.isRead,
                iconUrl: old.iconUrl,
                vipIcon: old.vipIcon,
                crapDuration: old.crapDuration,
                jumpPage: old.jumpPage,
              );
              messages.refresh();
            }
          }
        }
      }
    } catch (e) {
      logError('发送图片失败: $e');
      OKToastUtil.showError("发送图片失败");
      
    }
  }

  /// 将腾讯 IM 消息转换为 ChatMessage（仅处理当前会话、文字、图片、自定义等）
  ChatMessage? _convertIMMessageToChatMessage(
    V2TimMessage msg, {
    required String? currentUserId,
    required String? partnerId,
  }) {
    // 只处理单聊
    if ((msg.groupID ?? '').isNotEmpty) return null;

    final sender = msg.sender;
    final peerId = msg.userID;
    final isSelf = sender == currentUserId;

    // 只处理当前聊天对象的消息
    if (partnerId != null && partnerId.isNotEmpty) {
      final isFromPartner = sender == partnerId;
      final isToPartner = peerId == partnerId;
      if (!(isFromPartner || (isSelf && isToPartner))) {
        return null;
      }
    }

    // 时间
    final msgTimeSeconds =
        msg.timestamp ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final msgTime =
        DateTime.fromMillisecondsSinceEpoch(msgTimeSeconds * 1000);

    // 自定义消息处理
    if (msg.customElem?.data != null && msg.customElem!.data!.isNotEmpty) {
      try {
        final raw = msg.customElem!.data!;
        final dynamic decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          // 处理敏感事件（sensitive）——可能是文本或位置通知，支持 im_font_color 和 default_ext
          final String? msgType = decoded['msg_type'] as String?;
          if (msgType == 'sensitive') {
            final String messageType = (decoded['message_type'] as String?) ?? 'text';

            // 通用字段
            final String content =
                (decoded['content'] as String?)?.trim().isNotEmpty == true
                    ? (decoded['content'] as String?)!
                    : '系统通知';
            final String? icon = decoded['icon'] as String?;
            final String? jumpPage = decoded['jump_page'] as String?;

            // 解析 im_font_color（可选）
            List<FontColorItem>? fontItems;
            try {
              final rawFont = decoded['im_font_color'];
              if (rawFont is List && rawFont.isNotEmpty) {
                fontItems = rawFont.map<FontColorItem?>((e) {
                  try {
                    if (e is Map) {
                      final changeText = (e['change_text'] as String?) ?? '';
                      final colorHex = (e['color'] as String?) ?? '#4E90FF';
                      if (changeText.isEmpty) return null;
                      return FontColorItem(changeText: changeText, colorHex: colorHex);
                    }
                  } catch (_) {}
                  return null;
                }).whereType<FontColorItem>().toList();
                if (fontItems.isEmpty) fontItems = null;
              }
            } catch (_) {
              fontItems = null;
            }
            // 解析 is_vip（可选）
            int? isVip;
            try {
              final rawVip = decoded['is_vip'];
              if (rawVip != null) {
                if (rawVip is int) {
                  isVip = rawVip;
                } else {
                  isVip = int.tryParse(rawVip.toString());
                }
              }
            } catch (_) {
              isVip = null;
            }

            // 解析 im_vip_content（VIP用户显示的内容）
            String? imVipContent;
            try {
              imVipContent = decoded['im_vip_content'] as String?;
            } catch (_) {
              imVipContent = null;
            }

            // 解析 vip_icon（VIP用户显示的图标）
            String? vipIcon;
            try {
              vipIcon = decoded['vip_icon'] as String?;
            } catch (_) {
              vipIcon = null;
            }

            // 如果服务端把敏感事件标记为位置类型，则构建居中的位置通知（不走气泡）
            if (messageType == 'location') {
              final Map<String, dynamic>? ext =
                  (decoded['default_ext'] is Map) ? Map<String, dynamic>.from(decoded['default_ext']) : null;
              double? lat;
              double? lng;
              String? locName;
              if (ext != null) {
                lat = double.tryParse((ext['latitude'] ?? ext['lat'] ?? '').toString());
                lng = double.tryParse((ext['longitude'] ?? ext['lon'] ?? ext['lng'] ?? '').toString());
                locName = (ext['location_name'] as String?) ?? (ext['location'] as String?) ?? ext['location_name']?.toString();
              }

              return ChatMessage(
                id: msg.msgID ?? DateTime.now().millisecondsSinceEpoch.toString(),
                content: content,
                type: MessageType.locationNotice,
                isSent: isSelf,
                time: msgTime,
                avatarUrl: null,
                locationName: locName,
                latitude: lat,
                longitude: lng,
                iconUrl: icon,
                jumpPage: (jumpPage != null && jumpPage.isNotEmpty) ? jumpPage : null,
                defaultExt: ext,
              );
            }

            // 否则按文本型敏感事件处理（保留原有 systemEvent 展示，但支持富文本替换）
            return ChatMessage(
              id: msg.msgID ?? DateTime.now().millisecondsSinceEpoch.toString(),
              content: content,
              type: MessageType.systemEvent,
              isSent: isSelf, // systemEvent 显示居中，不区分左右
              time: msgTime,
              avatarUrl: null,
              iconUrl: icon,
              vipIcon: vipIcon, // VIP用户显示的图标
              jumpPage: (jumpPage != null && jumpPage.isNotEmpty) ? jumpPage : null,
              imFontColor: fontItems,
              isVip: isVip,
              imVipContent: imVipContent,
            );
          }

          // 处理一起便便消息（msg_bubble: "defecate" 或 "endDefecate"）
          final String? msgBubble = decoded['msg_bubble'] as String?;
          if (msgBubble == 'defecate') {
            return ChatMessage(
              id: msg.msgID ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              content: '亲爱的，我们开始拉屎吧～',
              type: MessageType.defecate,
              isSent: isSelf,
              time: msgTime,
              avatarUrl: isSelf ? UserManager.userAvatar : avatarUrl.value,
            );
          }
          // 处理结束拉屎消息（msg_bubble: "endDefecate"）
          if (msgBubble == 'endDefecate') {
            final String? duration = decoded['crap_duration'] as String?;
            return ChatMessage(
              id: msg.msgID ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              content: '亲爱的，我结束拉屎啦，共拉了${duration ?? ''}',
              type: MessageType.defecate,
              isSent: isSelf,
              time: msgTime,
              avatarUrl: isSelf ? UserManager.userAvatar : avatarUrl.value,
              crapDuration: duration,
            );
          }
        }
      } catch (_) {
        // 自定义消息解析异常时忽略，继续按其他类型处理
      }
    }

    // 文本消息
    if (msg.textElem?.text != null && msg.textElem!.text!.isNotEmpty) {
      final text = msg.textElem!.text!;

      return ChatMessage(
        id: msg.msgID ?? DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        type: MessageType.text,
        isSent: isSelf,
        time: msgTime,
        avatarUrl: isSelf ? UserManager.userAvatar : avatarUrl.value,
      );
    }

    // 图片消息
    if (msg.imageElem != null) {
      // 尝试优先使用大图/原图/缩略图中的 URL，其次使用本地路径
      String? imageUrl;
      double? imageWidth;
      double? imageHeight;
      if (msg.imageElem!.imageList != null &&
          msg.imageElem!.imageList!.isNotEmpty) {
        // 这里简单取第一张（通常是缩略图），具体可以按类型筛选
        final first = msg.imageElem!.imageList!.first;
        imageUrl = first?.url ?? first?.localUrl;
        // 腾讯 IM 的 V2TimImage 一般会带宽高信息，这里用于前端展示比例
        try {
          if (first != null) {
            final w = first.width;
            final h = first.height;
            if (w != null && h != null && w > 0 && h > 0) {
              imageWidth = w.toDouble();
              imageHeight = h.toDouble();
            }
          }
        } catch (_) {
          // 忽略宽高解析异常，走默认展示比例
        }
      }
      imageUrl ??= msg.imageElem!.path;

      return ChatMessage(
        id: msg.msgID ?? DateTime.now().millisecondsSinceEpoch.toString(),
        content: '[图片]',
        type: MessageType.image,
        isSent: isSelf,
        time: msgTime,
        avatarUrl: isSelf ? UserManager.userAvatar : avatarUrl.value,
        imageUrl: imageUrl,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        isRead: msg.isRead ?? false,
      );
    }

    // 其他类型暂不处理
    return null;
  }

  // // 选择并发送位置 - 打开位置选择页面
  // Future<void> _pickAndSendLocation() async {
  //   try {
  //     // 直接从全局定位服务获取当前位置
  //     final locationService = SimpleLocationService.instance;
  //     final currentLoc = locationService.currentLocation.value;

  //     if (currentLoc == null) {
  //       Get.snackbar(
  //         '提示',
  //         '正在获取位置信息，请稍后再试',
  //         snackPosition: SnackPosition.BOTTOM,
  //         backgroundColor: Colors.orange,
  //         colorText: Colors.white,
  //         margin: const EdgeInsets.all(16),
  //       );
  //       return;
  //     }

  //     // 打开位置选择页面
  //     final selectedLocation = await Get.to<LocationInfo>(
  //       () => LocationPickerPage(
  //         initialLatitude: double.tryParse(currentLoc.latitude),
  //         initialLongitude: double.tryParse(currentLoc.longitude),
  //         initialLocationName: currentLoc.locationName.isNotEmpty 
  //             ? currentLoc.locationName 
  //             : '当前位置',
  //         avatarUrl: null, // 可以传入对方的头像
  //       ),
  //       transition: Transition.downToUp,
  //     );

  //     if (selectedLocation == null) return;

  //     // 发送位置消息
  //     final message = ChatMessage(
  //       id: DateTime.now().millisecondsSinceEpoch.toString(),
  //       content: selectedLocation.name,
  //       type: MessageType.location,
  //       isSent: true,
  //       time: DateTime.now(),
  //       // 使用当前用户头像
  //       avatarUrl: UserManager.userAvatar,
  //       locationName: selectedLocation.name,
  //       latitude: selectedLocation.latitude,
  //       longitude: selectedLocation.longitude,
  //     );

  //     messages.add(message);
  //     _scrollToBottom();

  //     logDebug('💬 发送位置: ${message.locationName} (${message.latitude}, ${message.longitude})');
  //     // TODO: 发送位置到服务器
  //   } catch (e) {
  //     logError('发送位置失败: $e');
  //     OKToastUtil.showError("发送位置失败");
       
  //   }
  // }

  // 处理更多菜单点击
  void handleMoreMenuAction(MoreMenuType type) {
    logDebug('💬 更多菜单: ${type.name}');

    switch (type) {
      case MoreMenuType.editRemark:
        _showEditRemarkDialog();
        break;
      case MoreMenuType.changeBackground:
        _showChangeBackgroundDialog();
        break;
    }
  }

  // 修改备注对话框
  void _showEditRemarkDialog() {
    final TextEditingController controller = TextEditingController(text: chatName.value);

    Get.dialog(
      AlertDialog(
        title: const Text('修改备注'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入备注名',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                chatName.value = newName;
              }
              Get.back();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 更换背景 - 直接调起相册
  void _showChangeBackgroundDialog() async {
    // 直接从相册选择背景图
    _pickBackgroundFromGallery();
  }

  // 从相册选择背景
  Future<void> _pickBackgroundFromGallery() async {
    final imageFile = await MediaPickerUtil.pickImageFromGallery(
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (imageFile != null) {
      // 使用本地图片路径作为背景
      backgroundImage.value = imageFile.path;
      OKToastUtil.showSuccess("背景已更换");
      // Get.snackbar(
      //   '成功',
      //   '背景已更换',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: const Color(0xffBA92FD),
      //   colorText: Colors.white,
      //   margin: const EdgeInsets.all(16),
      //   duration: const Duration(seconds: 1),
      // );
      
      logDebug('💬 更换聊天背景: ${imageFile.path}');
      // TODO: 上传背景图到服务器，保存用户偏好设置
    }
  }


  // 滚动到底部（公共方法）
  void scrollToBottom() {
    // 清除新消息提示
    hasNewMessageWhenNotAtBottom.value = false;
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients && messages.isNotEmpty) {
        // reverse:true时，滚动到0就是底部
        scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 滚动到底部（私有方法，内部使用）
  void _scrollToBottom() {
    scrollToBottom();
  }

  // 延迟滚动到底部（用于面板展开时）
  void _scrollToBottomWithDelay() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients && messages.isNotEmpty) {
        // reverse:true时，滚动到0就是底部
        scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 初始化时滚动到底部（如果消息超过一屏）
  void scrollToBottomOnInit() {
    // 如果已经执行过，则不再执行
    if (_hasScrolledOnInit) {
      return;
    }
    _hasScrolledOnInit = true;
    
    // 等待页面完全构建完成后再滚动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 再次延迟，确保ListView已经完全渲染
      Future.delayed(const Duration(milliseconds: 200), () {
        if (scrollController.hasClients && messages.isNotEmpty) {
          // reverse:true时，滚动到0就是底部
          scrollController.jumpTo(0.0);
          logDebug('💬 初始化时自动定位到底部');
        }
      });
    });
  }
}
