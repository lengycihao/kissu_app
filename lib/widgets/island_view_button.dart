import 'package:flutter/material.dart';

/// 屏视图按钮组件（定位、足迹、天气）
class IslandViewButton extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String value;
  final Color valueColor;
  final VoidCallback? onTap;
  final bool showArrow; // 是否显示箭头

  const IslandViewButton({
    Key? key,
    required this.iconAsset,
    required this.title,
    required this.value,
    required this.valueColor,
    this.onTap,
    this.showArrow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 303,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFFFD4D0), width: 1),
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 22),
            Image(
              image: AssetImage(iconAsset),
              width: 20,
              height: 20,
            ),
            SizedBox(width: 20),
            Text(
              title,
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 12,
              ),
            ),
            Spacer(),
            Container(
              width: 88,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFAF4FF), Color(0x00FAF4FF)],
                ),
                borderRadius: BorderRadius.circular(44),
              ),
              child: Center(
                child: Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            SizedBox(width: 1),
            if (showArrow) ...[
              Image(
                image: AssetImage("assets/kissu_mine_arrow.webp"),
                width: 16,
                height: 16,
              ),
              SizedBox(width: 12),
            ] else ...[
              SizedBox(width: 29),
            ],
          ],
        ),
      ),
    );
  }
}

