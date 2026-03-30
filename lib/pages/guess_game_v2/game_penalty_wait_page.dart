import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'controllers/game_play_controller.dart';

/// 发起者等待/查看惩罚凭证页
class GamePenaltyWaitPage extends StatefulWidget {
  const GamePenaltyWaitPage({super.key});

  @override
  State<GamePenaltyWaitPage> createState() => _GamePenaltyWaitPageState();
}

class _GamePenaltyWaitPageState extends State<GamePenaltyWaitPage> {
  late final GamePlayController _ctrl;
  late final String _penaltyType;
  String? _proofUrl; // null = 仍在等待
  bool _isPlaying = false;

  String get _penaltyLabel {
    switch (_penaltyType) {
      case 'photo': return '发一张搞怪自拍';
      case 'audio': return '说10遍我爱你';
      default:      return '完成惩罚';
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<GamePlayController>();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _penaltyType = args['penaltyType'] as String? ?? 'photo';

    ever(_ctrl.receivedPenaltyProof, (proofUrl) {
      if (proofUrl != null && proofUrl.isNotEmpty && mounted) {
        setState(() => _proofUrl = proofUrl);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
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
                        const SizedBox(height: 16),
                        Image.asset(
                          'assets/say_guess/kissu_say_guess_faile_small.webp',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '查看恋爱惩罚',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 37),
                        _proofUrl == null
                            ? _buildWaiting()
                            : _penaltyType == 'photo'
                                ? _buildPhotoProof(_proofUrl!)
                                : _buildAudioProof(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                _buildBottomButtons(),
              ],
            ),
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
            onTap: () => Get.until((route) => route.settings.name == KissuRoutePath.chat),
            child: const Icon(Icons.chevron_left, size: 28, color: Color(0xFF333333)),
          ),
          const Expanded(
            child: Center(
              child: Image(
                image: AssetImage('assets/say_guess/kissu_say_guess_title.webp'),
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

  Widget _buildWaiting() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFAA99EE)),
          ),
          SizedBox(width: 12),
          Text(
            '等待对方发送凭证...',
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoProof(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 260,
          decoration: BoxDecoration(
            color: const Color(0xFFF0EEFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined, size: 48, color: Color(0xFFAAAAAA)),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioProof() {
    return Container(
      width: 270,
      height: 270,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E8FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _penaltyLabel,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 30),
         Image(image: AssetImage('assets/say_guess/kissu_say_guess_audio.webp',),width: 50,),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: () => setState(() => _isPlaying = !_isPlaying),
            child: Container(
              width: 70,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(22),
              ),
              alignment: Alignment.center,
              child:Text(
                    _isPlaying ? '暂停' : '播放',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Get.until(
                (route) => route.settings.name == KissuRoutePath.guessGameV2Home),
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: Color(0xffFF9AD9),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Center(
                child: Text(
                  '再来一轮',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Get.until(
                (route) => route.settings.name == KissuRoutePath.chat),
            child: const Text(
              '退出游戏',
              style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
            ),
          ),
        ],
      ),
    );
  }
}
