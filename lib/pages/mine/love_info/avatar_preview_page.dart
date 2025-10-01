import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/no_placeholder_image.dart';
import 'love_info_controller.dart';

class AvatarPreviewPage extends StatefulWidget {
  const AvatarPreviewPage({Key? key}) : super(key: key);

  @override
  State<AvatarPreviewPage> createState() => _AvatarPreviewPageState();
}

class _AvatarPreviewPageState extends State<AvatarPreviewPage> {
  late LoveInfoController _controller;
  
  // 当前显示的大图头像URL
  String _currentDisplayAvatar = '';

  @override
  void initState() {
    super.initState();
    _controller = Get.find<LoveInfoController>();
    _loadAvatarData();
  }

  void _loadAvatarData() {
    // 获取传入的参数
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      final avatarUrl = arguments['avatarUrl'] as String?;
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        _currentDisplayAvatar = avatarUrl;
      } else {
        // 如果没有传入头像URL，默认显示自己的头像
        _currentDisplayAvatar = _controller.myAvatar.value;
      }
    } else {
      // 默认显示自己的头像
      _currentDisplayAvatar = _controller.myAvatar.value;
    }
    
    setState(() {});
  }

  void _onAvatarTap(String avatarUrl) {
    setState(() {
      _currentDisplayAvatar = avatarUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          '头像预览',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 大图显示区域
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.all(20),
                child: _currentDisplayAvatar.isNotEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          // 计算合适的显示尺寸，确保不超过可用空间
                          double maxSize = constraints.maxWidth < constraints.maxHeight 
                              ? constraints.maxWidth 
                              : constraints.maxHeight;
                          double imageSize = maxSize * 0.8; // 使用80%的可用空间
                          
                          return NoPlaceholderImage(
                            imageUrl: _currentDisplayAvatar,
                            defaultAssetPath: "assets/kissu_icon.webp",
                            width: imageSize,
                            height: imageSize,
                            fit: BoxFit.contain,
                          );
                        },
                      )
                    : const Center(
                        child: Text(
                          '暂无头像',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          
          // 底部头像选择区域
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: _buildBottomAvatarSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAvatarSection() {
    return Obx(() {
      if (!_controller.isBindPartner.value) {
        // 未绑定状态：只显示自己的头像（因为只能点击自己头像进入）
        return _buildSingleAvatar();
      } else {
        // 已绑定状态：显示两人的头像（因为可以点击自己和另一半头像都进入）
        return _buildCoupleAvatars();
      }
    });
  }

  Widget _buildSingleAvatar() {
    return Obx(() => Column(
      children: [
        const Text(
          '我的头像',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => _onAvatarTap(_controller.myAvatar.value),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _currentDisplayAvatar == _controller.myAvatar.value 
                    ? const Color(0xFF2196F3) 
                    : Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: NoPlaceholderImage(
                imageUrl: _controller.myAvatar.value,
                defaultAssetPath: "assets/kissu_icon.webp",
                width: 78,
                height: 78,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '点击查看',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    ));
  }

  Widget _buildCoupleAvatars() {
    return Obx(() => Column(
      children: [
        const Text(
          '我们的头像',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 我的头像
            GestureDetector(
              onTap: () => _onAvatarTap(_controller.myAvatar.value),
              child: Container(
                width:_currentDisplayAvatar == _controller.myAvatar.value ? 82 : 68,
                height:_currentDisplayAvatar == _controller.myAvatar.value ? 82 : 68,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    
                  image: DecorationImage(
                    image: AssetImage("assets/3.0/kissu3_avater_border.webp"),
                    fit: BoxFit.fill,
                  ),
                ),
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(39),
                  child: NoPlaceholderImage(
                    imageUrl: _controller.myAvatar.value,
                    defaultAssetPath: "assets/kissu_icon.webp",
                    width: 78,
                    height: 78,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // 对方头像
            GestureDetector(
              onTap: () => _onAvatarTap(_controller.partnerAvatar.value),
              child: Container(
                width:_currentDisplayAvatar == _controller.partnerAvatar.value ? 82 : 68,
                height:_currentDisplayAvatar == _controller.partnerAvatar.value ? 82 : 68,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    
                  image: DecorationImage(
                    image: AssetImage("assets/3.0/kissu3_avater_border.webp"),
                    fit: BoxFit.fill,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: NoPlaceholderImage(
                    imageUrl: _controller.partnerAvatar.value,
                    defaultAssetPath: "assets/kissu_icon.webp",
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          '点击查看',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    ));
  }
}
