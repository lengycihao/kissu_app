import 'package:flutter/material.dart';
import '../mine_controller.dart';

/// 我的页面-常用功能模块
class MineCommonFunctions extends StatelessWidget {
  final List<CommonFunctionItem> items;

  const MineCommonFunctions({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(bottom: 12, top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部标题
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 28),
            child: Text(
              "常用功能",
              style: TextStyle(
                fontSize: 15,
                color: Color(0xff000000),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // 功能图标网格（两排，每排4个）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Column(
              children: [
                // 第一排
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(4, (index) {
                    if (index < items.length) {
                      return _buildFunctionItem(items[index]);
                    }
                    return const SizedBox.shrink();
                  }),
                ),
                const SizedBox(height: 23),
                // 第二排
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(4, (index) {
                    final itemIndex = index + 4;
                    if (itemIndex < items.length) {
                      return _buildFunctionItem(items[itemIndex]);
                    }
                    return const SizedBox.shrink();
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建单个功能项
  Widget _buildFunctionItem(CommonFunctionItem item) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              item.icon,
              width: 44,
              height: 44,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.image_not_supported,
                    size: 24,
                    color: Color(0xFF999999),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              style: TextStyle(fontSize: 12, color: Color(0xff000000)),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

