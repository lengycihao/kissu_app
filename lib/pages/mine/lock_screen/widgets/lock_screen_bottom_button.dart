import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';
import '../lock_screen_controller.dart';

class LockScreenBottomButton extends StatefulWidget {
  const LockScreenBottomButton({super.key});

  @override
  State<LockScreenBottomButton> createState() => _LockScreenBottomButtonState();
}

class _LockScreenBottomButtonState extends State<LockScreenBottomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;
  bool _isLongPressing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.linear));
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isLongPressing) {
        // 埋点4: 长按锁机按钮事件
        AnalyticsHelper.trackLockPhoneLongPress();
        final controller = Get.find<LockScreenController>();
        controller.confirmLock();
        _animController.reset();
        _isLongPressing = false;
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LockScreenController>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 16),
      child: Obx(() {
        final step = controller.currentStep.value;

        if (step == 1) {
          return _buildStep1Button(controller);
        } else {
          return _buildStep2Button(controller);
        }
      }),
    );
  }

  Widget _buildStep1Button(LockScreenController controller) {
    return Obx(() {
      final canProceed = controller.isStep1Complete;
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: canProceed ? () {
            HapticFeedback.mediumImpact();
            controller.onStep1NextTap(context);
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canProceed ? Colors.black87 : Colors.grey[300],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
          ),
          child: Text(
            '下一步',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: canProceed ? Colors.white : Colors.grey[500],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildStep2Button(LockScreenController controller) {
    return Obx(() {
      final canLock = controller.isStep2Complete;

      if (!canLock) {
        return Column(
          children: [
            _buildActionButtons(controller),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xff999999),
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text(
                  '请先完善问题',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () => controller.goBackToStep1(),
              child: Text(
                '上一步',
                style: TextStyle(color: Color(0xff666666), fontSize: 16),
              ),
            ),
          ],
        );
      }

      // 长按确定锁机按钮
      return Column(
        children: [
          _buildActionButtons(controller),
          const SizedBox(height: 16),
          GestureDetector(
            onLongPressStart: (_) {
              _isLongPressing = true;
              HapticFeedback.mediumImpact();
              _animController.forward(from: 0.0);
            },
            onLongPressEnd: (_) {
              if (_animController.status != AnimationStatus.completed) {
                _isLongPressing = false;
                _animController.reset();
              }
            },
            onLongPressCancel: () {
              _isLongPressing = false;
              _animController.reset();
            },
            child: AnimatedBuilder(
              animation: _progressAnim,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.black87,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Stack(
                      children: [
                        // 进度填充
                        FractionallySizedBox(
                          widthFactor: _progressAnim.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7ECE),
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                        // 文字
                        const Center(
                          child: Text(
                            '长按确定锁机',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10),
          GestureDetector(
            onTap: () => controller.goBackToStep1(),
            child: Text(
              '上一步',
              style: TextStyle(color: Color(0xff666666), fontSize: 16),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildActionButtons(LockScreenController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => controller.randomQuestion(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/lock/kissu_lock_exchange.webp', width: 16),
              const SizedBox(width: 4),
              const Text(
                '系统随机问题',
                style: TextStyle(fontSize: 12, color: Color(0xFF009BFE)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
        GestureDetector(
          onTap: () => controller.clearAll(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/lock/kissu_lock_clean.webp', width: 16),
              const SizedBox(width: 4),
              const Text(
                '一键清空',
                style: TextStyle(fontSize: 12, color: Color(0xFF009BFE)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
