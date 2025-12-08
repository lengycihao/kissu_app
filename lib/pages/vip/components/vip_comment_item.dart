import 'package:flutter/material.dart';
import 'package:kissu_app/models/vip_banner_model.dart';
import 'package:kissu_app/utils/network_image_helper.dart';

class VipCommentItem extends StatelessWidget {
  final CommentItem comment;

  const VipCommentItem({
    super.key,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCDBD7), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: comment.hasAvatar
                    ? NetworkImageHelper.loadImage(
                        imageUrl: comment.avatar,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        errorWidget: const SizedBox.shrink(),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              Text(
                comment.nickname,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              if (comment.hasVipIcon)
                NetworkImageHelper.loadImage(
                  imageUrl: comment.vipIcon,
                  width: 60,
                  height: 18,
                  fit: BoxFit.contain,
                  errorWidget: const SizedBox(width: 24, height: 24),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              comment.content,
              style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (comment.hasStarImage)
            NetworkImageHelper.loadImage(
              imageUrl: comment.starImage,
              width: 100,
              height: 20,
              fit: BoxFit.contain,
              errorWidget: const SizedBox(width: 100, height: 20),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}


