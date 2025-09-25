import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kissu_app/model/login_model/login_model.dart';
import 'package:kissu_app/network/public/auth_api.dart';
import 'package:kissu_app/network/public/auth_service.dart';
import 'package:kissu_app/network/public/file_upload_api.dart';
import 'package:kissu_app/network/public/service_locator.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/services/permission_service.dart';
import 'package:kissu_app/widgets/dialogs/permission_request_dialog.dart';

class InfoSettingController extends GetxController {
  final AuthApi _authApi = AuthApi();
  final FileUploadApi _fileUploadApi = FileUploadApi();
  final AuthService _authService = getIt<AuthService>();
  final PermissionService _permissionService = PermissionService();

  // 初始化变量
  var avatarUrl = RxString(''); // 头像URL
  var nickname = RxString('');
  var selectedGender = RxString('男');
  var selectedDate = Rx<DateTime>(DateTime(2007, 1, 1)); // 默认2007年1月1日，后续会根据用户数据更新
  var isLoading = false.obs;
  var uploadedHeadPortrait = RxString(''); // 上传后的头像URL

  // 昵称输入框控制器
  late TextEditingController nicknameController;
  late FocusNode nicknameFocusNode;

  @override
  void onInit() {
    super.onInit();
    nicknameController = TextEditingController();
    nicknameFocusNode = FocusNode();
    _initUserData();
  }

  @override
  void onClose() {
    nicknameController.dispose();
    nicknameFocusNode.dispose();
    super.onClose();
  }

  /// 初始化用户数据
  void _initUserData() {
    final user = UserManager.currentUser;
    if (user != null) {
      // 设置头像
      if (user.headPortrait?.isNotEmpty == true) {
        avatarUrl.value = user.headPortrait!;
        uploadedHeadPortrait.value = user.headPortrait!;
      } else {
        // 如果没有头像，使用默认头像背景
        avatarUrl.value = 'assets/kissu_info_setting_headerbg.webp';
      }

      // 设置昵称
      if (user.nickname?.isNotEmpty == true) {
        nickname.value = user.nickname!;
        nicknameController.text = user.nickname!;
      }

      // 设置性别 (1男2女)
      if (user.gender != null) {
        selectedGender.value = user.gender == 1 ? '男' : '女';
      }

      // 设置生日
      if (user.birthday?.isNotEmpty == true) {
        try {
          selectedDate.value = DateTime.parse(user.birthday!);
          print('用户生日已设置: ${user.birthday}');
        } catch (e) {
          print('生日解析失败: $e，使用默认生日');
          // 如果解析失败，设置为2007年1月1日作为合理的默认值
          selectedDate.value = DateTime(2007, 1, 1);
        }
      } else {
        print('用户生日为空，使用默认生日');
        // 如果没有生日信息，设置为2007年1月1日作为合理的默认值
        selectedDate.value = DateTime(2007, 1, 1);
      }
    } else {
      print('用户信息为空，使用默认值');
      // 如果没有用户信息，设置默认值
      avatarUrl.value = 'assets/kissu_info_setting_headerbg.webp';
      selectedDate.value = DateTime(2007, 1, 1);
    }
  }

  /// 选择头像
  Future<void> pickImage() async {
    try {
      // 检查是否已有相册和相机权限
      final hasPhotoPermission = await _permissionService.checkPermissionStatus(PermissionType.photos);
      final hasCameraPermission = await _permissionService.checkPermissionStatus(PermissionType.camera);
      
      // 如果两个权限都有，直接显示选择来源对话框
      if (hasPhotoPermission && hasCameraPermission) {
        final source = await _showImageSourceDialog();
        if (source == null) return;
        await _pickImageFromSource(source);
        return;
      }
      
      // 如果没有权限，先显示权限说明弹窗
      final shouldContinue = await PermissionRequestDialog.showPhotosPermissionDialog(Get.context!);
      if (shouldContinue != true) return;
      
      // 申请权限
      bool photoPermissionGranted = hasPhotoPermission;
      bool cameraPermissionGranted = hasCameraPermission;
      
      if (!hasPhotoPermission) {
        photoPermissionGranted = await _permissionService.requestPhotosPermission();
      }
      
      if (!hasCameraPermission) {
        cameraPermissionGranted = await _permissionService.requestCameraPermission();
      }
      
      // 如果至少有一个权限被授予，显示选择来源对话框
      if (photoPermissionGranted || cameraPermissionGranted) {
        final source = await _showImageSourceDialog();
        if (source == null) return;
        await _pickImageFromSource(source);
      } else {
        OKToastUtil.show('权限未授予，无法选择图片');
      }
    } catch (e) {
      print('选择头像失败: $e');
      OKToastUtil.show('选择头像失败');
    }
  }

  /// 从指定来源选择图片
  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      // 再次检查权限状态（防止用户在选择来源时权限被撤销）
      bool hasPermission = false;
      if (source == ImageSource.camera) {
        hasPermission = await _permissionService.checkPermissionStatus(PermissionType.camera);
      } else {
        hasPermission = await _permissionService.checkPermissionStatus(PermissionType.photos);
      }

      if (!hasPermission) {
        OKToastUtil.show('权限未授予，无法选择图片');
        return;
      }

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        isLoading.value = true;

        // 上传图片
        final file = File(pickedFile.path);
        final result = await _fileUploadApi.uploadFile(file);

        if (result.isSuccess && result.data != null) {
          avatarUrl.value = result.data!;
          uploadedHeadPortrait.value = result.data!;
          OKToastUtil.show('头像上传成功');
        } else {
           OKToastUtil.show(result.msg ?? '头像上传失败');
        }
      }
    } catch (e) {
      OKToastUtil.show('选择图片失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 显示图片来源选择对话框
  Future<ImageSource?> _showImageSourceDialog() async {
    return await showModalBottomSheet<ImageSource>(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部拖拽指示器
                Container(
                  margin: EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),

                // 标题
                Text(
                  '选择图片来源',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 20),

                // 选项列表
                _buildImageSourceOption(
                  icon: Icons.photo_library_outlined,
                  title: '从相册选择',
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                Divider(height: 1, color: Colors.grey[200]),
                _buildImageSourceOption(
                  icon: Icons.camera_alt_outlined,
                  title: '拍照',
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),

                SizedBox(height: 10),

                // 取消按钮
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '取消',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建图片来源选项
  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Color(0xFFFEA39C).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Color(0xFFFEA39C), size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF333333),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  /// 选择生日
  Future<void> pickBirthday(DateTime initialDate) async {
    // 隐藏键盘并移除输入框焦点
    nicknameFocusNode.unfocus();
    FocusScope.of(Get.context!).unfocus();

    await showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        DateTime tempPicked = initialDate;

        return Localizations.override(
          context: context,
          locale: const Locale('zh', 'CN'),
          child: SizedBox(
            height: 300,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      child: const Text("取消"),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      child: const Text("确定"),
                      onPressed: () {
                        selectedDate.value = tempPicked;
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    minimumDate: DateTime(1950, 1, 1), // 设置更合理的起始日期
                    maximumDate: DateTime.now().subtract(const Duration(days: 1)), // 最大日期为昨天
                    onDateTimeChanged: (DateTime newDate) {
                      tempPicked = newDate;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 提交表单
  Future<void> onSubmit() async {
    // 从TextEditingController获取最新的昵称值
    final currentNickname = nicknameController.text.trim();

    if (currentNickname.isEmpty) {
       OKToastUtil.show('请输入昵称');
      return;
    }

    try {
      isLoading.value = true;

      // 格式化生日为 YYYY-MM-DD 格式
      final birthday = DateFormat('yyyy-MM-dd').format(selectedDate.value);
      final loveTime = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 转换性别为数字 (1男2女)
      final gender = selectedGender.value == '男' ? 1 : 2;

      // 更新用户信息，使用TextEditingController中的值
      final result = await _authApi.updateUserInfo(
        nickname: currentNickname,
        headPortrait: uploadedHeadPortrait.value.isNotEmpty
            ? uploadedHeadPortrait.value
            : null,
        gender: gender,
        birthday: birthday,
        loveTime: loveTime,
      );

      if (result.isSuccess) {

        // 先本地更新用户数据
        await _updateLocalUserInfo(currentNickname, gender, birthday);

        // 然后尝试从服务器刷新最新数据并缓存
        try {
          final refreshSuccess = await _authService.refreshUserInfoFromServer();

          if (refreshSuccess) {
            print('用户信息刷新成功');
            // 通知其他Controller刷新数据（使用最新的缓存数据）
            _notifyControllersToRefresh();
          } else {
            print('用户信息刷新失败，但本地数据已更新');
            // 即使服务器刷新失败，我们仍然有本地更新的数据
          }
        } catch (e) {
          print('刷新用户信息时发生异常: $e');
          // 异常情况下也继续执行，因为更新操作已经成功且本地数据已更新
        }

        // 根据is_perfect_information字段决定跳转
        final currentUser = UserManager.currentUser;
        if (currentUser?.isPerfectInformation == 0) {
          // 跳转到分享页面
          Get.offAllNamed(KissuRoutePath.share);
        } else {
          // 跳转到首页
          Get.offAllNamed(KissuRoutePath.home);
        }
      } else {
         OKToastUtil.show(result.msg ?? '更新失败');
      }
    } catch (e) {
      OKToastUtil.show('更新失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 选择性别
  void selectGender(String gender) {
    selectedGender.value = gender;
  }

  /// 更新昵称（从TextEditingController同步到响应式变量）
  void updateNickname(String value) {
    nickname.value = value;
  }

  /// 通知其他Controller刷新数据
  void _notifyControllersToRefresh() {
    // 由于我们已经更新了缓存的用户数据，其他Controller会自动使用最新数据
    // 这里可以添加特定的Controller刷新逻辑，如果需要的话
    print('通知其他Controller使用最新的用户数据');
  }

  /// 本地更新用户信息（在服务器更新成功后立即更新本地缓存）
  Future<void> _updateLocalUserInfo(
    String nickname,
    int gender,
    String birthday,
  ) async {
    try {
      final currentUser = UserManager.currentUser;
      if (currentUser != null) {
        // 创建当前用户的副本，通过构造函数创建新对象，保持复杂对象不变
        final updatedUser = LoginModel(
          id: currentUser.id,
          nickname: nickname,
          headPortrait: uploadedHeadPortrait.value.isNotEmpty
              ? uploadedHeadPortrait.value
              : currentUser.headPortrait,
          gender: gender,
          birthday: birthday,
          token: currentUser.token,
          phone: currentUser.phone,
          bindStatus: currentUser.bindStatus,
          latelyBindTime: currentUser.latelyBindTime,
          loverInfo: currentUser.loverInfo, // 保持原对象不变
          halfUserInfo: currentUser.halfUserInfo, // 保持原对象不变
          isVip: currentUser.isVip,
          vipEndDate: currentUser.vipEndDate,
          provinceName: currentUser.provinceName,
          cityName: currentUser.cityName,
          friendCode: currentUser.friendCode,
          loginTime: currentUser.loginTime,
          isPerfectInformation: currentUser.isPerfectInformation,
          // 保持其他所有字段
          loverId: currentUser.loverId,
          halfUid: currentUser.halfUid,
          status: currentUser.status,
          inviterId: currentUser.inviterId,
          friendQrCode: currentUser.friendQrCode,
          isForEverVip: currentUser.isForEverVip,
          vipEndTime: currentUser.vipEndTime,
          channel: currentUser.channel,
          mobileModel: currentUser.mobileModel,
          deviceId: currentUser.deviceId,
          uniqueId: currentUser.uniqueId,
          latelyUnbindTime: currentUser.latelyUnbindTime,
          latelyLoginTime: currentUser.latelyLoginTime,
          latelyPayTime: currentUser.latelyPayTime,
          loginNums: currentUser.loginNums,
          openAppNums: currentUser.openAppNums,
          latelyOpenAppTime: currentUser.latelyOpenAppTime,
          isTest: currentUser.isTest,
          isOrderVip: currentUser.isOrderVip,
          imSign: currentUser.imSign,
        );

        // 更新本地缓存
        await _authService.updateCurrentUser(updatedUser);
        print(
          '本地用户信息已更新: nickname=$nickname, gender=$gender, birthday=$birthday',
        );
      }
    } catch (e) {
      print('更新本地用户信息失败: $e');
    }
  }
}
