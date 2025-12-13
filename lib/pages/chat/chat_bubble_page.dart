import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/chat/chat_bubble_controller.dart';

class ChatBubblePage extends GetView<ChatBubbleController> {
  const ChatBubblePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        appBar: _buildAppBar(),
        body: _buildBubbleList(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Colors.black,
          size: 20,
        ),
        onPressed: () => Get.back(),
      ),
      title: const Text(
        '设置聊天气泡',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: SizedBox(
            width: 70,
            height: 33,
            child: ElevatedButton(
              onPressed: controller.applyBubbleStyle,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF90CA),
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.5),
                ),
                elevation: 0,
              ),
              child: const Text(
                '使用',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBubbleList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: ChatBubbleController.bubbleStyles.length,
      itemBuilder: (context, index) {
        final style = ChatBubbleController.bubbleStyles[index];
        return _buildBubbleItem(style);
      },
    );
  }

  Widget _buildBubbleItem(int style) {
    return Obx(() {
      final isSelected = controller.selectedBubbleStyle.value == style;
      
      return InkWell(
        onTap: () => controller.selectBubbleStyle(style),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 头像（左边）- 圆形
              ClipOval(
                child: Image.asset(
                  'assets/3.0/kissu3_love_avater.webp',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              // 气泡（中间）- 使用other资源
              Container(
                width: 146,
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/chat/kissu_chat_bubble_show$style.webp'),
                    fit: BoxFit.fill,
                  ),
                ) 
              ),
              const Spacer(),
              // 单选框（右边）
              Image.asset(
                isSelected
                    ? 'assets/chat/kissu_chat_bubble_sel.webp'
                    : 'assets/chat/kissu_chat_bubble_unsel.webp',
                width: 20,
                height: 20,
              ),
            ],
          ),
        ),
      );
    });
  }
}

