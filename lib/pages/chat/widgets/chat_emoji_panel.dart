import 'package:flutter/material.dart';

/// 表情类型枚举
enum EmojiType {
  normal,  // 常规表情
  vip,     // 会员表情
}

/// 会员动态表情数据模型
class VipEmoji {
  final String id;
  final String name;
  final String url; // 动图URL或本地路径

  VipEmoji({
    required this.id,
    required this.name,
    required this.url,
  });
}

/// 表情面板组件
class ChatEmojiPanel extends StatefulWidget {
  final Function(String)? onEmojiSelected;
  final Function(VipEmoji)? onVipEmojiSelected;
  final bool isVip; // 是否是会员

  const ChatEmojiPanel({
    super.key,
    this.onEmojiSelected,
    this.onVipEmojiSelected,
    this.isVip = false,
  });

  @override
  State<ChatEmojiPanel> createState() => _ChatEmojiPanelState();
}

class _ChatEmojiPanelState extends State<ChatEmojiPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 常规表情列表
  static const List<String> _normalEmojis = [
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
    '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩',
    '😘', '😗', '😚', '😙', '😋', '😛', '😜', '🤪',
    '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨',
    '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥',
    '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕',
    '🤢', '🤮', '🤧', '🥵', '🥶', '🥴', '😵', '🤯',
    '🤠', '🥳', '😎', '🤓', '🧐', '😕', '😟', '🙁',
    '😮', '😯', '😲', '😳', '🥺', '😦', '😧', '😨',
    '😰', '😥', '😢', '😭', '😱', '😖', '😣', '😞',
    '😓', '😩', '😫', '🥱', '😤', '😡', '😠', '🤬',
    '👍', '👎', '👌', '✌️', '🤞', '🤟', '🤘', '🤙',
    '👏', '🙌', '👐', '🤲', '🤝', '🙏', '💪', '🦾',
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
    '💔', '❣️', '💕', '💞', '💓', '💗', '💖', '💘',
    '💝', '💟', '☮️', '✝️', '☪️', '🕉️', '☸️', '✡️',
  ];

  // 会员表情列表（动图）
  // TODO: 这里使用模拟数据，实际应从服务器获取
  static final List<VipEmoji> _vipEmojis = List.generate(
    24,
    (index) => VipEmoji(
      id: 'vip_emoji_${index + 1}',
      name: '会员表情${index + 1}',
      url: 'assets/emojis/vip/emoji_${index + 1}.gif', // 动图路径
    ),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 标签栏
            _buildTabBar(),

            // 表情内容区
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNormalEmojiGrid(),
                  _buildVipEmojiGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 标签栏
  Widget _buildTabBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xffBA92FD),
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        indicatorColor: const Color(0xffBA92FD),
        indicatorWeight: 2.5,
        tabs: [
          Tab(
            child: Container(
              width: 70,
              child: Image.asset(
                'assets/chat/kissu3_emoji_common.webp',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Tab(
            child: Container(
              width: 115,
              child: Image.asset(
                'assets/chat/kissu3_emoji_vip.webp',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 常规表情网格
  Widget _buildNormalEmojiGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: _normalEmojis.length,
      itemBuilder: (context, index) {
        return _buildNormalEmojiItem(_normalEmojis[index]);
      },
    );
  }

  // 会员表情网格
  Widget _buildVipEmojiGrid() {
    // 非会员用户显示升级提示
    if (!widget.isVip) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              '升级会员解锁动态表情',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: 跳转到会员购买页面
                debugPrint('跳转到会员购买页面');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffBA92FD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('立即升级'),
            ),
          ],
        ),
      );
    }

    // 会员用户显示动态表情列表
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _vipEmojis.length,
      itemBuilder: (context, index) {
        return _buildVipEmojiItem(_vipEmojis[index]);
      },
    );
  }

  // 常规表情项
  Widget _buildNormalEmojiItem(String emoji) {
    return GestureDetector(
      onTap: () => widget.onEmojiSelected?.call(emoji),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  // 会员表情项（动图）
  Widget _buildVipEmojiItem(VipEmoji emoji) {
    return GestureDetector(
      onTap: () => widget.onVipEmojiSelected?.call(emoji),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildVipEmojiImage(emoji),
        ),
      ),
    );
  }

  // 会员表情图片（动图）
  Widget _buildVipEmojiImage(VipEmoji emoji) {
    // TODO: 实际应该从网络或本地加载GIF动图
    // 这里使用占位图标代替
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gif_box,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 4),
            Text(
              emoji.name,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
    
    // 实际使用时应该这样加载GIF：
    // return Image.network(
    //   emoji.url,
    //   fit: BoxFit.cover,
    //   errorBuilder: (context, error, stackTrace) {
    //     return Icon(Icons.broken_image, color: Colors.grey);
    //   },
    // );
  }
}

