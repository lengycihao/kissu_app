import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/agreement_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:kissu_app/services/version_service.dart';
import 'package:kissu_app/utils/image_saver_util.dart';

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


  Widget _buildItem(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF000000),
                 ),
              ),
            ),
            const SizedBox(width: 8),
            Image.asset(
              "assets/images/kissu_mine_arrow.webp",
              // color: Color(0x66000000),
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
      backgroundColor: const Color(0xFFF6F6F6),
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
              SizedBox(
                height: 44 + MediaQuery.of(context).padding.top,
                child: Stack(
                  children: [
                    // 返回按钮
                    Positioned(
                      left: 5,
                      top: MediaQuery.of(context).padding.top,
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
                      top: MediaQuery.of(context).padding.top,
                      bottom: 0,
                      child: Center(
                        child: Text(
                          "关于我们",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                    ),
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                       color: Color(0xffffffff),
                      borderRadius: BorderRadius.circular(16),
                       
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildItem("隐私协议", () {
                          AgreementUtils.toPrivacyAgreement();
                        }),
                         _buildItem("用户协议", () {
                          AgreementUtils.toUserAgreement();
                        }),
                         _buildItem("检查更新", () {
                          final versionService = Get.find<VersionService>();
                          versionService.checkVersionForAboutPage(context);
                        }),
                         _buildItem("kissu福利官", () {
                          _showFuliDialog(context);
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

  /// 显示福利官弹窗
  void _showFuliDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // 允许点击背景关闭弹窗
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return GestureDetector(
          // 点击背景关闭弹窗
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.opaque,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: GestureDetector(
              // 阻止点击事件向上传递，防止点击图片时关闭弹窗
              onTap: () {},
              child: Center(
                child: SizedBox(
                  width: 294,
                  height: 443,
                  child: Stack(
                    children: [
                      // 主图片（固定大小 294 * 443）
                      Image.asset(
                        'assets/setting/kissu_fuli_dialog.webp',
                        width: 294,
                        height: 443,
                        fit: BoxFit.cover,
                      ),
                      // 保存按钮（叠加在图片底部）
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: () async {
                              // 保存图片到相册
                              final success = await ImageSaverUtil.saveAssetImageToGallery(
                                'assets/setting/kissu_fuli_dialog.webp',
                              );
                              if (success) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: Image.asset(
                              'assets/setting/kissu_fuli_save.webp',
                              width: 222,
                              height: 50,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
