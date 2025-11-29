import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/model/setting/common_question_model/common_question_model.dart';
import 'package:kissu_app/network/public/setting_api.dart';
import 'package:kissu_app/pages/mine/sub_pages/question_page_info.dart';

class QuestionPage extends StatefulWidget {
  final int? targetProblemId; // 目标问题ID，如果提供则自动跳转到对应问题详情
  const QuestionPage({Key? key, this.targetProblemId}) : super(key: key);

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  List<CommonQuestionModel> questions = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // 延迟加载，等待页面转场动画完成
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        _loadQuestions();
      }
    });
  }

  Future<void> _loadQuestions() async {
    try {
      final settingApi = SettingApi();
      final result = await settingApi.getProblemList();

      if (result.isSuccess && result.data != null) {
        setState(() {
          questions = result.data!;
          isLoading = false;
        });
        
        // 如果有目标问题ID，自动跳转到对应的问题详情
        if (widget.targetProblemId != null) {
          _navigateToTargetQuestion();
        }
      } else {
        setState(() {
          errorMessage = result.msg ?? '加载失败';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = '网络错误: $e';
        isLoading = false;
      });
    }
  }

  /// 跳转到目标问题详情
  void _navigateToTargetQuestion() {
    final targetQuestion = questions.firstWhereOrNull(
      (question) => question.id == widget.targetProblemId,
    );
    
    if (targetQuestion != null) {
      // 找到对应的问题，跳转到详情页
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.to(
          () => QuestionPageInfo(question: targetQuestion),
          transition: Transition.rightToLeft,
        );
      });
    } else {
      // 没有找到对应的问题，显示提示
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          '提示',
          '未找到对应的问题信息',
          snackPosition: SnackPosition.TOP,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _QuestionPageContent(
      questions: questions,
      isLoading: isLoading,
      errorMessage: errorMessage,
      onRefresh: _loadQuestions,
      targetProblemId: widget.targetProblemId,
    );
  }
}

/// 问题页面内容组件
class _QuestionPageContent extends StatelessWidget {
  final List<CommonQuestionModel> questions;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final int? targetProblemId;

  const _QuestionPageContent({
    required this.questions,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    this.targetProblemId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/4.0/kissu4_new_use_bg.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Image.asset(
                        "assets/images/kissu_mine_back.webp",
                        width: 22,
                        height: 22,
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          "常见问题",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 22),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? _buildSkeletonList()
                    : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              errorMessage!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: onRefresh,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFEA39C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    : questions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无常见问题',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: onRefresh,
                        color: const Color(0xFFFEA39C),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(22),
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          itemCount: questions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            return _QuestionCard(
                              question: questions[index],
                              index: index,
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建骨架屏列表
  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.all(22),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _buildSkeletonCard();
      },
    );
  }

  /// 构建骨架屏卡片
  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 200,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

/// 问题卡片组件 - 带动画效果
class _QuestionCard extends StatefulWidget {
  final CommonQuestionModel question;
  final int index;

  const _QuestionCard({
    required this.question,
    required this.index,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 50)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: () {
            Get.to(
              () => QuestionPageInfo(question: widget.question),
              transition: Transition.rightToLeft,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/images/kissu_mine_question_bg.webp'),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.question.problem ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xff333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/images/kissu_mine_arrow.webp',
                  width: 16,
                  height: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
