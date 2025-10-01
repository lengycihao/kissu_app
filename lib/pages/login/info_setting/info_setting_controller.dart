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
import 'package:kissu_app/utils/image_source_dialog.dart';
import 'package:kissu_app/pages/home/home_controller.dart';
import 'package:kissu_app/pages/mine/mine_controller.dart';
import 'package:kissu_app/pages/common/image_crop_page.dart';

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
        // nicknameController.text = user.nickname!;
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
        final result = await ImageSourceDialog.show(Get.context!);
        if (result == null) return;
        
        // 处理选择结果
        if (result.systemAvatarPath != null) {
          // 选择了系统头像，直接使用
          print('🎨 选择了系统头像: ${result.systemAvatarPath}');
          avatarUrl.value = result.systemAvatarPath!;
          uploadedHeadPortrait.value = result.systemAvatarPath!;
          print('   avatarUrl: ${avatarUrl.value}');
          print('   uploadedHeadPortrait: ${uploadedHeadPortrait.value}');
        } else if (result.imageSource != null) {
          // 选择了相册或相机
          await _pickImageFromSource(result.imageSource!);
        }
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
        final result = await ImageSourceDialog.show(Get.context!);
        if (result == null) return;
        
        // 处理选择结果
        if (result.systemAvatarPath != null) {
          // 选择了系统头像，直接使用
          print('🎨 选择了系统头像: ${result.systemAvatarPath}');
          avatarUrl.value = result.systemAvatarPath!;
          uploadedHeadPortrait.value = result.systemAvatarPath!;
          print('   avatarUrl: ${avatarUrl.value}');
          print('   uploadedHeadPortrait: ${uploadedHeadPortrait.value}');
        } else if (result.imageSource != null) {
          // 选择了相册或相机
          await _pickImageFromSource(result.imageSource!);
        }
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
        // 进入图片裁剪页面
        await _navigateToCropPage(pickedFile.path);
      }
    } catch (e) {
      OKToastUtil.show('选择图片失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 导航到图片裁剪页面
  Future<void> _navigateToCropPage(String imagePath) async {
    try {
      await Get.to(
        () => ImageCropPage(
          imagePath: imagePath,
          onCropComplete: _onCropComplete,
          customCropFrameAsset: 'assets/3.0/kissu3_crop_icon.webp', // 自定义裁剪框
        ),
        fullscreenDialog: true,
      );
    } catch (e) {
      print('导航到裁剪页面失败: $e');
      OKToastUtil.show('打开裁剪页面失败');
    }
  }

  /// 裁剪完成回调
  Future<void> _onCropComplete(String croppedImagePath) async {
    try {
      isLoading.value = true;

      // 上传裁剪后的图片
      final file = File(croppedImagePath);
      final result = await _fileUploadApi.uploadFile(file);

      if (result.isSuccess && result.data != null) {
        avatarUrl.value = result.data!;
        uploadedHeadPortrait.value = result.data!;
        OKToastUtil.show('头像上传成功');
      } else {
        OKToastUtil.show(result.msg ?? '头像上传失败');
      }
    } catch (e) {
      print('上传裁剪后的图片失败: $e');
      OKToastUtil.show('头像上传失败');
    } finally {
      isLoading.value = false;
    }
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
                          selectedDate.value = tempPicked;
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

  /// 提交表单
  Future<void> onSubmit() async {
    // 从TextEditingController获取最新的昵称值
    var currentNickname = nicknameController.text.trim();

    if (currentNickname.isEmpty) {
      currentNickname = nickname.value;
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

      print('📥 服务器响应: ${result.isSuccess ? "成功" : "失败"}');
      if (result.msg != null) {
        print('   消息: ${result.msg}');
      }

      if (result.isSuccess) {

        // 先本地更新用户数据
        await _updateLocalUserInfo(currentNickname, gender, birthday);

        // 然后尝试从服务器刷新最新数据并缓存
        try {
          final refreshSuccess = await _authService.refreshUserInfoFromServer();

          if (refreshSuccess) {
            print('✅ 用户信息刷新成功');
            // 检查刷新后的头像
            final refreshedUser = UserManager.currentUser;
            print('   刷新后的头像: ${refreshedUser?.headPortrait}');
            // 通知其他Controller刷新数据（使用最新的缓存数据）
            _notifyControllersToRefresh();
          } else {
            print('❌ 用户信息刷新失败，但本地数据已更新');
            // 即使服务器刷新失败，我们仍然有本地更新的数据
          }
        } catch (e) {
          print('⚠️ 刷新用户信息时发生异常: $e');
          // 异常情况下也继续执行，因为更新操作已经成功且本地数据已更新
        }

        // 根据is_perfect_information字段决定跳转
        final currentUser = UserManager.currentUser;
        if (currentUser?.isPerfectInformation == 0) {
          // 跳转到分享页面，传递来源页面参数
          Get.offAllNamed(KissuRoutePath.share, arguments: {'fromPage': 'register'});
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
    // 通知首页刷新
    try {
      final homeController = Get.find<HomeController>();
      homeController.loadUserInfo();
      print('✅ 首页Controller已刷新');
    } catch (e) {
      print('❌ 首页Controller未找到: $e');
    }
    
    // 通知我的页面刷新
    try {
      final mineController = Get.find<MineController>();
      mineController.loadUserInfo();
      print('✅ 我的页面Controller已刷新');
    } catch (e) {
      print('❌ 我的页面Controller未找到: $e');
    }
    
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
