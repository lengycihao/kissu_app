import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'controllers/game_play_controller.dart';

/// 拍照惩罚执行页（发起者拍一张搞怪自拍发给对方）
class GamePenaltyPhotoPage extends StatefulWidget {
  const GamePenaltyPhotoPage({super.key});

  @override
  State<GamePenaltyPhotoPage> createState() => _GamePenaltyPhotoPageState();
}

class _GamePenaltyPhotoPageState extends State<GamePenaltyPhotoPage> {
  File? _photoFile;
  bool _isSending = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _photoFile = File(picked.path));
    }
  }

  Future<void> _onDone() async {
    if (_photoFile == null) {
      _takePhoto();
      return;
    }
    setState(() => _isSending = true);
    try {
      final ctrl = Get.find<GamePlayController>();
      // 通过IM发送图片（先上传到腾讯IM，获取URL后发送game_penalty_guesser消息）
      // 这里暂用file路径，后续接入接口替换
      await ctrl.imService.sendPenaltyProof(
        penaltyType: 'photo',
        proofUrl: _photoFile!.path,
      );
      // 发送完成，退出到聊天页
      Get.until((route) => route.settings.name == KissuRoutePath.chat);
    } catch (e) {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/say_guess/kissu_say_guess_bg.webp'),
            alignment: Alignment.topCenter,
          ),
          color: Colors.white,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Image.asset(
                        'assets/say_guess/kissu_say_guess_faile_small.webp',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '拍一张搞怪自拍，完成惩罚',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF666666),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildPhotoArea(),
                    ],
                  ),
                ),
              ),
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(Icons.chevron_left, size: 28, color: Color(0xFF333333)),
          ),
          const Expanded(
            child: Center(
              child: Image(
                image: AssetImage(
                  'assets/say_guess/kissu_say_guess_title.webp',
                ),
                width: 102,
                height: 24,
              ),
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _buildPhotoArea() {
    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        width: double.infinity,
        height: 260,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EEFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: _photoFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _photoFile!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 28,
                      color: Color(0xFFAA99EE),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '发一张搞怪自拍',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFAA99EE),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '点击拍照',
                    style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: GestureDetector(
        onTap: _isSending ? null : _onDone,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: _photoFile != null
                ? const LinearGradient(colors: [Color(0xFFFF90CA), Color(0xFFFF6B9D)])
                : null,
            color: _photoFile != null ? null : const Color(0xFFDDDDDD),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    _photoFile != null ? '完成' : '拍照',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
