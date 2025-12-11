import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/common_back_button.dart';
import 'package:kissu_app/widgets/dialogs/system_permission_complete_dialog.dart';
import 'system_permission_controller.dart';

class SystemPermissionGuidePage extends GetView<SystemPermissionController> {
  final SystemPermissionGuideType guideType;
  final String title;

  const SystemPermissionGuidePage({
    super.key,
    required this.guideType,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _showCompleteConfirmDialog(context);
        // 由弹窗中确认后手动返回
        return false;
      },
      child: Obx(() {
        final imageAsset = controller.getGuideAsset(guideType);

        return Scaffold(
          backgroundColor: const Color(0xFFffffff),
          body: Stack(
            children: [
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
                    _buildTopBar(context),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: ClipRRect(
                          child: Container(
                            padding: const EdgeInsets.only(top: 16),
                            decoration:
                                const BoxDecoration(color: Colors.white),
                            child: Scrollbar(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Image.asset(
                                  imageAsset,
                                  fit: BoxFit.fitWidth,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// 底部按钮区域：根据不同指引类型和完成状态切换文案
  Widget _buildActionButtons(BuildContext context) {
    // “让程序锁在后台”：只有一个“完成”按钮
    if (guideType == SystemPermissionGuideType.lockInBackground) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
        child: _buildBottomButton(
          text: '完成',
          color: Colors.black,
          onTap: () => _showCompleteConfirmDialog(context),
        ),
      );
    }

    final bool hasCompleted = controller.isGuideCompleted(guideType);
    final bool openedThisSession =
        controller.isGuideOpenedThisSession(guideType);
    final bool showTwoButtons = hasCompleted || openedThisSession;

    // 首次进入且未完成：只显示“去设置”
    if (!showTwoButtons) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
        child: _buildBottomButton(
          text: '去设置',
          color: Colors.black,
          onTap: _handleGoSettings,
        ),
      );
    }

    // 返回后或已完成：显示“再次设置 / 完成”
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
      child: Row(
        children: [
          Expanded(
            child: _buildBottomButton(
              text: '再次设置',
              color: const Color(0xffFF83C4),
              onTap: _handleGoSettings,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildBottomButton(
              text: '完成',
              color: Colors.black,
              onTap: () => _showCompleteConfirmDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Row(
        children: [
          CommonBackButton(
            onTap: () => _showCompleteConfirmDialog(context),
            assetPath: "assets/images/kissu_mine_back.webp",
            iconSize: 22,
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          const SizedBox(width: 22),
        ],
      ),
    );
  }

  void _handleGoSettings() {
    controller.markGuideOpenedThisSession(guideType);
    controller.openGuideSetting(guideType);
  }

  Future<void> _showCompleteConfirmDialog(BuildContext context) async {
    await SystemPermissionCompleteDialog.show(
      onConfirm: () async {
        await controller.markGuideCompleted(guideType);
        Get.back();
      },
      onCancel: () {
        // 点错了：关闭弹窗并返回上一页
        Get.back();
      },
    );
  }
}
