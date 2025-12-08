import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/agreement_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:kissu_app/services/version_service.dart';
import 'package:kissu_app/widgets/common_back_button.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  String _version = '加载中...';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
      });
    } catch (e) {
      setState(() {
        _version = '1.0.1'; // 默认版本号
      });
    }
  }

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
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Image.asset(
              "assets/images/kissu_mine_arrow.webp",
              width: 16,
              height: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          // 背景图
          Positioned.fill(
            child: Image.asset(
              "assets/4.0/kissu4_new_use_bg.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),

          Column(
            children: [
              // 自定义导航栏
              Padding(
                padding:   EdgeInsets.only(top: MediaQuery.of(context).padding.top+12, left: 6, right: 16),
                child: Row(
                  children: [
                    CommonBackButton(
                      onTap: () => Get.back(),
                      assetPath: "assets/images/kissu_mine_back.webp",
                      iconSize: 22,
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

              const SizedBox(height: 30),

              // App 图标 - 添加动画效果
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFEA39C).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      "assets/3.0/kissu3_about_us_logo.webp",
                      width: 90,
                      height: 90,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

               

              // 版本号
              Text(
                  "当前版本：v$_version",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),

              const SizedBox(height: 32),

              // 列表
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage("assets/images/kissu_setting_aboutus.webp"),
                        fit: BoxFit.fill,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildItem("隐私协议", () {
                          AgreementUtils.toPrivacyAgreement();
                        }),
                        _buildDashedDivider(),
                        _buildItem("用户协议", () {
                          AgreementUtils.toUserAgreement();
                        }),
                        _buildDashedDivider(),
                        _buildItem("检查更新", () {
                          final versionService = Get.find<VersionService>();
                          versionService.checkVersionForAboutPage(context);
                        }),
                      ],
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
