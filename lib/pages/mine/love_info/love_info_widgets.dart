import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/dash_line_widget.dart';
import 'love_info_controller.dart';

// 信息项组件 - 性能优化版本
class InfoItem extends StatelessWidget {
  final String title;
  final String value;
  final bool hasImage;
  final bool showArrow;
  final bool isPartner;
  final String? imageUrl;
  final VoidCallback? onTap;

  const InfoItem({
    Key? key,
    required this.title,
    required this.value,
    this.hasImage = false,
    this.showArrow = false,
    this.isPartner = false,
    this.imageUrl,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
            Row(
              children: [
                if (hasImage)
                  _buildAvatar()
                else
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
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
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE8B4CB),
      ),
      child: ClipOval(
        child: imageUrl?.isNotEmpty == true
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    size: 20,
                    color: Colors.white,
                  );
                },
              )
            : const Icon(Icons.person, size: 20, color: Colors.white),
      ),
    );
  }
}

// 在一起天数卡片组件 - 性能优化版本
class TogetherCard extends StatelessWidget {
  final LoveInfoController controller;

  const TogetherCard({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        height: 83,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/kissu_loveinfo_day_bg.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/kissu_loveinfo_day_left.png',
              width: 32,
              height: 36,
            ),
            const SizedBox(width: 10),
            const Text(
              '在一起',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF333333),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            _buildDaysDisplay(),
            const SizedBox(width: 5),
            const Text(
              '天',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF333333),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Image.asset(
              'assets/kissu_loveinfo_day_right.png',
              width: 32,
              height: 36,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysDisplay() {
    final daysStr = controller.isBindPartner.value
        ? controller.loveDays.value.toString()
        : '-';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: daysStr.split("").map((d) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/kissu_loveinfo_num_bg.webp'),
              fit: BoxFit.cover,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            d,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF69B4),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// 相恋时间组件 - 性能优化版本
class LoveTimeSection extends StatelessWidget {
  final LoveInfoController controller;

  const LoveTimeSection({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xffFFD4D1)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '相恋时间',
              style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
           controller.isBindPartner.value ? Text(
              controller.loveTime.value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ) : Container(
              height: 4,
              width: 30,
              decoration: BoxDecoration(
                color: Color(0xffFFD4D1),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 我的信息组件 - 性能优化版本
class MyInfoSection extends StatelessWidget {
  final LoveInfoController controller;

  const MyInfoSection({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            image: AssetImage('assets/kissu_love_info_item_bg.webp'),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            InfoItem(
              title: '我的头像',
              value: '',
              hasImage: true,
              imageUrl: controller.myAvatar.value,
              onTap: () => controller.onAvatarTap(context),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DashedLine(),
            ),
            InfoItem(
              title: '我的昵称',
              value: controller.myNickname.value,
              onTap: () => controller.onNicknameTap(context),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DashedLine(),
            ),
            InfoItem(
              title: '性别',
              value: controller.myGender.value,
              onTap: () => controller.onGenderTap(context),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DashedLine(),
            ),
            InfoItem(
              title: '我的生日',
              value: controller.myBirthday.value,
              onTap: () => controller.onBirthdayTap(context),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DashedLine(),
            ),
            InfoItem(
              title: '我的手机号',
              value: controller.formatPhone(controller.myPhone.value),
              showArrow: true,
              onTap: () => controller.onPhoneTap(context),
            ),
          ],
        ),
      ),
    );
  }
}

// 伴侣信息组件 - 性能优化版本
class PartnerInfoSection extends StatelessWidget {
  final LoveInfoController controller;

  const PartnerInfoSection({Key? key, required this.controller})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            image: AssetImage('assets/kissu_love_info_item_bg.webp'),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            InfoItem(
              title: 'TA的头像',
              value: '',
              hasImage: true,
              isPartner: true,
              imageUrl: controller.partnerAvatar.value,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DashedLine(),
            ),
            InfoItem(
              title: 'TA的昵称',
              value: controller.partnerNickname.value.isEmpty
                  ? "未设置"
                  : controller.partnerNickname.value,
              isPartner: true,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DashedLine(),
            ),
            InfoItem(
              title: '性别',
              value: controller.partnerGender.value,
              isPartner: true,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DashedLine(),
            ),
            InfoItem(
              title: 'TA的生日',
              value: controller.partnerBirthday.value,
              isPartner: true,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DashedLine(),
            ),
            InfoItem(
              title: 'TA的手机号',
              value: controller.formatPhone(controller.partnerPhone.value),
              isPartner: true,
            ),
          ],
        ),
      ),
    );
  }
}

// 头像组件 - 性能优化版本
class AvatarSection extends StatelessWidget {
  final LoveInfoController controller;

  const AvatarSection({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isBindPartner.value) {
        // 已绑定 - 显示两个头像
        return Stack(
          alignment: AlignmentGeometry.bottomCenter,
          children: [_buildMyAvatar(), _buildPartnerAvatar()],
        );
      } else {
        // 未绑定 - 显示头像和加号
        return Stack(
          alignment: AlignmentGeometry.bottomCenter,
          children: [
            _buildMyAvatar(),
            // const SizedBox(width: 40),
            _buildAddButton(context),
          ],
        );
      }
    });
  }

  Widget _buildMyAvatar() {
    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/kissu_loveinfo_header_bg.webp'),
          fit: BoxFit.fill,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: ClipOval(
          child: controller.myAvatar.value.isNotEmpty
              ? Image.network(
                  controller.myAvatar.value,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        color: const Color(0xFFE8B4CB),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    );
                  },
                )
              : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: const Color(0xFFE8B4CB),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPartnerAvatar() {
    return Container(
      width: 50,
      height: 50,
      margin: EdgeInsets.only(left: 50),
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/kissu_loveinfo_header_bg.webp'),
          fit: BoxFit.fill,
        ),
      ),
      child: ClipOval(
        child: controller.partnerAvatar.value.isNotEmpty
            ? Image.network(
                controller.partnerAvatar.value,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: const Color(0xFFE8B4CB),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  );
                },
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: const Color(0xFFE8B4CB),
                ),
                child: const Icon(Icons.person, size: 40, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.showAddPartnerDialog(context),
      child: Container(
        width: 50,
        height: 50,margin: EdgeInsets.only(left: 50),
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
        child: const Icon(Icons.add, size: 30, color: Color(0xFFFF69B4)),
      ),
    );
  }
}
