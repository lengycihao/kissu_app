import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 188打卡页面 - 返回挽留弹窗
class CheckIn188RetentionDialog extends StatelessWidget {
  final VoidCallback onJoinNow;
  final VoidCallback onNextTime;
  final VoidCallback onBack;

  const CheckIn188RetentionDialog({
    super.key,
    required this.onJoinNow,
    required this.onNextTime,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = Get.width;
    final dialogWidth = screenWidth * 276 / 375;
    final dialogHeight = dialogWidth * 356 / 276;

    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 弹窗主体
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: dialogWidth,
                height: dialogHeight,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/188/kissu_188_dialog_bg.webp'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 标题文本
                    const Text(
                      '你要放弃得520红包的机会吗？',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 副标题
                    const Text(
                      '截至目前，已累计被领取',
                      style: TextStyle(
                        fontSize: 12,

                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 金额
                    const Text(
                      '¥ 170560.00',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'AlimamaShuHeiTi',
                        color: Color(0xFFFF0469),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // 立即参加按钮
                    GestureDetector(
                      onTap: onJoinNow,
                      child: Container(
                        width: 205,
                        height: 40,
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage(
                              'assets/188/kissu_188_btn_bg.webp',
                            ),
                            fit: BoxFit.fill,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '立即参加',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'AlimamaShuHeiTi',
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '已有23183人参加',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 下次再说按钮
                    GestureDetector(
                      onTap: onBack,
                      child: const Text(
                        '下次再说',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFc8c8c8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              SizedBox(height: 100),
            ],
          ),
          // 底部关闭按钮
          Positioned(
            bottom:
                MediaQuery.of(context).size.height * 0.5 -
                dialogHeight * 0.5 -
                20,
            child: GestureDetector(
              onTap: onNextTime,
              child: Container(
                width: 20,
                height: 20,

                child: Image(
                  image: AssetImage('assets/188/kissu_188_close.webp'),
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示挽留弹窗
  static Future<bool?> show({required VoidCallback onJoinNow}) {
    return Get.dialog<bool>(
      CheckIn188RetentionDialog(
        onJoinNow: () {
          Get.back(result: true);
          onJoinNow();
        },
        onNextTime: () {
          Get.back(result: false);
        },
        onBack: () {
          Get.back(result: false);
          Get.back(result: false);
        },
      ),
      barrierColor: Colors.black.withOpacity(0.7),
      barrierDismissible: false,
    );
  }
}
