import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 协议WebView页面
class AgreementWebViewPage extends StatefulWidget {
  final String title;
  final String url;

  const AgreementWebViewPage({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<AgreementWebViewPage> createState() => _AgreementWebViewPageState();
}

class _AgreementWebViewPageState extends State<AgreementWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print('WebView加载进度: $progress%');
          },
          onPageStarted: (String url) {
            print('WebView开始加载: $url');
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            print('WebView加载完成: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView加载错误: ${error.description}');
            print('错误代码: ${error.errorCode}');
            print('错误类型: ${error.errorType}');
            print('失败URL: ${error.url}');
            
            String errorMsg = _getErrorMessage(error);
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = errorMsg;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('WebView导航请求: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF6F0),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF333333),
              size: 20,
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
         
      ),
      body: Stack(
        children: [
          // WebView内容
          if (!_hasError)
            WebViewWidget(controller: _controller)
          else
            _buildErrorWidget(),
          
          // 加载指示器
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
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
              ),
            ),
        ],
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
              'assets/kissu3_love_avater.webp',
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
