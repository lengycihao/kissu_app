import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'package:kissu_app/model/unbind_reason_model.dart';
import 'package:kissu_app/model/unbind_result.dart';
import 'package:kissu_app/widgets/dialogs/custom_feedback_dialog.dart';
import 'package:kissu_app/widgets/dialogs/dialog_manager.dart';
import 'break_relationship_controller.dart';
import '../../../network/public/auth_api.dart';
import '../../../utils/user_manager.dart';
import '../../../services/relationship_animation_service.dart';
import '../../usage_report/usage_report_controller.dart';
import '../../home/home_controller.dart';
import '../mine_controller.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';

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
    '清空双方聊天记录',
    '清空双方足迹记录',
    '会员权益（未购买方）失效',
    '清空双方用机记录（手机记录、App记录、敏感信息）',
    // '「188打卡活动」仅对本次配对中有效，解除关系后双方将失去参与「188打卡活动」资格，同时会清空188打卡记录'
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
              "assets/images/kissu_info_bg.webp",
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
                  child: Transform.translate(
                    offset: Offset(0, -10),
                    child: Container(
                      padding: const EdgeInsets.all(20).copyWith(top: 0),
                      decoration: BoxDecoration(
                        color: Color(0xffF6F6F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.only(bottom: 20),
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
                  ),
                ),
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
//解除关系页面的自定义AppBar
  Widget _buildCustomAppBar() {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          // 返回按钮
          Positioned(
            left: 5,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/kissu_mine_back.webp',
                  width: 22,
                  height: 22,
                ),
              ),
            ),
          ),
          // 标题 - 绝对居中
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
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
        mainAxisAlignment: MainAxisAlignment.center,
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
                border: Border.all(width: 2, color: Color(0xffFEB5E4)),
                borderRadius: BorderRadius.circular(30),
              ),
              child: ClipOval(
                child: controller.myAvatar.value.isNotEmpty
                    ? controller.myAvatar.value.startsWith('assets/')
                          ? Image.asset(
                              controller.myAvatar.value,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
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
          Image(
            image: AssetImage("assets/images/kissu_mine_heart_un.webp"),
            width: 110,
            height: 110,
          ),
          // 另一半头像（必定有头像，不可能是添加按钮）
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xffFEB5E4), width: 2),
            ),
            child: ClipOval(
              child: controller.partnerAvatar.value.isNotEmpty
                  ? controller.partnerAvatar.value.startsWith('assets/')
                        ? Image.asset(
                            controller.partnerAvatar.value,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return buildDefaultAvatar(25);
                            },
                          )
                        : NetworkImageHelper.loadImage(
                            imageUrl: controller.partnerAvatar.value,
                            fit: BoxFit.cover,
                            errorWidget: buildDefaultAvatar(25),
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
      style: TextStyle(
        fontSize: 14,
        color: Color(0xFF333333),
        fontWeight: FontWeight.w500,
      ),
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
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
            // const SizedBox(width: 8),
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
          // 埋点：解除关系页面确认按钮点击
          AnalyticsHelper.trackUnbindBtn();
          
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
          // 动画服务内部会自动返回到根路由
          animationService.showUnbindAnimation();
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

// 复用恋爱信息的在一起天数卡片，适配解除关系页面
class _BreakTogetherCard extends StatelessWidget {
  final BreakRelationshipController controller;

  const _BreakTogetherCard({required this.controller});

  @override
  
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        // height: 60,
        padding: const EdgeInsets.symmetric( horizontal: 30).copyWith(bottom: 20),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '已在一起',
              style: TextStyle(
                fontSize: 15,
                fontFamily: "Resource-Han-Rounded",
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
                fontFamily: "Resource-Han-Rounded",
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

    // 参考恋爱信息页面的数字设置
    double fontSize = 20.0; // 基础字体大小（1-3位数字）
    double containerSize = 28.0; // 基础容器大小
    double horizontalMargin = 3.0; // 基础间距

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: daysStr.split("").map((d) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
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
