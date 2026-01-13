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
import 'package:kissu_app/services/log_upload_service.dart';

/// 控制器
class FeedbackController extends GetxController {
  var content = "".obs; // 问题和意见
  var contact = "".obs; // 联系方式
  var selectedImages = <File>[].obs; // 选择的图片（最多3张）
  var isSubmitting = false.obs; // 是否正在提交
  var loadingText = "正在提交反馈...".obs; // loading文案

  // 日志上传相关
  var isUploadingLog = false.obs; // 是否正在上传日志
  var logUploadProgress = 0.0.obs; // 日志上传进度
  var isSelectingLog = false.obs; // 是否正在选择日志
  // var logFilesSize = ''.obs; // 日志文件大小

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

    // 获取日志文件大小
    // _loadLogFilesSize();
  }

  /// 加载日志文件大小
  // Future<void> _loadLogFilesSize() async {
  //   try {
  //     logFilesSize.value = await LogUploadService.instance.getLogFilesSize();
  //   } catch (e) {
  //     logFilesSize.value = '0 B';
  //   }
  // }

  /// 上传日志文件
  /// 返回上传成功后的 file_url，失败返回 null
  Future<String?> uploadLogs({bool showToast = true}) async {
    if (isUploadingLog.value) {
      if (showToast) {
        CustomToast.show(Get.context!, "正在上传中，请稍候...");
      }
      return null;
    }

    try {
      isUploadingLog.value = true;
      logUploadProgress.value = 0.0;

      logDebug('开始上传日志文件', tag: 'Feedback');

      final result = await LogUploadService.instance.uploadLogs(
        remark: content.value.isNotEmpty ? content.value : '用户主动上传日志',
        onProgress: (sent, total) {
          if (total > 0) {
            logUploadProgress.value = sent / total;
          }
        },
      );

      isUploadingLog.value = false;

      if (result.isSuccess) {
        final data = result.getDataJson();
        final fileUrl = data['file_url'] as String?;
        logDebug('日志上传成功，URL: $fileUrl', tag: 'Feedback');
        if (showToast) {
          CustomToast.show(Get.context!, "日志上传成功，感谢您的配合！");
        }
        return fileUrl;
      } else {
        logError('日志上传失败: ${result.msg}', tag: 'Feedback');
        if (showToast) {
          CustomToast.show(Get.context!, result.msg ?? "日志上传失败，请重试");
        }
        return null;
      }
    } catch (e) {
      isUploadingLog.value = false;
      logError('日志上传异常: $e', tag: 'Feedback', error: e);
      if (showToast) {
        CustomToast.show(Get.context!, "上传失败: $e");
      }
      return null;
    }
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
    // 检查是否已达到最大数量
    if (selectedImages.length >= 3) {
      CustomToast.show(Get.context!, "最多只能上传3张图片");
      return;
    }

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
          selectedImages.add(File(picked.path));
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
            selectedImages.add(File(picked.path));
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
  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  /// 上传多张图片
  Future<List<String>> _uploadImages() async {
    if (selectedImages.isEmpty) return [];

    List<String> uploadedUrls = [];

    try {
      for (var image in selectedImages) {
        final result = await fileUploadApi.uploadFile(image);
        if (result.isSuccess && result.data != null) {
          uploadedUrls.add(result.data!);
        } else {
          // 如果有一张上传失败，返回空列表
          logError('❌ 意见反馈: 图片上传失败', tag: 'Feedback');
          return [];
        }
      }
      return uploadedUrls;
    } catch (e) {
      logError('❌ 意见反馈: 图片上传失败 - $e', tag: 'Feedback', error: e);
      return [];
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
      List<String> attachmentUrls = [];
      if (selectedImages.isNotEmpty) {
        attachmentUrls = await _uploadImages();

        if (selectedImages.isNotEmpty && attachmentUrls.isEmpty) {
          // 有图片但上传失败
          isSubmitting.value = false;
          CustomToast.show(Get.context!, "图片上传失败，请重试");
          return;
        }
      }

      // 如果勾选了上传日志，先上传日志获取URL
      String? logUrl;
      if (isSelectingLog.value) {
        loadingText.value = "正在上传日志...";
        logUrl = await uploadLogs(showToast: false);
        
        if (logUrl == null) {
          // 日志上传失败
          isSubmitting.value = false;
          CustomToast.show(Get.context!, "日志上传失败，请重试");
          return;
        }
      }

      // 确定联系方式：如果用户没有填写，则使用用户手机号
      String contactWay = trimmedContact.isNotEmpty
          ? trimmedContact
          : (UserManager.userPhone ?? '');

      // 将多张图片URL用逗号拼接
      String? attachmentUrl = attachmentUrls.isNotEmpty
          ? attachmentUrls.join(',')
          : null;

      loadingText.value = "正在提交反馈...";
      final result = await settingApi.submitFeedback(
        content: content.value.trim(),
        contactWay: contactWay,
        attachment: attachmentUrl,
        logUrl: logUrl,
      );

      if (result.isSuccess) {
        loadingText.value = "提交成功";

        // 延迟后执行清空和返回操作
        Timer(const Duration(milliseconds: 1000), () {
          // 清空表单
          content.value = "";
          contact.value = "";
          contactTextController.clear();
          selectedImages.clear();

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
        logError('提交反馈失败: ${result.msg}', tag: 'Feedback');
        isSubmitting.value = false;
        CustomToast.show(Get.context!, result.msg ?? "提交失败，请重试");
      }
    } catch (e) {
      logError('提交反馈失败: $e', tag: 'Feedback');
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
          borderRadius: BorderRadius.circular(4),
          child: Image.file(
            file,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            cacheWidth: 180, // 限制缓存尺寸
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Image(
              image: AssetImage("assets/images/kissu_feedback_close.webp"),
              width: 16,
              height: 10,
            ),
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
                SizedBox(
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
                              "assets/images/kissu_mine_back.webp",
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
                            "投诉与反馈",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      ),
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
                                  "投诉与反馈",
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
                                  // 显示已选择的图片
                                  ...List.generate(
                                    controller.selectedImages.length,
                                    (index) => ImageItem(
                                      file: controller.selectedImages[index],
                                      onRemove: () =>
                                          controller.removeImage(index),
                                    ),
                                  ),
                                  // 添加图片按钮，最多3张
                                  if (controller.selectedImages.length < 3)
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

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              controller.isSelectingLog.value = !controller.isSelectingLog.value;
                            },
                            child: Obx(
                            () => Image(
                              image: AssetImage(
                                controller.isSelectingLog.value
                                    ? 'assets/images/kissu_login_privite_sel.webp'
                                    : 'assets/images/kissu_login_privite_unsel.webp',
                              ),
                              width: 16,
                              height: 16,
                            ),
                          ),
                          ),
                          SizedBox(width: 5,),
                          const Text(
                            "上传日志(上传日志可帮助我们更快解决问题)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFaaaaaa),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 100), // 增加底部间距，为底部按钮留空间
                    ],
                  ),
                ),

                // 底部提交按钮
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 45,
                    vertical: 30,
                  ),
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
