import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/permission_helper.dart';

/// 个人信息收集清单页面
class PersonalInfoCollectionPage extends StatelessWidget {
  const PersonalInfoCollectionPage({super.key});

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
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 自定义导航栏
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
                            "个人信息收集清单",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // 页面内容
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 页面标题和介绍
                        const Text(
                          '个人信息收集清单',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '为了向您提供更好的服务，我们会在您使用Kissu应用时收集以下个人信息。我们会严格按照法律法规的要求处理您的个人信息，确保信息安全。',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 收集信息分类
                        _buildInfoCategory(
                          title: '1. 设备信息',
                          items: [
                            '设备型号、操作系统版本、设备标识符（IMEI、Android ID、OAID等）',
                            '屏幕分辨率、设备品牌、设备序列号',
                            '电池状态、设备温度等硬件信息',
                          ],
                        ),

                        _buildInfoCategory(
                          title: '2. 位置信息',
                          items: [
                            'GPS定位信息（经纬度坐标）',
                            'WiFi信息（SSID、BSSID）',
                            '基站信息（用于粗略位置定位）',
                            '运动轨迹数据（步行、骑行、驾车轨迹）',
                          ],
                        ),

                        _buildInfoCategory(
                          title: '3. 网络信息',
                          items: [
                            'IP地址、MAC地址',
                            '网络类型（WiFi、4G、5G等）',
                            '网络状态、运营商信息',
                            '设备连接的WiFi热点信息',
                          ],
                        ),

                        _buildInfoCategory(
                          title: '4. 应用使用信息',
                          items: [
                            '应用启动时间、使用时长',
                            '页面访问记录、功能使用情况',
                            '崩溃日志、性能数据',
                            '用户操作行为（点击、滑动等）',
                          ],
                        ),

                        _buildInfoCategory(
                          title: '5. 账号信息',
                          items: [
                            '手机号码、昵称、头像',
                            '性别、生日等个人资料',
                            '好友关系数据、匹配码',
                            '聊天记录（仅在双方同意的情况下）',
                          ],
                        ),

                        _buildInfoCategory(
                          title: '6. 媒体信息',
                          items: [
                            '相册照片（用户主动上传）',
                            '拍摄的照片和视频',
                            '录音文件（语音聊天时）',
                          ],
                        ),

                        _buildInfoCategory(
                          title: '7. 传感器信息',
                          items: [
                            '加速度传感器数据',
                            '陀螺仪数据',
                            '磁场传感器数据',
                            '用于提高定位精度和运动识别',
                          ],
                        ),

                        const SizedBox(height: 24),

                        // 收集目的说明
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '收集目的',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '我们收集这些信息的主要目的是：\n'
                                '• 提供定位和地图服务\n'
                                '• 实现好友匹配和绑定功能\n'
                                '• 保障应用安全和稳定性\n'
                                '• 优化用户体验和功能完善\n'
                                '• 遵守法律法规要求',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 隐私保护说明
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '隐私保护承诺',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '我们承诺：\n'
                                '• 严格遵守《个人信息保护法》等法律法规\n'
                                '• 采用行业标准的安全措施保护您的信息\n'
                                '• 不会出售或出租您的个人信息\n'
                                '• 仅在必要情况下收集和使用您的信息\n'
                                '• 您可以随时申请删除或修改您的个人信息',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF2E7D32),
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 联系我们
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                '如果您对个人信息收集有任何疑问，请联系我们：',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () async {
                                  // 企业微信配置信息
                                  const String corpId = 'ww5c345e5aa1a2a697'; // 企业微信ID (ww开头)
                                  const String kfId = 'kfcf77b8b4a2a2a61d9'; // 客服 ID

                                  try {
                                    // 直接使用客服ID拉起会话
                                    await PermissionHelper.openWeComKfWithParams(corpId: corpId, kfId: kfId);
                                  } catch (e) {
                                    Get.snackbar(
                                      '联系我们',
                                      '打开客服失败，请手动添加企业微信客服',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  }
                                },
                                child: const Text(
                                  '联系我们',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFFF9AD9),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
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

  /// 构建信息分类组件
  Widget _buildInfoCategory({
    required String title,
    required List<String> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
