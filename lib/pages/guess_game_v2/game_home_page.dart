import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'controllers/game_home_controller.dart';
import 'models/game_models.dart';

/// 你说我猜V2 首页：开始游戏 + 历史记录列表
class GameHomePage extends GetView<GameHomeController> {
  const GameHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/say_guess/kissu_say_guess_bg.webp'),
            alignment: AlignmentGeometry.topCenter,
          ),
          color: Colors.white,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Align(
                alignment: AlignmentGeometry.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Image(
                    image: AssetImage(
                      'assets/say_guess/kissu_say_guess_tips.webp',
                    ),
                    width: 24,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    _buildIconArea(),
                    const SizedBox(height: 30),
                    _buildStartButton(),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _buildHistoryList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 顶部导航栏
  _buildAppBar() {
    return Container(
      height: 44,
      color: Colors.transparent,
      child: Stack(
        children: [
          // 返回按钮
          Positioned(
            left: 5,
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
            top: 0,
            bottom: 0,
            child: const Center(
              child: Image(
                image: AssetImage(
                  'assets/say_guess/kissu_say_guess_title.webp',
                ),
                width: 102,
                height: 24,
              ),
            ),
          ),
          // 标题 - 绝对居中
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Row(
              children: [
                Text(
                  "惩罚记录",
                  style: TextStyle(fontSize: 12, color: Color(0xff777777)),
                ),
                SizedBox(width: 10),
                Image(
                  image: AssetImage(
                    'assets/say_guess/kissu_say_guess_share.webp',
                  ),
                  width: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 图标区域：图标 + 星星得分 + 排名
  Widget _buildIconArea() {
    return Column(
      children: [
        // kissu_say_guess.webp 图标
        Image.asset(
          'assets/say_guess/kissu_say_guess.webp',
          width: 108,
          height: 82,
          errorBuilder: (_, __, ___) => Container(
            width: 108,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.assignment_turned_in,
              size: 48,
              color: Color(0xFFFF90CA),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 星星 + 得分
        Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 22, color: Color(0xFFFFD700)),
              const SizedBox(width: 4),
              Text(
                'X${controller.totalScore.value}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Text(
            '排名:${controller.ranking.value}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
          ),
        ),
      ],
    );
  }

  /// 开始游戏按钮
  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GestureDetector(
        onTap: () {
          // 跳转到选题页面
          Get.toNamed(KissuRoutePath.guessGameV2TopicSelection);
        },
        child: Container(
          width: 280,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Center(
            child: Text(
              '开始游戏',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 历史记录列表
  Widget _buildHistoryList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFFFF90CA)),
          ),
        );
      }

      final selected = controller.selectedTab.value;
      return Column(
        children: [
          const SizedBox(height: 6),
          _buildHistoryTabs(selected),
          const SizedBox(height: 20),
          Expanded(
            child: PageView(
              controller: controller.pageController,
              onPageChanged: (i) => controller.switchTab(i),
              children: [
                _buildHistoryPage(controller.myInitiatedRecords),
                _buildHistoryPage(controller.taInitiatedRecords),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildHistoryTabs(int selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildHistoryTabItem(
            label: '我发起的',
            selected: selected == 0,
            onTap: () {
              controller.switchTab(0);
              controller.pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
              );
            },
          ),
          const SizedBox(width: 22),
          _buildHistoryTabItem(
            label: 'Ta发起的',
            selected: selected == 1,
            onTap: () {
              controller.switchTab(1);
              controller.pageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTabItem({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111111) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF777777),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryPage(List<GameRecord> records) {
    if (records.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(
              image: AssetImage('assets/say_guess/kissu_say_guess_empty.webp'),
              width: 56,
            ),
            SizedBox(height: 8),
            Text(
              '这里什么都没有',
              style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: records.length,
      itemBuilder: (context, index) => _buildRecordItem(records[index]),
    );
  }

  /// 单条历史记录
  Widget _buildRecordItem(GameRecord record) {
    final dateStr = DateFormat('yyyy/MM/dd HH:mm:ss').format(record.createTime);
    Widget statusWidget;

    if (record.status == GameRecordStatus.ongoing) {
      statusWidget = GestureDetector(
        onTap: () {
          Get.toNamed(
            KissuRoutePath.guessGameV2Play,
            arguments: {
              'groupId': record.groupId,
              'isInitiator': record.isMeInitiator,
            },
          );
        },
        child: Container(
          height: 58, width: 58,
          alignment: Alignment.center,
          child: const Text(
            '查看',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xffFF9AD9),
            ),
          ),
        ),
      );
    } else if (record.status == GameRecordStatus.passed) {
      statusWidget = Image.asset(
        'assets/say_guess/kissu_say_guess_history_success.webp',
        width: 58,
        height: 58,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Text(
          '通过',
          style: TextStyle(
            color: Color(0xFF4CAF50),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else {
      statusWidget = Image.asset(
        'assets/say_guess/kissu_say_guess_history_fail.webp',
        width: 58,
        height: 58,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Text(
          '失败',
          style: TextStyle(
            color: Color(0xFFFF4444),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // 点击记录进入游戏页面
        Get.toNamed(
          KissuRoutePath.guessGameV2Play,
          arguments: {
            'groupId': record.groupId,
            'isInitiator': record.isMeInitiator,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15).copyWith(right: 20),
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage(
              'assets/say_guess/kissu_say_guess_history_bg.webp',
            ),
            fit: BoxFit.fill,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '发起方：${record.initiator}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
            statusWidget,
          ],
        ),
      ),
    );
  }
}
