import 'package:flutter/material.dart';
import '../mine_controller.dart';

/// 我的页面-应用设置模块
class MineSettings extends StatelessWidget {
  final List<SettingItem> items;

  const MineSettings({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox.shrink(),
        itemBuilder: (_, index) {
          final item = items[index];
          return GestureDetector(
            onTap: item.onTap,
            behavior: HitTestBehavior.opaque, // 确保整个区域都能响应点击
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 19,
                vertical: 12, // 增加垂直内边距，扩大点击区域
              ),
              child: Row(
                children: [
                  Image.asset(item.icon, width: 20, height: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF000000),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    "assets/4.0/kissu4_arrow_right.webp",
                    width: 16,
                    height: 16,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

