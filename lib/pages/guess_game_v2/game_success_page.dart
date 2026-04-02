import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';

/// 挑战成功分享页
class GameSuccessPage extends StatelessWidget {
  const GameSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final correctCount = args['correctCount'] as int? ?? 0;
    final tacitPercent = args['tacitPercent'] as String? ?? '0%';

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
                        'assets/say_guess/kissu_say_guess_success.webp',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '第231名',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Image(
                            image: AssetImage(
                              'assets/say_guess/kissu_say_guess_star.webp',
                            ),
                            width: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'x12',
                            style: TextStyle(
                              fontSize: 8,
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildResultCard(correctCount, tacitPercent),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              _buildBottomButtons(
                isInitiator: args['isInitiator'] as bool? ?? false,
              ),
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
            onTap: () => Get.until(
              (route) => route.settings.name == KissuRoutePath.guessGameV2Home,
            ),
            child: const Icon(
              Icons.chevron_left,
              size: 28,
              color: Color(0xFF333333),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '结算',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _buildResultCard(int correctCount, String tacitPercent) {
    return Container(
      width: 275,
      height: 245,
       decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            'assets/say_guess/kissu_say_guess_share_bg_left.webp',
          ),
          fit: BoxFit.cover
        ),
       ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
             
            child: const Center(
              child: Text(
                '心有灵犀！',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          Padding(
            padding:   EdgeInsets.only(left: 40,right: 40,top: 20),
            child: Column(
              children: [
                _buildStatRow('回答正确', '$correctCount'),
                // const SizedBox(height: 14),
                // _buildStatRow('连胜暴击', 'X${correctCount * 12}'),
                const SizedBox(height: 14),
                _buildStatRow(
                  '默契度',
                  tacitPercent,
                ),
                const SizedBox(height: 16),
                const Text(
                  '使用默契特权不计入+2星范围',
                  style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons({required bool isInitiator}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (isInitiator) {
                Get.until(
                  (route) =>
                      route.settings.name == KissuRoutePath.guessGameV2Home,
                );
              } else {
                Get.until(
                  (route) => route.settings.name == KissuRoutePath.chat,
                );
              }
            },
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
           SizedBox(height: 40,)
           
        ],
      ),
    );
  }

 
}
