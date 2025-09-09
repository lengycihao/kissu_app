import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SystemPermissionPage extends StatelessWidget {
  final List<Map<String, String>> items = [
    {
      "icon": "assets/kissu_setting_ssdw.webp",
      "title": "开启实时定位",
      "subtitle": "和ta持续分享你的位置",
    },
    {
      "icon": "assets/kissu_setting_zqd.webp",
      "title": "开启自启动",
      "subtitle": "确保数据始终保持最新",
    },
    {
      "icon": "assets/kissu_setting_htyx.webp",
      "title": "允许后台运行",
      "subtitle": "应用后台常驻，确保数据同步",
    },
    {
      "icon": "assets/kissu_setting_tztx.webp",
      "title": "开启通知提醒",
      "subtitle": "收到ta的实时动态提醒",
    },
    {
      "icon": "assets/kissu_setting_cc.webp",
      "title": "允许获取应用使用权限",
      "subtitle": "和ta分享手机使用报告",
    },
  ];

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
                          "系统权限",
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: items.map((item) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 14,
                        ), // item间距14px
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFF6D4128)),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.1), // 可调透明度
                        ),
                        child: Row(
                          children: [
                            Image.asset(item["icon"]!, width: 44, height: 44),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item["title"]!,
                                    style: TextStyle(
                                      color: Color(0xff333333),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item["subtitle"]!,
                                    style: TextStyle(
                                      color: Color(0xff666666),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              height: 24,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: Color(0xffFF88AA),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "去设置",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
