import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// 控制器
class FeedbackController extends GetxController {
  var content = "".obs; // 问题和意见
  var contact = "".obs; // 联系方式
  var images = <File>[].obs; // 选择的图片

  final picker = ImagePicker();

  /// 选择图片
  Future<void> pickImage() async {
    if (images.length >= 3) {
      Get.snackbar("提示", "最多只能上传三张图片");
      return;
    }
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      images.add(File(picked.path));
    }
  }

  /// 删除图片
  void removeImage(int index) {
    images.removeAt(index);
  }

  /// 提交
  void submit() {
    if (content.value.trim().isEmpty) {
      Get.snackbar("提示", "请填写问题和意见");
      return;
    }

    if (contact.value.isNotEmpty) {
      final phoneReg = RegExp(r'^1\d{10}$'); // 简单手机号正则
      final emailReg = RegExp(r'^[\w-]+@([\w-]+\.)+[\w-]{2,4}$');

      if (!phoneReg.hasMatch(contact.value) && !emailReg.hasMatch(contact.value)) {
        Get.snackbar("提示", "请输入有效的手机号或邮箱");
        return;
      }
    }

    Get.snackbar("提交成功", "感谢您的反馈！");
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
            icon: const Icon(Icons.close, color: Colors.red, size: 18),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                              onChanged: (val) => controller.content.value = val,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF333333),
                              ),
                              decoration: const InputDecoration(
                                hintText: "期待您写下宝贵的意见~",
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF999999),
                                ),
                                border: InputBorder.none,
                                counterText: "",
                              ),
                            ),
                            Obx(() => Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    "${controller.content.value.length}/200",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                )),
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
                                "问题截图（选填，最多3张）",
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
                                  for (int i = 0; i < controller.images.length; i++)
                                    ImageItem(
                                      file: controller.images[i],
                                      onRemove: () => controller.removeImage(i),
                                    ),
                                  if (controller.images.length < 3)
                                    GestureDetector(
                                      onTap: controller.pickImage,
                                      child: Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade400),
                                        ),
                                        child: const Icon(Icons.add, size: 32, color: Colors.grey),
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
                              onChanged: (val) => controller.contact.value = val,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF333333),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9a-zA-Z@._\-]')),
                              ],
                              decoration: const InputDecoration(
                                hintText: "请输入您的手机号/邮箱",
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF999999),
                                ),
                                border: InputBorder.none,
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
        ],
      ),
    );
  }
}
