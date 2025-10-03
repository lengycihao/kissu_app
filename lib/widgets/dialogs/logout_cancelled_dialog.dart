import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 登录注销账号提示弹窗
class LogoutCancelledDialog extends StatelessWidget {
  const LogoutCancelledDialog({super.key});

  /// 确认知道了
  void _confirm() {
    Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/3.0/kissu3_dialog_jiechu_bg.webp'),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 标题
              const Text(
                '登录注销账号提示',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 内容
              RichText(
                textAlign: TextAlign.left,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(text: '因你再次登录，此账号注销流程已自动停止你可以继续正常使用\n\n'),
                     const TextSpan(
                      text: '很高兴你选择继续留下，我们会继续陪伴你',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF408D),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 知道了按钮
              GestureDetector(
                onTap: _confirm,
                child: Container(
                  width: double.infinity,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF408D),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text(
                      '知道了',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 显示登录注销账号提示弹窗
class LogoutCancelledDialogUtil {
  /// 显示登录注销账号提示弹窗
  static Future<bool?> showLogoutCancelledDialog() {
    return Get.dialog<bool>(
      const LogoutCancelledDialog(),
      barrierDismissible: false,
    );
  }
}
