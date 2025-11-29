import 'package:flutter/material.dart';
import 'package:kissu_app/utils/network_image_helper.dart';

/// 我的页面-头像区域
class MineAvatarSection extends StatelessWidget {
  final String userAvatar;
  final String partnerAvatar;
  final bool isBound;
  final VoidCallback onAvatarTap;
  final VoidCallback onPartnerAvatarTap;

  const MineAvatarSection({
    super.key,
    required this.userAvatar,
    required this.partnerAvatar,
    required this.isBound,
    required this.onAvatarTap,
    required this.onPartnerAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none, // 允许子元素超出边界显示
          children: [
            // 用户头像 - 只有这个有点击事件
            GestureDetector(
              onTap: onAvatarTap,
              child: _buildAvatar(),
            ),
            // 另一半头像或添加按钮 - 独立的点击事件
            Positioned(
              right: -15,
              bottom: 0,
              child: GestureDetector(
                onTap: onPartnerAvatarTap,
                child: _buildPartnerAvatar(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xffffffff), width: 2),
        borderRadius: BorderRadius.circular(80),
      ),
      child: ClipOval(
        child: userAvatar.startsWith('assets/')
            ? Image.asset(
                userAvatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: const Color(0xFFE8B4CB),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.white,
                    ),
                  );
                },
              )
            : NetworkImageHelper.loadImage(
                imageUrl: userAvatar,
                fit: BoxFit.cover,
                errorWidget: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: const Color(0xFFE8B4CB),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }

  // 另一半头像显示逻辑
  Widget _buildPartnerAvatar() {
    // 未绑定时不显示第二个头像
    if (!isBound) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFffffff), width: 2),
      ),
      child: ClipOval(
        child: partnerAvatar.startsWith('assets/')
            ? Image.asset(
                partnerAvatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: const Color(0xFFE8B4CB),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 24,
                      color: Colors.white,
                    ),
                  );
                },
              )
            : NetworkImageHelper.loadImage(
                imageUrl: partnerAvatar,
                fit: BoxFit.cover,
                errorWidget: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: const Color(0xFFE8B4CB),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }
}

