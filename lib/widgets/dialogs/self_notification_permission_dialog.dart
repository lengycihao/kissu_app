import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/permission_service.dart';

/// 自己是否打开通知权限弹窗
class SelfNotificationPermissionDialog extends StatelessWidget {
  final VoidCallback? onKnow;
  final VoidCallback? onGoSettings;

  const SelfNotificationPermissionDialog({
    Key? key,
    this.onKnow,
    this.onGoSettings,
  }) : super(key: key);

  /// 跳转到通知设置页面
  Future<void> _goToNotificationSettings() async {
    try {
      final permissionService = PermissionService();
      await permissionService.openNotificationSettings();
      onGoSettings?.call();
    } catch (e) {
      print('跳转通知设置失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        height: 308,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/location/kissu3_notice_big_bg.webp'),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.all(Radius.circular(25)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 18,right: 18,top: 115,bottom: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 标题行：提示 + 关闭按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '提示',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 3),
              
              // 副标题
              const Align(
                alignment: Alignment.center,
                child: Text(
                  '你还没有开通消息通知哦!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 内容
              const Text(
                '建议开通消息通知权限～开通后，当 Ta 的位置发生变化，系统会第一时间向通知你；若未开通，可能会导致你错过通知',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                  height: 1.7,
                ),
              ),
              
              const SizedBox(height: 18),
              
              // 按钮区域
              Row(
                children: [
                  // 知道了按钮
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.back(result: false);
                        onKnow?.call();
                      },
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF999999),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '知道了',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF999999),
                           ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 去开启按钮
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Get.back(result: true);
                        await _goToNotificationSettings();
                      },
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(0xFFFF408D),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '去开启',
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
            ],
          ),
        ),
      ),
    );
  }
}

/// 显示自己通知权限弹窗
class SelfNotificationPermissionDialogUtil {
  /// 显示自己通知权限弹窗
  static Future<bool?> show({
    VoidCallback? onKnow,
    VoidCallback? onGoSettings,
  }) {
    return Get.dialog<bool>(
      SelfNotificationPermissionDialog(
        onKnow: onKnow,
        onGoSettings: onGoSettings,
      ),
      barrierDismissible: true,
    );
  }
}

