import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';

/// 注销提示弹窗
class LogoutDialog extends StatefulWidget {
  const LogoutDialog({super.key});

  @override
  State<LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<LogoutDialog> {
  int _countdown = 10;
  bool _canConfirm = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  /// 获取7天后的日期
  String _getSevenDaysLaterDate() {
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));
    return '${sevenDaysLater.year}年${sevenDaysLater.month}月${sevenDaysLater.day}日';
  }

  /// 开始倒计时
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          _canConfirm = true;
        });
        timer.cancel();
      }
    });
  }

  /// 确认注销
  void _confirmLogout() {
    if (_canConfirm) {
      Get.back(result: true);
    } else {
      CustomToast.show(
        Get.context!,
        '请等待倒计时结束后再确认注销',
      );
    }
  }

  /// 取消注销
  void _cancelLogout() {
    Get.back(result: false);
  }

  @override
  Widget build(BuildContext context) {
    final sevenDaysLater = _getSevenDaysLaterDate();
    
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
                '注销提示',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              
              
              const SizedBox(height: 16),
              
              // 内容
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(text: '为保证你的账号安全，点击确认注销后，你的Kissu账号将在7天后('),
                    TextSpan(
                      text: sevenDaysLater,
                      style: const TextStyle(
                        color: Color(0xFFFF408D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: ')完成注销\n\n'),
                    const TextSpan(text: ''),
                    const TextSpan(
                      text: '手机号、会员等信息',
                      style: TextStyle(
                        color: Color(0xFFFF408D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: '将于账号完成注销的同时被释放，'),
                    const TextSpan(
                      text: '账号相关数据将会被删除',
                      style: TextStyle(
                        color: Color(0xFFFF408D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: '。若你在此期间再次登录该账号，注销流程将会被终止\n\n'),
                    const TextSpan(text: ''),
                    const TextSpan(
                      text: '账号完成注销时间不可提前',
                      style: TextStyle(
                        color: Color(0xFFFF408D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: '，如注销完成前你的账号涉及双方争议纠纷，Kissu将会终止本账号的注销\n\n'),
                    const TextSpan(text: '阅读'),
                    const TextSpan(
                      text: '10',
                      style: TextStyle(
                        color: Color(0xFFFF408D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: '秒后，"确认注销"按钮你可点击'),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 按钮区域
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 取消按钮
                  GestureDetector(
                    onTap: _cancelLogout,
                    child: Container(
                      width: 80,
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF999999),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Text(
                          '取消',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // 确认注销按钮
                  GestureDetector(
                    onTap: _canConfirm ? _confirmLogout : null,
                    child: Container(
                      width: 133,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _canConfirm 
                            ? const Color(0xFFFF408D)
                            : const Color(0xFFFF9DC4),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          _canConfirm ? '确认注销' : '确认注销($_countdown)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}