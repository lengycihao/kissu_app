import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'account_cancellation_controller.dart';

class AccountCancellationPage extends StatelessWidget {
  AccountCancellationPage({Key? key}) : super(key: key);

  final controller = Get.put(AccountCancellationController());

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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // 用户信息卡片
                    _buildUserInfoCard(),

                    const SizedBox(height: 30),

                    // 注销须知
                    _buildCancellationNotice(),

                    const SizedBox(height: 60),

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

  // 用户信息卡片
  Widget _buildUserInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/kissu_accout_info_bg.webp'),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // 头像
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(controller.userAvatar.value),
                fit: BoxFit.fill,
              ),

              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.black.withOpacity(0.1),
              //     blurRadius: 10,
              //     offset: const Offset(0, 5),
              //   ),
              // ],
            ),
          ),

          const SizedBox(height: 15),

          // 昵称
          Obx(
            () => Text(
              controller.userName.value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 注销须知
  Widget _buildCancellationNotice() {
    return Container(
     padding: const EdgeInsets.all(15),
     decoration: BoxDecoration(
       color: Colors.white.withOpacity(0.8),
       borderRadius: BorderRadius.circular(12),
     ),
     child: Column(crossAxisAlignment: CrossAxisAlignment.center,
       children: [
         const Text(
           '注销须知',
           style: TextStyle(
             fontSize: 14,
             fontWeight: FontWeight.w500,
             color: Color(0xFF333333),
           ),
         ),const SizedBox(height: 15),
         const Text(
           '在注销账户前，请仔细阅读APP的隐私政策，了解个人信息的使用规则和授权情况。注销账户将撤销您在服务生命周期中的各种业务授权。',
           style: TextStyle(
             fontSize: 13,
             color: Color(0xFF333333),
             height: 1.6,
           ),
         ),
       ],
     ),
            );
  }

  // 注销按钮
  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: controller.navigateToPhoneVerification,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE9E9),
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: const Text(
          '注销',
          style: TextStyle(
            color: Color(0xff333333),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
