import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kissu_app/routers/kissu_route_path.dart'; // 用于选择头像

class InfoSettingController extends GetxController {
  // 初始化变量
  var avatarUrl = RxString('assets/kissu_info_setting_headerbg.webp'); // 默认头像
  var nickname = RxString('');
  var selectedGender = RxString('男');
  var selectedDate = Rx<DateTime>(DateTime(2000, 1, 1));

  // 选择头像
  // Future<void> pickImage() async {
  //   final picker = ImagePicker();
  //   final pickedFile = await picker.getImage(source: ImageSource.gallery); // 从相册选择图片

  //   if (pickedFile != null) {
  //     // 更新头像
  //     avatarUrl.value = pickedFile.path;
  //   }
  // }

  // 选择生日
  Future<void> pickBirthday(DateTime initialDate) async {
    await showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        DateTime tempPicked = initialDate;

        return Localizations.override(
          // 👈 强制中文
          context: context,
          locale: const Locale('zh', 'CN'),
          child: SizedBox(
            height: 300,
            child: Column(
              children: [
                // 顶部操作栏
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      child: const Text("取消"),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      child: const Text("确定"),
                      onPressed: () {
                        selectedDate.value = tempPicked;
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),

                // iOS 风格日期选择器
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    minimumDate: DateTime(1900),
                    maximumDate: DateTime(2101),
                    onDateTimeChanged: (DateTime newDate) {
                      tempPicked = newDate;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 提交表单
  void onSubmit() {
    // 提交的逻辑
    Get.offAllNamed(KissuRoutePath.home,);
    print('提交信息');
  }

  // 选择性别
  void selectGender(String gender) {
    selectedGender.value = gender;
  }
}
