import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/chat/chat_controller.dart';
import 'package:kissu_app/pages/chat/widgets/chat_input_bar.dart';
import 'package:kissu_app/pages/chat/widgets/chat_emoji_panel.dart';
import 'package:kissu_app/pages/chat/widgets/chat_device_info_bar.dart';
import 'package:kissu_app/pages/chat/widgets/chat_message_list_view.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/widgets/dialogs/lock_screen_vip_dialog.dart';
import 'package:kissu_app/utils/source_page_utils.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  // 输入框的 GlobalKey，用于访问输入框的 state
  final GlobalKey<ChatInputBarState> _inputBarKey = GlobalKey<ChatInputBarState>();
  
  ChatController get controller => Get.find<ChatController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App进入后台
        controller.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        // App从后台恢复
        controller.onAppResumed();
        controller.refreshLatestMessages();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取键盘高度
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // 改为 false，我们手动处理键盘
      extendBodyBehindAppBar: true, // 让body延伸到AppBar后面
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // 背景层 - 覆盖整个屏幕包括导航栏区域
          Obx(() => controller.backgroundImage.value.isNotEmpty
              ? Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 80, // 底部留出约80像素，让背景稍微延伸到输入框下方，圆角区域能看到背景
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: _getBackgroundImageProvider(controller.backgroundImage.value),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink()),
          
          // 主体内容区域
          Column(
            children: [
              // 消息列表（用Stack包裹，以便悬浮tip）
              Expanded(
                child: SafeArea(
                  bottom: false, // 底部不使用SafeArea，因为我们有输入栏
                  child: Stack(
                    clipBehavior: Clip.none, // 允许tip超出边界，不影响布局
                    children: [
                      // 消息列表（固定，不受tip影响）
                      ChatMessageListView(controller: controller),
                      // 悬浮的新消息提示tip（完全悬浮，不影响布局）
                      Positioned(
                        bottom: 5,
                        left: 0,
                        right: 0,
                        child: Obx(() => controller.hasNewMessageWhenNotAtBottom.value
                            ? _buildNewMessageTip(controller)
                            : const SizedBox.shrink()),
                      ),
                    ],
                  ),
                ),
              ),

              // 🔥 一键锁机 + 你说我猜按钮
              Row(
                children: [
                  _buildLockButton(),
                  _buildSayGuessButton(),
                ],
              ),

              // 输入栏
              Obx(() => ChatInputBar(
                    key: _inputBarKey,
                    onSendText: controller.sendTextMessage,
                    onTyping: controller.notifyTyping,
                    onEmojiTap: controller.toggleEmojiPanel,
                    onAlbumTap: controller.onAlbumTap,
                    onCameraTap: controller.onCameraTap,
                    onLocationTap: controller.onLocationTap,
                    showEmojiPanel: controller.showEmojiPanel.value,
                    focusNode: controller.inputFocusNode,
                    themeButtonColor: controller.getThemeButtonColor(),
                    themeIndex: controller.chatTheme.value,
                  )),

              // 表情面板
              Obx(() => controller.showEmojiPanel.value
                  ? ChatEmojiPanel(
                      onEmojiSelected: (emoji) {
                        // 点击表情时，插入到输入框而不是直接发送
                        _inputBarKey.currentState?.insertEmoji(emoji);
                      },
                      onDelete: () {
                        // 删除输入框中光标前的一个字符/表情
                        _inputBarKey.currentState?.deleteLastEmoji();
                      },
                    )
                  : const SizedBox.shrink()),
              
              // 键盘占位空间 - 关键！这会像面板一样占据空间
              Obx(() => SizedBox(
                height: controller.showEmojiPanel.value ? 0 : keyboardHeight,
              )),
            ],
          ),

        ],
      ),
    );
  }

  // 🔥 一键锁机按钮
  Widget _buildLockButton() {
    return Obx(() {
      final isLocked = controller.isPartnerLocked.value;
      return GestureDetector(
        onTap: () async {
          // 埋点1: 聊天页面一键锁机点击事件
          final lockStatus = UserManager.currentUser?.halfLockStatus ?? 0;
          AnalyticsHelper.trackChatLockPhoneClick(lockStatus: lockStatus);

          // 1. 未绑定：弹出绑定弹窗
          final isBound = UserManager.currentUser?.bindStatus?.toString() == "1";
          if (!isBound) {
            await CustomBottomDialog.show(
              context: context,
              caller: SourcePageUtilsCaller.chat,
              sourceEvent: ChatEvents.lockPhoneClick,
              isDismissible: false,
              enableDrag: false,
            );
            return;
          }
          // 2. 已绑定但非会员：弹出VIP弹窗
          if (!UserManager.isVip) {
            await LockScreenVipDialog.show(context, isFromChat: true);
            return;
          }
          // 3. 已绑定且是会员：进入一键锁机页面
          await Get.toNamed(KissuRoutePath.lockScreen);
          // 从锁机页面返回后刷新状态
          controller.refreshPartnerLockState();
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
           decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))
           ),
          
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
            decoration: BoxDecoration(
              color: Color(0xffF2F2F2),
              borderRadius: BorderRadius.circular(28)
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, 
              children: [
                // 锁机图标（带锁机中/new状态角标）
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(
                      'assets/lock/kissu_lock_icon.webp',
                      width: 16,
                      height: 16,
                    ),
                    if (isLocked)
                      Positioned(
                        top: -12,
                        left: 50,
                        child: Image.asset(
                          'assets/lock/kissu_locking.webp',
                          width: 40,
                          height: 15,
                        ),
                      )
                    // // else if (!controller.hasEnteredLockScreen.value)
                    // else 
                    //   Positioned(
                    //     top: -15,
                    //     left: 44,
                    //     child: Image.asset(
                    //       'assets/4.0/kissu_change_logo_new.webp',
                    //       width: 28,
                    //       height: 20,
                    //     ),
                    //   ),
                  ],
                ),
                const SizedBox(width: 4),
                // 一键锁机文字
                const Text(
                  '一键锁机',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF503F3F),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // 🔥 你说我猜按钮
  Widget _buildSayGuessButton() {
    return GestureDetector(
      onTap: () async {
        // 埋点1: 聊天页面你说我猜点击事件
        //  AnalyticsHelper.trackChatLockPhoneClick(lockStatus: lockStatus);

        // 1. 未绑定：弹出绑定弹窗
        final isBound = UserManager.currentUser?.bindStatus?.toString() == "1";
        if (!isBound) {
          await CustomBottomDialog.show(
            context: context,
            caller: SourcePageUtilsCaller.chat,
            sourceEvent: ChatEvents.lockPhoneClick, //warning: 这里需要替换成你说我猜的点击事件
            isDismissible: false,
            enableDrag: false,
          );
          return;
        }
        // 2. 已绑定：进入你说我猜页面
        await Get.toNamed(KissuRoutePath.guessGameV2Home);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 10, 16, 0),
         decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))
         ),
        
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
          decoration: BoxDecoration(
            color: Color(0xffF2F2F2),
            borderRadius: BorderRadius.circular(28)
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, 
            children: [
              // 锁机图标（带锁机中/new状态角标）
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    'assets/say_guess/kissu_chat_compent.webp',
                    width: 16,
                    height: 16,
                  ),
                 Positioned(
                      top: -15,
                      left:90,
                      child: Image.asset(
                        'assets/4.0/kissu_change_logo_new.webp',
                        width: 28,
                        height: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
               const Text(
                '你说我猜（竞技版）',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF503F3F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // 顶部导航栏
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return PreferredSize(
      preferredSize: Size.fromHeight(65 + statusBarHeight), // 增加导航栏高度以容纳设备信息
      child: Container(
        padding: EdgeInsets.only(top: statusBarHeight),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xffcccccc),
              Color(0x00ffffff),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // 第一行：返回按钮、头像、昵称、设置按钮 - 横向对齐
            SizedBox(
              height: 56, // AppBar的标准高度
              child: Stack(
                children: [
                  // 返回按钮
                  Positioned(
                    left: 5,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        // 埋点：返回按钮点击
                        AnalyticsHelper.trackChatBack();
                        Get.back();
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: Image.asset(
                          "assets/images/kissu_mine_back.webp",
                          width: 22,
                          height: 22,
                        ),
                      ),
                    ),
                  ),
                  // 另一半头像
                  Positioned(
                    left: 54, // 44(返回按钮宽度) + 10(间距)
                    top: 8,
                    bottom: 8,
                    child: Obx(() => Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                            image: controller.avatarUrl.value.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(controller.avatarUrl.value),
                                    fit: BoxFit.cover,
                                  )
                                : const DecorationImage(
                                    image: AssetImage('assets/3.0/kissu3_love_avater.webp'),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        )),
                  ),
                  // 昵称 / 正在输入（二选一，同一字体样式）
                  Positioned(
                    left: 104, // 54 + 40(头像宽度) + 10(间距)
                    right: 54, // 留出设置按钮的空间
                    top: 0,
                    bottom: 0,
                    child: Obx(() {
                      final typing = controller.isPartnerTyping.value;
                      final title = typing ? '对方正在输入…' : controller.chatName.value;
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xff333333),
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ),
                  // 设置按钮
                  Positioned(
                    right: 5,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        // 埋点：设置按钮点击
                        AnalyticsHelper.trackChatSetting();
                        
                        // 埋点：页面离开（进入下一页）
                        controller.onNavigateToNextPage?.call();
                        
                        Get.toNamed(KissuRoutePath.chatSettings);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: Image.asset('assets/chat/kissu_chat_setting.webp', width: 24, height: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 第二行：设备信息模块
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: ChatDeviceInfoBar(controller: controller),
            ),
          ],
        ),
      ),
    );
  }

  // 获取背景图片提供器（支持资产图片和文件图片）
  ImageProvider _getBackgroundImageProvider(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  // 构建新消息提示tip（悬浮在消息列表底部）
  Widget _buildNewMessageTip(ChatController controller) {
    return Center(
      child: GestureDetector(
        onTap: () {
          // 点击时滚动到底部
          controller.scrollToBottom();
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFF90CA) ,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Color(0xFFffffff)),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFF90CA).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
                  '有新消息',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
          ),
        ),
      ),
    );
  }

}

