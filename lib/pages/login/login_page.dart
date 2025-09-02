 
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/login/login_controller.dart';
import 'package:kissu_app/utils/toast_toalog.dart';

class LoginPage extends StatelessWidget {
  final LoginController controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    controller.context = context;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          
          Image.asset('assets/kissu_login_bg.webp', fit: BoxFit.cover),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    SizedBox(height: 100),
                    _buildInputField('请输入手机号', false, controller.phoneNumber),
                    SizedBox(height: 20),
                    _buildInputField(
                      '请输入验证码',
                      true,
                      controller.verificationCode,
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Obx(
                          () => Checkbox(
                            value: controller.isChecked.value,
                            onChanged: (bool? value) {
                              controller.isChecked.value = value!;
                            },
                          ),
                        ),
                        Text(
                          '登录即代表同意 ',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // print('点击隐私协议');
                            ToastDialog.showTitleWithImageDialog(
                              context,
                              '带背景图的标题', // 标题
                              'assets/kissu_toast_title_bg.webp', // 标题背景图URL
                              '这是弹窗的内容', // 内容
                              () {
                                // 确认按钮点击回调
                                print('确认按钮被点击');
                              },
                            );
                          },
                          child: Text(
                            '《隐私协议》',
                            style: TextStyle(
                              color: Color(0xFFFF839E),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          ' 和 ',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                           ToastDialog.showBasicDialog(
  context,
  '弹窗标题',  // 标题
  '这是弹窗的内容',  // 内容
  () {
    // 确认按钮点击回调
    print('确认按钮被点击');
  },
  height: 400.0,  // 传递弹窗的高度（例如：400.0）
);

                          },
                          child: Text(
                            '《用户协议》',
                            style: TextStyle(
                              color: Color(0xFFFF839E),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 40),
                    GestureDetector(
                      onTap: controller.login,
                      child: Container(
                        height: 50,
                        margin: EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                          color: Color(0xFFFEA39C),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            '登录',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String hintText, bool isCodeField, RxString field) {
    return TextField(
      onChanged: (value) {
        field.value = value;
      },
      decoration: InputDecoration(
        hintText: hintText,
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
        suffixIcon:
            isCodeField
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.end, // 使内容右对齐
                  mainAxisSize: MainAxisSize.min, // 使 Row 仅占用 TextField 尾部的空间
                  children: [
                    GestureDetector(
                      onTap: () {
                        controller.validatePhoneNumber();
                        // 这里可以调用获取验证码的逻辑
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '获取验证码',
                          style: TextStyle(color: Color(0xFFFF839E)),
                        ),
                      ),
                    ),
                  ],
                )
                : null,
      ),
      keyboardType: isCodeField ? TextInputType.number : TextInputType.phone,
    );
  }
}

void main() {
  runApp(GetMaterialApp(home: LoginPage()));
}
