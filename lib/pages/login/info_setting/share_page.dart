import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'share_controller.dart';

class SharePage extends StatelessWidget {
  const SharePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Get.put(ShareController());

    return Obx(
      () => Stack(
        children: [
          // 背景图层
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/kissu_mine_bg.webp"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          Scaffold(
            backgroundColor: Colors.transparent,
            body: GestureDetector(
              onTap: () {
                // 点击页面其他地方时释放键盘和光标
                FocusScope.of(context).unfocus();
              },
              child: SafeArea(
                child: Column(
                  children: [
                    // 自定义标题栏
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () =>  Get.offAllNamed(KissuRoutePath.home),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                'assets/kissu_mine_back.webp',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),

                          // 占位符保持标题居中
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    // 页面内容
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            const SizedBox(height: 30),
                            // 主要内容容器
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(30),
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                    "assets/kissu_share_bg.webp",
                                  ),
                                  fit: BoxFit.fill,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // 头像
                                  Stack(
                                    children: [
                                      _buildAvatar(),
                                      Container(
                                        width: 50,
                                        height: 50,
                                        margin: EdgeInsets.only(
                                          left: 60,
                                          top: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                            color: const Color(0xFFFFB6C1),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          size: 30,
                                          color: Color(0xFFFF69B4),
                                        ),
                                      ),
                                      Positioned(
                                        right: 30,
                                        top: 40,
                                        child: Image(
                                          image: AssetImage(
                                            "assets/kissu_heart.webp",
                                          ),
                                          width: 29,
                                          height: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // 自定义row - 两个图片中间只有文字
                                  _buildCustomRow(),
                                  const SizedBox(height: 15),

                                  // 匹配吗输入框和绑定按钮
                                  _buildMatchInputRow(),
                                  const SizedBox(height: 15),

                                  // 二维码图片
                                  _buildQRCode(),
                                  const SizedBox(height: 10),

                                  // 扫描文字
                                  _buildScanText(),
                                  const SizedBox(height: 15),

                                  // 我的匹配码
                                  _buildMatchCodeSection(),
                                  const SizedBox(height: 20),

                                  // 分享按钮行
                                  _buildShareButtons(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 46),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建头像
  Widget _buildAvatar() {
    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/kissu_loveinfo_header_bg.webp'),
          fit: BoxFit.fill,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: ClipOval(
          child: Get.find<ShareController>().userAvatar.value.isNotEmpty
              ? Image.network(
                  Get.find<ShareController>().userAvatar.value,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        color: const Color(0xFFE8B4CB),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    );
                  },
                )
              : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: const Color(0xFFE8B4CB),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  /// 构建自定义row - 两个图片中间只有文字
  Widget _buildCustomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/kissu_loveinfo_day_left.png',
          width: 32,
          height: 36,
        ),
        const SizedBox(width: 8),
        const Text(
          '绑定另一半体验全部功能',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'LiuHuanKaTongShouShu',
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(width: 8),
        Image.asset(
          'assets/kissu_loveinfo_day_right.png',
          width: 32,
          height: 36,
        ),
      ],
    );
  }

  /// 构建匹配输入框和绑定按钮
  Widget _buildMatchInputRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: TextField(
              controller: Get.find<ShareController>().matchCodeController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],

              // textAlign: TextAlign.left,
              decoration: const InputDecoration(
                hintText: '请输入对方的匹配码',

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8, // 增加垂直内边距确保居中
                ),
                isDense: true, // 减少默认内边距

                alignLabelWithHint: true,
                hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 14),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
          ),
        ),
        const SizedBox(width: 18),
        GestureDetector(
          onTap: () => Get.find<ShareController>().bindPartner(),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFF69B4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                '绑定',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建二维码
  Widget _buildQRCode() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Get.find<ShareController>().qrCodeUrl.value.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                Get.find<ShareController>().qrCodeUrl.value,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.qr_code,
                      size: 60,
                      color: Color(0xFF999999),
                    ),
                  );
                },
              ),
            )
          : const Center(
              child: Icon(Icons.qr_code, size: 60, color: Color(0xFF999999)),
            ),
    );
  }

  /// 构建扫描文字
  Widget _buildScanText() {
    return const Text(
      '扫描KISSU二维码和我匹配吧~',
      style: TextStyle(fontSize: 14, color: Color(0xFFAA7268)),
    );
  }

  /// 构建匹配码部分
  Widget _buildMatchCodeSection() {
    return Column(
      children: [
        const Text(
          '我的匹配码',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFFFF69B4),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Color(0x22FF69B4),
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
          width: 150,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                Get.find<ShareController>().matchCode.value,
                style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Get.find<ShareController>().copyMatchCode(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.copy_outlined,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建分享按钮
  Widget _buildShareButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildShareButton(
          icon: 'assets/kissu_qq.webp',
          text: 'QQ邀请',
          onTap: () => Get.find<ShareController>().shareToQQ(),
        ),
        _buildShareButton(
          icon: 'assets/kissu_wechat.webp',
          text: '微信邀请',
          onTap: () => Get.find<ShareController>().shareToWechat(),
        ),
        _buildShareButton(
          icon: 'assets/kissu_qrcode.webp',
          text: '扫码绑定',
          onTap: () => Get.find<ShareController>().shareQRCode(),
        ),
      ],
    );
  }

  /// 构建单个分享按钮
  Widget _buildShareButton({
    required String icon,required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Center(child: Image.asset(icon, width: 40, height: 40)),
          Text(text,style: TextStyle(fontSize: 12,color: Color(0xffAA7268)),)
        ],
      ),
    );
  }
}

/// 虚线绘制器
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
