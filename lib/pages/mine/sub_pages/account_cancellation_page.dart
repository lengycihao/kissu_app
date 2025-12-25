import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'account_cancellation_controller.dart';

class AccountCancellationPage extends StatelessWidget {
  AccountCancellationPage({Key? key}) : super(key: key);

  final controller = Get.put(AccountCancellationController());

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
              children: [
                // 顶部导航栏
                _buildAppBar(),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // 用户信息卡片
                        _buildUserInfoCard(),

                        const SizedBox(height: 30),

                        // 注销须知
                        _buildCancellationNotice(),

                        const SizedBox(height: 100), // 增加底部间距，为底部按钮留空间
                      ],
                    ),
                  ),
                ),

                // 底部注销按钮
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 30),
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

  // 用户信息卡片
  Widget _buildUserInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),

      child: Column(
        children: [
          // 头像
          _buildMyAvatar(),

          const SizedBox(height: 10),

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
          const SizedBox(height: 10),
          Text(
            "在开始注销前，请确认以下内容",
            style: const TextStyle(fontSize: 12, color: Color(0xFF777777)),
          ),
        ],
      ),
    );
  }

  // 注销须知
  Widget _buildCancellationNotice() {
    return Container(
 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xffFF9AD9),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: 6,),
              const Text(
                '注销须知',
                style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '    在注销账户前，请仔细阅读APP的隐私政策，了解个人信息的使用规则和授权情况。',
            style: TextStyle(fontSize: 12, color: Color(0xFF777777)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xffFF9AD9),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: 6,),
              const Text(
                '授权自动终止',
                style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '    注销账户将撤销您在服务生命周期中的各种业务授权。',
            style: TextStyle(fontSize: 12, color: Color(0xFF777777)),
          ),
        ],
      ),
    );
  }

  Widget _buildMyAvatar() {
    return ClipOval(
      child: controller.userAvatar.value.isNotEmpty
          ? NetworkImageHelper.loadImage(
              imageUrl: controller.userAvatar.value,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorWidget: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: const Color(0xFFE8B4CB),
                ),
                child: const Icon(Icons.person, size: 40, color: Colors.white),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: const Color(0xFFE8B4CB),
              ),
              child: const Icon(Icons.person, size: 40, color: Colors.white),
            ),
    );
  }

  // 注销按钮
  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: controller.navigateToPhoneVerification,
      child: Container(
        height: 44,
        margin: EdgeInsets.zero, // 移除边距，由外部Container控制
        decoration: BoxDecoration(
          color: const Color(0xFFFFA9E0),
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: const Text(
          '注销',
          style: TextStyle(
            color: Color(0xffffffff),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
