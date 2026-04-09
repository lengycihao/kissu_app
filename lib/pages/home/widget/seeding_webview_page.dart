import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

/// 种草专用WebView页面
/// 特性：
/// 1. 无导航栏
/// 2. 左上角返回按钮
/// 3. 支持外链打开
class SeedingWebViewPage extends StatefulWidget {
  final String url;

  const SeedingWebViewPage({
    super.key,
    required this.url,
  });

  @override
  State<SeedingWebViewPage> createState() => _SeedingWebViewPageState();
}

class _SeedingWebViewPageState extends State<SeedingWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    try {
      _controller.clearCache();
      _controller.clearLocalStorage();
    } catch (e) {
      logError('清理WebView资源失败: $e', tag: 'SeedingWebView', error: e);
    }
    super.dispose();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: _handleJsMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress;
              if (progress == 100) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                });
              }
            });
          },
          onPageStarted: (String url) {
            logDebug('WebView开始加载: $url', tag: 'SeedingWebView');
            setState(() {
              _isLoading = true;
              _loadingProgress = 0;
            });
          },
          onPageFinished: (String url) {
            logDebug('WebView加载完成: $url', tag: 'SeedingWebView');
            // 注入 viewBack 方法
            _injectViewBackBridge();
          },
          onWebResourceError: (WebResourceError error) {
            logError('WebView加载错误: ${error.description}',
                tag: 'SeedingWebView');
          },
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.parse(request.url);
            
            // 判断是否为外链（不同域名）
            final currentUri = Uri.parse(widget.url);
            final isDifferentDomain = uri.host != currentUri.host;
            
            if (isDifferentDomain) {
              // 外链，使用系统浏览器打开
              logDebug('检测到外链，使用系统浏览器打开: ${request.url}',
                  tag: 'SeedingWebView');
              _launchExternalUrl(request.url);
              return NavigationDecision.prevent;
            }
            
            // 同域名链接，允许在WebView中加载
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  /// 注入 JS 适配：把 H5 期望的 window.android.viewBack 方法映射到 FlutterBridge
  void _injectViewBackBridge() {
    const script = '''
      (function() {
        if (!window.android) {
          window.android = {};
        }
        // 注入 viewBack 方法
        if (typeof window.android.viewBack !== 'function') {
          window.android.viewBack = function() {
            try {
              var payload = {
                event: 'viewBack'
              };
              if (window.FlutterBridge && window.FlutterBridge.postMessage) {
                window.FlutterBridge.postMessage(JSON.stringify(payload));
              } else if (window.flutter_inappwebview) {
                // 备用：兼容其他Flutter WebView实现
                window.flutter_inappwebview.callHandler('FlutterBridge', payload);
              }
            } catch (e) {
              console.error('viewBack bridge error', e);
            }
          };
        }
      })();
    ''';

    _controller.runJavaScript(script);
  }

  /// 处理来自 H5 的消息
  /// 处理H5通过 FlutterBridge 发送的消息
  /// 约定：调用 window.FlutterBridge.postMessage(JSONString)
  /// 支持的事件：
  /// - viewBack: {"event":"viewBack"} 或 {"type":"viewBack"}
  void _handleJsMessage(JavaScriptMessage message) {
    try {
      final raw = message.message;
      logDebug('收到H5消息: $raw', tag: 'SeedingWebView');

      Map<String, dynamic> root;
      try {
        root = Map<String, dynamic>.from(jsonDecode(raw));
      } catch (_) {
        return;
      }

      final event = root['event'] as String? ?? root['type'] as String?;
      if (event == null) return;

      // 处理 viewBack 事件：关闭H5页面返回原生
      if (event == 'viewBack') {
        logDebug('收到 viewBack 事件，关闭H5页面', tag: 'SeedingWebView');
        _safeClose();
        return;
      }

      // 其他未知事件，记录日志但不处理
      logDebug('收到未知H5事件: $event', tag: 'SeedingWebView');
    } catch (e) {
      logError('处理H5消息失败: $e', tag: 'SeedingWebView', error: e);
    }
  }

  /// 安全关闭页面
  void _safeClose() {
    try {
      if (mounted) {
        Get.back();
      }
    } catch (e) {
      logError('关闭H5页面失败: $e', tag: 'SeedingWebView', error: e);
    }
  }

  /// 使用系统浏览器打开外链
  Future<void> _launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        logDebug('成功打开外链: $url', tag: 'SeedingWebView');
      } else {
        logError('无法打开外链: $url', tag: 'SeedingWebView');
      }
    } catch (e) {
      logError('打开外链失败: $e', tag: 'SeedingWebView', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // WebView主体
         WebViewWidget(controller: _controller),
          // 加载进度条
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: LinearProgressIndicator(
                  value: _loadingProgress / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFFF4D67),
                  ),
                ),
              ),
            ),

       
        ],
      ),
    );
  }
}
