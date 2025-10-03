import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kissu_app/widgets/dialogs/dialog_manager.dart';
import 'package:kissu_app/widgets/dialogs/image_dialog_util.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/widgets/dialogs/permission_request_dialog.dart';
import 'package:kissu_app/widgets/dialogs/location_permission_dialog.dart';
import 'package:kissu_app/widgets/dialogs/simple_image_source_dialog.dart';
import 'package:kissu_app/widgets/dialogs/logout_dialog.dart';
import 'package:kissu_app/widgets/dialogs/logout_cancelled_dialog.dart';

/// 弹窗展示页面
class DialogShowcasePage extends StatelessWidget {
  const DialogShowcasePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景
          Positioned.fill(
            child: Image.asset(
              "assets/3.0/kissu3_view_bg.webp",
              fit: BoxFit.fill,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 顶部导航
                _buildTopBar(),
                // 内容区域
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          '通用确认弹窗',
                          [
                            _buildDialogItem(
                              '退出登录确认',
                              '显示退出登录确认弹窗',
                              () => DialogManager.showLogoutConfirm(context),
                            ),
                            _buildDialogItem(
                              '手机号更改确认',
                              '显示手机号更改确认弹窗',
                              () => DialogManager.showPhoneChangeConfirm(
                                context,
                                '+86 192****2378',
                              ),
                            ),
                            _buildDialogItem(
                              '解除关系确认',
                              '显示解除关系确认弹窗',
                              () => DialogManager.showUnbindConfirm(context),
                            ),
                            _buildDialogItem(
                              '注销提示弹窗',
                              '显示注销提示弹窗（带倒计时）',
                              () => _showLogoutDialog(),
                            ),
                            _buildDialogItem(
                              '登录注销账号提示',
                              '显示登录注销账号提示弹窗',
                              () => _showLogoutCancelledDialog(),
                            ),
                            _buildDialogItem(
                              '自定义确认弹窗',
                              '显示自定义确认弹窗',
                              () => DialogManager.showConfirm(
                                context: context,
                                title: '自定义标题',
                                content: '这是自定义内容',
                                subContent: '这是副标题',
                                confirmText: '好的',
                                cancelText: '算了',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          '输入与选择弹窗',
                          [
                            _buildDialogItem(
                              '性别选择弹窗',
                              '显示性别选择弹窗',
                              () async {
                                final gender = await DialogManager.showGenderSelect(
                                  context: context,
                                  selectedGender: '男生',
                                );
                                if (gender != null) {
                                  _showToast('选择了: $gender');
                                }
                              },
                            ),
                            _buildDialogItem(
                              '昵称输入弹窗',
                              '显示昵称输入弹窗',
                              () async {
                                final nickname = await DialogManager.showNicknameInput(
                                  context,
                                  currentNickname: '当前昵称',
                                );
                                if (nickname != null) {
                                  _showToast('输入了: $nickname');
                                }
                              },
                            ),
                            _buildDialogItem(
                              '通用输入弹窗',
                              '显示通用输入弹窗',
                              () async {
                                final input = await DialogManager.showInput(
                                  context: context,
                                  title: '输入内容',
                                  hintText: '请输入内容',
                                  maxLength: 20,
                                );
                                if (input != null) {
                                  _showToast('输入了: $input');
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          'VIP相关弹窗',
                          [
                            _buildDialogItem(
                              'VIP通用弹窗',
                              '显示VIP通用弹窗',
                              () => DialogManager.showVip(
                                context: context,
                                title: 'VIP专属功能',
                                subtitle: '解锁更多精彩内容',
                                content: '成为VIP会员，享受更多特权',
                                buttonText: '立即开通',
                              ),
                            ),
                            _buildDialogItem(
                              '再看30秒得会员',
                              '显示"再看30秒得会员"弹窗',
                              () => DialogManager.showVipWatchMore(context),
                            ),
                            _buildDialogItem(
                              '再看2个视频得全天免费会员',
                              '显示"再看2个视频得全天免费会员"弹窗',
                              () => DialogManager.showVipWatchVideos(context),
                            ),
                            _buildDialogItem(
                              '恭喜你完成了今天任务',
                              '显示"恭喜你完成了今天任务"弹窗',
                              () => DialogManager.showVipTaskComplete(context),
                            ),
                            _buildDialogItem(
                              '恭喜成功开通会员',
                              '显示"恭喜成功开通会员"弹窗',
                              () => DialogManager.showVipSuccess(context),
                            ),
                            _buildDialogItem(
                              '华为渠道VIP推广',
                              '显示华为渠道VIP推广弹窗',
                              () => DialogManager.showHuaweiVipPromo(context),
                            ),
                            _buildDialogItem(
                              'VIP开通弹窗',
                              '显示VIP开通弹窗（0.9元/天）',
                              () => DialogManager.showVipPurchase(
                                context: context,
                                onConfirm: () => _showToast('确认开通VIP'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          '底部弹窗',
                          [
                            _buildDialogItem(
                              '自定义底部弹窗',
                              '显示带轮播banner的底部弹窗',
                              () => CustomBottomDialog.show(
                                context: context,
                                customContent: Container(
                                  padding: const EdgeInsets.all(20),
                                  child: const Text(
                                    '这是自定义内容区域',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          '权限相关弹窗',
                          [
                            _buildDialogItem(
                              '相机权限请求弹窗',
                              '显示相机权限请求弹窗',
                              () async {
                                final result = await PermissionRequestDialog.showCameraPermissionDialog(context);
                                _showToast(result == true ? '确认授权相机' : '取消授权相机');
                              },
                            ),
                            _buildDialogItem(
                              '相册权限请求弹窗',
                              '显示相册权限请求弹窗',
                              () async {
                                final result = await PermissionRequestDialog.showPhotosPermissionDialog(context);
                                _showToast(result == true ? '确认授权相册' : '取消授权相册');
                              },
                            ),
                            _buildDialogItem(
                              '位置权限弹窗',
                              '显示位置权限弹窗',
                              () => showDialog(
                                context: context,
                                builder: (context) => LocationPermissionDialog(
                                  onAllow: () {
                                    Navigator.of(context).pop();
                                    _showToast('确认授权位置');
                                  },
                                  onCancel: () {
                                    Navigator.of(context).pop();
                                    _showToast('取消授权位置');
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          '图片/头像相关弹窗',
                          [
                            _buildDialogItem(
                              '头像上传弹窗',
                              '显示头像上传弹窗（带预览和裁剪）',
                              () => ImageDialogUtil.showImageDialog(
                                context: context,
                                imagePath: 'assets/3.0/kissu3_avater_viewbg.webp',
                              ),
                            ),
                            _buildDialogItem(
                              '简单图片来源选择',
                              '显示简单的图片来源选择弹窗',
                              () async {
                                final result = await SimpleImageSourceDialog.show(context);
                                if (result != null) {
                                  _showToast('选择了${result == ImageSource.camera ? '相机' : '相册'}');
                                } else {
                                  _showToast('取消选择图片');
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          '业务特定弹窗',
                          [
                            _buildDialogItem(
                              '通话历史设置弹窗',
                              '显示通话历史设置弹窗',
                              () => _showToast('通话历史设置弹窗（需要导入相应页面）'),
                            ),
                            _buildDialogItem(
                              '解除关系提示弹窗',
                              '显示解除关系提示弹窗',
                              () => _showUnbindRelationshipDialog(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建顶部导航栏
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Image.asset(
              "assets/kissu_mine_back.webp",
              width: 22,
              height: 22,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "弹窗展示",
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xff333333),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 22), // 占位保持居中
        ],
      ),
    );
  }

  /// 构建分组
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFCE92FF).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFCE92FF),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  /// 构建弹窗项目
  Widget _buildDialogItem(String title, String description, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xff333333),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff666666),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xff999999),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示Toast提示
  void _showToast(String message) {
    Get.snackbar(
      '提示',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// 显示解除关系提示弹窗
  void _showUnbindRelationshipDialog() {
    UnbindRelationshipDialogUtil.showUnbindRelationshipDialog().then((result) {
      if (result == true) {
        _showToast('解除关系成功');
      } else if (result == false) {
        _showToast('已取消解除关系');
      }
    });
  }

  /// 显示注销提示弹窗
  void _showLogoutDialog() {
    Get.dialog<bool>(
      const LogoutDialog(),
      barrierDismissible: false,
    ).then((result) {
      if (result == true) {
        _showToast('确认注销');
      } else if (result == false) {
        _showToast('取消注销');
      }
    });
  }

  /// 显示登录注销账号提示弹窗
  void _showLogoutCancelledDialog() {
    LogoutCancelledDialogUtil.showLogoutCancelledDialog().then((result) {
      if (result == true) {
        _showToast('已确认');
      }
    });
  }
}
