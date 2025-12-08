import 'package:flutter/material.dart';
import 'package:kissu_app/widgets/common_back_button.dart';

/// 我的页面-顶部导航栏
class MineTopBar extends StatelessWidget {
  final VoidCallback onBackTap;
  final VoidCallback onSettingTap;

  const MineTopBar({
    super.key,
    required this.onBackTap,
    required this.onSettingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ).copyWith(bottom: 0,left: 6,right: 15),
      child: Row(
        children: [
          CommonBackButton(
            onTap: onBackTap,
            assetPath: "assets/images/kissu_mine_back.webp",
          ),
          const Expanded(
            child: Center(
              child: Text(
                "我的",
                style: TextStyle(fontSize: 18, color: Color(0xff333333),fontWeight: FontWeight.w500),
              ),
            ),
          ),
          GestureDetector(
            onTap: onSettingTap,
            child: Image.asset(
              "assets/4.0/kissu4_setting.webp",
              width: 22,
              height: 22,
            ),
          ),
        ],
      ),
    );
  }
}

