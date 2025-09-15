import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/login/login_controller.dart';
import 'package:flutter/services.dart';
import 'package:kissu_app/widgets/loading_dots_widget.dart';
import 'package:kissu_app/utils/agreement_utils.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginController controller = Get.put(LoginController());
  final ScrollController _scrollController = ScrollController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _codeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // 添加焦点监听
    _phoneFocusNode.addListener(() {
      _handleFocusChange(context, _phoneFocusNode.hasFocus, 0);
    });

    _codeFocusNode.addListener(() {
      _handleFocusChange(context, _codeFocusNode.hasFocus, 1);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _phoneFocusNode.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    controller.context = context;
    return Scaffold(
      resizeToAvoidBottomInset: false, // 禁用自动调整，手动控制
      body: GestureDetector(
            onTap: () {
              // 释放所有焦点
              _phoneFocusNode.unfocus();
              _codeFocusNode.unfocus();
              FocusScope.of(context).unfocus();

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
                Image.asset('assets/kissu_login_bg.webp', fit: BoxFit.cover),
                Center(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SizedBox(
                          //   height: MediaQuery.of(context).size.height * 0.15,
                          // ), // 动态高度
                          Image.asset(
                            'assets/kissu_login_title.webp',
                            width: 80,
                            height: 25,
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            '请输入手机号',
                            false,
                            controller.phoneNumber,
                            context,
                            focusNode: _phoneFocusNode,
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            '请输入验证码',
                            true,
                            controller.verificationCode,
                            context,
                            focusNode: _codeFocusNode,
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () {
                              // 释放所有焦点并收起键盘
                              _phoneFocusNode.unfocus();
                              _codeFocusNode.unfocus();
                              FocusScope.of(context).unfocus();
                              controller.login();
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                image: const DecorationImage(
                                  image: AssetImage(
                                    'assets/kissu_login_btn_bg.webp',
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
                ),
                Positioned(
                  bottom: 80,
                  left: 1,
                  right: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Obx(
                        () => GestureDetector(
                          onTap: () {
                            controller.isChecked.value =
                                !controller.isChecked.value;
                          },
                          child: Container(
                            width: 16, // 设置圆的宽度
                            height: 16, // 设置圆的高度
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(
                                  controller.isChecked.value
                                      ? 'assets/kissu_login_privite_sel.webp'
                                      : 'assets/kissu_login_privite_unsel.webp',
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
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 12,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          AgreementUtils.toUserAgreement();
                        },
                        child: const Text(
                          '《用户协议》',
                          style: TextStyle(
                            color: Color(0xFFFF839E),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Text(
                        '和',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 12,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          AgreementUtils.toPrivacyAgreement();
                        },
                        child: const Text(
                          '《隐私政策》',
                          style: TextStyle(
                            color: Color(0xFFFF839E),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }

  // 处理焦点变化，智能滚动
  void _handleFocusChange(BuildContext context, bool hasFocus, int fieldIndex) {
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
    RxString field,
    BuildContext context, {
    required FocusNode focusNode,
  }) {
    return TextField(
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18, // 增加垂直内边距确保居中
        ),
        isDense: true, // 减少默认内边距
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFF6D383E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFF6D383E)),
        ),
        suffixIcon: isCodeField
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      // 释放所有焦点并收起键盘
                      _phoneFocusNode.unfocus();
                      _codeFocusNode.unfocus();
                      FocusScope.of(context).unfocus();
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
          ? [FilteringTextInputFormatter.digitsOnly,LengthLimitingTextInputFormatter(6),] // 验证码只能输入数字
          : [
              FilteringTextInputFormatter.digitsOnly, // 手机号只能输入数字
              LengthLimitingTextInputFormatter(11), // 最多 11 位
            ],
    );
  }
}
