import 'package:flutter/material.dart';
import 'package:kissu_app/widgets/skeleton/skeleton_loading.dart';

/// 常见问题列表骨架屏
class QuestionListSkeleton extends StatelessWidget {
  const QuestionListSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(22),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _buildQuestionCardSkeleton();
      },
    );
  }

  Widget _buildQuestionCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonText(width: 200, height: 14),
                const SizedBox(height: 8),
                SkeletonText(
                  width: 150,
                  height: 12,
                  baseColor: const Color(0xFFEEEEEE),
                  highlightColor: const Color(0xFFF8F8F8),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SkeletonLoading(
            width: 16,
            height: 16,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}
