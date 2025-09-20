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
      backgroundColor: const Color(0xFFFFF5F0),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            _buildAppBar(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 43),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    const SizedBox(height: 50),
                    Image(
                      image: AssetImage(
                        "assets/kissu_delete_phone_lable_bg.webp",
                      ),
                      width: 96,
                      height: 21,
                    ),
                    const SizedBox(height: 25),
                    // 输入框组
                    _buildInputSection(),

                    const SizedBox(height: 30),

                    // 注销按钮
                    _buildCancelButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                fontSize: 18,
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
            height: 58,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/kissu_setting_account_code_bg.webp"),
                fit: BoxFit.fill,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.verificationCodeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(
                      hintText: '请输入验证码',
                      hintStyle: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20),
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
                          ? '获取验证码'
                          : '${controller.countdown.value}s',
                      style: TextStyle(
                        color: controller.canResend.value
                            ? const Color(0xFFFF69B4)
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
          height: 50,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/kissu_delete_btn_bg.webp"),
              fit: BoxFit.fill,
            ),
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
                    color: Color(0xffA29D9D),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
        ),
      ),
    );
  }
}
