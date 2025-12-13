import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/pages/chat/chat_settings_controller.dart';

class ChatSettingsPage extends GetView<ChatSettingsController> {
  const ChatSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: _buildContent(),
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
        '设置',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 修改昵称
          _buildNicknameItem(),
        
          // 设置聊天背景
          _buildSettingItem(
            title: '设置聊天背景',
            onTap: controller.setChatBackground,
            showArrow: true,
          ), 
          // 设置聊天气泡
          _buildSettingItem(
            title: '设置聊天气泡',
            onTap: controller.setChatBubbles,
            showArrow: true,
          ), 
          // 敏感信息
          _buildSettingItem(
            title: '敏感信息',
            subtitle: '可设置聊天页面中敏恋信息展示/隐藏',
            onTap: controller.setSensitiveInfo,
            showArrow: true,
          ), 
          // 设置聊天主题
          _buildSettingItem(
            title: '设置聊天主题',
            onTap: controller.setChatTheme,
            showArrow: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    required bool showArrow,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xcc000000),
                      fontSize:13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing,
            ],
           Row(
            children: [
               if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0x99000000),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
            if (showArrow) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF999999),
                size: 20,
              ),
            ],
            ],
           )
            
          ],
        ),
      ),
    );
  }

  Widget _buildNicknameItem() {
    return InkWell(
      onTap: controller.editNickname,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                '修改昵称',
                style: TextStyle(
                  color: Color(0xcc000000),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Obx(() => controller.isEditingNickname.value
                ? SizedBox(
                    width: 120,
                    child: TextField(
                      controller: controller.nicknameController,
                      focusNode: controller.nicknameFocusNode,
                      style: const TextStyle(
                        color: Color(0x99000000),
                        fontSize: 11,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xffBA92FD)),
                        ),
                      ),
                      onSubmitted: (_) => controller.saveNickname(),
                    ),
                  )
                : Text(
                    controller.currentNickname.value,
                    style: const TextStyle(
                      color: Color(0x99000000),
                      fontSize: 11,
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

