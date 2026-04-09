import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:kissu_app/model/setting/common_question_model/common_question_model.dart';

class QuestionPageInfo extends StatefulWidget {
  final CommonQuestionModel question;
  const QuestionPageInfo({Key? key, required this.question}) : super(key: key);

  @override
  State<QuestionPageInfo> createState() => _QuestionPageInfoState();
}

class _QuestionPageInfoState extends State<QuestionPageInfo> {
  final List<QuestionItem> questions = [
    QuestionItem(
      question: "开通会员后为什么一方的定位会获取不到？",
      answer: "因为定位权限需要双方都开启，并且一方处于在线状态才可获取。",
    ),
    QuestionItem(
      question: "如果我们绑定且充值会员，解除关系后会员还会存在吗？",
      answer: "会员会在解除关系后失效，但充值记录会保留在系统中，可用于后续恢复。",
    ),
    QuestionItem(
      question: "解除关系后再重新绑定，我们之前的记录数据还会存在吗？",
      answer:
          "暂时是不会存在的。我们的初衷KISSU是提供给情侣的恋爱升温工具，所有为了方便大家的体验，我们仅会保留近7天的数据，7天后会永久删除。",
    ),
    QuestionItem(
      question: "我们是情侣，为什么绑定关系还需要对方审核？",
      answer: "为了保护双方的隐私和安全，绑定需要双方确认，避免误操作或骚扰。",
    ),
  ];

  final GlobalKey _questionTextKey = GlobalKey();
  double _questionSpacing = 20.0; // 固定的间距

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6f6f6),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/4.0/kissu4_new_use_bg.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 顶部导航栏
                SizedBox(
                  height: 44,
                  child: Stack(
                    children: [
                      // 返回按钮
                      Positioned(
                        left: 5,
                        top: 0,
                        bottom: 0,
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
                        child: Center(
                          child: Text(
                            "常见问题",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xcc000000),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // 内容区域
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // 问题详情卡片
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 问题标题
                              Row(
                                children: [
                                  Image(
                                    image: AssetImage('assets/images/kissu_question_q.webp'),
                                    width: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.question.problem ?? '问题描述',
                                      key: _questionTextKey,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xff333333),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: _questionSpacing),
                              // 答案内容
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Image(
                                      image: AssetImage('assets/images/kissu_question_a.webp'),
                                      width: 16,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.question.answer ?? '答案描述',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.8,
                                        color: Color(0xff333333),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
