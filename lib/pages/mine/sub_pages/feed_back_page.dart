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

/// 控制器
class FeedbackController extends GetxController {
  var content = "".obs; // 问题和意见
  var contact = "".obs; // 联系方式
  var selectedImage = Rx<File?>(null); // 选择的图片（只能一张）
  var isSubmitting = false.obs; // 是否正在提交
  var loadingText = "正在提交反馈...".obs; // loading文案

  // 添加焦点控制器
  final FocusNode contactFocusNode = FocusNode();

  final picker = ImagePicker();
  final fileUploadApi = FileUploadApi();
  final settingApi = SettingApi();

  @override
  void onClose() {
    contactFocusNode.dispose();
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
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      selectedImage.value = File(picked.path);
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
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// 提交
  Future<void> submit() async {
    if (isSubmitting.value) {
      CustomToast.show(Get.context!, "正在提交中，请稍候...");
      return;
    }

    if (content.value.trim().isEmpty) {
      CustomToast.show(Get.context!, "请填写问题和意见");
      return;
    }

    // 验证联系方式格式
    if (contact.value.isNotEmpty) {
      final error = validateContact(contact.value.trim());
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
      String contactWay = contact.value.isNotEmpty
          ? contact.value.trim()
          : (UserManager.userPhone ?? '');

      final result = await settingApi.submitFeedback(
        content: content.value.trim(),
        contactWay: contactWay,
        attachment: attachmentUrl,
      );

      if (result.isSuccess) {
        loadingText.value = "提交成功";

        // 延迟后执行清空和返回操作
        Timer(Duration(milliseconds: 1000), () {
          // 清空表单
          content.value = "";
          contact.value = "";
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

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FeedbackController());

    return Scaffold(
      body: Stack(
        children: [
          // 背景
          Positioned.fill(
            child: Image.asset(
              "assets/kissu_mine_bg.webp",
              fit: BoxFit.cover,
            ),
          ),

          // 内容
          SafeArea(
                child: Column(
                  children: [
                    // 导航栏
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Image.asset(
                              "assets/kissu_mine_back.webp",
                              width: 24,
                              height: 24,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            "意见反馈",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 24),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 内容区域
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // 问题和意见
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "问题和意见（必填）",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  maxLength: 200,
                                  maxLines: 6,
                                  onChanged: (val) =>
                                      controller.content.value = val,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF333333),
                                    height: 1.2, // 设置行高确保垂直居中
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: "期待您写下宝贵的意见~",
                                    hintStyle: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF999999),
                                      height: 1.2, // 设置占位符行高确保垂直居中
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 0,
                                      vertical: 8, // 增加垂直内边距确保居中
                                    ),
                                    isDense: true, // 减少默认内边距
                                    counterText: "",
                                  ),
                                ),
                                Obx(
                                  () => Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      "${controller.content.value.length}/200",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF999999),
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
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Obx(() {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "图片(选填，提供问题截图)",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      // 显示选择的图片（如果有的话）
                                      if (controller.selectedImage.value !=
                                          null)
                                        ImageItem(
                                          file: controller.selectedImage.value!,
                                          onRemove: controller.removeImage,
                                        ),
                                      // 添加图片按钮，只有没有图片时才显示
                                      if (controller.selectedImage.value ==
                                          null)
                                        GestureDetector(
                                          onTap: controller.pickImage,
                                          child: Container(
                                            width: 90,
                                            height: 90,
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: AssetImage(
                                                  "assets/kissu_image_add.webp",
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              );
                            }),
                          ),

                          const SizedBox(height: 20),

                          // 联系方式
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "联系方式（选填）",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                TextField(
                                  focusNode: controller.contactFocusNode,
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
                                      RegExp(r'[0-9a-zA-Z@._\-]'),
                                    ),
                                    LengthLimitingTextInputFormatter(
                                      50,
                                    ), // 限制最大长度
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: "请输入您的手机号/邮箱",
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
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // 提交按钮
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFEA39C),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                onPressed: controller.submit,
                                child: const Text(
                                  "提交",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          
          // Loading 覆盖层
          Obx(() => controller.isSubmitting.value
              ? Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFEA39C)),
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
              : const SizedBox.shrink()),
        ],
      ),
    );
  }
}
