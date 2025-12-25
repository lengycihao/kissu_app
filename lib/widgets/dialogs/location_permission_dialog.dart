import 'package:flutter/material.dart';

/// 定位权限申请自定义弹窗
class LocationPermissionDialog extends StatelessWidget {
  final VoidCallback? onAllow;
  final VoidCallback? onCancel;

  const LocationPermissionDialog({Key? key, this.onAllow, this.onCancel})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 270,
          // height: 180,
          // margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 主弹窗容器
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/dialog/kissu4_dialog_small_bg.webp',
                    ),
                    fit: BoxFit.fill
                  ),
                  borderRadius: BorderRadius.circular(16),
                   
                ),
                child: Column(
                  children: [
                    // 内容区域
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 25, 24, 24),
                      child: Column(
                        children: [
                          Text(
                            "开启定位权限",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xff333333),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 14),
                          // 标题文字
                          const Text(
                            '为向你在地图上展示位置信息 Kissu需要获取你的定位权限',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff333333),
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24),

                          // 允许使用按钮
                          GestureDetector(
                            onTap:
                                onAllow ??
                                () => Navigator.of(context).pop(true),
                            child: Container(
                              width: 106,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9AD9), // 粉色按钮
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Center(
                                child: Text(
                                  '继续',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 关闭按钮 - 放在弹窗下方16px处
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onCancel ?? () => Navigator.of(context).pop(false),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF999999), // 灰色背景
                    borderRadius: BorderRadius.circular(16), // 圆角
                    image: const DecorationImage(
                      image: AssetImage(
                        'assets/images/kissu_location_close.webp',
                      ),
                      fit: BoxFit.cover,
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

  /// 显示定位权限申请弹窗
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocationPermissionDialog(),
    );
  }
}
