import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart'; // 用于选择头像
class InfoSettingController extends GetxController {
  // 初始化变量
  var avatarUrl = RxString('assets/default_avatar.png'); // 默认头像
  var nickname = RxString('');
  var selectedGender = RxString('男');
  var selectedDate = Rx<DateTime>(DateTime(2000, 1, 1));

  // 选择头像
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery); // 从相册选择图片

    if (pickedFile != null) {
      // 更新头像
      avatarUrl.value = pickedFile.path;
    }
  }

  // 选择生日
  Future<void> pickBirthday(DateTime initialDate) async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != initialDate) {
      selectedDate.value = picked;
    }
  }

  // 提交表单
  void onSubmit() {
    // 提交的逻辑
    print('提交信息');
  }

  // 选择性别
  void selectGender(String gender) {
    selectedGender.value = gender;
  }
}
