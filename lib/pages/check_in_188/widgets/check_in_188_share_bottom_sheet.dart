import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kissu_app/utils/oktoast_util.dart';

/// 188活动分享底部弹窗组件
class CheckIn188ShareBottomSheet extends StatelessWidget {
  final int activityId;
  
  const CheckIn188ShareBottomSheet({
    super.key,
    required this.activityId,
  });

  /// 显示分享弹窗
  static void show(BuildContext context, int activityId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CheckIn188ShareBottomSheet(activityId: activityId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 30),
              const Text(
                '分享至',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.close,
                  size: 24,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // 分享选项
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildShareOption(
                icon: 'assets/188/kissu_188_share_wechat.webp',
                label: '微信好友',
                onTap: () => _shareToWeChatFriend(context),
              ),
              _buildShareOption(
                icon: 'assets/188/kissu_188_share_wechat_friend.webp',
                label: '微信朋友圈',
                onTap: () => _shareToWeChatMoments(context),
              ),
              _buildShareOption(
                icon: 'assets/188/kissu_188_share_qq.webp',
                label: 'QQ',
                onTap: () => _shareToQQ(context),
              ),
              _buildShareOption(
                icon: 'assets/188/kissu_188_share_copy.webp',
                label: '复制链接',
                onTap: () => _copyLink(context),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 底部安全区域
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// 构建分享选项
  Widget _buildShareOption({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            icon,
            width: 40,
            height: 40,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  /// 分享到微信好友
  void _shareToWeChatFriend(BuildContext context) {
    Navigator.of(context).pop();
    // TODO: 调用微信分享SDK
    OKToastUtil.showInfo('分享到微信好友功能开发中');
  }

  /// 分享到微信朋友圈
  void _shareToWeChatMoments(BuildContext context) {
    Navigator.of(context).pop();
    // TODO: 调用微信朋友圈分享SDK
    OKToastUtil.showInfo('分享到微信朋友圈功能开发中');
  }

  /// 分享到QQ
  void _shareToQQ(BuildContext context) {
    Navigator.of(context).pop();
    // TODO: 调用QQ分享SDK
    OKToastUtil.showInfo('分享到QQ功能开发中');
  }

  /// 复制链接
  void _copyLink(BuildContext context) {
    Navigator.of(context).pop();
    
    // TODO: 生成实际的邀请链接
    const inviteLink = 'https://www.kissu.app/188activity?code=xxxxx';
    
    Clipboard.setData(const ClipboardData(text: inviteLink)).then((_) {
      OKToastUtil.showInfo('复制成功');
    }).catchError((error) {
      OKToastUtil.showInfo('复制失败');
    });
  }
}
