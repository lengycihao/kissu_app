import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
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
              style: const TextStyle(fontSize: 12, color: Color(0xFF333333),fontWeight: FontWeight.w500),
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
                          : const Color(0xFF333333),
                    ),
                  ),
                if (showArrow || (!isPartner && !hasImage)) ...[
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF777777),
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
            ? imageUrl!.startsWith('assets/')
                ? Image.asset(
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
                : NetworkImageHelper.loadImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: const Icon(
                      Icons.person,
                      size: 20,
                      color: Colors.white,
                    ),
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
      () => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.9 + (0.1 * value),
              child: child,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          height: 83,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
          
        //相爱信息ROW
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             
            const Text(
              '在一起',
              style: TextStyle(
                fontSize: 20,
                fontFamily: "Resource-Han-Rounded",
                color: Color(0xFF333333),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            _buildDaysDisplay(),
            const SizedBox(width: 12),
            const Text(
              '天',
              style: TextStyle(
                fontSize: 20, fontFamily: "Resource-Han-Rounded",
                color: Color(0xFF333333),
                // fontWeight: FontWeight.w600,
              ),
            ),
            
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildDaysDisplay() {
    final daysStr = controller.isBindPartner.value
        ? controller.loveDays.value.toString()
        : '-';

    // 计算数字位数，根据位数调整字体大小和容器大小
     double fontSize = 20.0;  // 基础字体大小（1-3位数字）
    double containerSize = 28.0;  // 基础容器大小
    double horizontalMargin = 3.0;  // 基础间距
 

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: daysStr.split("").map((d) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: horizontalMargin,),
        
            width: containerSize,
            height: containerSize,
            decoration:   BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(4)
            ),
            alignment: Alignment.center,
            child: Text(
              d,
              style: TextStyle(
                fontSize: fontSize,
                fontFamily: "Resource-Han-Rounded",
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF8AFA),
              ),
            ),
          );
        }).toList(),
      ),
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
      () => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: controller.isBindPartner.value 
              ? () => controller.onLoveTimeTap(context)
              : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
             
              borderRadius: BorderRadius.circular(12),
              
            ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '相恋时间',
                style: TextStyle(fontSize: 14, color: Color(0xFF333333),fontWeight: FontWeight.w500),
              ),
              controller.isBindPartner.value
                  ? Row(
                      children: [
                        Text(
                          controller.loveTime.value,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Color(0xFF777777),
                        ),
                      ],
                    )
                  : Container(
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
      () => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14).copyWith(left: 10,right: 10,bottom: 4),
          decoration: BoxDecoration(
            color: Colors.white,
             
            borderRadius: BorderRadius.circular(12),
             
          ),
        child: Column(
          children: [
            InfoItem(
              title: '我的头像',
              value: '',
              hasImage: true,
              showArrow: true,
              imageUrl: controller.myAvatar.value,
              onTap: () => controller.onAvatarTap(context),
            ),
            InfoItemLine(),
            InfoItem(
              title: '我的昵称',
              value: controller.myNickname.value,
              onTap: () => controller.onNicknameTap(context),
            ),
            InfoItemLine(),
            InfoItem(
              title: '性别',
              value: controller.myGender.value,
              onTap: () => controller.onGenderTap(context),
            ),
            InfoItemLine(),
            InfoItem(
              title: '我的生日',
              value: controller.myBirthday.value,
              onTap: () => controller.onBirthdayTap(context),
            ),
            InfoItemLine(),
            InfoItem(
              title: '我的手机号',
              value: controller.formatPhone(controller.myPhone.value),
              showArrow: true,
              onTap: () => controller.onPhoneTap(context),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class InfoItemLine extends StatelessWidget {
  const InfoItemLine({super.key});

  @override
  Widget build(BuildContext context) {
    return  Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                height: 0.5,
                color: const Color(0xFFE8E8E8),
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
      () => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 40 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14).copyWith(left: 10,right: 10,bottom: 0),
          decoration: BoxDecoration(
            color: Colors.white,
             
            borderRadius: BorderRadius.circular(12),
            
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
            InfoItemLine(),
            InfoItem(
              title: 'TA的昵称',
              value: controller.partnerNickname.value.isEmpty
                  ? "未设置"
                  : controller.partnerNickname.value,
              isPartner: true,
            ),
           InfoItemLine(),
            InfoItem(
              title: '性别',
              value: controller.partnerGender.value,
              isPartner: true,
            ),
           InfoItemLine(),
            InfoItem(
              title: 'TA的生日',
              value: controller.partnerBirthday.value,
              isPartner: true,
            ),
            InfoItemLine(),
            InfoItem(
              title: 'TA的手机号',
              value: controller.formatPhone(controller.partnerPhone.value),
              isPartner: true,
            ),
          ],
        ),
        ),
      ),
    );
  }
  
}

 
