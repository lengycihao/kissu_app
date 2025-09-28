import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:kissu_app/widgets/dialogs/dialog_manager.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/network/public/auth_api.dart';
import 'package:kissu_app/network/public/file_upload_api.dart';
import 'package:kissu_app/model/login_model/login_model.dart';
import 'package:kissu_app/model/login_model/lover_info.dart';
import 'package:kissu_app/pages/mine/mine_controller.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'phone_change_page.dart';
import 'dart:io';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/widgets/custom_toast_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kissu_app/services/permission_service.dart';
import 'package:kissu_app/widgets/dialogs/permission_request_dialog.dart';

class LoveInfoController extends GetxController {
  // 绑定状态
  var isBindPartner = false.obs;
  
  // 权限服务
  final PermissionService _permissionService = PermissionService();

  // 用户信息
  var myAvatar = "".obs;
  var myNickname = "输入昵称".obs;
  var myGender = "未选择".obs;
  var myBirthday = "未选择".obs;
  var myPhone = "".obs;

  // 伴侣信息
  var partnerAvatar = "".obs;
  var partnerNickname = "".obs;
  var partnerGender = "未选择".obs;
  var partnerBirthday = "未选择".obs;
  var partnerPhone = "".obs;

  // 恋爱信息
  var loveTime = "一一".obs;
  var togetherDays = 0.obs;
  var bindDate = "".obs;
  var loveDays = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
  }

  void _loadUserInfo() {
    final user = UserManager.currentUser;
    if (user != null) {
      DebugUtil.info('Loading user info: ${user.nickname}');

      // 绑定状态处理 (1绑定，2未绑定，0初始未绑定)
      final bindStatus = user.bindStatus.toString();
      isBindPartner.value = bindStatus.toString() == "1";
      // isBindPartner.value  = false;
      DebugUtil.info('Bind status: $bindStatus, isBindPartner: ${isBindPartner.value}');

      // 我的信息
      myAvatar.value = user.headPortrait ?? "";
      myNickname.value = user.nickname ?? "输入昵称";
      myGender.value = user.gender == 1
          ? "男"
          : user.gender == 2
          ? "女"
          : "未选择";
      myBirthday.value = user.birthday ?? "未选择";
      myPhone.value = user.phone ?? "";

      if (isBindPartner.value) {
        DebugUtil.info('Processing bound state...');
        // 已绑定状态 - 处理伴侣信息和恋爱信息
        _handleBoundState(user);
      }
    }
  }

  void _handleBoundState(user) {
    DebugUtil.info('Handling bound state...');

    // 处理绑定时间和在一起天数
    if (user.latelyBindTime != null) {
      final bindTime = DateTime.fromMillisecondsSinceEpoch(
        user.latelyBindTime! * 1000,
      );
      loveTime.value = _formatDate(bindTime);

      // 计算在一起天数（作为备用值）
      final now = DateTime.now();
      final difference = now.difference(bindTime).inDays;
      togetherDays.value = difference + 1;
      DebugUtil.info('Calculated together days: ${togetherDays.value}');
    }
    if (user.halfUserInfo != null) {
      DebugUtil.info('Using halfUserInfo for partner data');
      final half = user.halfUserInfo!;
      partnerAvatar.value = half.headPortrait ?? "";
      partnerNickname.value = half.nickname ?? "";
      partnerGender.value = half.gender == 1
          ? "男"
          : half.gender == 2
          ? "女"
          : "未选择";
      partnerBirthday.value = half.birthday ?? "未选择";
      partnerPhone.value = half.phone ?? "";

      DebugUtil.info(
        'Partner info from halfUserInfo - nickname: ${partnerNickname.value}, gender: ${partnerGender.value}',
      );
    }
    // 处理伴侣信息 - 优先使用loverInfo，其次halfUserInfo
    if (user.loverInfo != null) {
      DebugUtil.info('Using loverInfo for partner data');
      final lover = user.loverInfo!;

      // 从LoverInfo获取恋爱信息
      if (lover.bindDate != null && lover.bindDate!.isNotEmpty) {
        bindDate.value = lover.bindDate!;
        DebugUtil.info('Bind date from loverInfo: ${bindDate.value}');
      }
      if (lover.loveTime != null && lover.loveTime!.isNotEmpty) {
        loveTime.value = lover.loveTime!;
        DebugUtil.info('Love time from loverInfo: ${loveTime.value}');
        
        // 重新计算恋爱天数以保持一致性
        _recalculateLoveDays();
      } else {
        // 如果服务器没有提供 loveTime，保持之前设置的值（从 latelyBindTime 计算）
        DebugUtil.info('Using calculated love time: ${loveTime.value}');
      }
      if (lover.loveDays != null) {
        // 优先使用服务器返回的天数，但如果存在不一致，则以本地计算为准
        final serverLoveDays = lover.loveDays!;
        _recalculateLoveDays();
        final calculatedLoveDays = loveDays.value;
        
        // 如果服务器天数与本地计算相差超过1天，以本地计算为准
        if ((serverLoveDays - calculatedLoveDays).abs() > 1) {
          DebugUtil.warning('服务器恋爱天数($serverLoveDays)与本地计算($calculatedLoveDays)相差过大，使用本地计算结果');
        } else {
          loveDays.value = serverLoveDays; // 直接使用服务器数据
        }
        DebugUtil.info('Final love days: ${loveDays.value}');
      } else {
        // 如果服务器没有提供 loveDays，重新计算
        _recalculateLoveDays();
        DebugUtil.info('Using calculated love days: ${loveDays.value}');
      }
    }
  }
  
  /// 重新计算恋爱天数
  void _recalculateLoveDays() {
    if (loveTime.value != "一一") {
      try {
        final loveDate = _parseDate(loveTime.value);
        if (loveDate != null) {
          final now = DateTime.now();
          final difference = now.difference(loveDate).inDays;
          // 直接使用计算结果，不加1
          loveDays.value = difference;
          togetherDays.value = difference;
          DebugUtil.info('Recalculated love days: ${loveDays.value}');
        }
      } catch (e) {
        DebugUtil.error('Failed to recalculate love days: $e');
      }
    }
  }

  /// 格式化日期为 YYYY-MM-DD 格式
  String _formatDate(DateTime dateTime) {
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
  }

  /// 格式化手机号（显示完整手机号）
  String formatPhone(String phone) {
    return phone.isEmpty ? "未绑定" : phone;
  }

  // 显示添加伴侣对话框 - 直接跳转到分享页面
  void showAddPartnerDialog(BuildContext context) {
    // 直接跳转到分享页面，不再显示弹窗
    Get.toNamed(KissuRoutePath.share);
  }

  /// 处理头像点击
  Future<void> onAvatarTap(BuildContext context) async {
    await pickImage();
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
        CustomToast.show(Get.context!, '权限未授予，无法选择图片');
      }
    } catch (e) {
      print('选择头像失败: $e');
      CustomToast.show(Get.context!, '选择头像失败');
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
        CustomToast.show(Get.context!, '权限未授予，无法选择图片');
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
        // 上传图片
        final file = File(pickedFile.path);
        await _uploadAvatar(file);
      }
    } catch (e) {
      CustomToast.show(Get.context!, '选择图片失败: $e');
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

  /// 上传头像
  Future<void> _uploadAvatar(File imageFile) async {
    try {
      // 显示加载指示器
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // 上传图片
      final fileUploadApi = FileUploadApi();
      final result = await fileUploadApi.uploadFile(imageFile);

      // 关闭加载指示器
      Get.back();

      if (result.isSuccess && result.data != null) {
        // 直接更新头像URL
        myAvatar.value = result.data!;
        // 更新用户信息
        await _updateUserAvatar(result.data!);
        CustomToast.show(Get.context!, '头像更新成功');
      } else {
        CustomToast.show(Get.context!, result.msg ?? '头像上传失败');
      }
    } catch (e) {
      // 关闭加载指示器（如果还在显示）
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      CustomToast.show(Get.context!, '上传头像失败：$e');
    }
  }


  /// 更新用户头像
  Future<void> _updateUserAvatar(String avatarUrl) async {
    try {
      final authApi = AuthApi();
      final result = await authApi.updateUserInfo(headPortrait: avatarUrl);

      if (result.isSuccess) {
        // 更新本地数据
        myAvatar.value = avatarUrl;

        // 更新用户缓存
        final currentUser = UserManager.currentUser;
        if (currentUser != null) {
          final updatedUser = LoginModel(
            id: currentUser.id,
            phone: currentUser.phone,
            nickname: currentUser.nickname,
            headPortrait: avatarUrl,
            gender: currentUser.gender,
            loverId: currentUser.loverId,
            birthday: currentUser.birthday,
            halfUid: currentUser.halfUid,
            status: currentUser.status,
            inviterId: currentUser.inviterId,
            friendCode: currentUser.friendCode,
            friendQrCode: currentUser.friendQrCode,
            isForEverVip: currentUser.isForEverVip,
            vipEndTime: currentUser.vipEndTime,
            channel: currentUser.channel,
            mobileModel: currentUser.mobileModel,
            deviceId: currentUser.deviceId,
            uniqueId: currentUser.uniqueId,
            provinceName: currentUser.provinceName,
            cityName: currentUser.cityName,
            bindStatus: currentUser.bindStatus,
            latelyBindTime: currentUser.latelyBindTime,
            latelyUnbindTime: currentUser.latelyUnbindTime,
            latelyLoginTime: currentUser.latelyLoginTime,
            latelyPayTime: currentUser.latelyPayTime,
            loginNums: currentUser.loginNums,
            openAppNums: currentUser.openAppNums,
            latelyOpenAppTime: currentUser.latelyOpenAppTime,
            isTest: currentUser.isTest,
            isOrderVip: currentUser.isOrderVip,
            loginTime: currentUser.loginTime,
            vipEndDate: currentUser.vipEndDate,
            isVip: currentUser.isVip,
            token: currentUser.token,
            imSign: currentUser.imSign,
            isPerfectInformation: currentUser.isPerfectInformation,
            halfUserInfo: currentUser.halfUserInfo, // 保留伴侣信息
            loverInfo: currentUser.loverInfo, // 保留恋爱信息
          );
          await UserManager.updateUserInfo(updatedUser);
        }

        // 通知我的页面刷新
        try {
          final mineController = Get.find<MineController>();
          mineController.loadUserInfo();
          DebugUtil.success('Avatar updated, mine page refreshed');
        } catch (e) {
          DebugUtil.error('Mine page not found: $e');
        }

        CustomToast.show(Get.context!, '头像更新成功');
      } else {
        CustomToast.show(Get.context!, result.msg ?? '头像更新失败');
      }
    } catch (e) {
      CustomToast.show(Get.context!, '头像更新失败：$e');
    }
  }

  /// 处理昵称点击
  void onNicknameTap(BuildContext context) {
    DialogManager.showNicknameInput(
      context,
      currentNickname: myNickname.value,
    ).then((result) {
      if (result != null && result.isNotEmpty) {
        _updateUserNickname(result);
      }
    });
  }

  /// 处理性别点击
  void onGenderTap(BuildContext context) {
    // 转换当前性别为弹窗需要的格式
    String currentGender = myGender.value == '男'
        ? '男生'
        : myGender.value == '女'
        ? '女生'
        : '男生';

    DialogManager.showGenderSelect(
      context: context,
      selectedGender: currentGender,
      onGenderSelected: (gender) {
        // 转换弹窗返回的格式为数据库格式
        String genderText = gender == '男生'
            ? '男'
            : gender == '女生'
            ? '女'
            : '未选择';
        _updateUserGender(genderText);
      },
    );
  }

  /// 处理生日点击
  void onBirthdayTap(BuildContext context) {
    _showBirthdayPicker(context);
  }

  /// 处理手机号点击
  void onPhoneTap(BuildContext context) {
    DialogManager.showPhoneChangeConfirm(
      context,
      formatPhone(myPhone.value),
    ).then((result) {
      if (result == true) {
        // 跳转到手机号更换页面
        Get.to(() => PhoneChangePage())?.then((result) {
          if (result == true) {
            // 手机号更换成功，刷新信息
            _loadUserInfo();
            // 通知我的页面刷新
            try {
              final mineController = Get.find<MineController>();
              mineController.loadUserInfo();
              DebugUtil.success('Phone changed, mine page refreshed');
            } catch (e) {
              DebugUtil.error('Mine page not found: $e');
            }
          }
        });
      }
    });
  }

  /// 处理相恋时间点击
  void onLoveTimeTap(BuildContext context) {
    _showLoveTimePicker(context);
  }

  /// 更新用户昵称
  Future<void> _updateUserNickname(String nickname) async {
    try {
      final authApi = AuthApi();
      final result = await authApi.updateUserInfo(nickname: nickname);

      if (result.isSuccess) {
        // 更新本地数据
        myNickname.value = nickname;

        // 更新用户缓存
        final currentUser = UserManager.currentUser;
        if (currentUser != null) {
          final updatedUser = LoginModel(
            id: currentUser.id,
            phone: currentUser.phone,
            nickname: nickname,
            headPortrait: currentUser.headPortrait,
            gender: currentUser.gender,
            loverId: currentUser.loverId,
            birthday: currentUser.birthday,
            halfUid: currentUser.halfUid,
            status: currentUser.status,
            inviterId: currentUser.inviterId,
            friendCode: currentUser.friendCode,
            friendQrCode: currentUser.friendQrCode,
            isForEverVip: currentUser.isForEverVip,
            vipEndTime: currentUser.vipEndTime,
            channel: currentUser.channel,
            mobileModel: currentUser.mobileModel,
            deviceId: currentUser.deviceId,
            uniqueId: currentUser.uniqueId,
            provinceName: currentUser.provinceName,
            cityName: currentUser.cityName,
            bindStatus: currentUser.bindStatus,
            latelyBindTime: currentUser.latelyBindTime,
            latelyUnbindTime: currentUser.latelyUnbindTime,
            latelyLoginTime: currentUser.latelyLoginTime,
            latelyPayTime: currentUser.latelyPayTime,
            loginNums: currentUser.loginNums,
            openAppNums: currentUser.openAppNums,
            latelyOpenAppTime: currentUser.latelyOpenAppTime,
            isTest: currentUser.isTest,
            isOrderVip: currentUser.isOrderVip,
            loginTime: currentUser.loginTime,
            vipEndDate: currentUser.vipEndDate,
            isVip: currentUser.isVip,
            token: currentUser.token,
            imSign: currentUser.imSign,
            isPerfectInformation: currentUser.isPerfectInformation,
            halfUserInfo: currentUser.halfUserInfo, // 保留伴侣信息
            loverInfo: currentUser.loverInfo, // 保留恋爱信息
          );
          await UserManager.updateUserInfo(updatedUser);
        }

        // 通知我的页面刷新
        try {
          final mineController = Get.find<MineController>();
          mineController.loadUserInfo();
          DebugUtil.success('Nickname updated, mine page refreshed');
        } catch (e) {
          DebugUtil.error('Mine page not found: $e');
        }

        CustomToast.show(Get.context!, '昵称更新成功');
      } else {
        CustomToast.show(Get.context!, result.msg ?? '昵称更新失败');
      }
    } catch (e) {
      CustomToast.show(Get.context!, '昵称更新失败：$e');
    }
  }

  /// 更新用户性别
  Future<void> _updateUserGender(String genderText) async {
    try {
      // 转换性别文本为数字
      int genderValue = genderText == '男'
          ? 1
          : genderText == '女'
          ? 2
          : 0;

      final authApi = AuthApi();
      final result = await authApi.updateUserInfo(gender: genderValue);

      if (result.isSuccess) {
        // 更新本地数据
        myGender.value = genderText;

        // 更新用户缓存
        final currentUser = UserManager.currentUser;
        if (currentUser != null) {
          final updatedUser = LoginModel(
            id: currentUser.id,
            phone: currentUser.phone,
            nickname: currentUser.nickname,
            headPortrait: currentUser.headPortrait,
            gender: genderValue,
            loverId: currentUser.loverId,
            birthday: currentUser.birthday,
            halfUid: currentUser.halfUid,
            status: currentUser.status,
            inviterId: currentUser.inviterId,
            friendCode: currentUser.friendCode,
            friendQrCode: currentUser.friendQrCode,
            isForEverVip: currentUser.isForEverVip,
            vipEndTime: currentUser.vipEndTime,
            channel: currentUser.channel,
            mobileModel: currentUser.mobileModel,
            deviceId: currentUser.deviceId,
            uniqueId: currentUser.uniqueId,
            provinceName: currentUser.provinceName,
            cityName: currentUser.cityName,
            bindStatus: currentUser.bindStatus,
            latelyBindTime: currentUser.latelyBindTime,
            latelyUnbindTime: currentUser.latelyUnbindTime,
            latelyLoginTime: currentUser.latelyLoginTime,
            latelyPayTime: currentUser.latelyPayTime,
            loginNums: currentUser.loginNums,
            openAppNums: currentUser.openAppNums,
            latelyOpenAppTime: currentUser.latelyOpenAppTime,
            isTest: currentUser.isTest,
            isOrderVip: currentUser.isOrderVip,
            loginTime: currentUser.loginTime,
            vipEndDate: currentUser.vipEndDate,
            isVip: currentUser.isVip,
            token: currentUser.token,
            imSign: currentUser.imSign,
            isPerfectInformation: currentUser.isPerfectInformation,
            halfUserInfo: currentUser.halfUserInfo, // 保留伴侣信息
            loverInfo: currentUser.loverInfo, // 保留恋爱信息
          );
          await UserManager.updateUserInfo(updatedUser);
        }

        // 通知我的页面刷新
        try {
          final mineController = Get.find<MineController>();
          mineController.loadUserInfo();
          DebugUtil.success('Gender updated, mine page refreshed');
        } catch (e) {
          DebugUtil.error('Mine page not found: $e');
        }

        CustomToast.show(Get.context!, '性别更新成功');
      } else {
        CustomToast.show(Get.context!, result.msg ?? '性别更新失败');
      }
    } catch (e) {
      CustomToast.show(Get.context!, '性别更新失败：$e');
    }
  }

  /// 显示生日选择器
  Future<void> _showBirthdayPicker(BuildContext context) async {
    final initialDate = myBirthday.value == '未选择'
        ? DateTime(2000, 1, 1)
        : _parseDate(myBirthday.value) ?? DateTime(2000, 1, 1);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        DateTime tempPicked = initialDate;

        return StatefulBuilder(
          builder: (context, setState) {
            // 计算当前月份的天数
            int daysInMonth(int year, int month) {
              return DateTime(year, month + 1, 0).day;
            }

            // 确保日期有效
            void validateAndUpdateDate() {
              final maxDay = daysInMonth(tempPicked.year, tempPicked.month);
              if (tempPicked.day > maxDay) {
                tempPicked = DateTime(tempPicked.year, tempPicked.month, maxDay);
              }
            }

            return SizedBox(
              height: 300,
              child: Column(
                children: [
                  // 顶部操作栏
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
                          _updateUserBirthday(tempPicked);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  // 自定义日期选择器
                  Expanded(
                    child: Row(
                      children: [
                        // 年份选择器
                        Expanded(
                          child: CupertinoPicker.builder(
                            itemExtent: 32,
                            scrollController: FixedExtentScrollController(
                              initialItem: tempPicked.year - 1950,
                            ),
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                tempPicked = DateTime(1950 + index, tempPicked.month, tempPicked.day);
                                validateAndUpdateDate();
                              });
                            },
                            childCount: DateTime.now().year - 1950 + 1,
                            itemBuilder: (context, index) {
                              return Center(
                                child: Text(
                                  '${1950 + index}年',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              );
                            },
                          ),
                        ),
                        // 月份选择器
                        Expanded(
                          child: CupertinoPicker.builder(
                            itemExtent: 32,
                            scrollController: FixedExtentScrollController(
                              initialItem: tempPicked.month - 1,
                            ),
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                tempPicked = DateTime(tempPicked.year, index + 1, tempPicked.day);
                                validateAndUpdateDate();
                              });
                            },
                            childCount: 12,
                            itemBuilder: (context, index) {
                              return Center(
                                child: Text(
                                  '${index + 1}月',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              );
                            },
                          ),
                        ),
                        // 日期选择器
                        Expanded(
                          child: CupertinoPicker.builder(
                            itemExtent: 32,
                            scrollController: FixedExtentScrollController(
                              initialItem: tempPicked.day - 1,
                            ),
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                tempPicked = DateTime(tempPicked.year, tempPicked.month, index + 1);
                              });
                            },
                            childCount: daysInMonth(tempPicked.year, tempPicked.month),
                            itemBuilder: (context, index) {
                              return Center(
                                child: Text(
                                  '${index + 1}日',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 更新用户生日
  Future<void> _updateUserBirthday(DateTime birthday) async {
    try {
      final birthdayStr = _formatDate(birthday);
      final authApi = AuthApi();
      final result = await authApi.updateUserInfo(birthday: birthdayStr);

      if (result.isSuccess) {
        // 更新本地数据
        myBirthday.value = birthdayStr;

        // 更新用户缓存
        final currentUser = UserManager.currentUser;
        if (currentUser != null) {
          final updatedUser = LoginModel(
            id: currentUser.id,
            phone: currentUser.phone,
            nickname: currentUser.nickname,
            headPortrait: currentUser.headPortrait,
            gender: currentUser.gender,
            loverId: currentUser.loverId,
            birthday: birthdayStr,
            halfUid: currentUser.halfUid,
            status: currentUser.status,
            inviterId: currentUser.inviterId,
            friendCode: currentUser.friendCode,
            friendQrCode: currentUser.friendQrCode,
            isForEverVip: currentUser.isForEverVip,
            vipEndTime: currentUser.vipEndTime,
            channel: currentUser.channel,
            mobileModel: currentUser.mobileModel,
            deviceId: currentUser.deviceId,
            uniqueId: currentUser.uniqueId,
            provinceName: currentUser.provinceName,
            cityName: currentUser.cityName,
            bindStatus: currentUser.bindStatus,
            latelyBindTime: currentUser.latelyBindTime,
            latelyUnbindTime: currentUser.latelyUnbindTime,
            latelyLoginTime: currentUser.latelyLoginTime,
            latelyPayTime: currentUser.latelyPayTime,
            loginNums: currentUser.loginNums,
            openAppNums: currentUser.openAppNums,
            latelyOpenAppTime: currentUser.latelyOpenAppTime,
            isTest: currentUser.isTest,
            isOrderVip: currentUser.isOrderVip,
            loginTime: currentUser.loginTime,
            vipEndDate: currentUser.vipEndDate,
            isVip: currentUser.isVip,
            token: currentUser.token,
            imSign: currentUser.imSign,
            isPerfectInformation: currentUser.isPerfectInformation,
            halfUserInfo: currentUser.halfUserInfo, // 保留伴侣信息
            loverInfo: currentUser.loverInfo, // 保留恋爱信息
          );
          await UserManager.updateUserInfo(updatedUser);
        }

        // 通知我的页面刷新
        try {
          final mineController = Get.find<MineController>();
          mineController.loadUserInfo();
          DebugUtil.success('Birthday updated, mine page refreshed');
        } catch (e) {
          DebugUtil.error('Mine page not found: $e');
        }

        CustomToast.show(Get.context!, '生日更新成功');
      } else {
        CustomToast.show(Get.context!, result.msg ?? '生日更新失败');
      }
    } catch (e) {
      CustomToast.show(Get.context!, '生日更新失败：$e');
    }
  }

  /// 解析日期字符串
  DateTime? _parseDate(String dateStr) {
    try {
      // 尝试解析 YYYY-MM-DD 格式
      if (dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      }
      // 尝试解析 YYYY.MM.DD 格式
      if (dateStr.contains('.')) {
        final parts = dateStr.split('.');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      }
      // 尝试解析其他格式
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// 显示相恋时间选择器
  Future<void> _showLoveTimePicker(BuildContext context) async {
    final initialDate = loveTime.value == '一一'
        ? DateTime.now()
        : _parseLoveTime(loveTime.value) ?? DateTime.now();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        DateTime tempPicked = initialDate;

        return SizedBox(
          height: 300,
          child: Column(
            children: [
              // 顶部操作栏
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
                      _updateLoveTime(tempPicked);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              // 自定义日期选择器（显示阿拉伯数字月份）
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return _buildCustomDatePicker(tempPicked, (newDate) {
                      setState(() {
                        tempPicked = newDate;
                      });
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 更新相恋时间
  Future<void> _updateLoveTime(DateTime loveTimeDate) async {
    try {
      final loveTimeStr = _formatLoveTime(loveTimeDate);
      final authApi = AuthApi();
      final result = await authApi.updateUserInfo(loveTime: loveTimeStr);

      if (result.isSuccess) {
        // 更新本地数据
        loveTime.value = _formatDate(loveTimeDate);

        // 重新计算在一起天数
        final now = DateTime.now();
        final difference = now.difference(loveTimeDate).inDays;
        togetherDays.value = difference + 1;
        loveDays.value = difference + 1;

        // 更新用户缓存
        final currentUser = UserManager.currentUser;
        if (currentUser != null) {
          // 更新loverInfo中的恋爱信息
          LoverInfo? updatedLoverInfo = currentUser.loverInfo;
          if (updatedLoverInfo != null) {
            updatedLoverInfo = LoverInfo(
              id: updatedLoverInfo.id,
              phone: updatedLoverInfo.phone,
              nickname: updatedLoverInfo.nickname,
              headPortrait: updatedLoverInfo.headPortrait,
              gender: updatedLoverInfo.gender,
              birthday: updatedLoverInfo.birthday,
              provinceName: updatedLoverInfo.provinceName,
              cityName: updatedLoverInfo.cityName,
              bindTime: updatedLoverInfo.bindTime,
              bindDate: updatedLoverInfo.bindDate,
              loveTime: _formatLoveTime(loveTimeDate), // 更新相恋时间
              loveDays: difference + 1, // 更新恋爱天数
            );
          }

          final updatedUser = LoginModel(
            id: currentUser.id,
            phone: currentUser.phone,
            nickname: currentUser.nickname,
            headPortrait: currentUser.headPortrait,
            gender: currentUser.gender,
            loverId: currentUser.loverId,
            birthday: currentUser.birthday,
            halfUid: currentUser.halfUid,
            status: currentUser.status,
            inviterId: currentUser.inviterId,
            friendCode: currentUser.friendCode,
            friendQrCode: currentUser.friendQrCode,
            isForEverVip: currentUser.isForEverVip,
            vipEndTime: currentUser.vipEndTime,
            channel: currentUser.channel,
            mobileModel: currentUser.mobileModel,
            deviceId: currentUser.deviceId,
            uniqueId: currentUser.uniqueId,
            provinceName: currentUser.provinceName,
            cityName: currentUser.cityName,
            bindStatus: currentUser.bindStatus,
            latelyBindTime: currentUser.latelyBindTime,
            latelyUnbindTime: currentUser.latelyUnbindTime,
            latelyLoginTime: currentUser.latelyLoginTime,
            latelyPayTime: currentUser.latelyPayTime,
            loginNums: currentUser.loginNums,
            openAppNums: currentUser.openAppNums,
            latelyOpenAppTime: currentUser.latelyOpenAppTime,
            isTest: currentUser.isTest,
            isOrderVip: currentUser.isOrderVip,
            loginTime: currentUser.loginTime,
            vipEndDate: currentUser.vipEndDate,
            isVip: currentUser.isVip,
            token: currentUser.token,
            imSign: currentUser.imSign,
            isPerfectInformation: currentUser.isPerfectInformation,
            halfUserInfo: currentUser.halfUserInfo, // 保留伴侣信息
            loverInfo: updatedLoverInfo, // 更新恋爱信息
          );
          await UserManager.updateUserInfo(updatedUser);
        }

        // 通知我的页面刷新
        try {
          final mineController = Get.find<MineController>();
          mineController.loadUserInfo();
          DebugUtil.success('Love time updated, mine page refreshed');
        } catch (e) {
          DebugUtil.error('Mine page not found: $e');
        }

        // 通知首页刷新
        try {
          final homeController = Get.find<HomeController>();
          homeController.loadUserInfo();
          DebugUtil.success('Love time updated, home page refreshed');
        } catch (e) {
          DebugUtil.error('Home controller not found: $e');
        }

        CustomToast.show(Get.context!, '相恋时间更新成功');
      } else {
        CustomToast.show(Get.context!, result.msg ?? '相恋时间更新失败');
      }
    } catch (e) {
      CustomToast.show(Get.context!, '相恋时间更新失败：$e');
    }
  }

  /// 格式化相恋时间为 YYYY-MM-DD 格式（用于API）
  String _formatLoveTime(DateTime dateTime) {
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
  }

  /// 构建自定义日期选择器（显示阿拉伯数字月份）
  Widget _buildCustomDatePicker(DateTime selectedDate, Function(DateTime) onDateChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 年份选择器
        Expanded(
          child: CupertinoPicker.builder(
            itemExtent: 32.0,
            scrollController: FixedExtentScrollController(
              initialItem: selectedDate.year - 1900,
            ),
            onSelectedItemChanged: (int index) {
              final newYear = 1900 + index;
              onDateChanged(DateTime(newYear, selectedDate.month, selectedDate.day));
            },
            childCount: 200, // 1900-2099
            itemBuilder: (context, index) {
              final year = 1900 + index;
              return Center(
                child: Text(
                  '${year}年',
                  style: const TextStyle(fontSize: 18),
                ),
              );
            },
          ),
        ),
        // 月份选择器
        Expanded(
          child: CupertinoPicker.builder(
            itemExtent: 32.0,
            scrollController: FixedExtentScrollController(
              initialItem: selectedDate.month - 1,
            ),
            onSelectedItemChanged: (int index) {
              final newMonth = index + 1;
              final daysInMonth = DateTime(selectedDate.year, newMonth + 1, 0).day;
              final newDay = selectedDate.day > daysInMonth ? daysInMonth : selectedDate.day;
              onDateChanged(DateTime(selectedDate.year, newMonth, newDay));
            },
            childCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              return Center(
                child: Text(
                  '${month}月',
                  style: const TextStyle(fontSize: 18),
                ),
              );
            },
          ),
        ),
        // 日期选择器
        Expanded(
          child: CupertinoPicker.builder(
            itemExtent: 32.0,
            scrollController: FixedExtentScrollController(
              initialItem: selectedDate.day - 1,
            ),
            onSelectedItemChanged: (int index) {
              final newDay = index + 1;
              onDateChanged(DateTime(selectedDate.year, selectedDate.month, newDay));
            },
            childCount: DateTime(selectedDate.year, selectedDate.month + 1, 0).day,
            itemBuilder: (context, index) {
              final day = index + 1;
              return Center(
                child: Text(
                  '${day}日',
                  style: const TextStyle(fontSize: 18),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 解析相恋时间字符串
  DateTime? _parseLoveTime(String dateStr) {
    try {
      // 尝试解析 YYYY.MM.DD 格式
      if (dateStr.contains('.')) {
        final parts = dateStr.split('.');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      }
      // 尝试解析 YYYY-MM-DD 格式
      if (dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      }
      // 尝试解析其他格式
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }
}
