import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 第三方信息共享清单页面
class ThirdPartySharingPage extends StatefulWidget {
  const ThirdPartySharingPage({super.key});

  @override
  State<ThirdPartySharingPage> createState() => _ThirdPartySharingPageState();
}

class _ThirdPartySharingPageState extends State<ThirdPartySharingPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            OKToastUtil.showError("加载失败，请检查网络连接");
            // 处理加载错误
            // Get.snackbar(
            //   '加载失败',
            //   '无法加载页面，请检查网络连接',
            //   snackPosition: SnackPosition.BOTTOM,
            // );
          },
          onNavigationRequest: (NavigationRequest request) {
            // 处理外部链接跳转
            if (request.url.startsWith('http') &&
                !request.url.contains('ikissu.cn')) {
              launchUrl(
                Uri.parse(request.url),
                mode: LaunchMode.externalApplication,
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.ikissu.cn/agreement/thirdPartyShare.html'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          // 背景图
          Positioned.fill(
            child: Image.asset(
              "assets/4.0/kissu4_new_use_bg.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 自定义导航栏
                SizedBox(
                  height: 44,
                  child: Stack(
                    children: [
                      // 返回按钮
                      Positioned(
                        left: 5,
                        top: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () => Get.back(),
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
                      // 标题 - 绝对居中
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            "第三方信息共享清单",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // WebView内容
                Expanded(
                  child: Stack(
                    children: [
                      WebViewWidget(controller: _controller),
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9AD9)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}