import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'transparent_banner_widget.dart';
import 'gradient_content_widget.dart';
import 'custom_bottom_dialog_controller.dart';

/// 自定义底部弹窗组件
class CustomBottomDialog extends GetView<CustomBottomDialogController> {
  final VoidCallback? onClose;
  final Widget? customContent;
  final List<String>? bannerImages;
  final double bannerHeight;
  final bool showBanner;

  const CustomBottomDialog({
    Key? key,
    this.onClose,
    this.customContent,
    this.bannerImages,
    this.bannerHeight = 220,
    this.showBanner = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          // 透明Banner区域 - 透过可以看到首页内容
          if (showBanner && bannerImages != null && bannerImages!.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).size.height - 420 - bannerHeight,
              left: 0,
              right: 0,
              height: bannerHeight,
              child: TransparentBannerWidget(
                imagePaths: bannerImages!,
                height: bannerHeight,
              ),
            ),

          // 渐变背景的内容区域 - 在Banner下方
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 412, // 固定内容区域高度
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
                    padding: const EdgeInsets.all(20).copyWith(top: 25),
                    child: customContent ?? _buildDefaultContent(),
                  ),

                  // 关闭按钮 - 使用Positioned定位
                  Positioned(
                    top: 15,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        if (onClose != null) {
                          onClose!();
                        }
                        Get.back();
                      },
                      child: Image.asset(
                        "assets/3.0/kissu3_close.webp",
                        width: 16,
                        height: 16,
                      ),
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
    
    return Obx(
      () {
        // 二次检查，防止在 Obx 构建过程中 Controller 被删除
        if (!Get.isRegistered<CustomBottomDialogController>()) {
          return const SizedBox.shrink();
        }
        
        return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '立即添加另一半',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff333333),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '一起在kissu开启亲密体验吧!',
            style: TextStyle(fontSize: 14, color: Color(0xff333333)),
          ),
          const SizedBox(height: 12),

          // 输入框
          GestureDetector(
            onTap: _showInputDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xffFF88AA)),
              ),
              child: const Text(
                '点击输入对方匹配码',
                style: TextStyle(color: Color(0xffFFB2C8), fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '我的匹配码',
            style: TextStyle(fontSize: 14, color: Color(0xff333333)),
          ),
          // 我的匹配码
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                controller.userMatchCode.value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff333333),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: controller.copyMatchCode,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 15,
                  ),
                  child: const Text(
                    '复制',
                    style: TextStyle(color: Color(0xffFF2462), fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          const Text(
            '你也可以通过以下方式和对方绑定',
            style: TextStyle(fontSize: 14, color: Color(0xff333333)),
          ),
          const SizedBox(height: 20),

          // 分享方式
          Wrap(
            alignment: WrapAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: controller.shareToQQ,
                child: _buildShareOption("assets/3.0/kissu3_share_qq.webp"),
              ),
              SizedBox(width: 50),
              GestureDetector(
                onTap: controller.shareToWechat,
                child: _buildShareOption("assets/3.0/kissu3_share_wechat.webp"),
              ),
              SizedBox(width: 50),
              GestureDetector(
                onTap: controller.scanQRCode,
                child: _buildShareOption("assets/3.0/kissu3_share_scan.webp"),
              ),
            ],
          ),
          const SizedBox(height: 26),

          // 二维码链接
          GestureDetector(
            onTap: controller.viewQRCode,
            child: Stack(
              children: [
               
            Positioned(
              bottom: 0,
              child: Container(
                width: 75,
                height: 7,
                decoration: BoxDecoration(
                  color: Color(0xffFFEEE8),
                  borderRadius: BorderRadius.circular(4),
                ),
                 
              ),
            ), const Text(
              '查看二维码',
              style: TextStyle(
                color: Color(0xff4496F9),
                fontSize: 12,
               ),
            ),
              ],
            )
          ),
          const SizedBox(height: 20),
        ],
      );
      },
    );
  }

  /// 显示输入对话框 - 底部弹窗形式
  void _showInputDialog() {
    final FocusNode focusNode = FocusNode();
    bool isDisposed = false; // 标记 FocusNode 是否已释放
    bool manualClose = false; // 标记是否为手动点击确认关闭

    // 监听焦点变化，当失去焦点时关闭弹窗
    void focusListener() {
      // 只有在 FocusNode 未释放、失去焦点且不是手动关闭时才自动关闭
      if (!isDisposed && !focusNode.hasFocus && !manualClose) {
        print('输入框失去焦点，关闭输入弹窗');
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
      WillPopScope(
        onWillPop: () async {
          // 用户手动关闭时，清空输入框
          controller.matchCodeController.clear();
          return true;
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
                   SizedBox(width: 10),
                   // 确认按钮 - 使用 Obx 包裹以实现响应式更新
                   Obx(
                     () {
                       final bool isEnabled = controller.inputMatchCode.value.isNotEmpty;
                       return SizedBox(
                         width: 62,
                         height: 50,
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
                             opacity: isEnabled ? 1.0 : 0.4,
                             child: Container(
                               decoration: BoxDecoration(
                                 color: const Color(0xffFF2462),
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
                     },
                   ),
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
      width: 60,
      height: 60,
      child: Image(image: AssetImage(icon), fit: BoxFit.contain),
    );
  }

  /// 显示自定义底部弹窗
  static Future<T?> show<T>({
    required BuildContext context,
    VoidCallback? onClose,
    Widget? customContent,
    List<String>? bannerImages,
    double bannerHeight = 220,
    bool showBanner = true,
    bool isDismissible = true,
  }) {
    // 删除旧的控制器实例（如果存在）
    if (Get.isRegistered<CustomBottomDialogController>()) {
      Get.delete<CustomBottomDialogController>();
    }
    
    // 初始化新的控制器
    Get.put(CustomBottomDialogController());

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
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomBottomDialog(
        onClose: onClose,
        customContent: customContent,
        bannerImages: bannerImages ?? defaultBannerImages,
        bannerHeight: bannerHeight,
        showBanner: showBanner,
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
