import 'package:flutter/material.dart';

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
        horizontal: 18,
        vertical: 16,
      ).copyWith(bottom: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBackTap,
            child: Image.asset(
              "assets/images/kissu_mine_back.webp",
              width: 22,
              height: 22,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "我的",
                style: TextStyle(fontSize: 18, color: Color(0xff333333)),
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

