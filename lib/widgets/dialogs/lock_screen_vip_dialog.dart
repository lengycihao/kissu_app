import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/utils/source_page_utils.dart';

/// 一键锁机VIP弹窗
/// 当非会员点击一键锁机功能时显示
class LockScreenVipDialog {
  static Future<void> show(BuildContext context, {bool isFromChat = false}) async {
    // 埋点2.1: VIP锁机弹窗曝光事件
    AnalyticsHelper.trackVipLockPhoneExposure(isFromChat: isFromChat);
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) => _LockScreenVipDialogContent(isFromChat: isFromChat),
    );
  }
}

class _LockScreenVipDialogContent extends StatelessWidget {
  final bool isFromChat;
  const _LockScreenVipDialogContent({this.isFromChat = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 背景图片
            Image.asset(
              'assets/lock/kissu_lock_vip_bg.webp',
              width: 276,
              height: 350,
              fit: BoxFit.contain,
            ),
           
            Positioned(
              top: 8,
              right: 8,
              left: 8,
              child: Column(
                children: [
                  Image(image: AssetImage('assets/gif/kissu_lock.gif')),

                  Text(
                    "一键锁定Ta的手机",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xff333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 30),
                    child: Text(
                      "随时锁定Ta的手机，不回消息或惹你生气时给Ta手机“按下暂停键”",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xff777777)),
                    ),
                  ),
                ],
              ),
            ),
             // 右上角关闭按钮
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  // 埋点2.2: VIP锁机弹窗点击关闭
                  AnalyticsHelper.trackVipLockPhoneClick(isFromChat: isFromChat, btnStatus: 0);
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            ),
            // 底部开通会员按钮
            Positioned(
              bottom: 24,
              left: 10,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    // 埋点2.2: VIP锁机弹窗点击进入
                    AnalyticsHelper.trackVipLockPhoneClick(isFromChat: isFromChat, btnStatus: 1);
                    Navigator.of(context).pop();
                    // 埋点7: 跳转到VIP开通页面，带上来源页和来源事件
                    Get.toNamed(
                      KissuRoutePath.vip,
                      arguments: {
                        'source_page': isFromChat ? SourcePageUtilsCaller.chat : SourcePageUtilsCaller.mine,
                        'source_event': isFromChat
                            ? ChatEvents.vipLockPhoneClick
                            : MyPageEvents.vipLockPhoneClick,
                      },
                    );
                  },
                  child: Image.asset(
                    'assets/lock/kissu_lock_vip_btn.webp',
                    width: 239,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
