import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/utils/network_image_helper.dart';
import 'package:kissu_app/pages/login/info_setting/info_setting_controller.dart';

class InfoSettingPage extends StatelessWidget {
  final controller = Get.put(InfoSettingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // 保持底部按钮固定，不随键盘抬起
      body: GestureDetector(
        onTap: () {
          // 点击空白区域时释放焦点
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          fit: StackFit.expand, // 使背景铺满整个页面
          children: [
            // 背景图片铺满整个页面
            // Image.asset('assets/dialog/info_bg.webp', fit: BoxFit.contain),
            Positioned.fill(
              child: Image.asset(
                'assets/dialog/info_bg.webp',
                fit: BoxFit.contain, alignment: Alignment.topCenter,
              ),
             
            ),
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 34,
                  right: 34,
                  bottom: 120, // 预留空间避免被底部按钮遮挡
                  top: MediaQuery.of(context).padding.top + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // 修改为左对齐
                  children: [
                    // 页面顶部的“个人信息”标题
                    Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        '完善信息',
                        style: TextStyle(
                          color: Color(0xdd000000),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    
                    SizedBox(height: 24),

                    // 头像部分
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          
                          // 用户头像 - 可点击预览
                          GestureDetector(
                            onTap: controller.previewAvatar,
                            child: Obx(() {
                              return ClipOval(
                                child:
                                    controller.avatarUrl.value.startsWith(
                                      'assets/',
                                    )
                                    ? Image.asset(
                                        controller.avatarUrl.value,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      )
                                    : NetworkImageHelper.loadImage(
                                        imageUrl: controller.avatarUrl.value,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorWidget: Image.asset(
                                          'assets/3.0/kissu3_love_avater.webp',
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                              );
                            }),
                          ),
                          // 相机图标 - 放在右下角，可点击上传
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: controller.pickImage,
                              child: Image.asset(
                                'assets/images/kissu_info_setting_camera.webp',
                                width: 28,
                                height: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // 昵称输入框
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '起个超迷人的名字~',
                        style: TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Obx(
                      () => TextField(
                        controller: controller.nicknameController,
                        focusNode: controller.nicknameFocusNode,
                        onChanged: (value) {
                          controller.updateNickname(value); // 使用新的更新方法
                        },
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF333333),
                          height: 1.0, // 设置行高为1.0确保垂直居中
                        ),

                        decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          hintText: controller.nickname.value,
                          hintStyle: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 16,
                            height: 1.0, // 设置占位符行高为1.0确保垂直居中
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18, // 增加垂直内边距确保居中
                          ),
                          isDense: true, // 减少默认内边距
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Color(0xFfE5E5E5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Color(0xFFE5E5E5)),
                          ),
                          // suffixIcon: controller.nicknameController.text.isNotEmpty
                          //     ? GestureDetector(
                          //         onTap: () {
                          //           controller.nicknameController.clear();
                          //           controller.updateNickname('');
                          //         },
                          //         child: Icon(
                          //           Icons.clear,
                          //           color: Color(0xFF999999),
                          //           size: 20,
                          //         ),
                          //       )
                          //     : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // 性别选择部分
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '选择你的性别',
                        style: TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => controller.selectGender('男'),
                            child: Obx(() {
                              return Image.asset(
                                controller.selectedGender.value == '男'
                                    ? 'assets/images/kissu_info_setting_boysel.webp'
                                    : 'assets/images/kissu_info_setting_boyunsel.webp',
                                height: 64,
                                fit: BoxFit.contain,
                              );
                            }),
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => controller.selectGender('女'),
                            child: Obx(() {
                              return Image.asset(
                                controller.selectedGender.value == '女'
                                    ? 'assets/images/kissu_info_setting_girlsel.webp'
                                    : 'assets/images/kissu_info_setting_girlunsel.webp',
                                height: 64,
                                fit: BoxFit.contain,
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // 生日选择部分
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Text(
                            '选择你的生日',
                            style: TextStyle(
                              color: Color(0xFF777777),
                              fontSize: 11,
                            ),
                          ),
                           
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => controller.pickBirthday(
                        controller.selectedDate.value,
                      ),
                      child: Obx(() {
                        return Container(
                          height: 50,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Color(0xFFE5E5E5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(width: 30),
                              Text(
                                DateFormat(
                                  'yyyy-MM-dd',
                                ).format(controller.selectedDate.value),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xff333333),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Color(0xFF777777),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 34),
                  ],
                ),
              ),
            ),
            // 开启陪伴按钮固定在页面底部，距离底部 36
            Positioned(
              left: 34,
              right: 34,
              bottom: 36,
              child: Obx(() {
                return GestureDetector(
                  onTap:
                      controller.isLoading.value ? null : controller.onSubmit,
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: controller.isLoading.value
                          ? Color(0xFFFF9AD9).withOpacity(0.6)
                          : Color(0xFFFF9AD9),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: controller.isLoading.value
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '保存中...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              '开启陪伴',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
