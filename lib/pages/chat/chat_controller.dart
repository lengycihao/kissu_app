import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/utils/sp_util.dart';
import 'package:kissu_app/pages/chat/widgets/chat_message_item.dart';
import 'package:kissu_app/pages/chat/widgets/chat_more_menu.dart';
import 'package:kissu_app/pages/chat/widgets/location_picker_page.dart';
import 'package:kissu_app/services/simple_location_service.dart';
import 'package:kissu_app/utils/media_picker_util.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/tencent_im_service.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_receipt.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_elem_type.dart';

class ChatController extends GetxController {
  // 滚动控制器
  final ScrollController scrollController = ScrollController();
  
  // 输入框焦点控制器
  final FocusNode inputFocusNode = FocusNode();

  // 面板显示状态
  final RxBool showEmojiPanel = false.obs;

  // 聊天消息列表
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;

  // 聊天背景图片路径
  final RxString backgroundImage = ''.obs;

  // 聊天气泡样式（1-4）
  final RxInt bubbleStyle = 1.obs;

  // 聊天主题（1-4，默认1）
  final RxInt chatTheme = 1.obs;

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

  // 历史消息分页相关
  String? _lastHistoryMsgId; // 最近一次拉取结果中最旧消息的ID
  bool _isLoadingHistory = false;
  bool _hasMoreHistory = true;

  @override
  void onInit() {
    super.onInit();
    debugPrint('💬 ChatController 初始化');
    // 使用真实IM聊天，关闭本地mock消息
    _initPartnerInfo();
    _setupIMMessageListener();
    _setupIMReadReceiptListener();
    _setupIMRevokeListener();
    _setupScrollForHistory();
    _loadInitialHistoryMessages();
    _setupFocusListener();
    _loadBackgroundFromCache();
    _loadBubbleStyleFromCache();
    _loadThemeFromCache();
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
      debugPrint('💬 初始化聊天对象: imId=$_partnerImId, name=${chatName.value}');
    } else {
      debugPrint('💬 未找到halfUserInfo，暂无法确定聊天对象IM ID');
    }
  }

  /// 绑定滚动监听，用于上拉加载更多历史消息
  void _setupScrollForHistory() {
    scrollController.addListener(() {
      // 滚动到列表顶部附近，尝试加载更多历史
      if (scrollController.positions.isNotEmpty &&
          scrollController.position.pixels <= 50 &&
          !_isLoadingHistory &&
          _hasMoreHistory) {
        _loadMoreHistoryMessages();
      }
    });
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
      debugPrint('💬 无法拉取历史消息：未找到另一半IM ID');
      return;
    }
    if (!im.isInitialized || !im.isLoggedIn) {
      debugPrint('💬 IM未初始化或未登录，无法拉取历史消息');
      return;
    }
    if (_isLoadingHistory || !_hasMoreHistory) {
      return;
    }

    _isLoadingHistory = true;

    try {
      final res = await im.getC2CHistoryMessages(
        userID: partnerId,
        count: 20,
        lastMsgID: _lastHistoryMsgId,
      );

      if (res == null || res.code != 0 || res.data == null) {
        debugPrint('💬 拉取历史消息失败: code=${res?.code}, desc=${res?.desc}');
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
        messages.refresh();

        // 记录当前拉取到的最旧一条消息ID，作为下一次分页的起点
        _lastHistoryMsgId = historyList.last.msgID;

        if (initialLoad) {
          // 首次加载后滚动到底部，显示最新消息
          _scrollToBottomWithDelay();
        }
      } else {
        // 说明已经没有更旧的消息
        _hasMoreHistory = false;
      }
    } catch (e) {
      debugPrint('💬 拉取历史消息异常: $e');
    } finally {
      _isLoadingHistory = false;
    }
  }

  // 从缓存加载背景
  Future<void> _loadBackgroundFromCache() async {
    final savedBackground = await SpUtil.getString('chat_background_path');
    if (savedBackground.isNotEmpty) {
      backgroundImage.value = savedBackground;
      debugPrint('💬 加载缓存的聊天背景: $savedBackground');
    }
  }

  // 从缓存加载气泡样式
  Future<void> _loadBubbleStyleFromCache() async {
    final savedStyle = await SpUtil.getInteger('chat_bubble_style', 1);
    if (savedStyle > 0 && savedStyle <= 4) {
      bubbleStyle.value = savedStyle;
      debugPrint('💬 加载缓存的气泡样式: $savedStyle');
    } else {
      // 如果缓存中没有或值无效，使用默认样式1
      bubbleStyle.value = 1;
      // 同时保存默认值到缓存
      await SpUtil.putInteger('chat_bubble_style', 1);
      debugPrint('💬 使用默认气泡样式: 1');
    }
  }

  // 从缓存加载主题
  Future<void> _loadThemeFromCache() async {
    final savedTheme = await SpUtil.getInteger('chat_theme', 1);
    if (savedTheme > 0 && savedTheme <= 4) {
      chatTheme.value = savedTheme;
      debugPrint('💬 加载缓存的主题: $savedTheme');
    } else {
      chatTheme.value = 1;
      await SpUtil.putInteger('chat_theme', 1);
      debugPrint('💬 使用默认主题: 1');
    }
  }

  // 更新气泡样式（由 ChatBubbleController 调用）
  void updateBubbleStyle(int style) {
    if (style >= 1 && style <= 4) {
      bubbleStyle.value = style;
      // 持久化到本地，确保返回聊天页后重新加载依然生效
      SpUtil.putInteger('chat_bubble_style', style);
      // 刷新消息列表以触发气泡重建
      messages.refresh();
      debugPrint('💬 更新并保存气泡样式: $style');
    }
  }

  // 更新主题（由 ChatThemeController 调用）
  void updateTheme(int theme) {
    if (theme >= 1 && theme <= 4) {
      chatTheme.value = theme;
      debugPrint('💬 更新主题: $theme');
    }
  }

  // 获取主题对应的按钮颜色
  Color getThemeButtonColor() {
    switch (chatTheme.value) {
      case 1:
      case 2:
        return const Color(0xffFF90CA);
      case 3:
        return const Color(0xffA6D7FF);
      case 4:
        return const Color(0xffAD7D63);
      default:
        return const Color(0xffFF90CA);
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    inputFocusNode.dispose();
    _deviceInfoTooltipTimer?.cancel();
    debugPrint('💬 ChatController 销毁');
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
        debugPrint('💬 键盘抬起，关闭所有面板');
        // 键盘抬起时，延迟滚动到底部
        _scrollToBottomWithDelay();
      }
    });
  }

  // 加载模拟消息
  void _loadMockMessages() {
    final now = DateTime.now();
    // 创建一个相同的时间点，用于测试时间戳去重
    final sameTime = now.subtract(const Duration(hours: 2, minutes: 21));
    messages.addAll([
      // 系统事件消息 - 对方更换手机进行了登录（显示时间戳）
      ChatMessage(
        id: 'event_1',
        content: '对方更换手机进行了登录 (iPhone 15 Pro Max)',
        type: MessageType.systemEvent,
        isSent: false, // systemEvent类型isSent不影响显示
        time: sameTime,
        iconUrl: 'assets/phone_history/kissu_phone_type.webp', // 使用手机型号图标作为占位
      ),
      // 系统事件消息 - 对方退出账号（不显示时间戳，因为时间相同）
      ChatMessage(
        id: 'event_2',
        content: '对方退出账号',
        type: MessageType.systemEvent,
        isSent: false,
        time: sameTime.add(const Duration(seconds: 10)),
        iconUrl: 'assets/phone_history/kissu_phone_barry.webp', // 使用占位图标
      ),
      // 系统事件消息 - 对方登录了Kissu（不显示时间戳，因为时间相同）
      ChatMessage(
        id: 'event_3',
        content: '对方登录了Kissu',
        type: MessageType.systemEvent,
        isSent: false,
        time: sameTime.add(const Duration(seconds: 20)),
        iconUrl: 'assets/3.0/kissu3_love_avater.webp', // 使用Kissu图标
      ),
      // 系统事件消息 - 对方打开了Kissu（不显示时间戳，因为时间相同）
      ChatMessage(
        id: 'event_4',
        content: '对方打开了Kissu',
        type: MessageType.systemEvent,
        isSent: false,
        time: sameTime.add(const Duration(seconds: 30)),
        iconUrl: 'assets/3.0/kissu3_love_avater.webp',
      ),
      // 系统事件消息 - 对方开启了定位（不显示时间戳，因为时间相同）
      ChatMessage(
        id: 'event_5',
        content: '对方开启了定位',
        type: MessageType.systemEvent,
        isSent: false,
        time: sameTime.add(const Duration(seconds: 40)),
        iconUrl: 'assets/phone_history/kissu_phone_distance.webp', // 使用定位相关图标
      ),
      // 系统事件消息 - 对方关闭了定位（不显示时间戳，因为时间相同）
      ChatMessage(
        id: 'event_6',
        content: '对方关闭了定位',
        type: MessageType.systemEvent,
        isSent: false,
        time: sameTime.add(const Duration(seconds: 50)),
        iconUrl: 'assets/phone_history/kissu_phone_distance.webp',
      ),
      // 系统事件消息 - 对方更换了网络（显示时间戳，因为时间不同）
      ChatMessage(
        id: 'event_7',
        content: '对方更换了网络 (yuiuo-5G)',
        type: MessageType.systemEvent,
        isSent: false,
        time: now.subtract(const Duration(hours: 2, minutes: 20)),
        iconUrl: 'assets/phone_history/kissu_phone_wifi.webp',
      ),
      // 系统事件消息 - 对方切换成了移动网络（不显示时间戳，因为时间相同）
      ChatMessage(
        id: 'event_8',
        content: '对方切换成了移动网络',
        type: MessageType.systemEvent,
        isSent: false,
        time: now.subtract(const Duration(hours: 2, minutes: 20, seconds: 10)),
        iconUrl: 'assets/phone_history/kissu_phone_wifi.webp',
      ),
      // 系统事件消息 - 对方手机正在充电（显示时间戳，因为时间不同）
      ChatMessage(
        id: 'event_9',
        content: '对方手机正在充电,当前电量32%',
        type: MessageType.systemEvent,
        isSent: false,
        time: now.subtract(const Duration(hours: 2, minutes: 19)),
        iconUrl: 'assets/phone_history/kissu_phone_barry.webp',
      ),
      // 系统事件消息 - 对方手机结束了充电（显示时间戳，因为时间不同）
      ChatMessage(
        id: 'event_10',
        content: '对方手机结束了充电,当前电量89%',
        type: MessageType.systemEvent,
        isSent: false,
        time: now.subtract(const Duration(hours: 2, minutes: 18)),
        iconUrl: 'assets/phone_history/kissu_phone_barry.webp',
      ),
      // 普通消息
      ChatMessage(
        id: '1',
        content: '你好！',
        type: MessageType.text,
        isSent: false,
        time: now.subtract(const Duration(minutes: 5)),
        avatarUrl: null,
      ),
      ChatMessage(
        id: '2',
        content: '嗨，在干嘛呢？',
        type: MessageType.text,
        isSent: true,
        time: now.subtract(const Duration(minutes: 4)),
        avatarUrl: null,
        isRead: true, // 已读
      ),
      ChatMessage(
        id: '3',
        content: '刚吃完饭，准备出去散步',
        type: MessageType.text,
        isSent: false,
        time: now.subtract(const Duration(minutes: 3)),
        avatarUrl: null,
      ),
    ]);
  }

  // 发送文字消息（走腾讯IM SDK）
  void sendTextMessage(String text) {
    if (text.trim().isEmpty) return;

    final localId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    final message = ChatMessage(
      id: localId,
      content: text,
      type: MessageType.text,
      isSent: true,
      time: now,
      avatarUrl: null,
    );

    // 添加消息到列表
    messages.add(message);
    
    // 强制刷新UI（确保 RxList 触发更新）
    messages.refresh();
    
    // 延迟滚动到底部，确保UI更新完成
    Future.microtask(() => _scrollToBottom());

    // 隐藏面板
    hideAllPanels();

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
      debugPrint('💬 未找到另一半IM ID，暂时只本地显示消息: $text');
      return;
    }

    final im = TencentIMService.instance;
    if (!im.isInitialized || !im.isLoggedIn) {
      debugPrint('💬 IM未初始化或未登录，暂时只本地显示消息: $text');
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
            locationName: old.locationName,
            latitude: old.latitude,
            longitude: old.longitude,
            isRead: old.isRead,
            iconUrl: old.iconUrl,
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
          // 对方“正在输入”在线消息：只更新顶部提示，不进消息列表
          if (msg.elemType == MessageElemType.V2TIM_ELEM_TYPE_CUSTOM &&
              msg.customElem?.data == 'typing') {
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
            messages.refresh();
            _scrollToBottomWithDelay();

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
      debugPrint('💬 设置IM消息监听失败: $e');
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

            // SDK C2C 场景下通常只给 userID + timestamp，不给具体 msgID。
            // 为避免本地时间与服务器时间偏差导致“最新一条不变已读”，
            // 这里对当前会话中所有自己发送且尚未标记已读的消息，统一标记为已读。
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
                locationName: m.locationName,
                latitude: m.latitude,
                longitude: m.longitude,
                isRead: true,
                iconUrl: m.iconUrl,
              );
              updated = true;
            }
          }

          if (updated) {
            messages.refresh();
          }
        },
      );
    } catch (e) {
      debugPrint('💬 设置IM已读回执监听失败: $e');
    }
  }

  /// 监听消息被撤回事件，在本地更新对应气泡为“已撤回”提示
  void _setupIMRevokeListener() {
    try {
      final im = TencentIMService.instance;
      im.setOnRecvMessageRevoked((String msgID) {
        if (msgID.isEmpty) return;

        final index = messages.indexWhere((m) => m.id == msgID);
        if (index == -1) return;

        final old = messages[index];
        final bool isSelf = old.isSent;

        // 将原消息替换为一条 systemEvent 文本提示
        messages[index] = ChatMessage(
          id: old.id,
          content: isSelf ? '你撤回了一条消息' : '对方撤回了一条消息',
          type: MessageType.systemEvent,
          isSent: false, // systemEvent 不区分左右
          time: old.time,
          avatarUrl: null,
          imageUrl: null,
          locationName: null,
          latitude: null,
          longitude: null,
          isRead: true,
          iconUrl: null,
        );
        messages.refresh();
      });
    } catch (e) {
      debugPrint('💬 设置IM撤回监听失败: $e');
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
      debugPrint('💬 表情面板展开，收起键盘');
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
      final partnerId = _partnerImId;
      final im = TencentIMService.instance;

      if (partnerId == null || partnerId.isEmpty) {
        debugPrint('💬 未找到另一半IM ID，暂时本地显示图片: ${imageFile.path}');
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
        avatarUrl: null,
        imageUrl: imageFile.path,
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
        debugPrint('💬 发送图片消息到IM: ${imageFile.path}');

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
                locationName: old.locationName,
                latitude: old.latitude,
                longitude: old.longitude,
                isRead: old.isRead,
                iconUrl: old.iconUrl,
              );
              messages.refresh();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('发送图片失败: $e');
      Get.snackbar(
        '错误',
        '发送图片失败',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  /// 将腾讯 IM 消息转换为 ChatMessage（仅处理当前会话、文字和图片）
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
      if (msg.imageElem!.imageList != null &&
          msg.imageElem!.imageList!.isNotEmpty) {
        // 这里简单取第一张（通常是缩略图），具体可以按类型筛选
        final first = msg.imageElem!.imageList!.first;
        imageUrl = first?.url ?? first?.localUrl;
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
        isRead: msg.isRead ?? false,
      );
    }

    // 其他类型暂不处理
    return null;
  }

  // 选择并发送位置 - 打开位置选择页面
  Future<void> _pickAndSendLocation() async {
    try {
      // 直接从全局定位服务获取当前位置
      final locationService = SimpleLocationService.instance;
      final currentLoc = locationService.currentLocation.value;

      if (currentLoc == null) {
        Get.snackbar(
          '提示',
          '正在获取位置信息，请稍后再试',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        return;
      }

      // 打开位置选择页面
      final selectedLocation = await Get.to<LocationInfo>(
        () => LocationPickerPage(
          initialLatitude: double.tryParse(currentLoc.latitude),
          initialLongitude: double.tryParse(currentLoc.longitude),
          initialLocationName: currentLoc.locationName.isNotEmpty 
              ? currentLoc.locationName 
              : '当前位置',
          avatarUrl: null, // 可以传入对方的头像
        ),
        transition: Transition.downToUp,
      );

      if (selectedLocation == null) return;

      // 发送位置消息
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: selectedLocation.name,
        type: MessageType.location,
        isSent: true,
        time: DateTime.now(),
        avatarUrl: null,
        locationName: selectedLocation.name,
        latitude: selectedLocation.latitude,
        longitude: selectedLocation.longitude,
      );

      messages.add(message);
      _scrollToBottom();

      debugPrint('💬 发送位置: ${message.locationName} (${message.latitude}, ${message.longitude})');
      // TODO: 发送位置到服务器
    } catch (e) {
      debugPrint('发送位置失败: $e');
      Get.snackbar(
        '错误',
        '发送位置失败',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // 处理更多菜单点击
  void handleMoreMenuAction(MoreMenuType type) {
    debugPrint('💬 更多菜单: ${type.name}');

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
      Get.snackbar(
        '成功',
        '背景已更换',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xffBA92FD),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 1),
      );
      
      debugPrint('💬 更换聊天背景: ${imageFile.path}');
      // TODO: 上传背景图到服务器，保存用户偏好设置
    }
  }


  // 滚动到底部（公共方法）
  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0.0, // reverse:true 时，offset 0 代表列表“底部”（最新消息）
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
      if (scrollController.hasClients) {
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
        if (scrollController.hasClients) {
          // reverse:true 时，offset 0.0 即为“底部”（最新一条）
          scrollController.jumpTo(0.0);
          debugPrint('💬 初始化时自动定位到最新一条消息');
        }
      });
    });
  }
}
