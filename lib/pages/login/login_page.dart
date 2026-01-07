import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/login/login_controller.dart';
import 'package:flutter/services.dart';
import 'package:kissu_app/services/analytics/analytics_params.dart';
import 'package:kissu_app/widgets/loading_dots_widget.dart';
import 'package:kissu_app/utils/agreement_utils.dart';
import 'package:kissu_app/services/analytics/analytics_manager.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/services/analytics/analytics_page_ids.dart';
import 'package:kissu_app/services/analytics/analytics_exit_types.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginController controller = Get.put(LoginController());
  final ScrollController _scrollController = ScrollController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _codeFocusNode = FocusNode();
  
  // 埋点相关
  int? _pageEnterTime; // 页面进入时间（毫秒）
  int _sourcePage = PageSourceIds.agreementDialog; // 来源页面，默认为协议弹窗

  @override
  void initState() {
    super.initState();
    
    // 埋点：记录页面进入时间
    _pageEnterTime = DateTime.now().millisecondsSinceEpoch;
    
    // 获取来源页面参数（如果有的话）
    final args = Get.arguments;
    if (args != null && args is Map && args.containsKey('source_page')) {
      _sourcePage = args['source_page'] as int;
    }

    // 添加焦点监听
    _phoneFocusNode.addListener(() {
      _handleFocusChange(_phoneFocusNode.hasFocus, 0);
    });

    _codeFocusNode.addListener(() {
      _handleFocusChange(_codeFocusNode.hasFocus, 1);
    });
  }

  @override
  void dispose() {
    // 埋点：记录页面浏览时长并上报
    if (_pageEnterTime != null) {
      final exitTime = DateTime.now().millisecondsSinceEpoch;
      final durationMs = exitTime - _pageEnterTime!;
      
      // 格式化时间和时长
      final enterTimeStr = _formatEnterTime(DateTime.fromMillisecondsSinceEpoch(_pageEnterTime!));
      final durationStr = _formatDuration(durationMs);
      
      // 判断离开方式（默认为返回）
      final exitType = ExitTypeValue.back;
      
      /**
       * 埋点
       * 页面名称：登录
       * 事件名称：登录页面浏览
       * 页面id: login_event
       * 事件id: login_page
       */
      AnalyticsManager.instance.trackPageView(
        pageId: LoginEvents.pageId,
        eventId: LoginEvents.page,
        enterTime: enterTimeStr,
        duration: durationStr,
        sourcePage: _sourcePage.toString(),
        exitType: exitType,
      );
    }
    
    _scrollController.dispose();
    _phoneFocusNode.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  void _unfocusAll() {
    _phoneFocusNode.unfocus();
    _codeFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    controller.context = context;
    return Scaffold(
      resizeToAvoidBottomInset: false, // 禁用自动调整，手动控制
      backgroundColor: Color(0xfff6f6f6),
      body: GestureDetector(
        onTap: () {
          // 释放所有焦点
          _unfocusAll();

          // 延迟后滚动回顶部
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && MediaQuery.of(context).viewInsets.bottom == 0) {
              _scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/home/login_bg.webp',
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
              ),
            ),

            // Positioned(top:MediaQuery.of(context).padding.top + 36 ,
            //   child: Image.asset(
            //     'assets/home/login_icon.png',
            //     fit: BoxFit.contain,
            //     width: 175,
            //     height: 206,
            //   )),
            SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 36,
                    left: 40,
                    right: 40,
                    bottom: 100, // 为底部隐私模块留出空间
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    // mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/home/login_icon.png',
                        fit: BoxFit.contain,
                        width: 175,
                        height: 206,
                      ),
                      const SizedBox(height: 30),
                      _buildInputField(
                        '请输入手机号',
                        false,
                        controller.phoneNumber,
                        focusNode: _phoneFocusNode,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        '请输入验证码',
                        true,
                        controller.verificationCode,
                        focusNode: _codeFocusNode,
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () {
                          // 释放所有焦点并收起键盘
                          _unfocusAll();
                          // 埋点：登录按钮点击
                          _trackLoginButtonClick();
                          controller.login();
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            image: const DecorationImage(
                              image: AssetImage(
                                'assets/images/kissu_login_btn_bg.webp',
                              ),
                              fit: BoxFit.fill,
                            ),
                          ),
                          child: Obx(
                            () => Center(
                              child: controller.isLoading.value
                                  ? const LoadingDotsWidget(
                                      color: Colors.white,
                                      size: 4.0,
                                    )
                                  : const Text(
                                      '登录/注册',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
             Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Obx(
                        () => GestureDetector(
                          onTap: () {
                            // 切换勾选状态
                            final newValue = !controller.isChecked.value;
                            controller.isChecked.value = newValue;

                        
                          },
                          child: Container(
                            width: 16, // 设置圆的宽度
                            height: 16, // 设置圆的高度
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(
                                  controller.isChecked.value
                                      ? 'assets/images/kissu_login_privite_sel.webp'
                                      : 'assets/images/kissu_login_privite_unsel.webp',
                                ),
                              ),
                              // color: controller.isChecked.value
                              //     ? Color(0xFFFF839E) // 勾选时的颜色
                              //     : Colors.white,
                              // shape: BoxShape.circle,
                              // border: Border.all(
                              //   color: Color(0xFF666666), // 未勾选时的边框颜色
                              //   width: 1.5,
                              // ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        '登录即代表同意 ',
                        style: TextStyle(color: Color(0xFF666666), fontSize: 12),
                      ),
                      
                      GestureDetector(
                        onTap: () {
                          AgreementUtils.toPrivacyAgreement();
                        },
                        child: const Text(
                          '《隐私政策》',
                          style: TextStyle(color: Color(0xFFFF97CE), fontSize: 12),
                        ),
                      ),
                      const Text(
                        '和',
                        style: TextStyle(color: Color(0xFF666666), fontSize: 12),
                      ),
                      
                      GestureDetector(
                        onTap: () {
                          AgreementUtils.toUserAgreement();
                        },
                        child: const Text(
                          '《用户协议》',
                          style: TextStyle(color: Color(0xFFFF97CE), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          ],
        ),
      ),
    );
  }

  // 处理焦点变化，智能滚动
  void _handleFocusChange(bool hasFocus, int fieldIndex) {
    if (hasFocus) {
      // 延迟执行，等待键盘完全弹起
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        if (keyboardHeight > 0) {
          // 计算输入框位置是否被键盘遮挡
          final screenHeight = MediaQuery.of(context).size.height;
          final availableHeight = screenHeight - keyboardHeight;

          // 根据输入框索引计算大概位置
          final inputFieldPosition =
              screenHeight * 0.4 + (fieldIndex * 70); // 估算位置

          // 如果输入框被遮挡，则滚动
          if (inputFieldPosition > availableHeight) {
            _scrollController.animateTo(
              100.0 + (fieldIndex * 50), // 动态滚动距离
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    } else {
      // 失去焦点时，检查是否需要滚动回顶部
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        if (keyboardHeight == 0) {
          // 键盘已收起，滚动回原位置
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Widget _buildInputField(
    String hintText,
    bool isCodeField,
    RxString field, {
    required FocusNode focusNode,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        image: const DecorationImage(
          image: AssetImage('assets/home/login_text_bg.webp'),

          fit: BoxFit.fill,
        ),
      ),
      child: TextField(
        focusNode: focusNode,
        onChanged: (value) {
          field.value = value;
        },
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF333333),
          height: 1.0, // 设置行高为1.0确保垂直居中
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF999999),
            fontSize: 16,
            height: 1.0, // 设置占位符行高为1.0确保垂直居中
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16, // 增加垂直内边距确保居中
          ),
          isDense: true, // 减少默认内边距
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          suffixIcon: isCodeField
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // 释放所有焦点并收起键盘
                        _unfocusAll();
                        // 埋点：获取验证码点击
                        _trackGetVerificationCodeClick();
                        controller.validatePhoneNumber();
                      },
                      child: Obx(
                        () => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 21),
                          child: Text(
                            controller.codeButtonText.value,
                            style: TextStyle(
                              color: controller.codeButtonColor.value,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : null,
        ),
        keyboardType: isCodeField ? TextInputType.number : TextInputType.phone,
        inputFormatters: isCodeField
            ? [FilteringTextInputFormatter.digitsOnly] // 验证码只能输入数字，无位数限制
            : [
                FilteringTextInputFormatter.digitsOnly, // 手机号只能输入数字
                LengthLimitingTextInputFormatter(11), // 最多 11 位
              ],
      ),
    );
  }
  
  /// 埋点：获取验证码点击事件
  void _trackGetVerificationCodeClick() {
    // 先记录点击事件，状态默认为成功
    AnalyticsHelper.trackGetVerificationCode(success: true);
  }
  
  /// 埋点：登录按钮点击事件
  void _trackLoginButtonClick() {
    // 先记录点击事件，状态默认为成功
    AnalyticsHelper.trackLoginButton(success: true);
  }
  
  /// 格式化页面进入时间为 "年-月-日 时:分:秒" 格式
  String _formatEnterTime(DateTime dateTime) {
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }
  
  /// 格式化时长为 mm:ss 格式
  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).round();
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
