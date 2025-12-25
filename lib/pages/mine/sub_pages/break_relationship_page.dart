import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'package:kissu_app/model/unbind_reason_model.dart';
import 'package:kissu_app/model/unbind_result.dart';
import 'package:kissu_app/widgets/dialogs/custom_feedback_dialog.dart';
import 'package:kissu_app/widgets/dialogs/dialog_manager.dart';
import 'package:kissu_app/widgets/common_back_button.dart';
import 'break_relationship_controller.dart';
import '../../../network/public/auth_api.dart';
import '../../../utils/user_manager.dart';
import '../../../services/relationship_animation_service.dart';
import '../../usage_report/usage_report_controller.dart';
import '../../home/home_controller.dart';
import '../mine_controller.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';

class BreakRelationshipPage extends StatefulWidget {
  const BreakRelationshipPage({super.key});

  @override
  State<BreakRelationshipPage> createState() => _BreakRelationshipPageState();
}

class _BreakRelationshipPageState extends State<BreakRelationshipPage> {
  late BreakRelationshipController controller;
  final RxBool isLoading = false.obs;
  final RxString loadingText = '解除中...'.obs;

  // 解绑须知文案常量，避免每次构建时重复创建列表
  static const List<String> _unbindNotices = [
    '清空188打卡记录',
    '清空双方聊天记录',
    '清空双方足迹记录',
    '会员权益（未购买方）失效',
    '清空双方用机记录（手机记录、App记录、敏感信息）', 
  ];

  @override
  void initState() {
    super.initState();
    controller = Get.put(BreakRelationshipController());
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f6),
      body: Stack(
        children: [
          // 背景图
          Positioned.fill(
            child: Image.asset(
              "assets/4.0/kissu4_breakship_bg.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
          child: Column(
            children: [
              // 自定义AppBar
              _buildCustomAppBar(),
              // 双人头像模块（与恋爱信息页面一致）
              _buildAvatarSection(),
              // 在一起天数卡片
              const SizedBox(height: 5),
              _buildTogetherCard(),
              // 页面内容
              Expanded(
                child: Transform.translate(offset: Offset(0, -10),child: Container(
                  padding: const EdgeInsets.all(20).copyWith(top: 0),
                        decoration: BoxDecoration(
                          color: Color(0xffF6F6F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                  child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(
                     
                    bottom: 20,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 15),

                      // 提示文字
                      _buildWarningText(),
                      const SizedBox(height: 15),

                      // 解除须知
                      _buildNoticeSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                ),
             ) ),
            ],
          ),
        ),

        // 底部解除关系按钮
        Positioned(
          left: 18,
          right: 18,
          bottom: bottomPadding + 30,
          child: _buildBreakButton(context),
        ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding:   EdgeInsets.fromLTRB(6, 12, 16, 16),
      child: Row(
        children: [
          CommonBackButton(
            onTap: () => Get.back(),
            assetPath: 'assets/images/kissu_mine_back.webp',
            iconSize: 24,
          ),
          const Expanded(
            child: Center(
              child: Text(
                '解除关系',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24), // 占位保持居中
        ],
      ),
    );
  }

  /// 构建双人头像模块（与恋爱信息页面一致）
  Widget _buildAvatarSection() {
    Widget buildDefaultAvatar(double radius) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: const Color(0xFFE8B4CB),
        ),
        child: Icon(Icons.person, size: radius, color: Colors.white),
      );
    }

    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 我的头像
          GestureDetector(
            onTap: () {
              // 解除关系页面不添加点击预览功能
            },
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
          // 另一半头像（必定有头像，不可能是添加按钮）
          Container(
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
              child: controller.partnerAvatar.value.isNotEmpty
                  ? controller.partnerAvatar.value
                              .startsWith('assets/')
                          ? Image.asset(
                              controller.partnerAvatar.value,
                              fit: BoxFit.cover,
                              errorBuilder: (
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
        ],
      );
    });
  }

  // Widget _buildAvatarSection() {
  //   return Container(
  //     height: 120,
  //     child: Center(
  //       child: _BreakAvatarSection(controller: controller),
  //     ),
  //   );
  // }

  Widget _buildTogetherCard() {
    return _BreakTogetherCard(controller: controller);
  }

  Widget _buildWarningText() {
    return const Text(
      '相爱不易，且行且珍惜，您确定解除关系吗？',
      style: TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500 ),
      textAlign: TextAlign.left,
    );
  }

  Widget _buildNoticeSection() {
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '解除须知',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          ..._buildNoticeItems(),
        ],
      ),
    );
  }

  List<Widget> _buildNoticeItems() {
    return List<Widget>.generate(_unbindNotices.length, (index) {
      final notice = _unbindNotices[index];

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}、',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notice,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBreakButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 30),
      child: ElevatedButton(
        onPressed: () async {
          final confirmResult =
              await DialogManager.showUnbindRelationshipDialog();
          if (confirmResult == true) {
            final feedbackResult = await _showUnbindRetentionDialog();
            if (feedbackResult != null) {
              await _handleBreakRelationship(
                reasonId: feedbackResult.reasonId,
                supplementReason: feedbackResult.supplementReason,
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFA9E0),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Text(
          '解除关系',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFFffffff),
          ),
        ),
      ),
    );
  }

  Future<UnbindResult?> _showUnbindRetentionDialog() async {
    try {
      final authApi = AuthApi();
      final result = await authApi.getUnbindReasons();

      final reasons = result.dataList ?? <UnbindReasonModel>[];
      if (!result.isSuccess || reasons.isEmpty) {
        CustomToast.show(Get.context!, result.msg ?? '获取解绑原因列表失败');
        return null;
      }

      return await CustomFeedbackDialogUtil.show(reasons: reasons);
    } catch (e) {
      CustomToast.show(Get.context!, '网络异常，请稍后重试');
      return null;
    }
  }

  Future<void> _handleBreakRelationship({
    required int reasonId,
    String? supplementReason,
  }) async {
    try {
      isLoading.value = true;
      loadingText.value = '解除中...';

      final authApi = AuthApi();
      final result = await authApi.unbindPartner(
        reasonId: reasonId,
        supplementReason: supplementReason,
      );

      if (result.isSuccess) {
        loadingText.value = '解除成功';

        // 刷新用户信息，确保数据同步
        await UserManager.refreshUserInfo();
        // 先刷新所有相关控制器的数据
        await _refreshAllControllers();

        // 播放解除绑定动画
        try {
          final animationService = RelationshipAnimationService.instance;
          animationService.showUnbindAnimation(
            onComplete: () {
              logDebug('🎯 解除绑定动画播放完成，返回到我的页面', tag: 'BreakRelationship');
              // 动画完成后依次关闭：动画 -> 解除关系页 -> 设置页，回到“我的”
              // 当前路由栈：我的 -> 设置(PrivacySettingPage) -> 解除关系(BreakRelationshipPage) -> 动画(overlay)
              // 1）关闭动画
              Get.back();
              // 2）关闭解除关系页
              if (Get.currentRoute != '/') {
                Get.back();
              }
              // 3）关闭设置页，回到“我的”
              if (Get.currentRoute != '/') {
                Get.back();
              }
            },
          );
        } catch (e) {
          logError('❌ 播放解除绑定动画失败: $e', tag: 'BreakRelationship', error: e);
          // 如果动画服务失败，直接返回
          Get.back();
          Get.back();
        }
      } else {
        CustomToast.show(Get.context!, result.msg ?? '解除关系失败');
      }
    } catch (e) {
      CustomToast.show(Get.context!, '网络异常，请重试');
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新所有相关控制器
  Future<void> _refreshAllControllers() async {
    // 给一点时间让UserManager的数据完全同步
    await Future.delayed(const Duration(milliseconds: 100));

    // 刷新首页绑定状态
    try {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.loadUserInfo();
        logDebug('✅ 已刷新首页绑定状态', tag: 'BreakRelationship');
      }
    } catch (e) {
      logError('❌ 刷新首页绑定状态失败: $e', tag: 'BreakRelationship', error: e);
    }

    // 刷新"我的"页面
    try {
      if (Get.isRegistered<MineController>()) {
        final mineController = Get.find<MineController>();
        // 先直接刷新界面绑定数据
        mineController.loadUserInfo();
        // 再执行原有的恢复逻辑（静默刷新、权限检查等）
        mineController.onPageResumed();
        logDebug('✅ 已刷新"我的"页面数据', tag: 'BreakRelationship');
      }
    } catch (e) {
      logError('❌ 刷新"我的"页面数据失败: $e', tag: 'BreakRelationship', error: e);
    }

    // 刷新用机记录页面（提前刷新）
    try {
      if (Get.isRegistered<UsageReportController>()) {
        final usageReportController = Get.find<UsageReportController>();
        usageReportController.loadData();
        logDebug('✅ 已刷新用机记录页面数据', tag: 'BreakRelationship');
      }
    } catch (e) {
      logError('❌ 刷新用机记录页面数据失败: $e', tag: 'BreakRelationship', error: e);
    }
  }
}

// 复用恋爱信息的头像组件，适配解除关系页面（已废弃，使用新的并排头像布局）
// class _BreakAvatarSection extends StatelessWidget {
//   final BreakRelationshipController controller;

//   const _BreakAvatarSection({required this.controller});

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       // if (controller.isBindPartner.value) {
//       //   // 已绑定 - 显示两个头像
//       //   return Stack(
//       //     alignment: AlignmentGeometry.bottomCenter,
//       //     children: [_buildMyAvatar(), _buildPartnerAvatar()],
//       //   );
//       // } else {
//       //   // 未绑定 - 只显示我的头像
//       //   return _buildMyAvatar();
//       // }
//       return Stack(
//         alignment: Alignment.bottomCenter,
//         children: [
//           _buildMyAvatar(),
//           _buildPartnerAvatar(),
//         ],
//       );
//     });
//   }

//   Widget _buildMyAvatar() {
//     return Container(
//       width: 80,
//       height: 80,
//       padding: const EdgeInsets.all(2),
//       decoration: const BoxDecoration(
//         image: DecorationImage(
//           image: AssetImage('assets/images/kissu_loveinfo_header_bg.webp'),
//           fit: BoxFit.fill,
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(3),
//         child: ClipOval(
//           child: controller.myAvatar.value.isNotEmpty
//               ? controller.myAvatar.value.startsWith('assets/')
//                     ? Image.asset(
//                         controller.myAvatar.value,
//                         width: 80,
//                         height: 80,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Container(
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(40),
//                               color: const Color(0xFFE8B4CB),
//                             ),
//                             child: const Icon(
//                               Icons.person,
//                               size: 40,
//                               color: Colors.white,
//                             ),
//                           );
//                         },
//                       )
//                     : NetworkImageHelper.loadImage(
//                         imageUrl: controller.myAvatar.value,
//                         width: 80,
//                         height: 80,
//                         fit: BoxFit.cover,
//                         errorWidget: Container(
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(40),
//                             color: const Color(0xFFE8B4CB),
//                           ),
//                           child: const Icon(
//                             Icons.person,
//                             size: 40,
//                             color: Colors.white,
//                           ),
//                         ),
//                       )
//               : Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(40),
//                     color: const Color(0xFFE8B4CB),
//                   ),
//                   child: const Icon(
//                     Icons.person,
//                     size: 40,
//                     color: Colors.white,
//                   ),
//                 ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPartnerAvatar() {
//     return Container(
//       width: 50,
//       height: 50,
//       margin: EdgeInsets.only(left: 50),
//       padding: const EdgeInsets.all(2),
//       decoration: const BoxDecoration(
//         image: DecorationImage(
//           image: AssetImage('assets/images/kissu_loveinfo_header_bg.webp'),
//           fit: BoxFit.fill,
//         ),
//       ),
//       child: ClipOval(
//         child: controller.partnerAvatar.value.isNotEmpty
//             ? controller.partnerAvatar.value.startsWith('assets/')
//                   ? Image.asset(
//                       controller.partnerAvatar.value,
//                       width: 50,
//                       height: 50,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) {
//                         return Container(
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(40),
//                             color: const Color(0xFFE8B4CB),
//                           ),
//                           child: const Icon(
//                             Icons.person,
//                             size: 40,
//                             color: Colors.white,
//                           ),
//                         );
//                       },
//                     )
//                   : NetworkImageHelper.loadImage(
//                       imageUrl: controller.partnerAvatar.value,
//                       width: 50,
//                       height: 50,
//                       fit: BoxFit.cover,
//                       errorWidget: Container(
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(40),
//                           color: const Color(0xFFE8B4CB),
//                         ),
//                         child: const Icon(
//                           Icons.person,
//                           size: 40,
//                           color: Colors.white,
//                         ),
//                       ),
//                     )
//             : Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(40),
//                   color: const Color(0xFFE8B4CB),
//                 ),
//                 child: const Icon(Icons.person, size: 40, color: Colors.white),
//               ),
//       ),
//     );
//   }
// }

// 复用恋爱信息的在一起天数卡片，适配解除关系页面
class _BreakTogetherCard extends StatelessWidget {
  final BreakRelationshipController controller;

  const _BreakTogetherCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        height: 83,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
         
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             
            const Text(
              '已在一起',
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
            
          ],
        ),
      ),
    );
  }

  Widget _buildDaysDisplay() {
    final daysStr = controller.isBindPartner.value
        ? controller.loveDays.value.toString()
        : '-';

    // 计算数字位数，根据位数调整字体大小和容器大小
    final digitCount = daysStr.length;
    double fontSize = 20.0; // 基础字体大小（1-3位数字）
    double containerSize = 30.0; // 基础容器大小
    double horizontalMargin = 2.0; // 基础间距

    // 根据数字位数逐步缩小
    if (digitCount >= 6) {
      // 6位数字及以上，最小
      fontSize = 12.0;
      containerSize = 20.0;
      horizontalMargin = 0.8;
    } else if (digitCount >= 5) {
      // 5位数字，较小
      fontSize = 14.0;
      containerSize = 22.0;
      horizontalMargin = 1.0;
    } else if (digitCount >= 4) {
      // 4位数字，进一步缩小以防溢出
      fontSize = 15.0;
      containerSize = 22.0;
      horizontalMargin = 1.0;
    } else if (digitCount >= 3) {
      // 3位数字，基础大小
      fontSize = 18.0;
      containerSize = 26.0;
      horizontalMargin = 1.5;
    }

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: daysStr.split("").map((d) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
            width: containerSize,
            height: containerSize,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/kissu_loveinfo_num_bg.webp'),
                fit: BoxFit.cover,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              d,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF69B4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
