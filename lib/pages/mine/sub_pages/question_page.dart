import 'package:flutter/material.dart';

import 'package:get/get.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({Key? key}) : super(key: key);

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  final List<QuestionItem> questions = [
    QuestionItem(
      question: "开通会员后为什么一方的定位会获取不到？",
      answer: "因为定位权限需要双方都开启，并且一方处于在线状态才可获取。",
    ),
    QuestionItem(
      question: "如果我们绑定且充值会员，解除关系后会员还会存在吗？",
      answer:
          "会员会在解除关系后失效，但充值记录会保留在系统中，可用于后续恢复。",
    ),
    QuestionItem(
      question: "解除关系后再重新绑定，我们之前的记录数据还会存在吗？",
      answer:
          "暂时是不会存在的。我们的初衷KISSU是提供给情侣的恋爱升温工具，所有为了方便大家的体验，我们仅会保留近7天的数据，7天后会永久删除。",
    ),
    QuestionItem(
      question: "我们是情侣，为什么绑定关系还需要对方审核？",
      answer:
          "为了保护双方的隐私和安全，绑定需要双方确认，避免误操作或骚扰。",
    ),
  ];

  // 用来记录每条是否展开
  final List<bool> expanded = [];

  @override
  void initState() {
    super.initState();
    expanded.addAll(List.filled(questions.length, false));
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
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
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
                child: ListView.separated(
                  padding: const EdgeInsets.all(22),
                  itemCount: questions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          expanded[index] = !expanded[index];
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage('assets/kissu_mine_question_bg.webp'),
                            fit: BoxFit.fill,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    questions[index].question,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xff333333),
                                    ),
                                  ),
                                ),
                                Transform.rotate(
                                  angle: expanded[index] ? 3.14 / 2 : 0,
                                  child: Image.asset(
                                    'assets/kissu_mine_arrow.webp',
                                    width: 16,
                                    height: 16,
                                  ),
                                ),
                              ],
                            ),
                            if (expanded[index])
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  questions[index].answer,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xff666666),
                                    height: 1.4,
                                  ),
                                ),
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

class QuestionItem {
  final String question;
  final String answer;

  QuestionItem({required this.question, required this.answer});
}
