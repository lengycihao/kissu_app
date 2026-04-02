import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'services/game_api_service.dart';

/// 选择惩罚方式页（在惩罚记录页"Ta的惩罚"中 penaltyType==0 时进入）
/// 仅选择惩罚类型，不含凭证上传
/// arguments: {'groupId': String}
class GamePenaltySelectPage extends StatefulWidget {
  const GamePenaltySelectPage({super.key});

  @override
  State<GamePenaltySelectPage> createState() => _GamePenaltySelectPageState();
}

class _GamePenaltySelectPageState extends State<GamePenaltySelectPage> {
  late final String _groupId;
  final _api = GameApiService();

  int _selectedType = 0; // 0=未选
  bool _submitting = false;

  final _penalties = [
    {'type': 1, 'icon': 'assets/say_guess/kissu_say_guess_photo.webp',   'label': '发一张搞怪自拍',  'bg': 0xFFDDF6FF},
    {'type': 2, 'icon': 'assets/say_guess/kissu_say_guess_audio.webp',   'label': '说10遍我爱你',   'bg': 0xFFE6E8FF},
    {'type': 3, 'icon': 'assets/say_guess/kissu_say_guess_dinner.webp',  'label': '承包下次晚餐',   'bg': 0xFFFFE5EB},
    {'type': 4, 'icon': 'assets/say_guess/kissu_say_guess_promess.webp', 'label': '见面答应一件事', 'bg': 0xFFFFEDDE},
  ];

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _groupId = args['groupId'] as String? ?? '';
  }

  Future<void> _onConfirm() async {
    if (_selectedType == 0) {
      showToast('请先选择惩罚方式');
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final ok = await _api.selectPenalty(
        groupId: _groupId,
        penaltyType: _selectedType,
      );
      if (!mounted) return;
      if (ok) {
        showToast('已选择惩罚方式');
        Get.back(result: true);
      } else {
        showToast('提交失败，请重试');
        setState(() => _submitting = false);
      }
    } catch (e) {
      if (mounted) {
        showToast('操作失败: $e');
        setState(() => _submitting = false);
      }
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
                      const SizedBox(height: 16),
                      Image.asset(
                        'assets/say_guess/kissu_say_guess_faile_small.webp',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '选择一个甜蜜的惩罚给对方吧',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildPenaltyGrid(),
                      const SizedBox(height: 24),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(Icons.chevron_left, size: 28, color: Color(0xFF333333)),
            ),
          ),
          const Image(
            image: AssetImage('assets/say_guess/kissu_say_guess_title.webp'),
            width: 102,
            height: 24,
          ),
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
        final p = _penalties[index];
        final pType = p['type'] as int;
        final isSelected = _selectedType == pType;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = pType),
          child: Container(
            decoration: BoxDecoration(
              color: Color(p['bg'] as int),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(p['icon'] as String, width: 44, height: 44, fit: BoxFit.contain),
                const SizedBox(height: 8),
                Text(
                  p['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? const Color(0xFFFF6B9D) : const Color(0xFF666666),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomButton() {
    final canSubmit = _selectedType > 0 && !_submitting;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          GestureDetector(
            onTap: canSubmit ? _onConfirm : null,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: canSubmit
                    ? const LinearGradient(colors: [Color(0xFFFF90CA), Color(0xFFFF6B9D)])
                    : null,
                color: canSubmit ? null : const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        '确认选择',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Get.back(),
            child: const Text(
              '暂不选择',
              style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
            ),
          ),
        ],
      ),
    );
  }
}
