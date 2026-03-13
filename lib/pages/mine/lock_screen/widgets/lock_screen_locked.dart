import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/mine/lock_screen/widgets/lock_screen_header.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';
import '../lock_screen_controller.dart';

class LockScreenLockedView extends StatelessWidget {
  const LockScreenLockedView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LockScreenController>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Image.asset(
            'assets/lock/kissu_lock_bg.webp',
            width: double.infinity,
            fit: BoxFit.fitWidth,
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              // 固定的顶部导航栏（透明，覆盖在背景图上）
              LockScreenTopBar(),
              // 顶部固定内容
              SizedBox(height: 30),
              Image(
                image: AssetImage('assets/lock/kissu_lock_bg_top.webp'),
                height: 130,
              ),
              SizedBox(height: 30),
              const Text(
                'Ta的手机已被锁定',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              // 计时器
              Obx(
                () => Text(
                  controller.lockDuration.value,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 解除锁定按钮
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      // 埋点5: 主动解锁按钮点击事件
                      AnalyticsHelper.trackLockPhoneInitiativeUnlock();
                      controller.unlockDevice();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '解除锁定',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // 锁定记录列表（可滚动）
              Expanded(
                child: _buildLockRecords(controller, bottomPadding),
              ),
            ],
          ),
        ),
      ],
    );
  }

 
  Widget _buildLockRecords(LockScreenController controller, double bottomPadding) {
    return Obx(() {
      if (controller.lockRecords.isEmpty) {
        return const SizedBox.shrink();
      }
      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >= notification.metrics.maxScrollExtent - 50) {
            controller.loadMoreLockRecords();
          }
          return false;
        },
        child: ListView.builder(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: bottomPadding + 20),
          itemCount: controller.lockRecords.length + (controller.lockRecordHasMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= controller.lockRecords.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF7ECE),
                    ),
                  ),
                ),
              );
            }
            return _buildRecordItem(controller.lockRecords[index]);
          },
        ),
      );
    });
  }

  Widget _buildRecordItem(LockRecord record) {
    final dateStr =
        '${record.dateTime.year}/${record.dateTime.month.toString().padLeft(2, '0')}/${record.dateTime.day.toString().padLeft(2, '0')} '
        '${record.dateTime.hour.toString().padLeft(2, '0')}:${record.dateTime.minute.toString().padLeft(2, '0')}:${record.dateTime.second.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '第${record.index}锁机',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xff333333),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  record.duration,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: Color(0xffaaaaaa)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
