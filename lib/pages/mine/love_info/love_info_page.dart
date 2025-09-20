import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'love_info_controller.dart';
import 'love_info_widgets.dart';

class LoveInfoPage extends StatelessWidget {
  const LoveInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoveInfoController());

    return Obx(
      () => Stack(
        children: [
          // 背景图层
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/kissu_mine_bg.webp"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
                children: [
                  // 自定义标题栏
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              'assets/kissu_mine_back.webp',
                              width: 24,
                              height: 24,
                            ),
                          ),
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
                  // 页面内容
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Column(
                            children: [
                              // 头像部分
                              const SizedBox(height: 60),

                              // 在一起天数卡片
                              TogetherCard(controller: controller),
                              const SizedBox(height: 20),

                              // 相恋时间
                              LoveTimeSection(controller: controller),
                              const SizedBox(height: 20),

                              // 我的信息
                              MyInfoSection(controller: controller),
                              const SizedBox(height: 20),

                              // TA的信息（仅在绑定状态显示）
                              if (controller.isBindPartner.value) ...[
                                PartnerInfoSection(controller: controller),
                                const SizedBox(height: 20),
                              ],
                            ],
                          ),
                          Obx(
                            () => Stack(
                              children: [
                                // 我的头像
                                Container(
                                  width: 80,
                                  height: 80,
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage(
                                        'assets/kissu_loveinfo_header_bg.webp',
                                      ),
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: 6,
                                      top: 6,
                                      right: 0,
                                      bottom: 3,
                                    ),
                                    child: ClipOval(
                                      child:
                                          controller.myAvatar.value.isNotEmpty
                                          ? Image.network(
                                              controller.myAvatar.value,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              40,
                                                            ),
                                                        color: const Color(
                                                          0xFFE8B4CB,
                                                        ),
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
                                                borderRadius:
                                                    BorderRadius.circular(40),
                                                color: const Color(
                                                  0xFFE8B4CB,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.person,
                                                size: 40,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                // 另一半头像或添加按钮
                                controller.isBindPartner.value
                                    ? Container(
                                        width: 50,
                                        height: 50,
                                        margin: EdgeInsets.only(left: 60, top: 20),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                            color: const Color(0xFFFFB6C1),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: controller.partnerAvatar.value.isNotEmpty
                                              ? Image.network(
                                                  controller.partnerAvatar.value,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(25),
                                                        color: const Color(0xFFE8B4CB),
                                                      ),
                                                      child: const Icon(
                                                        Icons.person,
                                                        size: 25,
                                                        color: Colors.white,
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(25),
                                                    color: const Color(0xFFE8B4CB),
                                                  ),
                                                  child: const Icon(
                                                    Icons.person,
                                                    size: 25,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      )
                                    : GestureDetector(
                                        onTap: () => controller.showAddPartnerDialog(context),
                                        child: Container(
                                          width: 50,
                                          height: 50,
                                          margin: EdgeInsets.only(left: 60, top: 20),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                            border: Border.all(
                                              color: const Color(0xFFFFB6C1),
                                              width: 1,
                                            ),
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
                                Positioned(
                                  right: 30,
                                  top: 40,
                                  child: Image(
                                    image: AssetImage(
                                      "assets/kissu_heart.webp",
                                    ),
                                    width: 29,
                                    height: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
  //         image: AssetImage('assets/kissu_loveinfo_header_bg.webp'),
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
