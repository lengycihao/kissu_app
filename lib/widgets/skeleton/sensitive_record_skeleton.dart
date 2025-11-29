import 'package:flutter/material.dart';
import 'package:kissu_app/widgets/skeleton/skeleton_loading.dart';

/// 敏感操作记录列表骨架屏
class SensitiveRecordSkeleton extends StatelessWidget {
  const SensitiveRecordSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 15).copyWith(bottom: 80, top: 20),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8, // 显示8个骨架屏卡片
      itemBuilder: (context, index) {
        return _buildRecordCardSkeleton();
      },
    );
  }

  Widget _buildRecordCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff000000).withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          // 左侧图标骨架
          SkeletonLoading(
            width: 18,
            height: 18,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(width: 6),
          // 中间文本骨架
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(
                  width: 200,
                  height: 13,
                ),
                const SizedBox(height: 4),
                SkeletonText(
                  width: 150,
                  height: 11,
                  baseColor: const Color(0xFFEEEEEE),
                  highlightColor: const Color(0xFFF8F8F8),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 右侧时间骨架
          SkeletonText(
            width: 40,
            height: 13,
            baseColor: const Color(0xFFEEEEEE),
            highlightColor: const Color(0xFFF8F8F8),
          ),
        ],
      ),
    );
  }
}
