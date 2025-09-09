import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/dialogs/dialog_manager.dart';
import 'break_relationship_controller.dart';
import '../../../network/public/auth_api.dart';
import '../../../utils/user_manager.dart';
import '../../../widgets/login_loading_widget.dart';
import '../mine_controller.dart';
import '../../phone_history/phone_history_controller.dart';

class BreakRelationshipPage extends StatefulWidget {
  const BreakRelationshipPage({super.key});

  @override
  State<BreakRelationshipPage> createState() => _BreakRelationshipPageState();
}

class _BreakRelationshipPageState extends State<BreakRelationshipPage> {
  late BreakRelationshipController controller;
  final RxBool isLoading = false.obs;
  final RxString loadingText = '解除中...'.obs;

  @override
  void initState() {
    super.initState();
    controller = Get.put(BreakRelationshipController());
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => LoginLoadingWidget(
        isLoading: isLoading.value,
        loadingText: loadingText.value,
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/phone_history/kissu_phone_bg.webp'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // 自定义AppBar
                  _buildCustomAppBar(),
                  // 页面内容
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: 18,
                        right: 18,
                        bottom: 20,
                      ),
                      child: Column(
                        children: [
                          // 复用恋爱信息的在一起天数卡片
                          _buildTogetherCard(),
                          const SizedBox(height: 20),

                          // 提示文字
                          _buildWarningText(),
                          const SizedBox(height: 30),

                          // 解除须知
                          _buildNoticeSection(),
                          const SizedBox(height: 40),

                          // 解除关系按钮
                          _buildBreakButton(context),
                          const SizedBox(height: 20),
                        ],
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
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Image.asset(
              'assets/kissu_mine_back.webp',
              width: 24,
              height: 24,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '解除关系',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24), // 占位保持居中
        ],
      ),
    );
  }

  // Widget _buildAvatarSection() {
  //   return Container(
  //     height: 120,
  //     child: Center(
  //       child: _BreakAvatarSection(controller: controller),
  //     ),
  //   );
  // }

  Widget _buildTogetherCard() {
    return _BreakTogetherCard(controller: controller);
  }

  Widget _buildWarningText() {
    return const Text(
      '任意一方可以发起解除关系，请务必查阅解除关系的代价后再进行操作',
      style: TextStyle(fontSize: 14, color: Color(0xFF999999), height: 1.5),
      textAlign: TextAlign.left,
    );
  }

  Widget _buildNoticeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '解除须知',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          ..._buildNoticeItems(),
        ],
      ),
    );
  }

  List<Widget> _buildNoticeItems() {
    final notices = [
      '清空365打卡记录',
      '清空聊天记录',
      '清空恋爱日记',
      '清空恋爱清单',
      '会员权益(未购买方)失效',
      '清空情侣定制记录',
      '清空对方用机记录',
      '清空活动步数',
      '清空相册里全部照片/视频',
    ];

    return notices.asMap().entries.map((entry) {
      int index = entry.key;
      String notice = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}、',
              style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notice,
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
    }).toList();
  }

  Widget _buildBreakButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: () async {
          final result = await DialogManager.showUnbindConfirm(context);
          if (result == false) {
            // 返回false表示点击了左边的"确认解除"按钮
            await _handleBreakRelationship();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFE9E9),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Text(
          '解除关系',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFFA29D9D),
          ),
        ),
      ),
    );
  }

  Future<void> _handleBreakRelationship() async {
    try {
      isLoading.value = true;
      loadingText.value = '解除中...';

      final authApi = AuthApi();
      final result = await authApi.unbindPartner();

      if (result.isSuccess) {
        loadingText.value = '解除成功';

        // 延迟一下让用户看到成功提示
        await Future.delayed(const Duration(milliseconds: 800));

        // 刷新用户信息
        try {
          await UserManager.refreshUserInfo();
        } catch (e) {
          print('刷新用户信息失败: $e');
        }

        // 返回到我的页面，并确保刷新我的页面数据
        _returnToMinePageAndRefresh();
        
        // 刷新敏感记录页面数据
        _refreshPhoneHistoryPage();

        Get.snackbar(
          '成功',
          '关系已解除',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF4CAF50),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          '失败',
          result.msg ?? '解除关系失败',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFFFF6B6B),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        '错误',
        '网络异常，请重试',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFFF6B6B),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 返回到我的页面并刷新数据
  void _returnToMinePageAndRefresh() {
    // 首先返回到上一级页面（隐私设置页面）
    Get.back();

    // 再返回到我的页面
    Get.back();

    // 刷新我的页面数据
    try {
      if (Get.isRegistered<MineController>()) {
        final mineController = Get.find<MineController>();
        // 调用我的页面的数据加载方法
        mineController.refreshUserInfo();
      }
    } catch (e) {
      print('刷新我的页面数据失败: $e');
    }
  }

  /// 刷新敏感记录页面数据
  void _refreshPhoneHistoryPage() {
    try {
      if (Get.isRegistered<PhoneHistoryController>()) {
        final phoneHistoryController = Get.find<PhoneHistoryController>();
        phoneHistoryController.loadData(isRefresh: true);
        print('已刷新敏感记录页面数据');
      }
    } catch (e) {
      print('刷新敏感记录页面数据失败: $e');
    }
  }
}

// 复用恋爱信息的头像组件，适配解除关系页面
class _BreakAvatarSection extends StatelessWidget {
  final BreakRelationshipController controller;

  const _BreakAvatarSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // if (controller.isBindPartner.value) {
      //   // 已绑定 - 显示两个头像
      //   return Stack(
      //     alignment: AlignmentGeometry.bottomCenter,
      //     children: [_buildMyAvatar(), _buildPartnerAvatar()],
      //   );
      // } else {
      //   // 未绑定 - 只显示我的头像
      //   return _buildMyAvatar();
      // }
      return Stack(
        alignment: AlignmentGeometry.bottomCenter,
        children: [_buildMyAvatar(), _buildPartnerAvatar()],
      );
    });
  }

  Widget _buildMyAvatar() {
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
          child: controller.myAvatar.value.isNotEmpty
              ? Image.network(
                  controller.myAvatar.value,
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

  Widget _buildPartnerAvatar() {
    return Container(
      width: 50,
      height: 50,
      margin: EdgeInsets.only(left: 50),
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/kissu_loveinfo_header_bg.webp'),
          fit: BoxFit.fill,
        ),
      ),
      child: ClipOval(
        child: controller.partnerAvatar.value.isNotEmpty
            ? Image.network(
                controller.partnerAvatar.value,
                width: 50,
                height: 50,
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
                child: const Icon(Icons.person, size: 40, color: Colors.white),
              ),
      ),
    );
  }
}

// 复用恋爱信息的在一起天数卡片，适配解除关系页面
class _BreakTogetherCard extends StatelessWidget {
  final BreakRelationshipController controller;

  const _BreakTogetherCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Stack(
        children: [
          Container(
            width: double.infinity,
            height: 83,
            margin: const EdgeInsets.only(top: 80),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/kissu_loveinfo_day_bg.png'),
                fit: BoxFit.fill,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/kissu_loveinfo_day_left.png',
                  width: 32,
                  height: 36,
                ),
                const SizedBox(width: 10),
                const Text(
                  '在一起',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                _buildDaysDisplay(),
                const SizedBox(width: 5),
                const Text(
                  '天',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Image.asset(
                  'assets/kissu_loveinfo_day_right.png',
                  width: 32,
                  height: 36,
                ),
              ],
            ),
          ),

          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: _BreakAvatarSection(controller: controller),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysDisplay() {
    final daysStr = controller.isBindPartner.value
        ? controller.loveDays.value.toString()
        : '-';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: daysStr.split("").map((d) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/kissu_loveinfo_num_bg.webp'),
              fit: BoxFit.cover,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            d,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF69B4),
            ),
          ),
        );
      }).toList(),
    );
  }
}
