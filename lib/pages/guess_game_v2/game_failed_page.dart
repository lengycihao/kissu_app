import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'controllers/game_play_controller.dart';

/// 挑战失败惩罚页
/// 发起者：可选择惩罚并确认；回答者：查看实时惩罚选择
class GameFailedPage extends StatefulWidget {
  const GameFailedPage({super.key});

  @override
  State<GameFailedPage> createState() => _GameFailedPageState();
}

class _GameFailedPageState extends State<GameFailedPage> {
  late final GamePlayController _ctrl;
  late final bool _isInitiator;

  String? _selectedPenalty; // 当前选中的惩罚类型

  final _penalties = [
    {'type': 'photo',   'icon': 'assets/say_guess/kissu_say_guess_photo.webp',   'label': '发一张搞怪自拍',  'bg': 0xFFDDF6FF},
    {'type': 'audio',   'icon': 'assets/say_guess/kissu_say_guess_audio.webp',   'label': '说10遍我爱你',   'bg': 0xFFE6E8FF},
    {'type': 'dinner',  'icon': 'assets/say_guess/kissu_say_guess_dinner.webp',  'label': '承包下次晚餐',   'bg': 0xFFFFE5EB},
    {'type': 'promise', 'icon': 'assets/say_guess/kissu_say_guess_promess.webp', 'label': '见面答应一件事', 'bg': 0xFFFFEDDE},
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<GamePlayController>();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _isInitiator = args['isInitiator'] as bool? ?? _ctrl.isInitiator;

    // 监听对方选择的惩罚（回答者视角）
    ever(_ctrl.receivedPenaltyType, (type) {
      if (type != null && type.isNotEmpty && !_isInitiator) {
        _onReceivedPenalty(type);
      }
    });
  }

  void _onReceivedPenalty(String penaltyType) {
    if (!mounted) return;
    setState(() => _selectedPenalty = penaltyType);

    // 回答者：跳转到对应执行页完成惩罚
    if (penaltyType == 'photo') {
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.toNamed(
          KissuRoutePath.guessGameV2PenaltyPhoto,
          arguments: {'penaltyType': penaltyType},
        );
      });
    } else if (penaltyType == 'audio') {
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.toNamed(
          KissuRoutePath.guessGameV2PenaltyAudio,
          arguments: {'penaltyType': penaltyType},
        );
      });
    }
    // 其他惩罚类型，停留在此页展示，显示再次游戏/退出按钮
  }

  void _onConfirm() {
    if (_selectedPenalty == null) return;
    // 发送惩罚选择给对方
    _ctrl.imService.sendPenaltySelected(_selectedPenalty!);

    if (_selectedPenalty == 'photo' || _selectedPenalty == 'audio') {
      // 发起者等待回答者发来凭证
      Get.toNamed(
        KissuRoutePath.guessGameV2PenaltyWait,
        arguments: {'penaltyType': _selectedPenalty, 'isInitiator': true},
      );
    } else {
      // 晚餐/承诺：选完直接回聊天
      Get.until((route) => route.settings.name == KissuRoutePath.chat);
    }
  }

  void _onSkip() {
    Get.until((route) => route.settings.name == KissuRoutePath.chat);
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
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Image.asset(
                          'assets/say_guess/kissu_say_guess_faile_small.webp',
                          width: 140,
                          height: 140,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),
                        if (_isInitiator)
                          const Text(
                            '哎呀，本轮挑战失败\n选一个甜蜜的惩罚给对方吧',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Color(0xFF333333), height: 1.6),
                          )
                        else
                          Obx(() => _ctrl.receivedPenaltyType.value == null
                              ? const Text(
                                  '等待对方选择惩罚...',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
                                )
                              : Text(
                                  '对方为你选择了：${_getPenaltyLabel(_ctrl.receivedPenaltyType.value!)}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFFF6B9D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                )),
                        const SizedBox(height: 24),
                        _buildPenaltyGrid(),
                        const SizedBox(height: 24),
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

  Widget _buildPenaltyGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 30,
        mainAxisSpacing: 20,
        childAspectRatio: 1,
      ),
      itemCount: _penalties.length,
      itemBuilder: (_, index) {
        final penalty = _penalties[index];
        final isSelected = _selectedPenalty == penalty['type'] as String;
        // 回答者视角：高亮对方选的惩罚
        final isReceivedSelected = !_isInitiator &&
            _ctrl.receivedPenaltyType.value == penalty['type'] as String;

        return GestureDetector(
          onTap: _isInitiator
              ? () => setState(() => _selectedPenalty = penalty['type'] as String)
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: Color(penalty['bg'] as int),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isSelected || isReceivedSelected)
                    ? Colors.black
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  penalty['icon'] as String,
                  width: 44,
                  height: 44,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                Text(
                  penalty['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: (isSelected || isReceivedSelected)
                        ? const Color(0xFFFF6B9D)
                        : const Color(0xFF666666),
                    fontWeight: (isSelected || isReceivedSelected)
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomButtons() {
    if (_isInitiator) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _selectedPenalty != null ? _onConfirm : null,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: _selectedPenalty != null
                      ? const LinearGradient(colors: [Color(0xFFFF90CA), Color(0xFFFF6B9D)])
                      : null,
                  color: _selectedPenalty != null ? null : const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Center(
                  child: Text(
                    '确认选择',
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
              onTap: _onSkip,
              child: const Text(
                '暂不选择',
                style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
              ),
            ),
          ],
        ),
      );
    } else {
      // 回答者：当收到非photo/audio惩罚时显示按钮
      return Obx(() {
        final received = _ctrl.receivedPenaltyType.value;
        if (received != null && received != 'photo' && received != 'audio') {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => Get.until(
                      (route) => route.settings.name == KissuRoutePath.guessGameV2Home),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFF90CA), Color(0xFFFF6B9D)]),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Center(
                      child: Text(
                        '再次游戏',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Get.until((route) => route.settings.name == KissuRoutePath.chat),
                  child: const Text(
                    '退出游戏',
                    style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox(height: 24);
      });
    }
  }

  String _getPenaltyLabel(String type) {
    return _penalties.firstWhere(
      (p) => p['type'] == type,
      orElse: () => {'label': type},
    )['label'] as String;
  }
}
