import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/pages/login/info_setting/info_setting_controller.dart';

class InfoSettingPage extends StatelessWidget {
  final InfoSettingController controller = Get.put(InfoSettingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand, // 使背景铺满整个页面
        children: [
          // 背景图片铺满整个页面
          Image.asset(
            'assets/kissu_info_setting_bg.webp',
            fit: BoxFit.cover,
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 修改为左对齐
                children: [
                  // 页面顶部的“个人信息”标题
                  Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      '个人信息',
                      style: TextStyle(color: Color(0xFF333333), fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 24),

                  // "完善信息" 文本，左对齐
                  Text(
                    '完善信息',
                    style: TextStyle(color: Color(0xFF333333), fontSize: 18),
                  ),
                  SizedBox(height: 24),

                  // 头像部分
                  Center( // 确保头像居中
                    child: Stack(
                      alignment: Alignment.bottomRight, // 相机图标放在右下角
                      children: [
                        Obx(() {
                          return ClipOval(
                            child: Image.asset(
                              controller.avatarUrl.value,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          );
                        }),
                        GestureDetector(
                          onTap: null,
                          child: Image.asset(
                            'assets/kissu_info_setting_camera.webp',
                            width: 30,
                            height: 30,
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
                      style: TextStyle(color: Color(0xFF333333), fontSize: 11),
                    ),
                  ),
                  SizedBox(height: 10),
                  Obx(() {
                    return TextField(
                      controller: TextEditingController(text: controller.nickname.value),
                      onChanged: (value) {
                        controller.nickname.value = value; // 更新昵称
                      },
                      decoration: InputDecoration(
                        hintText: '请输入昵称',
                        hintStyle: TextStyle(color: Color(0xFF666666)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Color(0xFF6D383E)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Color(0xFF6D383E)),
                        ),
                      ),
                      style: TextStyle(fontSize: 16),
                    );
                  }),
                  SizedBox(height: 24),

                  // 性别选择部分
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '选择你的性别',
                      style: TextStyle(color: Color(0xFF333333), fontSize: 11),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => controller.selectGender('男'),
                        child: Obx(() {
                          return Image.asset(
                            controller.selectedGender.value == '男'
                                ? 'assets/kissu_info_setting_boysel.webp'
                                : 'assets/kissu_info_setting_boyunsel.webp',
                            width: 140,
                            height: 64,
                          );
                        }),
                      ),
                      SizedBox(width: 25),
                      GestureDetector(
                        onTap: () => controller.selectGender('女'),
                        child: Obx(() {
                          return Image.asset(
                            controller.selectedGender.value == '女'
                                ? 'assets/kissu_info_setting_girlsel.webp'
                                : 'assets/kissu_info_setting_girlunsel.webp',
                             width: 140,
                            height: 64,
                          );
                        }),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // 生日选择部分
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '选择你的生日',
                      style: TextStyle(color: Color(0xFF333333), fontSize: 11),
                    ),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => controller.pickBirthday(controller.selectedDate.value),
                    child: Obx(() {
                      return Container(
                        height: 50,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Color(0xFF6D383E)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(width: 30,),
                            Text(
                              DateFormat('yyyy 年     MM 月     dd日').format(controller.selectedDate.value),
                              style: TextStyle(fontSize: 16,color: Color(0xff333333)),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Color(0xFF6D383E),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 34),

                  // 开启陪伴按钮
                  GestureDetector(
                    onTap: controller.onSubmit,
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFFFEA39C),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          '开启陪伴',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

 