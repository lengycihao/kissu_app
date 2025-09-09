import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:kissu_app/model/setting/common_question_model/common_question_model.dart';
import 'package:kissu_app/network/public/setting_api.dart';
import 'package:kissu_app/pages/mine/sub_pages/question_page_info.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({Key? key}) : super(key: key);

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
    _loadQuestions();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/kissu_mine_bg.webp', fit: BoxFit.cover),
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
                        "assets/kissu_mine_back.webp",
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
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadQuestions,
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    : questions.isEmpty
                    ? const Center(child: Text('暂无数据'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(22),
                        itemCount: questions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              // TODO: 导航到问题详情页
                              Get.to(
                                () => QuestionPageInfo(
                                  question: questions[index],
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                image: const DecorationImage(
                                  image: AssetImage(
                                    'assets/kissu_mine_question_bg.webp',
                                  ),
                                  fit: BoxFit.fill,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          questions[index].problem ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xff333333),
                                          ),
                                        ),
                                      ),
                                      Image.asset(
                                        'assets/kissu_mine_arrow.webp',
                                        width: 16,
                                        height: 16,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
