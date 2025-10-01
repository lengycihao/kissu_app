import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'transparent_banner_widget.dart';
import 'gradient_content_widget.dart';

/// 自定义底部弹窗组件
class CustomBottomDialog extends StatelessWidget {
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
                  if (onClose != null)
                    Positioned(
                      top: 10,
                      right: 16,
                      child: GestureDetector(
                        onTap: onClose,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.close,
                            color: Color(0xffdddddd),
                            size: 20,
                          ),
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
        Container(
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
        const SizedBox(height: 16),
        const Text(
          '我的匹配码',
          style: TextStyle(fontSize: 14, color: Color(0xff333333)),
        ),
        // 我的匹配码
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '9061026',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xff333333),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                // 复制匹配码
                Get.snackbar('提示', '匹配码已复制');
              },
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
            _buildShareOption("assets/3.0/kissu3_share_qq.webp"),
            SizedBox(width: 50),
            _buildShareOption("assets/3.0/kissu3_share_wechat.webp"),
            SizedBox(width: 50),
            _buildShareOption("assets/3.0/kissu3_share_scan.webp"),
          ],
        ),
        const SizedBox(height: 20),

        // 二维码链接
        GestureDetector(
          onTap: () {
            // 查看二维码
            Get.snackbar('提示', '查看二维码');
          },
          child: const Text(
            '查看二维码',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 16,
              decoration: TextDecoration.underline,
            ),
          ),
        ),const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildShareOption(String icon) {
    return Container(
      width: 60,
      height: 60,
      child: Image(
        image: AssetImage(icon),
        fit: BoxFit.contain,
      ),
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
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomBottomDialog(
        onClose: onClose,
        customContent: customContent,
        bannerImages: bannerImages,
        bannerHeight: bannerHeight,
        showBanner: showBanner,
      ),
    );
  }
}
