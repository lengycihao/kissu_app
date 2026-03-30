import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'controllers/game_play_controller.dart';

/// 录音惩罚执行页（发起者录一条语音发给对方）
class GamePenaltyAudioPage extends StatefulWidget {
  const GamePenaltyAudioPage({super.key});

  @override
  State<GamePenaltyAudioPage> createState() => _GamePenaltyAudioPageState();
}

class _GamePenaltyAudioPageState extends State<GamePenaltyAudioPage>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isSending = false;
  int _recordSeconds = 0;
  Timer? _timer;
  late AnimationController _waveController;

  // TODO: 接入真实录音功能（需要 flutter_sound 或 record 包）
  String? _recordedFilePath;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final min = _recordSeconds ~/ 60;
    final sec = _recordSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });
    _waveController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordSeconds++);
    });
    // TODO: 调用真实录音 API
  }

  void _stopRecording() {
    _timer?.cancel();
    _waveController.stop();
    setState(() {
      _isRecording = false;
      _hasRecording = _recordSeconds > 0;
      // TODO: 获取真实录音文件路径
      _recordedFilePath = 'mock_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    });
  }

  Future<void> _onDone() async {
    if (!_hasRecording) return;
    setState(() => _isSending = true);
    try {
      final ctrl = Get.find<GamePlayController>();
      await ctrl.imService.sendPenaltyProof(
        penaltyType: 'audio',
        proofUrl: _recordedFilePath ?? '',
      );
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
                      const SizedBox(height: 20),
                      const Text(
                        '请说10遍我爱你，完成惩罚',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF333333),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 37),
                      _buildRecordingCard(),
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

  Widget _buildRecordingCard() {
    return Container(
      width: 270,
      height: 270,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E8FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            '说10遍我爱你',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '00:$_formattedTime',
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 20),
          _buildWaveform(),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _isRecording ? const Color(0xFFFF6B9D) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: _isRecording ? Colors.white : const Color(0xFFAA99EE),
                size: 26,
              ),
            ),
          ),
          if (_isRecording) ...[
            const SizedBox(height: 8),
            const Text(
              '点击停止录音',
              style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
            ),
          ] else if (_hasRecording) ...[
            const SizedBox(height: 8),
            const Text(
              '点击重新录音',
              style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              '点击开始录音',
              style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(20, (i) {
            final base = 8.0;
            final maxHeight = 32.0;
            double height = base;
            if (_isRecording) {
              final phase = (i / 20 + _waveController.value) % 1.0;
              height = base + (maxHeight - base) * (0.3 + 0.7 * (0.5 + 0.5 * (phase * 2 - 1).abs()));
            } else if (_hasRecording) {
              height = base + ((i % 5) * 4.0);
            }
            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _isRecording
                    ? const Color(0xFFAA99EE)
                    : (_hasRecording ? const Color(0xFFBBBBBB) : const Color(0xFFDDDDDD)),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: GestureDetector(
        onTap: (_hasRecording && !_isSending) ? _onDone : null,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: _hasRecording
                ? const LinearGradient(colors: [Color(0xFFFF90CA), Color(0xFFFF6B9D)])
                : null,
            color: _hasRecording ? null : const Color(0xFFDDDDDD),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    '完成',
                    style: TextStyle(
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
