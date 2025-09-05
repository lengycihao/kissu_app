import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/dialogs/dialog_manager.dart';

class LoveInfoController extends GetxController {
  // 绑定状态
  var isBindPartner = false.obs; // 改为false可以看到未绑定状态

  // 显示添加伴侣对话框
  void showAddPartnerDialog(BuildContext context) {
    DialogManager.showGenderSelect(
  context: context,
  selectedGender: '男生',
);
 
  }
}

// 信息项组件
class InfoItem extends StatelessWidget {
  final String title;
  final String value;
  final bool hasImage;
  final bool showArrow;
  final bool isPartner;

  const InfoItem({
    Key? key,
    required this.title,
    required this.value,
    this.hasImage = false,
    this.showArrow = false,
    this.isPartner = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF333333),
            ),
          ),
          Row(
            children: [
              if (hasImage)
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE8B4CB),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 20,
                    color: Colors.white,
                  ),
                )
              else
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: value.contains('未') || value.contains('输入')
                        ? const Color(0xFF999999)
                        : const Color(0xFF666666),
                  ),
                ),
              if (showArrow || (!isPartner && !hasImage)) ...[
                const SizedBox(width: 5),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF999999),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// 在一起天数卡片组件
class TogetherCard extends StatelessWidget {
  final LoveInfoController controller;

  const TogetherCard({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE4E8), Color(0xFFFFF0F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB6C1), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite,
            color: Color(0xFFFF69B4),
            size: 20,
          ),
          const SizedBox(width: 10),
          const Text(
            '在一起',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            controller.isBindPartner.value ? '6' : '-',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF69B4),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            '天',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.favorite,
            color: Color(0xFFFF69B4),
            size: 20,
          ),
        ],
      ),
    ));
  }
}

// 相恋时间组件
class LoveTimeSection extends StatelessWidget {
  const LoveTimeSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '相恋时间',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF333333),
            ),
          ),
          Row(
            children: [
              const Text(
                '2025.02.02',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF999999),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 我的信息组件
class MyInfoSection extends StatelessWidget {
  const MyInfoSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InfoItem(title: '我的头像', value: '', hasImage: true),
          InfoItem(title: '我的昵称', value: '输入昵称'),
          InfoItem(title: '性别', value: '未选择'),
          InfoItem(title: '我的生日', value: '未选择'),
          InfoItem(title: '我的手机号', value: '142****5214', showArrow: true),
        ],
      ),
    );
  }
}

// 伴侣信息组件
class PartnerInfoSection extends StatelessWidget {
  const PartnerInfoSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InfoItem(title: 'TA的头像', value: '', hasImage: true, isPartner: true),
          InfoItem(title: 'TA的昵称', value: 'kisuu炎炎', isPartner: true),
          InfoItem(title: '性别', value: '男', isPartner: true),
          InfoItem(title: 'TA的生日', value: '2022.02.02', isPartner: true),
          InfoItem(title: 'TA的手机号', value: '142****5214', isPartner: true),
        ],
      ),
    );
  }
}

class LoveInfoPage extends StatelessWidget {
  const LoveInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoveInfoController());
    return Obx(() => Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F4F0),
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
              'assets/kissu_mine_back.webp',
              width: 24,
              height: 24,
            ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          '恋爱信息',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 头像部分
            AvatarSection(controller: controller),
            const SizedBox(height: 30),

            // 在一起天数卡片
            TogetherCard(controller: controller),
            const SizedBox(height: 20),

            // 相恋时间
            if (controller.isBindPartner.value) LoveTimeSection(),
            if (controller.isBindPartner.value) const SizedBox(height: 20),

            // 我的信息
            MyInfoSection(),
            const SizedBox(height: 20),

            // TA的信息（仅在绑定状态显示）
            if (controller.isBindPartner.value) PartnerInfoSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ));
  }







}

// 头像组件
class AvatarSection extends StatelessWidget {
  final LoveInfoController controller;

  const AvatarSection({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isBindPartner.value) {
        // 已绑定状态：显示两个头像
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 左侧头像（我的）
            _buildAvatar(),
            const SizedBox(width: 40),
            // 右侧头像（TA的）
            _buildPartnerAvatar(),
          ],
        );
      } else {
        // 未绑定状态：显示一个头像和加号
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 我的头像
            _buildAvatar(),
            const SizedBox(width: 40),
            // 加号按钮
            GestureDetector(
              onTap: () => controller.showAddPartnerDialog(context),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFFFB6C1), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  size: 30,
                  color: Color(0xFFFF69B4),
                ),
              ),
            ),
          ],
        );
      }
    });
  }

  Widget _buildAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          color: const Color(0xFFE8B4CB),
          child: const Icon(
            Icons.person,
            size: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          color: const Color(0xFFE8B4CB),
          child: const Icon(
            Icons.person,
            size: 30,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}