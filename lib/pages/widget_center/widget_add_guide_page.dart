import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/config/app_configN.dart';

const _kMoveToBackChannel = MethodChannel('kissu_app/move_to_back');

/// 添加小组件引导页（根据打包渠道显示对应图片）
class WidgetAddGuidePage extends StatefulWidget {
  const WidgetAddGuidePage({super.key});

  @override
  State<WidgetAddGuidePage> createState() => _WidgetAddGuidePageState();
}

class _WidgetAddGuidePageState extends State<WidgetAddGuidePage> {
  late final String _guideImage;

  @override
  void initState() {
    super.initState();
    final channel = AppConfigN.appChannel.toLowerCase();
    if (channel.contains('xiaomi')) {
      _guideImage = 'assets/say_guess/kissu_compent_xiaomi.webp';
    } else if (channel.contains('oppo')) {
      _guideImage = 'assets/say_guess/kissu_compent_oppo.webp';
    } else {
      _guideImage = 'assets/say_guess/kissu_compent_huawei.webp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFffffff),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/4.0/kissu4_new_use_bg.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 25),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: ClipRRect(
                      child: Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration:
                            const BoxDecoration(color: Colors.white),
                        child: Scrollbar(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Image.asset(
                              _guideImage,
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildBottomButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          Positioned(
            left: 5,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Image.asset(
                  "assets/images/kissu_mine_back.webp",
                  width: 22,
                  height: 22,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                '添加小组件',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
      child: GestureDetector(
        onTap: () {
          _kMoveToBackChannel.invokeMethod('moveToBack');
        },
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: const Text(
            '去设置',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
