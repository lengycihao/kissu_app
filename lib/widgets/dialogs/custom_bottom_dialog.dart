import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/source_page_utils.dart';
import 'transparent_banner_widget.dart';
import 'gradient_content_widget.dart';
import 'custom_bottom_dialog_controller.dart';
import 'binding_close_confirm_dialog.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

/// 自定义底部弹窗组件
class CustomBottomDialog extends StatefulWidget {
  final VoidCallback? onClose;
  final Widget? customContent;
  final List<String>? bannerImages;
  final double bannerHeight;
  final bool showBanner;
  final Future<bool> Function()? onCloseConfirm; // 关闭确认回调，返回true表示允许关闭
  final SourcePageUtilsCaller? caller; // 调用者页面类型（用于判断是否上报埋点）

  const CustomBottomDialog({
    Key? key,
    this.onClose,
    this.customContent,
    this.bannerImages,
    this.bannerHeight = 220,
    this.showBanner = true,
    this.onCloseConfirm,
    required this.caller,
  }) : super(key: key);

  @override
  State<CustomBottomDialog> createState() => _CustomBottomDialogState();

  /// 显示自定义底部弹窗
  static Future<T?> show<T>({
    required BuildContext context,
    VoidCallback? onClose,
    Widget? customContent,
    List<String>? bannerImages,
    double bannerHeight = 220,
    bool showBanner = true,
    bool isDismissible = false, // 全局禁止点击背景关闭
    bool enableDrag = false, // 全局禁止滑动关闭
    SourcePageUtilsCaller? caller, // 调用者页面类型
    Future<bool> Function()? onCloseConfirm, // 关闭确认回调
  }) {
    // 删除旧的控制器实例（如果存在）
    if (Get.isRegistered<CustomBottomDialogController>()) {
      Get.delete<CustomBottomDialogController>();
    }

    // 初始化新的控制器并设置调用者
    final controller = Get.put(CustomBottomDialogController());
    controller.caller = caller;

    // 使用默认轮播图图片（如果未提供）
    final defaultBannerImages = [
      'assets/3.0/kissu3_banner_1.webp',
      'assets/3.0/kissu3_banner_2.webp',
      'assets/3.0/kissu3_banner_3.webp',
      'assets/3.0/kissu3_banner_4.webp',
    ];

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomBottomDialog(
        onClose: onClose,
        customContent: customContent,
        bannerImages: bannerImages ?? defaultBannerImages,
        bannerHeight: bannerHeight,
        showBanner: showBanner,
        onCloseConfirm: onCloseConfirm,
        caller: caller, // 传递调用者页面类型
      ),
    ).then((result) {
      // 延迟删除控制器，确保所有 UI 重建完成
      Future.delayed(const Duration(milliseconds: 100), () {
        if (Get.isRegistered<CustomBottomDialogController>()) {
          Get.delete<CustomBottomDialogController>();
        }
      });
      return result;
    });
  }
}

class _CustomBottomDialogState extends State<CustomBottomDialog> with WidgetsBindingObserver {
  CustomBottomDialogController get controller => Get.find<CustomBottomDialogController>();

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
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 主要内容
        _buildMainContent(context),
        
        // 监听关闭标志（使用Obx）
        _buildCloseListener(context),
      ],
    );
  }
  
  /// 监听关闭标志
  Widget _buildCloseListener(BuildContext context) {
    if (!Get.isRegistered<CustomBottomDialogController>()) {
      return const SizedBox.shrink();
    }
    
    return Obx(() {
      // 检查是否应该关闭
      if (controller.shouldClose.value) {
        // 延迟一帧执行，确保在build完成后再关闭
        WidgetsBinding.instance.addPostFrameCallback((_) {
          logDebug('💬 检测到shouldClose标志，准备关闭绑定弹窗');
          if (Navigator.of(context).canPop()) {
             // 调用onClose回调（如果存在）
            if (widget.onClose != null) {
              widget.onClose!();
            }
            // 重置关闭标志
            controller.shouldClose.value = false;
            // 关闭弹窗
            Navigator.of(context).pop();
            logDebug('✅ 绑定弹窗已自动关闭（通过Navigator）');
          }
        });
      }
      return const SizedBox.shrink();
    });
  }
  
  /// 构建主要内容
  Widget _buildMainContent(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          // 透明Banner区域 - 透过可以看到首页内容
          // 40px是轮播图和下方内容的间距
          if (widget.showBanner && widget.bannerImages != null && widget.bannerImages!.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).size.height - 356 - widget.bannerHeight - 40,
              left: 0,
              right: 0,
              height: widget.bannerHeight,
              child: TransparentBannerWidget(
                imagePaths: widget.bannerImages!,
                height: widget.bannerHeight,
              ),
            ),

          // 渐变背景的内容区域 - 在Banner下方
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 356, // 固定内容区域高度
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
               ),
              child: Stack(
                children: [
                  // 主要内容区域
                  GradientContentWidget(
                    padding: const EdgeInsets.all(20).copyWith(top: 15),
                    child: widget.customContent ?? _buildDefaultContent(),
                  ),

                  // 关闭按钮 - 使用Positioned定位
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        // 埋点：关闭按钮事件
                        controller.trackBindCancel();
                        
                        // 统一弹出挽回弹窗
                        final result = await BindingCloseConfirmDialog.show(
                          context: context,
                          barrierDismissible: true,
                          isFromHomePage:
                              widget.caller == SourcePageUtilsCaller.home, // 只有首页才上报埋点
                          onCancel: () {
                            // 点击"再想想"，关闭绑定弹窗
                            debugPrint('💬 用户点击"再想想"，关闭绑定弹窗');
                          },
                          onConfirm: () {
                            // 点击"立即绑定"，保持绑定弹窗显示
                            debugPrint('💬 用户点击"立即绑定"，保持绑定弹窗显示');
                          },
                        );

                        // result 为 true 表示点击了"再想想"，应该关闭绑定弹窗
                        if (result == true) {
                          if (widget.onClose != null) {
                            widget.onClose!();
                          }
                          Get.back();
                        }
                        // result 为 false 或 null 表示不关闭绑定弹窗
                      },
                      child: Container(width: 32, height: 32,
                      padding: EdgeInsets.all(8),
                      child: Image.asset(
                        "assets/3.0/kissu3_close.webp",
                        width: 16,
                        height: 16,
                      ),),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 默认内容
  Widget _buildDefaultContent() {
    // 安全地获取 Controller，如果不存在则返回空容器
    if (!Get.isRegistered<CustomBottomDialogController>()) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      // 二次检查，防止在 Obx 构建过程中 Controller 被删除
      if (!Get.isRegistered<CustomBottomDialogController>()) {
        return const SizedBox.shrink();
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset("assets/home/bind_dialog_title.webp", width: 154, height: 36,),
          const SizedBox(height: 8),
          const Text(
            '一起在kissu开启亲密体验吧!',
            style: TextStyle(fontSize: 14, color: Color(0x99333333)),
          ),
          const SizedBox(height: 15),

          // 输入框
          GestureDetector(
            onTap: _showInputDialog,
            child: Container(
              // 外层：粉色背景模拟边框
              decoration: BoxDecoration(
                color: Color(0xffFF9AD9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(2), // 1px边框宽度
              child: Container(
                // 内层：白色背景
                padding: const EdgeInsets.symmetric(
                  horizontal: 67,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10), // 比外层小1
                ),
                child: const Text(
                  '点击输入对方匹配码',
                  style: TextStyle(color: Color(0xffAAAAAA), fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '我的匹配码',
            style: TextStyle(fontSize: 14, color: Color(0xff333333),fontWeight:FontWeight.w500, ),
          ),
          // 我的匹配码
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                controller.userMatchCode.value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff333333),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: controller.copyMatchCode,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 15,
                  ),
                  child: const Text(
                    '复制',
                    style: TextStyle(color: Color(0xffFF9AD9), fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          const Text(
            '你也可以通过以下方式和对方绑定',
            style: TextStyle(fontSize: 14, color: Color(0xff333333)),
          ),
          const SizedBox(height: 10),

          // 分享方式
          Wrap(
            alignment: WrapAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: controller.shareToQQ,
                child: _buildShareOption("assets/3.0/kissu3_share_qq.webp"),
              ),
              SizedBox(width: 42),
              GestureDetector(
                onTap: controller.shareToWechat,
                child: _buildShareOption("assets/3.0/kissu3_share_wechat.webp"),
              ),
              SizedBox(width: 42),
              GestureDetector(
                onTap: controller.scanQRCode,
                child: _buildShareOption("assets/3.0/kissu3_share_scan.webp"),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 二维码链接
          GestureDetector(
            onTap: controller.viewQRCode,
            child: const Text(
                  '查看二维码',
                  style: TextStyle(color: Color(0xffFF9AD9), fontSize: 12,fontWeight: FontWeight.w500),
                ),
          ),
          const SizedBox(height: 5),
        ],
      );
    });
  }

  /// 显示输入对话框 - 底部弹窗形式
  void _showInputDialog() {
    // 埋点：输入匹配码事件
    controller.trackBindInput();
    
    final FocusNode focusNode = FocusNode();
    bool isDisposed = false; // 标记 FocusNode 是否已释放
    bool manualClose = false; // 标记是否为手动点击确认关闭

    // 监听焦点变化，当失去焦点时关闭弹窗
    void focusListener() {
      // 只有在 FocusNode 未释放、失去焦点且不是手动关闭时才自动关闭
      if (!isDisposed && !focusNode.hasFocus && !manualClose) {
        logDebug('输入框失去焦点，关闭输入弹窗', tag: 'CustomBottomDialog');
        // 延迟一帧执行关闭操作，避免在 listener 中操作导致状态混乱
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!isDisposed && (Get.isBottomSheetOpen ?? false)) {
            Get.back();
          }
        });
      }
    }

    focusNode.addListener(focusListener);

    Get.bottomSheet(
      PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) return;
          // 用户手动关闭时，清空输入框
          controller.matchCodeController.clear();
        },
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 输入框
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                      controller: controller.matchCodeController,
                      focusNode: focusNode,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '输入对方匹配码',
                        hintStyle: const TextStyle(
                          color: Color(0xffCCCCCC),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xffF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xff333333),
                      ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  // 确认按钮 - 使用 Obx 包裹以实现响应式更新
                  Obx(() {
                    final bool isEnabled =
                        controller.inputMatchCode.value.isNotEmpty;
                    return SizedBox(
                      width: 76,
                      height: 36,
                      child: GestureDetector(
                        onTap: isEnabled
                            ? () {
                                // 标记为手动关闭，防止监听器再次触发
                                manualClose = true;
                                // 执行绑定
                                controller.bindPartner();
                                // 清空输入框
                                controller.matchCodeController.clear();
                                // 关闭弹窗，让 .then() 回调自然清理 FocusNode
                                Get.back();
                              }
                            : null,
                        child: Opacity(
                          opacity: 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xffFF9AD9),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '确认',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
    ).then((_) {
      // 标记为已释放
      isDisposed = true;
      // 移除监听器并释放
      focusNode.removeListener(focusListener);
      focusNode.dispose();
    });
  }

  Widget _buildShareOption(String icon) {
    return Container(
      width: 40,
      height: 40,
      child: Image(image: AssetImage(icon), fit: BoxFit.contain),
    );
  }
}
