import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  Widget _buildDashedDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 7),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 2.0;
          const dashSpace = 1.0;
          final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xffE6E2E3)),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildItem(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
              ),
            ),
            Image.asset("assets/kissu_mine_arrow.webp", width: 16, height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图
          Positioned.fill(
            child: Image.asset("assets/kissu_mine_bg.webp", fit: BoxFit.cover),
          ),

          Column(
            children: [
              // 自定义导航栏
              Padding(
                padding: const EdgeInsets.only(top: 62, left: 20, right: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Image.asset(
                        "assets/kissu_mine_back.webp",
                        width: 24,
                        height: 24,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      "关于我们",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 24),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // App 图标
              Image.asset("assets/kissu_icon.webp", width: 80, height: 80),

              const SizedBox(height: 20),

              // 版本号
              const Text(
                "当前版本:1.2.0",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 27),

              // 列表
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage("assets/kissu_setting_aboutus.webp"),
                      fit: BoxFit.fill,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildItem("去评分", () {
                        // TODO: 打开应用商店评分
                      }),
                      _buildDashedDivider(),
                      _buildItem("隐私协议", () {
                        // TODO: 跳转隐私协议页面
                      }),
                      _buildDashedDivider(),
                      _buildItem("用户协议", () {
                        // TODO: 跳转用户协议页面
                      }),
                    ],
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
