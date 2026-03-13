import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/chat/chat_background_controller.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/utils/source_page_utils.dart';

class ChatBackgroundPage extends GetView<ChatBackgroundController> {
  const ChatBackgroundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: _buildBackgroundGrid(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(44 + MediaQuery.of(Get.context!).padding.top),
      child: Container(
        height: 55 + MediaQuery.of(Get.context!).padding.top,
        color: Colors.white,
        child: Stack(
          children: [
            // 返回按钮
            Positioned(
              left: 5,
              top: MediaQuery.of(Get.context!).padding.top,
              bottom: 0,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: Image.asset(
                    "assets/images/kissu_mine_back.webp",
                    width: 22,
                    height: 22,
                  ),
                ),
              ),
            ),
            // 标题 - 绝对居中
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(Get.context!).padding.top,
              bottom: 0,
              child: const Center(
                child: Text(
                  '聊天背景',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundGrid() {
    return Obx(() {
      final backgrounds = controller.allBackgrounds;
      // 背景数量 + 1个添加按钮
      final itemCount = backgrounds.length + 1;

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.56, // 接近手机屏幕比例
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == backgrounds.length) {
            // 最后一个是添加按钮
            return _buildAddButton();
          } else {
            // 背景缩略图
            final bgItem = backgrounds[index];
            return _buildBackgroundThumbnail(bgItem, index);
          }
        },
      );
    });
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: controller.addBackgroundFromGallery,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Image.asset(
          'assets/chat/kissu_add_picture.webp',
          width: 40,
          height: 40,
        ),
      ),
    );
  }

  Widget _buildBackgroundThumbnail(ChatBackgroundItem bgItem, int index) {
    return Obx(() {
      final isSelected = controller.selectedBackground.value == bgItem.path;

      return GestureDetector(
        onTap: () => _showPreviewBottomSheet(bgItem),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: const Color(0xFF000000), width: 1.5)
                : null,
          ),
          child: Stack(
            children: [
              // 背景图片
              ClipRRect(
                borderRadius: BorderRadius.circular(isSelected ? 6 : 8),
                child: Image(
                  image: controller.getBackgroundImageProvider(bgItem.path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFF5F5F5),
                      child: const Icon(
                        Icons.broken_image,
                        color: Color(0xFF999999),
                      ),
                    );
                  },
                ),
              ),
              // VIP标识
              if (bgItem.requiresVip)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Image.asset(
                    'assets/images/logo_vip.webp',
                    width: 28,
                    height: 16,
                  ),
                ),
              // 选中标识
              if (isSelected)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF90CA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  void _showPreviewBottomSheet(ChatBackgroundItem bgItem) {
    Get.bottomSheet(
      _PreviewBottomSheet(
        bgItem: bgItem,
        controller: controller,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

/// 预览底部弹窗
class _PreviewBottomSheet extends StatelessWidget {
  final ChatBackgroundItem bgItem;
  final ChatBackgroundController controller;

  const _PreviewBottomSheet({
    required this.bgItem,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    

    return Container(
      height: screenHeight * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFFffffff),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: controller.getBackgroundImageProvider(bgItem.path),
                  fit: BoxFit.cover,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildMockChatUI(),
              ),
            ),
    );
  }

  Widget _buildMockChatUI() {
    final bottomPadding = MediaQuery.of(Get.context!).padding.bottom;
    return Column(
      children: [
        // 顶部信息栏
        _buildMockHeader(),
        // 设备信息栏
        _buildMockDeviceInfo(),_buildMockMessages(),
        // 聊天消息区域
        // Expanded(
        //   child: _buildMockMessages(),
        // ),
        Spacer(),
        // 底部按钮
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 16),
            child: _buildBottomButton(),
          ),
      ],
    );
  }

  Widget _buildMockHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        
      ),
      child: Row(
        children: [
          // 返回按钮
          const Icon(Icons.arrow_back_ios, size: 18, color: Color(0xff333333)),
          const SizedBox(width: 8),
          // 头像
          SizedBox(
            width: 40,
            height: 40,
            child: Image(image: AssetImage('assets/chat/kissu_chat_bg_header.webp')),
          ),
          const SizedBox(width: 12),
          // 对方输入中...
          const Expanded(
            child: Text(
              '对方输入中...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xff333333),
              ),
            ),
          ),
          // 设置按钮
          const Icon(Icons.more_vert, size: 20, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _buildMockDeviceInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDeviceInfoItem('Iphone 1...', 'assets/phone_history/kissu_phone_type.webp'),
          _buildDeviceInfoItem('相距120km', 'assets/phone_history/kissu_phone_distance.webp'),
          _buildDeviceInfoItem('85%', 'assets/phone_history/kissu_phone_barry.webp'),
          _buildDeviceInfoItem('WIFI', 'assets/phone_history/kissu_phone_wifi.webp'),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoItem(String text, String? iconPath) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (iconPath != null) ...[
          Image.asset(iconPath, width: 16, height: 16),
          const SizedBox(height: 2),
        ],
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildMockMessages() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Image(image: AssetImage('assets/chat/kissu_chat_bg_message.webp')),
    );
  }

  Widget _buildBottomButton() {
    if (bgItem.requiresVip && !controller.chatController.isVip.value) {
      // 需要VIP且用户非VIP - 显示开通会员按钮
      return GestureDetector(
        onTap: () {
          Get.back();
          Get.toNamed(
            KissuRoutePath.vip,
            arguments: {
              'source_event': ChatEvents.bgBtn,
              'source_page':SourcePageUtilsCaller.chat,
            },
          );
        },
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_vip_bottom.webp',
                width: 34,
                height: 34,
              ),
              const SizedBox(width: 8),
              const Text(
                '开通会员',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // 免费 - 显示立即更换按钮
      return GestureDetector(
        onTap: () {
          controller.selectBackground(bgItem.path);
          controller.applyBackground();
          Get.back();
        },
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Center(
            child: Text(
              '立即更换',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }
  }
}

