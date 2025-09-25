import 'package:flutter/material.dart';

/// 定位权限申请自定义弹窗
class LocationPermissionDialog extends StatelessWidget {
  final VoidCallback? onAllow;
  final VoidCallback? onCancel;

  const LocationPermissionDialog({
    Key? key,
    this.onAllow,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 280,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 主弹窗容器
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF8F8F8), // 浅灰色渐变开始
                      Colors.white,      // 白色渐变结束
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    // 内容区域
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Column(
                        children: [
                          // 标题文字
                          const Text(
                            'Kissu需要使用你的位置信息展',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '示到地图上',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          
                          // 允许使用按钮
                          GestureDetector(
                            onTap: onAllow ?? () => Navigator.of(context).pop(true),
                            child: Container(
                              width: double.infinity,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B9D), // 粉色按钮
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  '允许使用',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
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
                      image: AssetImage('assets/kissu_location_close.webp'),
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
