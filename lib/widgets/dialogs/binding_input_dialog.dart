import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../network/public/auth_api.dart';
import '../../utils/user_manager.dart';
import '../../network/example/http_manager_example.dart';
import '../../widgets/login_loading_widget.dart';
import '../../pages/mine/mine_controller.dart';
import '../../pages/phone_history/phone_history_controller.dart';

/// 绑定输入弹窗
class BindingInputDialog {
  /// 显示绑定输入弹窗
  static Future<bool?> show({
    required BuildContext context,
    String title = '',
    String hintText = '输入对方匹配码',
    String confirmText = '确认绑定',
    Function(String code)? onConfirm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      builder: (context) => const _BindingInputBottomSheet(),
    );
  }
}

class _BindingInputBottomSheet extends StatefulWidget {
  const _BindingInputBottomSheet();

  @override
  State<_BindingInputBottomSheet> createState() =>
      _BindingInputBottomSheetState();
}

class _BindingInputBottomSheetState extends State<_BindingInputBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxString loadingText = '申请中...'.obs;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    // 立即收起键盘
    FocusScope.of(context).unfocus();

    final code = _controller.text.trim();
    if (code.isEmpty) {
      Get.snackbar('提示', '请输入对方的匹配码');
      return;
    }

    isLoading.value = true;
    loadingText.value = '申请中...';

    try {
      // 确保网络管理器已初始化
      try {
        await HttpManagerExample.initializeHttpManager();
      } catch (e) {
        print('重新初始化HttpManager: $e');
      }

      final authApi = AuthApi();
      final result = await authApi.bindPartner(friendCode: code);

      if (result.isSuccess) {
        loadingText.value = '申请成功';
        // await Future.delayed(const Duration(milliseconds: 1000));

        // 获取最新用户信息并更新缓存
        try {
          // 使用UserManager的刷新方法，这会同步更新缓存和内存数据
          await UserManager.refreshUserInfo();

          // 刷新我的页面数据
          if (Get.isRegistered<MineController>()) {
            final mineController = Get.find<MineController>();
            // 直接调用loadUserInfo刷新数据
            mineController.loadUserInfo();
          }
          
          // 刷新敏感记录页面数据
          if (Get.isRegistered<PhoneHistoryController>()) {
            final phoneHistoryController = Get.find<PhoneHistoryController>();
            // 刷新敏感记录页面数据
            phoneHistoryController.loadData(isRefresh: true);
          }
        } catch (e) {
          print('刷新用户信息失败: $e');
        }

        if (mounted) {
          Navigator.of(context).pop(true);
        }
        Get.snackbar('成功', '申请成功');
      } else {
        isLoading.value = false;
        Get.snackbar('错误', result.msg ?? '申请失败');
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('错误', '网络异常，请重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Obx(
      () => LoginLoadingWidget(
        isLoading: isLoading.value,
        loadingText: loadingText.value,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: Container(
            width: double.infinity,
            height: screenWidth,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/kissu_binding_dailog_bg.webp'),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 48,
                right: 48,
                top: 20,
                bottom: 30,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 顶部拖拽条
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 标题
                  const Text(
                    ' ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 输入框
                  Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/kissu_input_bg.png'),
                        fit: BoxFit.fill,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _controller,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        hintText: '输入对方匹配码',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF999999),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        counterText: '', // 隐藏字符计数器
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 确认按钮
                  GestureDetector(
                    onTap: _handleConfirm,
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        image: const DecorationImage(
                          image: AssetImage(
                            'assets/kissu_dialop_common_sure_bg.webp',
                          ),
                          fit: BoxFit.fill,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '确认绑定',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
  }
}
