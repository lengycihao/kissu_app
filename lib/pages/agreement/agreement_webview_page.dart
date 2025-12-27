import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/widgets/share_bottom_sheet.dart';
import 'package:kissu_app/services/tencent_im_service.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

/// 协议WebView页面
class AgreementWebViewPage extends StatefulWidget {
  final String title;
  final String url;
  final bool showAppBar;
  final Color? backgroundColor;
  final bool showLoadingIndicator; // 是否显示加载动画

  const AgreementWebViewPage({
    super.key,
    required this.title,
    required this.url,
    this.showAppBar = true,
    this.backgroundColor,
    this.showLoadingIndicator = true, // 默认显示加载动画
  });

  @override
  State<AgreementWebViewPage> createState() => _AgreementWebViewPageState();
}

class _AgreementWebViewPageState extends State<AgreementWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _canGoBack = false; // WebView是否可以返回
  int _loadingProgress = 0; // 加载进度 0-100

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    // 🔥 修复：确保WebView正确释放，防止内存泄漏
    try {
      _controller.clearCache();
      _controller.clearLocalStorage();
    } catch (e) {
      logError('清理WebView资源失败: $e', tag: 'AgreementWebView', error: e);
    }
    super.dispose();
  }

  /// 更新导航状态
  Future<void> _updateNavigationState() async {
    final canGoBack = await _controller.canGoBack();
    setState(() {
      _canGoBack = canGoBack;
    });
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: _handleJsMessage,
      )
      // 使用默认 User-Agent，让 H5 页面能正确识别设备类型和屏幕尺寸
      // 移除固定的 User-Agent，避免某些设备上布局识别错误
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            logDebug('WebView加载进度: $progress%', tag: 'AgreementWebView');
            setState(() {
              _loadingProgress = progress;
              // 进度达到100%时，延迟一小段时间再隐藏加载状态，确保页面渲染完成
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
            logDebug('WebView开始加载: $url', tag: 'AgreementWebView');
            setState(() {
              _isLoading = true;
              _hasError = false;
              _loadingProgress = 0;
            });
          },
          onPageFinished: (String url) {
            logDebug('WebView加载完成: $url', tag: 'AgreementWebView');
            // 注入 viewport meta 标签，确保移动端布局正确
            _injectViewportMeta();
            // 注入 JS 适配层，兼容 H5 调用 window.android.sharePop(...)
            _injectShareBridge();
            // 更新导航状态
            _updateNavigationState();
            // 延迟隐藏加载状态，确保页面完全渲染
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _loadingProgress = 100;
                });
              }
            });
          },
          onUrlChange: (UrlChange change) {
            logDebug('WebView URL改变: ${change.url}', tag: 'AgreementWebView');
            // URL改变时更新导航状态
            _updateNavigationState();
          },
          onWebResourceError: (WebResourceError error) {
            logError('WebView加载错误: ${error.description}', tag: 'AgreementWebView');
            logDebug('错误代码: ${error.errorCode}', tag: 'AgreementWebView');
            logDebug('错误类型: ${error.errorType}', tag: 'AgreementWebView');
            logDebug('失败URL: ${error.url}', tag: 'AgreementWebView');
            
            String errorMsg = _getErrorMessage(error);
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = errorMsg;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            logDebug('WebView导航请求: ${request.url}', tag: 'AgreementWebView');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  /// 注入 viewport meta 标签，确保移动端布局正确
  /// 这可以解决某些手机上 H5 布局混乱的问题
  void _injectViewportMeta() {
    const viewportScript = '''
      (function() {
        // 检查是否已有 viewport meta 标签
        var viewport = document.querySelector('meta[name="viewport"]');
        if (!viewport) {
          // 如果没有，创建一个
          var meta = document.createElement('meta');
          meta.name = 'viewport';
          meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
          document.getElementsByTagName('head')[0].appendChild(meta);
        } else {
          // 如果已有，确保内容正确
          var content = viewport.getAttribute('content') || '';
          if (!content.includes('width=device-width')) {
            viewport.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover');
          }
        }
        
        // 确保 body 和 html 的样式正确
        if (document.documentElement) {
          document.documentElement.style.width = '100%';
          document.documentElement.style.height = '100%';
          document.documentElement.style.overflow = 'hidden';
        }
        if (document.body) {
          document.body.style.width = '100%';
          document.body.style.height = '100%';
          document.body.style.margin = '0';
          document.body.style.padding = '0';
          document.body.style.overflow = 'auto';
          document.body.style.webkitOverflowScrolling = 'touch';
        }
      })();
    ''';
    
    _controller.runJavaScript(viewportScript);
  }

  /// 注入 JS 适配：把 H5 期望的 window.android 方法映射到 FlutterBridge
  void _injectShareBridge() {
    const script = '''
      (function() {
        if (!window.android) {
          window.android = {};
        }
        // 注入 sharePop 方法
        if (typeof window.android.sharePop !== 'function') {
          window.android.sharePop = function(image, url) {
            try {
              var payload = {
                event: 'sharePop',
                image: image || '',
                url: url || ''
              };
              if (window.FlutterBridge && window.FlutterBridge.postMessage) {
                window.FlutterBridge.postMessage(JSON.stringify(payload));
              } else if (window.flutter_inappwebview) {
                // 备用：兼容其他Flutter WebView实现
                window.flutter_inappwebview.callHandler('FlutterBridge', payload);
              }
            } catch (e) {
              console.error('sharePop bridge error', e);
            }
          };
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
        // 注入 shareConvene 方法
        if (typeof window.android.shareConvene !== 'function') {
          window.android.shareConvene = function() {
            try {
              var payload = {
                event: 'shareConvene'
              };
              if (window.FlutterBridge && window.FlutterBridge.postMessage) {
                window.FlutterBridge.postMessage(JSON.stringify(payload));
              } else if (window.flutter_inappwebview) {
                // 备用：兼容其他Flutter WebView实现
                window.flutter_inappwebview.callHandler('FlutterBridge', payload);
              }
            } catch (e) {
              console.error('shareConvene bridge error', e);
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
  /// - sharePop: {"event":"sharePop","image":"...","url":"..."}
  /// - shareConvene: {"event":"shareConvene"} 触发发送一起便便消息
  /// - viewBack: {"event":"viewBack"} 或 {"type":"viewBack"}
  void _handleJsMessage(JavaScriptMessage message) {
    try {
      final raw = message.message;
      logDebug('收到H5消息: $raw', tag: 'AgreementWebView');

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
        logDebug('收到 viewBack 事件，关闭H5页面', tag: 'AgreementWebView');
        _safeClose();
        return;
      }

      // 处理 shareConvene 事件：发送一起便便消息
      if (event == 'shareConvene') {
        logDebug('收到 shareConvene 事件，发送一起便便消息', tag: 'AgreementWebView');
        _sendDefecateMessage();
        return;
      }

      // 处理 sharePop 事件：调起分享弹窗
      if (event == 'sharePop') {
        // 兼容两种格式：
        // 1) {event:'sharePop', image:'https://xx.png', url:'https://xx.html'}
        // 2) {event:'sharePop', image:'{"image":"...","url":"..."}', url:''}
        String image = '';
        String baseUrl = '';

        final dynamic imageField = root['image'];
        final dynamic urlField = root['url'];

        if (imageField is String && imageField.trim().startsWith('{')) {
          // image 里是一个 JSON 字符串
          try {
            final nested =
                Map<String, dynamic>.from(jsonDecode(imageField) as Map);
            image = (nested['image'] as String?) ?? '';
            baseUrl = (nested['url'] as String?) ?? '';
          } catch (e) {
            logError('解析嵌套 image JSON 失败: $e', tag: 'AgreementWebView', error: e);
          }
        } else {
          image = (imageField as String?) ?? '';
          baseUrl = (urlField as String?) ?? '';
        }

        if (baseUrl.isEmpty) {
          logError('sharePop 缺少有效的 url，取消分享', tag: 'AgreementWebView');
          return;
        }

        // 拼接 bindCode（自己的绑定码）
        String finalUrl = baseUrl;
        try {
          final user = UserManager.currentUser;
          final bindCode = user?.friendCode ?? '1000000';
          if (baseUrl.contains('?')) {
            finalUrl = '$baseUrl&bindCode=$bindCode';
          } else {
            finalUrl = '$baseUrl?bindCode=$bindCode';
          }
        } catch (_) {}

        _showShareSheet(image: image, url: finalUrl);
        return;
      }

      // 其他未知事件，记录日志但不处理
      logDebug('收到未知H5事件: $event', tag: 'AgreementWebView');
    } catch (e) {
      logError('处理H5消息失败: $e', tag: 'AgreementWebView', error: e);
    }
  }

  /// 调起分享弹窗（使用和"我的"页面相同的UI）
  void _showShareSheet({required String image, required String url}) {
    ShareBottomSheet.showH5Share(
      context,
      image: image,
      url: url,
    );
  }

  /// 发送一起便便消息
  Future<void> _sendDefecateMessage() async {
    try {
      // 获取另一半的 IM ID
      final user = UserManager.currentUser;
      final halfUserInfo = user?.halfUserInfo;
      final partnerImId = halfUserInfo?.uniqueId;

      if (partnerImId == null || partnerImId.isEmpty) {
        logError('无法发送一起便便消息：未找到另一半的 IM ID', tag: 'AgreementWebView');
        return;
      }

      // 检查 IM 服务是否可用
      final imService = TencentIMService.instance;
      if (!imService.isInitialized || !imService.isLoggedIn) {
        logError('无法发送一起便便消息：IM 未初始化或未登录', tag: 'AgreementWebView');
        return;
      }

      // 构造自定义消息数据
      final customData = jsonEncode({
        'msg_bubble': 'defecate',
      });

      // 发送自定义消息
      final result = await imService.sendCustomMessage(
        receiverID: partnerImId,
        customData: customData,
        isGroup: false,
      );

      if (result != null && result.code == 0) {
        logDebug('一起便便消息发送成功', tag: 'AgreementWebView');
        // 显示成功提示
        OKToastUtil.show('邀请成功');
        // 消息会通过 IM SDK 的回调自动添加到聊天列表（ChatController 监听）
      } else {
        logError(
          '一起便便消息发送失败: code=${result?.code}, desc=${result?.desc}',
          tag: 'AgreementWebView',
        );
      }
    } catch (e) {
      logError('发送一起便便消息异常: $e', tag: 'AgreementWebView', error: e);
    }
  }

  /// 获取友好的错误信息
  String _getErrorMessage(WebResourceError error) {
    switch (error.errorType) {
      case WebResourceErrorType.hostLookup:
        return '无法连接到服务器，请检查网络连接';
      case WebResourceErrorType.timeout:
        return '连接超时，请检查网络状况';
      case WebResourceErrorType.connect:
        return '连接失败，服务器可能无法访问';
      case WebResourceErrorType.badUrl:
        return 'URL格式错误';
      case WebResourceErrorType.fileNotFound:
        return '页面不存在 (404)';
      case WebResourceErrorType.unknown:
      default:
        return '${error.description} (错误代码: ${error.errorCode})';
    }
  }

  /// 安全关闭页面（防止闪退和误关闭Dialog）
  void _safeClose() {
    try {
      if (mounted) {
        // 🔥 修复：优先使用 Get.back()，避免误关闭Dialog
        // Get.back() 只会关闭当前路由（H5页面），不会影响Dialog
        try {
          Get.back();
        } catch (e) {
          // 如果Get.back失败，尝试Navigator（但要确保不会关闭Dialog）
          try {
            // 使用 rootNavigator: false 确保不会关闭Dialog
            final navigator = Navigator.of(context, rootNavigator: false);
            if (navigator.canPop()) {
              navigator.pop();
            } else {
              logDebug('无法安全关闭页面，可能已经是根页面', tag: 'AgreementWebView');
            }
          } catch (e2) {
            logError('Navigator关闭失败: $e2', tag: 'AgreementWebView', error: e2);
          }
        }
      }
    } catch (e) {
      logError('关闭H5页面失败: $e', tag: 'AgreementWebView', error: e);
      // 最后的兜底：什么都不做，避免闪退
    }
  }

  /// 处理返回操作
  Future<void> _handleBack() async {
    if (_canGoBack) {
      // 如果WebView可以返回，则返回到上一页
      try {
        await _controller.goBack();
        _updateNavigationState();
      } catch (e) {
        logError('WebView返回失败: $e', tag: 'AgreementWebView', error: e);
        // 如果WebView返回失败，尝试关闭页面
        _safeClose();
      }
    } else {
      // 否则关闭页面
      _safeClose();
    }
  }

  /// 处理关闭操作
  void _handleClose() {
    _safeClose();
  }

  @override
  Widget build(BuildContext context) {
    final Color scaffoldBg =
        widget.backgroundColor ?? const Color(0xFFFFF6F0);

    return PopScope(
      // 拦截系统返回按钮
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          await _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: widget.showAppBar
            ? AppBar(
                backgroundColor: scaffoldBg,
                elevation: 0,
                toolbarHeight: 44,
                leading: GestureDetector(
                  onTap: _handleBack,
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
                title: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                centerTitle: true,
                actions: _canGoBack
                    ? [
                        GestureDetector(
                          onTap: _handleClose,
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.close,
                              color: Color(0xFF333333),
                              size: 20,
                            ),
                          ),
                        ),
                      ]
                    : null,
              )
            : null,
        body: Padding(
          padding: EdgeInsets.only(
            top:0 ,
          ),
          child: Stack(
            children: [
              // WebView内容（始终渲染，但加载时可能被遮挡）
              if (!_hasError)
                AnimatedOpacity(
                  opacity: _isLoading ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: WebViewWidget(controller: _controller),
                )
              else
                _buildErrorWidget(),
              
              // 加载进度条（显示在顶部）
              if (_isLoading && _loadingProgress > 0 && _loadingProgress < 100)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _loadingProgress / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF839E)),
                    minHeight: 2,
                  ),
                ),
              
              // 加载占位内容（避免白屏，即使showLoadingIndicator为false也显示）
              if (_isLoading)
                Container(
                  color: scaffoldBg,
                  child: widget.showLoadingIndicator
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF839E)),
                              ),
                              SizedBox(height: 16),
                              Text(
                                '正在加载...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildLoadingPlaceholder(scaffoldBg),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建加载占位内容（用于showLoadingIndicator为false时避免白屏）
  Widget _buildLoadingPlaceholder(Color backgroundColor) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 使用一个简单的加载动画
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFFFF839E).withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建错误页面
  Widget _buildErrorWidget() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/3.0/kissu3_love_avater.webp',
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              '页面加载失败',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : '请检查网络连接后重试',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _controller.reload();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF839E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                '重新加载',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

