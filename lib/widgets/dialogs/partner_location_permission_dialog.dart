import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 检查对方是否打开位置权限弹窗
class PartnerLocationPermissionDialog extends StatelessWidget {
  final VoidCallback? onConfirm;

  const PartnerLocationPermissionDialog({
    Key? key,
    this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        height: 300,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/location/kissu3_notice_middle_bg.webp'),
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
              
              const SizedBox(height: 12),
              
              // 副标题
              const Align(
                alignment: Alignment.center,
                child: Text(
                  '系统检查Ta没有开通位置权限~',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 内容
              const Text(
                '建议Ta开通位置权限，否则将无法监控ta的位置~！',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 18),
              
              // 知道了按钮
              GestureDetector(
                onTap: () {
                  Get.back(result: true);
                  onConfirm?.call();
                },
                child: Container(
                  width: double.infinity,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF408D),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '知道了',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    
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

/// 显示检查对方位置权限弹窗
class PartnerLocationPermissionDialogUtil {
  /// 显示检查对方位置权限弹窗
  static Future<bool?> show({
    VoidCallback? onConfirm,
  }) {
    return Get.dialog<bool>(
      PartnerLocationPermissionDialog(
        onConfirm: onConfirm,
      ),
      barrierDismissible: true,
    );
  }
}

