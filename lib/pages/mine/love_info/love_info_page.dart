import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'package:kissu_app/widgets/common_back_button.dart';

import 'love_info_controller.dart';
import 'love_info_widgets.dart';

class LoveInfoPage extends StatelessWidget {
  const LoveInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoveInfoController(), permanent: true);

    Widget buildDefaultAvatar(double radius) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: const Color(0xFFE8B4CB),
        ),
        child: Icon(Icons.person, size: radius, color: Colors.white),
      );
    }

    return Obx(
      () => Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: Stack(
          children: [
            // 背景图层
            Positioned.fill(
              child: Image.asset(
                "assets/images/kissu_info_bg.webp",
                fit: BoxFit.fitWidth,
                height: 260,
                alignment: Alignment.topCenter,
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // 自定义标题栏
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        CommonBackButton(
                          onTap: () => Get.back(),
                          assetPath: 'assets/images/kissu_mine_back.webp',
                          iconSize: 22,
                        ),
                        Expanded(
                          child: Center(
                            child: const Text(
                              '恋爱信息',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        // 占位符保持标题居中
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 我的头像 - 添加预览功能
                      GestureDetector(
                        onTap: () => controller.onMyAvatarPreview(context),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              width: 2,
                              color: Color(0xffFEB5E4),
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ClipOval(
                            child: controller.myAvatar.value.isNotEmpty
                                ? controller.myAvatar.value.startsWith(
                                        'assets/',
                                      )
                                      ? Image.asset(
                                          controller.myAvatar.value,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return buildDefaultAvatar(40);
                                              },
                                        )
                                      : NetworkImageHelper.loadImage(
                                          imageUrl: controller.myAvatar.value,
                                          fit: BoxFit.cover,
                                          errorWidget: buildDefaultAvatar(40),
                                        )
                                : buildDefaultAvatar(40),
                          ),
                        ),
                      ),
                      // 另一半头像或添加按钮
                      controller.isBindPartner.value
                          ? GestureDetector(
                              onTap: () =>
                                  controller.onPartnerAvatarPreview(context),
                              child: Container(
                                width: 60,
                                height: 60,

                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xffFEB5E4),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child:
                                      controller.partnerAvatar.value.isNotEmpty
                                      ? controller.partnerAvatar.value
                                                .startsWith('assets/')
                                            ? Image.asset(
                                                controller.partnerAvatar.value,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return buildDefaultAvatar(
                                                        25,
                                                      );
                                                    },
                                              )
                                            : NetworkImageHelper.loadImage(
                                                imageUrl: controller
                                                    .partnerAvatar
                                                    .value,
                                                fit: BoxFit.cover,
                                                errorWidget: buildDefaultAvatar(
                                                  25,
                                                ),
                                              )
                                      : buildDefaultAvatar(25),
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: () =>
                                  controller.showAddPartnerDialog(context),
                              child: Container(
                                width: 60,
                                height: 60,

                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xffFEB5E4),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 30,
                                  color: Color(0xFFFF69B4),
                                ),
                              ),
                            ),
                    ],
                  ),
                  // 在一起天数卡片
                  const SizedBox(height: 5),
                  TogetherCard(controller: controller),
                  // 页面内容
                  Expanded(
                    child: Container(
                        padding: const EdgeInsets.all(20).copyWith(top: 15),
                        decoration: BoxDecoration(
                          color: Color(0xffF6F6F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(physics: const BouncingScrollPhysics(),
                          child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Column(
                              children: [
                                const SizedBox(height: 10),
                                // 相恋时间
                                LoveTimeSection(controller: controller),
                                const SizedBox(height: 14),

                                // 我的信息
                                MyInfoSection(controller: controller),
                                const SizedBox(height: 14),

                                // TA的信息（仅在绑定状态显示）
                                if (controller.isBindPartner.value) ...[
                                  PartnerInfoSection(controller: controller),
                                  const SizedBox(height: 14),
                                ],
                              ],
                            ),
                            Stack(children: [
                             
                            ],
                          ),
                          ],
                        ),
                     
                        ) ),
                   
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //  Widget _buildAvatar() {
  //   return Container(
  //     width: 80,
  //     height: 80,
  //     padding: const EdgeInsets.all(2),
  //     decoration: const BoxDecoration(
  //       image: DecorationImage(
  //         image: AssetImage('assets/images/kissu_loveinfo_header_bg.webp'),
  //         fit: BoxFit.fill,
  //       ),
  //     ),
  //     child: Padding(
  //       padding: EdgeInsets.only(left: 6, top: 6, right: 0, bottom: 3),
  //       child: ClipOval(
  //         child: controller.userAvatar.value.isNotEmpty
  //             ? Image.network(
  //                 controller.userAvatar.value,
  //                 fit: BoxFit.cover,
  //                 errorBuilder: (context, error, stackTrace) {
  //                   return Container(
  //                     decoration: BoxDecoration(
  //                       borderRadius: BorderRadius.circular(40),
  //                       color: const Color(0xFFE8B4CB),
  //                     ),
  //                     child: const Icon(
  //                       Icons.person,
  //                       size: 40,
  //                       color: Colors.white,
  //                     ),
  //                   );
  //                 },
  //               )
  //             : Container(
  //                 decoration: BoxDecoration(
  //                   borderRadius: BorderRadius.circular(40),
  //                   color: const Color(0xFFE8B4CB),
  //                 ),
  //                 child: const Icon(
  //                   Icons.person,
  //                   size: 40,
  //                   color: Colors.white,
  //                 ),
  //               ),
  //       ),
  //     ),
  //   );
  // }
}
