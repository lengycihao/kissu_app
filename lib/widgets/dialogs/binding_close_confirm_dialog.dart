import 'package:flutter/material.dart';
import 'package:kissu_app/services/tracking_service.dart';
import 'base_dialog.dart';

/// 绑定弹窗关闭确认弹窗
class BindingCloseConfirmDialog extends BaseDialog {
  final VoidCallback? onConfirm; // 点击"立即绑定"
  final VoidCallback? onCancel;  // 点击"再想想"
  final bool isFromHomePage;     // 是否来自首页（用于判断是否上报埋点）

  const BindingCloseConfirmDialog({
    Key? key,
    this.onConfirm,
    this.onCancel,
    this.isFromHomePage = false, // 默认不是首页
  }) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: 269,
        height: 220,
        clipBehavior: Clip.hardEdge, // 强制裁剪，避免渲染问题
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/location/kissu3_state_delete_bg.webp'),
            fit: BoxFit.fill,
          ),
        ),
        child: Stack(
          children: [
          // 标题 - Y轴位置115，加粗
          Positioned(
            top: 115,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '等等！最后一步啦，就能和Ta开启甜蜜之旅啦！',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.bold, // 加粗
                ),
              ),
            ),
          ),
          // 按钮区域 - 底部间距18（为文字换行留出更多空间）
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 左按钮 - "再想想"
                GestureDetector(
                  onTap: () async {
                    // 只有来自首页的绑定弹窗才上报埋点
                    if (isFromHomePage) {
                      await TrackingService.trackBindingReback(buttonName: '再想想');
                    }
                    
                    Navigator.of(context).pop(true); // 返回true表示允许关闭绑定弹窗
                    onCancel?.call();
                  },
                  child: Container(
                    width: 106,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Color(0xFFFF88AA),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '再想想',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFFF88AA),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 右按钮 - "立即绑定"
                GestureDetector(
                  onTap: () async {
                    // 只有来自首页的绑定弹窗才上报埋点
                    if (isFromHomePage) {
                      await TrackingService.trackBindingReback(buttonName: '立即绑定');
                    }
                    
                    Navigator.of(context).pop(false); // 返回false表示不关闭绑定弹窗
                    onConfirm?.call();
                  },
                  child: Container(
                    width: 106,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF408D), Color(0xFFFF6699)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '立即绑定',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
    );
  }

  /// 显示绑定关闭确认弹窗
  /// 
  /// [isFromHomePage] 是否来自首页的绑定弹窗（用于判断是否上报埋点）
  static Future<bool?> show({
    required BuildContext context,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
    bool isFromHomePage = false, // 默认不是首页
  }) {
    return BaseDialog.show<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      dialog: BindingCloseConfirmDialog(
        onConfirm: onConfirm,
        onCancel: onCancel,
        isFromHomePage: isFromHomePage,
      ),
    );
  }
}

