import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kissu_app/network/public/setting_api.dart';
import '../../../network/public/file_upload_api.dart';
import '../../../utils/user_manager.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:kissu_app/services/permission_service.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/widgets/common_back_button.dart';

/// 控制器
class FeedbackController extends GetxController {
  var content = "".obs; // 问题和意见
  var contact = "".obs; // 联系方式
  var selectedImage = Rx<File?>(null); // 选择的图片（只能一张）
  var isSubmitting = false.obs; // 是否正在提交
  var loadingText = "正在提交反馈...".obs; // loading文案

  // 联系方式输入相关
  final FocusNode contactFocusNode = FocusNode();
  final TextEditingController contactTextController = TextEditingController();

  final picker = ImagePicker();
  final fileUploadApi = FileUploadApi();
  final settingApi = SettingApi();
  final PermissionService _permissionService = PermissionService();

  @override
  void onInit() {
    super.onInit();

    // // 自动填入用户手机号到联系方式输入框
    // if (UserManager.userPhone != null && UserManager.userPhone!.isNotEmpty) {
    //   contact.value = UserManager.userPhone!;
    //   logDebug('✅ 意见反馈: 已自动填入用户手机号 ${UserManager.userPhone}', tag: 'Feedback');
    // }

    // 同步到 TextEditingController，确保初始值展示正确
    contactTextController.text = contact.value;
  }

  @override
  void onClose() {
    contactFocusNode.dispose();
    contactTextController.dispose();
    super.onClose();
  }

  /// 验证手机号格式
  bool _isValidPhoneNumber(String phone) {
    // 中国大陆手机号正则：1开头，第二位是3-9，总共11位
    final phoneReg = RegExp(r'^1[3-9]\d{9}$');
    return phoneReg.hasMatch(phone);
  }

  /// 验证联系方式
  String? validateContact(String value) {
    if (value.isEmpty) return null; // 选填字段，空值有效

    // 判断是否是手机号格式（纯数字且以1开头）
    if (RegExp(r'^1\d+$').hasMatch(value)) {
      // 按手机号校验
      if (value.length != 11) {
        return "手机号应为11位数字";
      }
      if (!_isValidPhoneNumber(value)) {
        return "请输入有效的手机号";
      }
    } else if (value.contains('@')) {
      // 按邮箱校验
      final emailReg = RegExp(r'^[\w-]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailReg.hasMatch(value)) {
        return "请输入有效的邮箱地址";
      }
    } else {
      return "请输入有效的手机号或邮箱";
    }

    return null;
  }

  /// 失去焦点时的处理
  void onContactFocusLost() {
    contactFocusNode.unfocus();
    // 验证联系方式格式
    final error = validateContact(contact.value.trim());
    if (error != null) {
      CustomToast.show(Get.context!, error);
    }
  }

  /// 选择图片
  Future<void> pickImage() async {
    try {
      // 直接检查权限状态
      final hasPermission = await _permissionService.checkPermissionStatus(
        PermissionType.photos,
      );

      if (hasPermission) {
        // 有权限，直接选择图片
        logDebug('✅ 意见反馈: 已有权限，直接选择图片', tag: 'Feedback');
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          selectedImage.value = File(picked.path);
          logDebug('✅ 意见反馈: 图片选择成功 path=${picked.path}', tag: 'Feedback');
        } else {
          logDebug('⚠️ 意见反馈: 用户取消了图片选择', tag: 'Feedback');
        }
      } else {
        // 没有权限，申请权限（会弹出系统权限弹窗）
        logDebug('⚠️ 意见反馈: 没有权限，申请权限', tag: 'Feedback');
        final permissionGranted = await _permissionService
            .requestPhotosPermission();

        if (permissionGranted) {
          logDebug('✅ 意见反馈: 权限申请成功，开始选择图片', tag: 'Feedback');
          final picked = await picker.pickImage(source: ImageSource.gallery);
          if (picked != null) {
            selectedImage.value = File(picked.path);
            logDebug('✅ 意见反馈: 图片选择成功 path=${picked.path}', tag: 'Feedback');
          } else {
            logDebug('⚠️ 意见反馈: 用户取消了图片选择', tag: 'Feedback');
          }
        } else {
          logWarning('❌ 意见反馈: 权限申请被拒绝', tag: 'Feedback');
          OKToastUtil.show('需要相册权限才能选择图片');
        }
      }
    } catch (e) {
      logError('❌ 意见反馈: 选择图片失败 - $e', tag: 'Feedback', error: e);
      OKToastUtil.showError('选择图片失败');
    }
  }

  /// 删除图片
  void removeImage() {
    selectedImage.value = null;
  }

  /// 上传图片
  Future<String?> _uploadImage() async {
    if (selectedImage.value == null) return null;

    try {
      final result = await fileUploadApi.uploadFile(selectedImage.value!);

      if (result.isSuccess && result.data != null) {
        return result.data!;
      }
      return null;
    } catch (e) {
      logError('❌ 意见反馈: 图片上传失败 - $e', tag: 'Feedback', error: e);
      return null;
    }
  }

  /// 提交
  Future<void> submit() async {
    if (isSubmitting.value) {
      CustomToast.show(Get.context!, "正在提交中，请稍候...");
      return;
    }

    final trimmedContent = content.value.trim();
    if (trimmedContent.isEmpty) {
      CustomToast.show(Get.context!, "请填写问题和意见");
      return;
    }

    // 验证联系方式格式
    final trimmedContact = contact.value.trim();
    if (trimmedContact.isNotEmpty) {
      final error = validateContact(trimmedContact);
      if (error != null) {
        CustomToast.show(Get.context!, error);
        return;
      }
    }

    try {
      isSubmitting.value = true;
      loadingText.value = "正在提交反馈...";

      // 先上传图片
      String? attachmentUrl;
      if (selectedImage.value != null) {
        attachmentUrl = await _uploadImage();

        if (selectedImage.value != null && attachmentUrl == null) {
          // 有图片但上传失败
          isSubmitting.value = false;
          CustomToast.show(Get.context!, "图片上传失败，请重试");
          return;
        }
      }

      // 确定联系方式：如果用户没有填写，则使用用户手机号
      String contactWay = trimmedContact.isNotEmpty
          ? trimmedContact
          : (UserManager.userPhone ?? '');

      final result = await settingApi.submitFeedback(
        content: content.value.trim(),
        contactWay: contactWay,
        attachment: attachmentUrl,
      );

      if (result.isSuccess) {
        loadingText.value = "提交成功";

        // 延迟后执行清空和返回操作
        Timer(const Duration(milliseconds: 1000), () {
          // 清空表单
          content.value = "";
          contact.value = "";
          contactTextController.clear();
          selectedImage.value = null;

          // 关闭loading
          isSubmitting.value = false;

          // 返回上一页 - 使用多种方式确保成功
          try {
            Get.back();
          } catch (e) {
            // 如果Get.back()失败，使用Navigator
            if (Get.context != null && Navigator.canPop(Get.context!)) {
              Navigator.pop(Get.context!);
            }
          }
        });
      } else {
        isSubmitting.value = false;
        CustomToast.show(Get.context!, result.msg ?? "提交失败，请重试");
      }
    } catch (e) {
      isSubmitting.value = false;
      CustomToast.show(Get.context!, "提交失败: $e");
    }
  }
}

/// 图片Item Widget
class ImageItem extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const ImageItem({required this.file, required this.onRemove, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            cacheWidth: 180, // 限制缓存尺寸
          ),
        ),
        Positioned(
          right: -6,
          top: -6,
          child: IconButton(
            icon: const Icon(Icons.close, color: Color(0xffFF7C98), size: 18),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
}

/// 页面
class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  /// 统一卡片外层装饰，保证阴影和圆角风格一致
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FeedbackController());

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          // 背景
          Positioned.fill(
            child: Image.asset(
              "assets/4.0/kissu4_new_use_bg.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),

          // 内容
          SafeArea(
            child: Column(
              children: [
                // 导航栏
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ).copyWith(right: 16),
                  child: Row(
                    children: [
                      CommonBackButton(
                        onTap: () => Get.back(),
                        assetPath: "assets/images/kissu_mine_back.webp",
                        iconSize: 24,
                      ),
                      const Spacer(),
                      const Text(
                        "意见反馈",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 内容区域
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // 问题和意见
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "问题和意见",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  "*",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFFF6A68),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFffffff),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: TextField(
                                maxLength: 200,
                                maxLines: 6,
                                onChanged: (val) =>
                                    controller.content.value = val,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF333333),
                                  height: 1.5,
                                ),
                                decoration: const InputDecoration(
                                  hintText: "小主，写下您的宝贵意见我们会努力改进哒～",
                                  hintStyle: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF999999),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                  counterText: "",
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Obx(
                              () => Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  "${controller.content.value.length}/200",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: controller.content.value.length > 180
                                        ? const Color(0xFFFEA39C)
                                        : const Color(0xFF999999),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 图片上传
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: _cardDecoration(),
                        child: Obx(() {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  // 显示选择的图片（如果有的话）
                                  if (controller.selectedImage.value != null)
                                    ImageItem(
                                      file: controller.selectedImage.value!,
                                      onRemove: controller.removeImage,
                                    ),
                                  // 添加图片按钮，只有没有图片时才显示
                                  if (controller.selectedImage.value == null)
                                    GestureDetector(
                                      onTap: controller.pickImage,
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage(
                                              "assets/images/kissu_image_add.webp",
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "上传图片可以更好的解决问题哦～",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF777777),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),

                      const SizedBox(height: 20),

                      // 联系方式
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "联系方式",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF333333),
                              ),
                            ),
                            Obx(() {
                              // 访问可观察变量，确保 Obx 能正确追踪
                              final _ = controller.contact.value;
                              return TextField(
                                focusNode: controller.contactFocusNode,
                                controller: controller.contactTextController,
                                onChanged: (val) =>
                                    controller.contact.value = val,
                                onSubmitted: (_) =>
                                    controller.onContactFocusLost(),
                                onTapOutside: (_) =>
                                    controller.onContactFocusLost(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF333333),
                                  height: 1.0, // 设置行高确保垂直居中
                                ),
                                keyboardType: TextInputType.emailAddress,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9a-zA-Z@._\\-]'),
                                  ),
                                  LengthLimitingTextInputFormatter(
                                    50,
                                  ), // 限制最大长度
                                ],
                                decoration: const InputDecoration(
                                  hintText: "请输入手机号，以便我们回复您～",
                                  hintStyle: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF999999),
                                    height: 1.0, // 设置占位符行高确保垂直居中
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 8, // 增加垂直内边距确保居中
                                  ),
                                  isDense: true, // 减少默认内边距
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100), // 增加底部间距，为底部按钮留空间
                    ],
                  ),
                ),

               

                // 底部提交按钮
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 30),
                  child: Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              controller.content.value.trim().isEmpty
                              ? const Color(0xFFCCCCCC)
                              : const Color(0xFFFFA9E0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0, // 去掉阴影
                        ),
                        onPressed: controller.content.value.trim().isEmpty
                            ? null
                            : controller.submit,
                        child: const Text(
                          "提交",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading 覆盖层
          Obx(
            () => controller.isSubmitting.value
                ? Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFEA39C),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              controller.loadingText.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
