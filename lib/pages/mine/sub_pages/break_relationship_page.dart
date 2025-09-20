import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/dialogs/dialog_manager.dart';
import 'break_relationship_controller.dart';
import '../../../network/public/auth_api.dart';
import '../../../utils/user_manager.dart';
import '../mine_controller.dart';
import '../../phone_history/phone_history_controller.dart';
import '../../home/home_controller.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';

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
    return Scaffold(
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

        // 先显示成功提示（在页面关闭前）
        CustomToast.show(
          Get.context!,
          '关系已解除',
        );

        // 延迟一下让Toast显示
        await Future.delayed(const Duration(milliseconds: 500));

        // 先刷新用户信息，确保数据同步
        final refreshSuccess = await UserManager.refreshUserInfo();
        if (!refreshSuccess) {
          CustomToast.show(
            Get.context!,
            '用户信息刷新失败，请重新进入页面',
          );
        }
        
        // 返回到我的页面，并确保刷新我的页面数据
        await _returnToMinePageAndRefresh();
      } else {
        CustomToast.show(
          Get.context!,
          result.msg ?? '解除关系失败',
        );
      }
    } catch (e) {
      CustomToast.show(
        Get.context!,
        '网络异常，请重试',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 返回到我的页面并刷新数据
  Future<void> _returnToMinePageAndRefresh() async {
    try {
      // 先刷新所有相关控制器的数据（在页面跳转前）
      await _refreshAllControllers();
      
      // 然后返回到我的页面
      // 首先返回到上一级页面（隐私设置页面）
      Get.back();

      // 再返回到我的页面
      Get.back();
      
      // 页面跳转后再次确保数据刷新
      await Future.delayed(const Duration(milliseconds: 200));
      await _refreshMineControllerAfterReturn();
      
    } catch (e) {
      print('返回页面并刷新数据失败: $e');
      // 即使出错也要返回页面
      Get.back();
      Get.back();
    }
  }
  
  /// 刷新所有相关控制器
  Future<void> _refreshAllControllers() async {
    // 给一点时间让UserManager的数据完全同步
    await Future.delayed(const Duration(milliseconds: 100));
    
    // 刷新首页绑定状态
    try {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.loadUserInfo();
        print('✅ 已刷新首页绑定状态');
      }
    } catch (e) {
      print('❌ 刷新首页绑定状态失败: $e');
    }
    
    // 刷新敏感记录页面（提前刷新）
    try {
      if (Get.isRegistered<PhoneHistoryController>()) {
        final phoneHistoryController = Get.find<PhoneHistoryController>();
        phoneHistoryController.loadData(isRefresh: true);
        print('✅ 已刷新敏感记录页面数据');
      }
    } catch (e) {
      print('❌ 刷新敏感记录页面数据失败: $e');
    }
  }
  
  /// 页面返回后刷新我的页面控制器
  Future<void> _refreshMineControllerAfterReturn() async {
    try {
      if (Get.isRegistered<MineController>()) {
        final mineController = Get.find<MineController>();
        // 直接调用 loadUserInfo，避免重复的网络请求
        mineController.loadUserInfo();
        print('✅ 已刷新我的页面数据');
      }
    } catch (e) {
      print('❌ 刷新我的页面数据失败: $e');
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

    // 计算数字位数，根据位数调整字体大小和容器大小
    final digitCount = daysStr.length;
    double fontSize = 20.0;  // 基础字体大小（1-3位数字）
    double containerSize = 30.0;  // 基础容器大小
    double horizontalMargin = 2.0;  // 基础间距

    // 根据数字位数逐步缩小
    if (digitCount >= 6) {
      // 6位数字及以上，最小
      fontSize = 12.0;
      containerSize = 20.0;
      horizontalMargin = 0.8;
    } else if (digitCount >= 5) {
      // 5位数字，较小
      fontSize = 14.0;
      containerSize = 22.0;
      horizontalMargin = 1.0;
    } else if (digitCount >= 4) {
      // 4位数字，稍微缩小
      fontSize = 16.0;
      containerSize = 24.0;
      horizontalMargin = 1.2;
    } else if (digitCount >= 3) {
      // 3位数字，基础大小
      fontSize = 18.0;
      containerSize = 26.0;
      horizontalMargin = 1.5;
    }

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: daysStr.split("").map((d) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
            width: containerSize,
            height: containerSize,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/kissu_loveinfo_num_bg.webp'),
                fit: BoxFit.cover,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              d,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF69B4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
