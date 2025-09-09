import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:kissu_app/model/setting/common_question_model/common_question_model.dart';
import 'package:kissu_app/widgets/dash_top_border.dart';

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
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/kissu_mine_question_bg.webp'),
                    fit: BoxFit.fill,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(left: 21, right: 21, top: 30),
                child: Text(
                  widget.question.problem ?? "问题描述",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xff333333),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -5), // 往上移动 5px
                child: Container(
                  // padding: const EdgeInsets.only(left: 22, right: 22, bottom: 22),
                  margin: const EdgeInsets.only(
                    left: 22,
                    right: 22,
                    bottom: 22,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffffffff),

                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DashedTopBorderContainer(
                    borderRadius: 12,
                    borderWidth: 1,
                    borderColor: Color(0xffff6D4128),
                    dashWidth: 2,
                    dashSpace: 2,
                    child: Container(
                      width: double.infinity,
                      // decoration: BoxDecoration(
                      //   color: const Color(0xffffffff),
                      //   border: Border.all(color: const Color(0xff6D4128)),
                      //   borderRadius: BorderRadius.circular(10),
                      // ),
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.question.answer ?? "问题描述",
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.8,
                          color: Color(0xff333333),
                        ),
                      ),
                    ),
                  ),
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
