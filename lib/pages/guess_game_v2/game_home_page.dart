import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oktoast/oktoast.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'controllers/game_home_controller.dart';
import 'models/game_models.dart';
import 'services/game_api_service.dart';
import 'package:kissu_app/utils/user_manager.dart';

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
                  child: GestureDetector(
                    onTap: () => _showRulesDialog(context),
                    child: Image(
                      image: AssetImage(
                        'assets/say_guess/kissu_say_guess_tips.webp',
                      ),
                      width: 24,
                    ),
                  ),
                ),
              ),
              // const SizedBox(height: 30),
              _buildIconArea(),
              const SizedBox(height: 10),
              _buildStartButton(),
              const SizedBox(height: 20),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    Obx(() => _buildHistoryTabs(controller.selectedTab.value)),
                    const SizedBox(height: 20),
                    Expanded(
                      child: PageView(
                        controller: controller.pageController,
                        onPageChanged: (i) => controller.switchTab(i),
                        children: [
                          Obx(
                            () => _buildHistoryPage(
                              controller.myInitiatedRecords,
                              isMy: true,
                            ),
                          ),
                          Obx(
                            () => _buildHistoryPage(
                              controller.taInitiatedRecords,
                              isMy: false,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildAppBar() {
    return Container(
      height: 44,
      color: Colors.transparent,
      child: Stack(
        children: [
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
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                Get.toNamed(KissuRoutePath.guessGameV2PenaltyRecord);
              },
              child: Container(
                height: 40,
                alignment: Alignment.center,
                child: Text(
                  "惩罚记录",
                  style: TextStyle(fontSize: 12, color: Color(0xff777777)),
                ),
              ),
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
        const SizedBox(height: 1),
        // // 星星 + 得分
        // Obx(
        //   () => Row(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: [
        //       Image(
        //         image: AssetImage('assets/say_guess/kissu_say_guess_star.webp'),
        //         width: 35,
        //       ),
        //       const SizedBox(width: 4),
        //       Text(
        //         'X${controller.totalScore.value}',
        //         style: const TextStyle(
        //           fontSize: 12,
        //           fontWeight: FontWeight.w500,
        //           color: Color(0xFF000000),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
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
        onTap: () async {
          // 跳转到选题页面
          await Get.toNamed(KissuRoutePath.guessGameV2TopicSelection);
          controller.refreshData();
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
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

  Widget _buildHistoryPage(List<GameRecord> records, {required bool isMy}) {
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

    final hasMore = isMy
        ? controller.hasMoreMy.value
        : controller.hasMoreTa.value;

    return RefreshIndicator(
      color: const Color(0xFFFF90CA),
      onRefresh: () => controller.refreshData(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (scroll) {
          if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 100 &&
              hasMore &&
              !controller.isLoadingMore.value) {
            controller.loadMore();
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: records.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= records.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF90CA),
                    ),
                  ),
                ),
              );
            }
            return _buildRecordItem(records[index]);
          },
        ),
      ),
    );
  }

  /// 单条历史记录
  Widget _buildRecordItem(GameRecord record) {
    final dateStr = DateFormat('yyyy/MM/dd HH:mm:ss').format(record.createTime);
    Widget statusWidget;

    if (record.status == GameRecordStatus.ongoing) {
      statusWidget = GestureDetector(
        onTap: () async {
          await Get.toNamed(
            KissuRoutePath.guessGameV2Play,
            arguments: {
              'groupId': record.groupId,
              'isInitiator': record.isMeInitiator,
            },
          );
          controller.refreshData();
        },
        child: Container(
          height: 58,
          width: 58,
          alignment: Alignment.center,
          child: Text(
            record.isMeInitiator ? '进行中' : '去挑战',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
      onTap: () => _onRecordTap(record),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ).copyWith(right: 20),
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
                    '发起方：${record.isMeInitiator ? '我' : (UserManager.getUserBasicInfo()['partnerNickname'] as String? ?? 'Ta')}',
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

  Future<void> _onRecordTap(GameRecord record) async {
    if (record.status == GameRecordStatus.passed) {
      // 通关 → 调对局详情接口获取数据，跳转成功页
      final info = await GameApiService().getGameInfo(record.groupId);
      if (info != null) {
        Get.toNamed(
          KissuRoutePath.guessGameV2Success,
          arguments: {
            'correctCount': info.correctAnswerNums,
            'tacitPercent': info.tacitPercent,
            'isInitiator': record.isMeInitiator,
          },
        );
      } else {
        showToast('获取对局详情失败');
      }
    } else if (record.status == GameRecordStatus.failed) {
      // 失败 → 提示去惩罚记录查看
      showToast('请去惩罚记录中查看详情');
    } else {
      // 进行中 → 进入游戏页面
      await Get.toNamed(
        KissuRoutePath.guessGameV2Play,
        arguments: {
          'groupId': record.groupId,
          'isInitiator': record.isMeInitiator,
        },
      );
      controller.refreshData();
    }
  }

  void _showRulesDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text(
                    '游戏规则',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff333333),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    physics: const BouncingScrollPhysics(),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: '基本规则\n',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xff333333),
                              fontWeight: FontWeight.w500,
                              height: 2.5,
                            ),
                          ),
                          const TextSpan(
                            text:
                                '每轮游戏由5道题组成，支持发起者自定义题目和描述\n'
                                '每轮游戏通过定义：每轮总答题数≥3题即通过本轮\n'
                                '游戏组合难度采用逐轮进行制，通过一轮+1⭐，每轮全部答对+2⭐（不含特权跳过的），由简单到难；难度逐步增加；如失败下次进入游戏仍为上次停留难度，成功下次进入为下一轮难度\n'
                                '\n'
                                '本次游戏支持双人/单人模式，单人模式即一方出完题，另一方根据已出题的描述语进行猜题\n',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xff777777),
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                          
                          const TextSpan(
                            text: '游戏玩法\n',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xff333333),
                              fontWeight: FontWeight.w500,
                              height: 2.5,
                            ),
                          ),
                          const TextSpan(
                            text:
                                '我要猜一方根据对方的描述进行回答，每道题有4次答案提交机会（聊天不占用机会），到指定次数仍未答对则本题失败，自动进入下一题；每道题可使用一次提示'
                                '每轮可使用一次特权，可选择直接跳过本题（按答对计算）或增加一次答题机会\n'
                                '每轮失败即进入情侣惩罚，描述者可选择不同惩罚给猜题者完成，需线下完成的会产生二维码，需双方线下扫码核验\n',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xff777777),
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 8,
              top: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/lock/kissu_lock_close.webp',
                    width: 16,
                    height: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
