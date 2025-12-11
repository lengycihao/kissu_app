import 'package:flutter/material.dart';
import 'package:kissu_app/widgets/skeleton/skeleton_loading.dart';

/// 推送设置模块骨架屏
class NotificationSettingsSkeleton extends StatelessWidget {
  final String? title;
  
  const NotificationSettingsSkeleton({Key? key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.only(left: 10, right: 10, top: 12, bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 模块标题
          if (title != null)
            Text(
              title!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            )
          else
            const SkeletonText(width: 80, height: 16),
          const SizedBox(height: 11),
          // 骨架屏占位项
          _buildItemSkeleton(),
          _buildItemSkeleton(),
          _buildItemSkeleton(),
        ],
      ),
    );
  }

  Widget _buildItemSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xfff9f9f9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SkeletonText(width: 100, height: 13),
                const SizedBox(height: 4),
                SkeletonText(
                  width: double.infinity,
                  height: 11,
                  baseColor: const Color(0xFFEEEEEE),
                  highlightColor: const Color(0xFFF8F8F8),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SkeletonLoading(
            width: 38,
            height: 20,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}
