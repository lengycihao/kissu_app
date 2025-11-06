import 'package:flutter/material.dart';

/// 我的页面-用户信息模块
class MineUserInfo extends StatelessWidget {
  final String nickname;
  final String partnerNickname;
  final bool isBound;
  final String days;
  final VoidCallback onLabelTap;
  final Widget avatarSection;

  const MineUserInfo({
    super.key,
    required this.nickname,
    required this.partnerNickname,
    required this.isBound,
    required this.days,
    required this.onLabelTap,
    required this.avatarSection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent, // 添加透明背景色确保空白区域也能点击
      padding: EdgeInsets.only(left: 18, right: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          avatarSection,
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔧 修复：动态调整昵称字体大小，未绑定时只显示自己的昵称
                SizedBox(
                  height: 24, // 限制高度，确保FittedBox有明确的约束
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isBound ? "$nickname & $partnerNickname" : nickname,
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xff333333),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(height: 3),
              if (isBound)
                Row(
                  children: [
                    Text(
                      "在一起",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xff666666),
                      ),
                    ),
                    SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Color(0xffFF82C6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        days,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xffffffff),
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      "天",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xff666666),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  "未绑定另一半",
                  style: TextStyle(fontSize: 12, color: Color(0xff999999)),
                ),
              SizedBox(height: 5),
              GestureDetector(
                onTap: onLabelTap,
                child: Row(
                  children: [
                    Text(
                      "恋爱信息",
                      style: TextStyle(fontSize: 12, color: Color(0xff666666)),
                    ),
                    SizedBox(width: 3),
                    Image(
                      image: AssetImage(
                        "assets/4.0/kissu4_mine_arrow_right_small.webp",
                      ),
                      width: 10,
                      height: 10,
                    ),
                  ],
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

