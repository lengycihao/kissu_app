import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'usage_settings_controller.dart';
import 'package:kissu_app/widgets/dialogs/location_state_delete_dialog.dart';

class UsageSettingsPage extends StatelessWidget {
  const UsageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UsageSettingsController());
    
    // 设置返回确认弹窗的回调
    controller.onShowBackDialog = () => _showBackConfirmDialog(context, controller);
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          controller.handleBack();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(child: _buildMainContent(controller)),
          ],
        ),
      ),
    );
  }

  // 背景图
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/phone_history/kissu3_phone_history_bg.webp'),
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  // 主内容
  Widget _buildMainContent(UsageSettingsController controller) {
    return Column(
      children: [
        _buildHeader(controller),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1.通知提示设置
                // _buildSectionTitle('1.通知提示设置'),
                // const SizedBox(height: 16),
                // _buildNotificationTypeSection(controller),
                
                // const SizedBox(height: 32),
                
                // 2.手机状态消息
                _buildSectionTitle('手机状态消息'),
                const SizedBox(height: 16),
                _buildPhoneStatusSection(controller),
                
                const SizedBox(height: 100), // 为底部保存按钮留出空间
              ],
            ),
          ),
        ),
        
        // 保存按钮区域
        _buildSaveButtonArea(controller),
      ],
    );
  }

  // 构建头部
  Widget _buildHeader(UsageSettingsController controller) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              controller.handleBack();
            },
            child: Image.asset(
              'assets/images/kissu_mine_back.webp',
              width: 24,
              height: 24,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '用机设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24), // 占位，保持标题居中
        ],
      ),
    );
  }

  /// 构建章节标题
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF333333),
      ),
    );
  }



  /// 构建手机状态消息区域
  Widget _buildPhoneStatusSection(UsageSettingsController controller) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 16, bottom: 30),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(9),
         
      // ),
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF87D1),
            ),
          );
        }

        if (controller.tempNotificationList.isEmpty) {
          return const Center(
            child: Text(
              '暂无通知设置',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
          );
        }

        // 动态构建两列布局
        final items = controller.tempNotificationList;
        final leftItems = <Widget>[];
        final rightItems = <Widget>[];

        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          final switchWidget = _buildDynamicSwitchItem(
            item.title,
            item.checked,
            () => controller.toggleNotification(i),
          );

          if (i % 2 == 0) {
            leftItems.add(switchWidget);
          } else {
            rightItems.add(switchWidget);
          }
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: leftItems,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: rightItems,
              ),
            ),
          ],
        );
      }),
    );
  }


  /// 构建动态开关选项
  Widget _buildDynamicSwitchItem(
    String title,
    bool isChecked,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isChecked ? const Color(0xFFFF9AD8) : Colors.transparent,
                border: Border.all(
                  color: const Color(0xFFFF9AD8),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isChecked
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建保存按钮区域
  Widget _buildSaveButtonArea(UsageSettingsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SafeArea(
        child: Obx(() {
          final hasChanges = controller.hasUnsavedChanges;
          final isSaving = controller.isSaving.value;
          
          return Row(
            children: [
              // 重置按钮
              if (hasChanges)
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: isSaving ? null : controller.resetSettings,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF87D1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        '重置',
                        style: TextStyle(
                          color: Color(0xFFFF87D1),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              
              // 保存按钮
              Expanded(
                flex: hasChanges ? 2 : 1,
                child: Container(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: (hasChanges && !isSaving) ? controller.saveSettings : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasChanges ? const Color(0xFFFF87D1) : const Color(0xFFE0E0E0),
                      foregroundColor: hasChanges ? Colors.white : const Color(0xFF999999),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      elevation: 0,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            hasChanges ? '保存设置' : '暂无更改',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
  
  /// 显示返回确认弹窗
  void _showBackConfirmDialog(BuildContext context, UsageSettingsController controller) {
    LocationStateDeleteDialog.show(
      context: context,
      title: '确定要放弃当前更改吗？',
      onConfirm: () {
        controller.confirmBack();
      },
      onCancel: () {
        controller.cancelBack();
      },
    );
  }
}
