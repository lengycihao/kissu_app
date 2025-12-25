import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'phone_verification_controller.dart';

class PhoneVerificationPage extends StatelessWidget {
  PhoneVerificationPage({Key? key}) : super(key: key);

  final controller = Get.put(PhoneVerificationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFffffff),
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
          children: [
            // 顶部导航栏
            _buildAppBar(),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 43),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    const SizedBox(height: 50),
                    Text("手机号验证",style: TextStyle(
                      color: Color(0xff333333),fontSize: 16,fontWeight: FontWeight.w500
                    ),),
                    const SizedBox(height: 12),
                    // 输入框组
                    _buildInputSection(),

                    const SizedBox(height: 100), // 增加底部间距，为底部按钮留空间
                  ],
                ),
              ),
            ),

            // 底部注销按钮
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 43, vertical: 30),
              child: _buildCancelButton(),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }

  // 顶部导航栏
  Widget _buildAppBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: controller.goBack,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios,
                size: 20,
                color: Color(0xFF333333),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              '注销账户',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // 输入框部分
  Widget _buildInputSection() {
    return Obx(
      () => Column(
        children: [
          // 验证码输入框（带获取验证码按钮）
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Color(0xfff8f8f8),
              borderRadius: BorderRadius.circular(22)
             ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.verificationCodeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // 验证码只能输入数字，无位数限制
                    ],
                    decoration:   InputDecoration(
                      hintText: '请输入验证码',
                      hintStyle: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 14,
                      ),

                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 5),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: controller.isLoading.value
                      ? null
                      : controller.sendVerificationCode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      controller.canResend.value
                          ? '发送验证码'
                          : '${controller.countdown.value}s',
                      style: TextStyle(
                        color: controller.canResend.value
                            ? const Color(0xFFFF9AD9)
                            : const Color(0xFF999999),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 注销按钮
  Widget _buildCancelButton() {
    return Obx(
      () => GestureDetector(
        onTap: controller.isLoading.value
            ? null
            : controller.confirmCancellation,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Color(0xffFFA9E0),
            borderRadius: BorderRadius.circular(22)
          ),
          alignment: Alignment.center,
          child: controller.isLoading.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  '注销',
                  style: TextStyle(
                    color: Color(0xffffffff),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}
