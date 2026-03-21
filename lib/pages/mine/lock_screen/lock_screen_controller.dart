import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:kissu_app/services/tencent_im_service.dart';
import 'package:kissu_app/services/lock_screen_overlay_service.dart';
import 'package:kissu_app/services/permission_service.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/network/public/lock_permission_api.dart';
import 'package:kissu_app/network/public/file_upload_api.dart';
import 'package:kissu_app/services/analytics/analytics_helper.dart';

class LockScreenController extends GetxController {
  // ==================== 步骤管理 ====================
  final currentStep = 1.obs; // 1: 设置锁屏信息, 2: 设置锁屏问题
  final pageState = 'setup'.obs; // 'setup' | 'locked'

  // ==================== Step1: 锁屏信息 ====================
  final lockTextController = TextEditingController(text: "哼 叫你玩游戏～");
  final lockText = '哼 叫你玩游戏～'.obs;
  final selectedImageIndex = 0.obs; // 0,1,2 = 预设图片, 3 = 自定义
  final customImagePath = ''.obs;

  // 预设图片资源
  final presetImages = [
    'assets/lock/kissu_lock_1.png',
    'assets/lock/kissu_lock_2.png',
    'assets/lock/kissu_lock_3.png',
  ];

  // 预览图片资源（对应预设图片）
  final previewImages = [
    'assets/lock/kissu_lock_preview_1.png',
    'assets/lock/kissu_lock_preview_2.png',
    'assets/lock/kissu_lock_preview_3.png',
  ];

  // ==================== Step2: 锁屏问题 ====================
  final questionController = TextEditingController();
  final question = ''.obs;
  final answerControllers = List.generate(4, (_) => TextEditingController());
  final answers = List.generate(4, (_) => ''.obs);
  final selectedAnswerIndex = (-1).obs; // 选中的正确答案索引
  final isQuestionEditable = false.obs; // 系统随机问题时不可编辑，清空后可编辑

  // ==================== 权限状态 ====================
  final isOverlayGranted = false.obs;
  final isUsageAccessGranted = false.obs; // app使用记录权限
  final isPartnerPermissionGranted = false.obs;
  final isLoadingPartnerPermission = true.obs; // 正在拉取对方权限

  /// 对方权限原始数据，来自 /get/lock/permission
  final Rxn<Map<String, dynamic>> halfUserPermission = Rxn();

  final PermissionService _permissionService = PermissionService();
  final _lockPermissionApi = LockPermissionApi();

  // ==================== 对方OS相关 ====================
  /// 对方系统："ios" | "android"（默认android）
  String get partnerOs =>
      (halfUserPermission.value?['os'] as String? ?? 'android').toLowerCase();

  bool get isPartnerIos => partnerOs == 'ios';

  /// 对方版本是否支持锁机功能（1=支持，0=不支持）
  bool get isPartnerVersionConform =>
      (halfUserPermission.value?['is_conform_version'] as int? ?? 0) == 1;

  /// 对方已关联的 App 列表（iOS 专用）
  List<Map<String, dynamic>> get partnerRelevanceApps {
    final raw = halfUserPermission.value?['relevance_app'];
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  // ==================== 锁定状态 ====================
  final lockStartTime = DateTime.now().obs;
  final lockDuration = '00:00:00'.obs;
  Timer? _lockTimer;
  final lockRecords = <LockRecord>[].obs;

  // ==================== API缓存的随机问题库 ====================
  /// 从 /get/lock/phone/question 接口获取并缓存的问题列表
  /// 每项: {"question": "...", "answer": [{"answer": "...", "is_answer": 0/1}, ...]}
  List<Map<String, dynamic>> _cachedQuestions = [];
  final isLoadingQuestions = false.obs;

  // ==================== 锁机记录（API） ====================
  final lockRecordPage = 1.obs;
  final lockRecordHasMore = false.obs;
  final isLoadingRecords = false.obs;
  int lockRecordTotal = 0; // API返回的total字段，用于计算锁机次数编号
  /// latest_lock_data 中的 lock_status（1=锁定中）
  final latestLockStatus = 0.obs;
  /// latest_lock_data 中的 lock_time（锁机开始时间戳）
  final latestLockTime = 0.obs;

  final _fileUploadApi = FileUploadApi();
  final isLocking = false.obs; // 防止重复点击
  bool _justUnlocked = false; // 防止解锁后fetchLockRecords再次锁定（API延迟更新）

  // ==================== 计算属性 ====================
  /// iOS 对方不需要选背景图，Android 对方需要
  bool get isStep1Complete {
    if (lockText.value.isEmpty) return false;
    if (isPartnerIos) return true; // iOS 无锁屏背景，只需文案
    return selectedImageIndex.value >= 0; // Android 需要选图片
  }

  bool get isStep2Complete {
    if (question.value.isEmpty) return false;
    if (selectedAnswerIndex.value < 0) return false;
    for (int i = 0; i < 4; i++) {
      if (answers[i].value.isEmpty) return false;
    }
    return true;
  }

  @override
  void onInit() {
    super.onInit();
    lockTextController.addListener(() {
      lockText.value = lockTextController.text;
    });
    questionController.addListener(() {
      question.value = questionController.text;
    });
    for (int i = 0; i < 4; i++) {
      answerControllers[i].addListener(() {
        answers[i].value = answerControllers[i].text;
      });
    }
    _fetchQuestions(); // 进入页面时拉取并缓存随机问题
    _fetchLockRecords(); // 从API拉取锁机记录
    _checkLockState();
    _checkPermissions();
    _fetchPartnerPermission();
    _listenForUnlockNotification();
    _reportPendingAnswerAnalytics();
  }

  @override
  void onClose() {
    lockTextController.dispose();
    questionController.dispose();
    for (var c in answerControllers) {
      c.dispose();
    }
    _lockTimer?.cancel();
    super.onClose();
  }

  // ==================== Step1 操作 ====================
  void selectImage(int index) {
    selectedImageIndex.value = index;
  }

  Future<void> pickCustomImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        customImagePath.value = pickedFile.path;
        selectedImageIndex.value = 3; // 自定义图片索引
      }
    } catch (e) {
      debugPrint('选择图片失败: $e');
    }
  }

  void goToStep2() {
    if (isStep1Complete) {
      currentStep.value = 2;
      // 进入Step2时自动填充一道随机问题
      if (question.value.isEmpty) {
        randomQuestion();
      }
    }
  }

  /// Step1 "下一步" 按钮点击：校验对方版本、iOS关联App、权限，再进入 Step2
  Future<void> onStep1NextTap(BuildContext context) async {
    if (!isStep1Complete) return;

    // 再次调用 /get/lock/permission 实时检查对方权限
    try {
      final result = await _lockPermissionApi.getLockPermission();
      if (result.isSuccess && result.data != null) {
        halfUserPermission.value = result.data;
        isPartnerPermissionGranted.value = _computePartnerPermissionGranted();
        LockPermissionApi.cachedPartnerPermission = result.data;
      }
    } catch (e) {
      logError('下一步：获取对方权限失败: $e');
    }

    // 先检查对方版本是否支持锁机
    if (!isPartnerVersionConform) {
      OKToastUtil.showError('对方版本过低，一键锁机无法使用');
      return;
    }
    // iOS对方且关联App为空时，弹出提示
    if (isPartnerIos && partnerRelevanceApps.isEmpty) {
      _showIosNoAppsWarningDialog(context);
      return;
    }
    if (!isPartnerPermissionGranted.value) {
      OKToastUtil.showError('对方还未开启相关权限，暂时无法锁机');
      _showPartnerPermissionWarningDialog(context);
    } else {
      goToStep2();
    }
  }

  void goBackToStep1() {
    currentStep.value = 1;
  }

  // ==================== Step2 操作 ====================
  void selectAnswer(int index) {
    selectedAnswerIndex.value = index;
  }

  /// 从缓存的API问题列表中随机选一题填充到Step2
  void randomQuestion() {
    if (_cachedQuestions.isEmpty) {
      // debugPrint('随机问题缓存为空，跳过');
      return;
    }
    final random = DateTime.now().millisecondsSinceEpoch % _cachedQuestions.length;
    final q = _cachedQuestions[random];
    questionController.text = q['question'] as String? ?? '';
    final answerList = q['answer'] as List? ?? [];
    for (int i = 0; i < 4 && i < answerList.length; i++) {
      final item = answerList[i];
      if (item is Map) {
        answerControllers[i].text = item['answer'] as String? ?? '';
        if ((item['is_answer'] as int? ?? 0) == 1) {
          selectedAnswerIndex.value = i;
        }
      }
    }
    isQuestionEditable.value = false; // 系统随机问题不可编辑
  }

  /// 进入页面时从API获取随机问题并缓存
  Future<void> _fetchQuestions() async {
    isLoadingQuestions.value = true;
    try {
      final result = await _lockPermissionApi.getLockPhoneQuestion();
      if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
        _cachedQuestions = result.data!
            .whereType<Map<String, dynamic>>()
            .toList();
        // debugPrint('✅ 缓存了 ${_cachedQuestions.length} 道随机问题');
      }
    } catch (e) {
      logWarning('获取随机问题失败: $e');
    } finally {
      isLoadingQuestions.value = false;
    }
  }

  void clearAll() {
    questionController.clear();
    for (var c in answerControllers) {
      c.clear();
    }
    selectedAnswerIndex.value = -1;
    isQuestionEditable.value = true; // 清空后可编辑
  }

  // ==================== 对方权限获取 ====================
  /// 下拉刷新：重新获取对方权限 + 自己的权限状态
  Future<void> refreshPermissions() async {
    await Future.wait([
      _fetchPartnerPermission(),
      _checkPermissions(),
    ]);
  }

  Future<void> _fetchPartnerPermission() async {
    // 优先使用 Mine/Chat 页面已预拉取的缓存数据（避免UI闪动）
    final cached = LockPermissionApi.cachedPartnerPermission;
    if (cached != null) {
      halfUserPermission.value = cached;
      isPartnerPermissionGranted.value = _computePartnerPermissionGranted();
      isLoadingPartnerPermission.value = false;
      debugPrint('✅ 使用缓存的对方权限数据');
    } else {
      isLoadingPartnerPermission.value = true;
    }
    // 后台静默刷新
    try {
      final result = await _lockPermissionApi.getLockPermission();
      if (result.isSuccess && result.data != null) {
        halfUserPermission.value = result.data;
        isPartnerPermissionGranted.value = _computePartnerPermissionGranted();
        // 同步更新全局缓存
        LockPermissionApi.cachedPartnerPermission = result.data;
      }
    } catch (e) {
      logError('获取对方权限状态失败: $e');
    } finally {
      isLoadingPartnerPermission.value = false;
    }
  }

  bool _computePartnerPermissionGranted() {
    final data = halfUserPermission.value;
    if (data == null) return false;
    final screenUse = data['is_open_screen_use'] as int? ?? 0;
    final suspendWindow = data['is_open_suspend_window'] as int? ?? 0;
    final relevanceApps = data['relevance_app'];
    final hasRelevanceApp =
        relevanceApps is List && relevanceApps.isNotEmpty;

    if (isPartnerIos) {
      return screenUse == 1;
    } else {
      return screenUse == 1 && suspendWindow == 1;
    }
  }

  // ==================== 权限相关 ====================
  Future<void> _checkPermissions() async {
    // 检查悬浮窗权限
    final overlayGranted = await LockScreenOverlayService.checkOverlayPermission();
    isOverlayGranted.value = overlayGranted;
    
    // 检查app使用记录权限
    final usageGranted = await _permissionService.isUsageAccessGranted();
    isUsageAccessGranted.value = usageGranted;
  }

  /// 检查自己的锁机权限是否全部开启（悬浮窗 + app使用记录）
  bool get isMyPermissionGranted => isOverlayGranted.value && isUsageAccessGranted.value;

  /// 上报自己的权限状态到 /set/permission
  Future<void> _uploadMyPermissions() async {
    try {
      final locationGranted = await _permissionService.isLocationPermissionGranted();
      final notificationGranted = await _permissionService.isNotificationPermissionGranted();
      final result = await _lockPermissionApi.setPermission(
        isOpenLocation: locationGranted ? 1 : 0,
        isOpenNoticeRemind: notificationGranted ? 1 : 0,
        isOpenScreenUse: isUsageAccessGranted.value ? 1 : 0,
        isOpenBackRun: 0,
        isOpenPreventProgramSleep: 0,
        isOpenSelfStarting: 0,
        isOpenProgramLock: 0,
        isOpenSuspendWindow: isOverlayGranted.value ? 1 : 0,
      );
      // debugPrint('上报权限状态: ${result.isSuccess ? '成功' : '失败: ${result.msg}'}');
    } catch (e) {
      logError('上报权限状态异常: $e');
    }
  }

  Future<void> goToPermissionSettings({bool flashOverlay = false, bool flashUsage = false}) async {
    await Get.toNamed(
      KissuRoutePath.systemPermission,
      arguments: {
        'flashOverlay': flashOverlay,
        'flashUsage': flashUsage,
      },
    );
    // 从权限设置页面返回后，刷新权限状态并上报
    await _checkPermissions();
    _uploadMyPermissions();
  }

  /// 「去提醒」直接发送消息，无需弹确认框
  void sendRemindDirectly() {
    _sendLockPhoneReminder();
  }

  /// "下一步" 被点击但对方权限不满足时，显示二次确认弹窗
  void _showPartnerPermissionWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        child: Stack(
          children: [
            Container(
              height: 160,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/dialog/kissu4_dialog_small_bg.webp'),
                  fit: BoxFit.fill,
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Ta还未开启相关权限\n还不能锁机哦～',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _sendLockPhoneReminder();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9AD9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '去提醒',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: const Icon(Icons.close, size: 20, color: Color(0xFFaaaaaa)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// iOS对方关联App为空时，显示提示弹窗
  void _showIosNoAppsWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        child: Stack(
          children: [
            Container(
              height: 160,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/dialog/kissu4_dialog_small_bg.webp'),
                  fit: BoxFit.fill,
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Ta还未关联任何APP\n还不能锁机哦~',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _sendConnectAppReminder();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9AD9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '去提醒',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: const Icon(Icons.close, size: 20, color: Color(0xFFaaaaaa)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 发送关联App提醒（iOS对方专用）
  void _sendConnectAppReminder() async {
    final partnerId = UserManager.currentUser?.halfUserInfo?.uniqueId;
    if (partnerId == null || partnerId.isEmpty) return;
    final im = TencentIMService.instance;
    await im.sendCustomMessage(
      receiverID: partnerId,
      customData: jsonEncode({'msg_lock': 'connect_app'}),
    );
    // debugPrint('已发送关联App提醒给iOS对方');
    OKToastUtil.showSuccess('已通过聊天通知Ta');
  }

  void _sendLockPhoneReminder() async {
    final partnerId = UserManager.currentUser?.halfUserInfo?.uniqueId;
    if (partnerId == null || partnerId.isEmpty) return;
    final im = TencentIMService.instance;
    final data = halfUserPermission.value;

    if (isPartnerIos) {
      // iOS：关联App为空时发 connect_app；screen_use 未开启时发 phone_use
      final relevanceApps = data?['relevance_app'];
      final hasApps = relevanceApps is List && relevanceApps.isNotEmpty;
      final screenUse = data?['is_open_screen_use'] as int? ?? 0;
      if (!hasApps) {
        await im.sendCustomMessage(
          receiverID: partnerId,
          customData: jsonEncode({'msg_lock': 'connect_app'}),
        );
        // debugPrint('已发送关联App提醒给iOS对方');
       }
      if (screenUse == 0) {
        await im.sendCustomMessage(
          receiverID: partnerId,
          customData: jsonEncode({'msg_lock': 'phone_use'}),
        );
        //  debugPrint('已发送screen_use权限提醒给iOS对方');
      }
        OKToastUtil.showSuccess('已通过聊天通知Ta');

    } else {
      // Android：悬浮窗和app使用记录权限各自判断
      final suspendWindow = data?['is_open_suspend_window'] as int? ?? 0;
      final screenUse = data?['is_open_screen_use'] as int? ?? 0;
      if (suspendWindow == 0) {
        await im.sendCustomMessage(
          receiverID: partnerId,
          customData: jsonEncode({'msg_lock': 'lock_phone'}),
        );
        //  debugPrint('已发送悬浮窗权限提醒给对方');
      }
      if (screenUse == 0) {
        await im.sendCustomMessage(
          receiverID: partnerId,
          customData: jsonEncode({'msg_lock': 'phone_use'}),
        );
        //  debugPrint('已发送app使用记录权限提醒给对方');
      }
        OKToastUtil.showSuccess('已通过聊天通知Ta');

    }
  }

  // ==================== 锁机操作（走接口） ====================
  void confirmLock() async {
    if (!isStep2Complete) return;
    if (isLocking.value) return; // 防止重复点击
    isLocking.value = true;

    try {
      // 1) 构建答案JSON: [{"answer":"xxx","is_answer":0/1}, ...]
      final answerList = <Map<String, dynamic>>[];
      for (int i = 0; i < 4; i++) {
        answerList.add({
          'answer': answers[i].value,
          'is_answer': (i == selectedAnswerIndex.value) ? 1 : 0,
        });
      }
      final lockAnswerJson = jsonEncode(answerList);

      // 2) 处理锁机背景图
      // 预设图片：传 default_bg_image_index（kissu_lock_1/2/3）
      // 自定义图片：上传后传 lock_bg_image URL
      String bgImageUrl = '';
      String defaultBgImageIndex = '';
      
      if (selectedImageIndex.value >= 0 && selectedImageIndex.value < 3) {
        // 预设图片，使用 default_bg_image_index
        final presetNames = ['kissu_lock_1', 'kissu_lock_2', 'kissu_lock_3'];
        defaultBgImageIndex = presetNames[selectedImageIndex.value];
      } else if (selectedImageIndex.value == 3 && !isPartnerIos) {
        // 自定义图片，上传获取URL（仅Android对方需要）
        bgImageUrl = await _uploadLockBgImage();
      }

      // 3) 调用锁机API（后端自动发送IM消息）
      final result = await _lockPermissionApi.lockUserPhone(
        lockQuestion: question.value,
        lockAnswer: lockAnswerJson,
        lockPrompt: lockText.value,
        lockBgImage: bgImageUrl,
        defaultBgImageIndex: defaultBgImageIndex,
      );

      if (result.isSuccess) {
        // debugPrint('✅ 锁机接口调用成功（后端自动发送IM）');
        OKToastUtil.showSuccess('锁机成功');
        // 更新本地状态
        final now = DateTime.now();
        lockStartTime.value = now;
        pageState.value = 'locked';
        _saveLockState(true);
        _startLockTimer();
        // 刷新用户信息（更新 half_lock_status）
        UserManager.refreshUserInfo();
        // 刷新锁机记录
        await _fetchLockRecords();
      } else {
        OKToastUtil.showError(result.msg ?? '锁机失败');
      }
    } catch (e) {
      debugPrint('锁机操作异常: $e');
      OKToastUtil.showError('锁机失败，请重试');
    } finally {
      isLocking.value = false;
    }
  }

  /// 上传锁机背景图并返回URL
  Future<String> _uploadLockBgImage() async {
    try {
      File? imageFile;
      if (selectedImageIndex.value >= 0 && selectedImageIndex.value < 3) {
        // 预设图片：从asset复制到临时目录后上传
        final assetPath = presetImages[selectedImageIndex.value];
        final byteData = await rootBundle.load(assetPath);
        final tempDir = await Directory.systemTemp.createTemp('lock_bg_');
        final tempFile = File('${tempDir.path}/lock_bg.png');
        await tempFile.writeAsBytes(byteData.buffer.asUint8List());
        imageFile = tempFile;
      } else if (selectedImageIndex.value == 3 && customImagePath.value.isNotEmpty) {
        imageFile = File(customImagePath.value);
      }
      if (imageFile != null && await imageFile.exists()) {
        final uploadResult = await _fileUploadApi.uploadFile(imageFile);
        if (uploadResult.isSuccess && uploadResult.data != null) {
          // debugPrint('✅ 锁机背景图上传成功: ${uploadResult.data}');
          return uploadResult.data!;
        }
        logError('⚠️ 锁机背景图上传失败: ${uploadResult.msg}');
      }
    } catch (e) {
      logError('上传锁机背景图异常: $e');
    }
    return '';
  }

  void _startLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final diff = DateTime.now().difference(lockStartTime.value);
      final hours = diff.inHours.toString().padLeft(2, '0');
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
      lockDuration.value = '$hours:$minutes:$seconds';

      // 更新最新记录的时长
      if (lockRecords.isNotEmpty) {
        lockRecords[0] = LockRecord(
          index: lockRecords[0].index,
          duration: lockDuration.value,
          dateTime: lockRecords[0].dateTime,
        );
      }
    });
  }

  /// 主动解锁（A锁B，A主动解锁，unlock_type=1）
  void unlockDevice() async {
    try {
      // 调用解锁API（后端自动发IM消息 unlock_phone_send）
      final result = await _lockPermissionApi.unlockUserPhone(unlockType: 1);
      if (result.isSuccess) {
        // debugPrint('🔓 主动解锁接口调用成功');
      } else {
        logError('🔓 主动解锁接口失败: ${result.msg}');
      }
    } catch (e) {
      logError('🔓 主动解锁异常: $e');
    }

    // 不管接口是否成功都重置本地状态
    _lockTimer?.cancel();
    pageState.value = 'setup';
    currentStep.value = 1;
    lockDuration.value = '00:00:00';
    _justUnlocked = true; // 防止fetchLockRecords再次锁定
    _saveLockState(false);
    // 刷新用户信息（更新 half_lock_status），必须 await 确保返回聊天页时数据已最新
    await UserManager.refreshUserInfo();
    // 刷新锁机记录
    await _fetchLockRecords();
    // 解锁成功提示
    OKToastUtil.showSuccess('解锁成功');
    // 解锁成功后返回上一页（我的页面）
    Get.back();
  }

  /// 🔥 监听被锁方答题解锁通知，自动重置锁机页面
  void _listenForUnlockNotification() {
    final im = TencentIMService.instance;
    im.onUnlockPhoneReceived.value = (int attempts) {
      debugPrint('🔓 收到被锁方解锁通知，答题次数: $attempts');
      // 重置锁机页面状态
      _lockTimer?.cancel();
      pageState.value = 'setup';
      currentStep.value = 1;
      lockDuration.value = '00:00:00';
      _justUnlocked = true; // 防止fetchLockRecords再次锁定
      _saveLockState(false);
      // 刷新用户信息（更新 half_lock_status）
      UserManager.refreshUserInfo();
      // 刷新锁机记录
      _fetchLockRecords();
    };
  }

  // ==================== 锁机记录（API） ====================
  Future<void> _fetchLockRecords({int page = 1}) async {
    isLoadingRecords.value = true;
    try {
      final result = await _lockPermissionApi.getLockPhoneRecord(
        page: page,
        pageSize: 10,
      );
      if (result.isSuccess && result.data != null) {
        final data = result.data!;
        final total = data['total'] as int? ?? 0;
        if (page == 1) {
          lockRecordTotal = total;
        }
        final list = data['data'] as List? ?? [];
        final pageSize = 10;
        final records = <LockRecord>[];
        final rawList = list.whereType<Map<String, dynamic>>().toList();
        for (int i = 0; i < rawList.length; i++) {
          final record = LockRecord.fromApiJson(rawList[i]);
          // 第一条数据 = 第total次锁机，依次减1
          final lockNumber = lockRecordTotal - ((page - 1) * pageSize) - i;
          records.add(LockRecord(
            index: lockNumber > 0 ? lockNumber : 0,
            duration: record.duration,
            dateTime: record.dateTime,
            id: record.id,
            lockStatus: record.lockStatus,
            unlockType: record.unlockType,
            lockTime: record.lockTime,
            unlockTime: record.unlockTime,
          ));
        }
        if (page == 1) {
          lockRecords.value = records;
        } else {
          lockRecords.addAll(records);
        }
        lockRecordPage.value = page;
        lockRecordHasMore.value = data['has_more'] == true;

        // 最新锁机数据（用于倒计时）
        final latest = data['latest_lock_data'] as Map<String, dynamic>?;
        if (latest != null) {
          latestLockStatus.value = latest['lock_status'] as int? ?? 0;
          latestLockTime.value = latest['lock_time'] as int? ?? 0;
          // 如果当前正在锁定中，恢复锁定状态（但刚解锁时跳过，防止API延迟导致再次锁定）
          if (latestLockStatus.value == 1 && latestLockTime.value > 0 && !_justUnlocked) {
            lockStartTime.value = DateTime.fromMillisecondsSinceEpoch(
              latestLockTime.value * 1000,
            );
            pageState.value = 'locked';
            _startLockTimer();
          }else{
             pageState.value = 'setup';
          }
        }
        _justUnlocked = false;
      }
    } catch (e) {
      logError('获取锁机记录失败: $e');
    } finally {
      isLoadingRecords.value = false;
    }
  }

  /// 加载更多锁机记录
  Future<void> loadMoreLockRecords() async {
    if (!lockRecordHasMore.value || isLoadingRecords.value) return;
    await _fetchLockRecords(page: lockRecordPage.value + 1);
  }

  Future<void> _checkLockState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLocked = prefs.getBool('is_locked') ?? false;
      if (isLocked) {
        final startTimeStr = prefs.getString('lock_start_time');
        if (startTimeStr != null) {
          lockStartTime.value = DateTime.parse(startTimeStr);
          // 立即计算并显示当前倒计时，避免等待1秒后才更新
          final diff = DateTime.now().difference(lockStartTime.value);
          final hours = diff.inHours.toString().padLeft(2, '0');
          final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
          final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
          lockDuration.value = '$hours:$minutes:$seconds';
          pageState.value = 'locked';
          _startLockTimer();
        }
      }
    } catch (e) {
      logError('检查锁定状态失败: $e');
    }
  }

  Future<void> _saveLockState(bool isLocked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_locked', isLocked);
      if (isLocked) {
        await prefs.setString(
          'lock_start_time',
          lockStartTime.value.toIso8601String(),
        );
      } else {
        await prefs.remove('lock_start_time');
      }
    } catch (e) {
      logError('保存锁定状态失败: $e');
    }
  }

  /// 埋点6: 读取原生锁屏答题事件并上报
  /// 原生LockScreenOverlayService在用户每次选择答案时会将事件保存到FlutterSharedPreferences
  /// 此方法在进入锁机页面时读取并上报这些事件，然后清除
  Future<void> _reportPendingAnswerAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString('lock_answer_analytics_events');
      if (eventsJson == null || eventsJson.isEmpty || eventsJson == '[]') return;

      final List<dynamic> events = jsonDecode(eventsJson);
      for (final event in events) {
        final unlockStatus = event['unlock_status'] as int? ?? 0;
        AnalyticsHelper.trackLockPhoneAnswerUnlock(unlockStatus: unlockStatus);
      }
      // 上报完毕后清除
      await prefs.remove('lock_answer_analytics_events');
      // debugPrint('📊 埋点6: 已上报${events.length}条答题事件');
    } catch (e) {
      logError('📊 读取答题埋点事件失败: $e');
    }
  }

  // 获取预览图
  ImageProvider getPreviewImage() {
    if (selectedImageIndex.value >= 0 && selectedImageIndex.value < 3) {
      return AssetImage(previewImages[selectedImageIndex.value]);
    } else if (selectedImageIndex.value == 3 &&
        customImagePath.value.isNotEmpty) {
      return FileImage(File(customImagePath.value));
    }
    return const AssetImage('assets/lock/kissu_lock_preview_1.png');
  }

  // 获取选中的图片Widget
  Widget getSelectedImageWidget({double? width, double? height}) {
    if (selectedImageIndex.value >= 0 && selectedImageIndex.value < 3) {
      return Image.asset(
        presetImages[selectedImageIndex.value],
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    } else if (selectedImageIndex.value == 3 &&
        customImagePath.value.isNotEmpty) {
      return Image.file(
        File(customImagePath.value),
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }
    return const SizedBox.shrink();
  }
}

// ==================== 锁定记录模型 ====================
class LockRecord {
  final int index;
  final String duration;
  final DateTime dateTime;
  final String? id;
  final int lockStatus; // 1=锁定中 0=已解锁
  final int unlockType; // 0=未解锁 1=主动 2=被动
  final int lockTime; // 锁机开始时间戳
  final int unlockTime; // 解锁时间戳

  LockRecord({
    required this.index,
    required this.duration,
    required this.dateTime,
    this.id,
    this.lockStatus = 0,
    this.unlockType = 0,
    this.lockTime = 0,
    this.unlockTime = 0,
  });

  /// 从API返回的JSON构造
  factory LockRecord.fromApiJson(Map<String, dynamic> json) {
    final lockTimestamp = json['lock_time'] as int? ?? 0;
    final unlockTimestamp = json['unlock_time'] as int? ?? 0;
    final status = json['lock_status'] as int? ?? 0;

    // 计算持续时长
    String dur = '00:00:00';
    if (lockTimestamp > 0) {
      final lockDt = DateTime.fromMillisecondsSinceEpoch(lockTimestamp * 1000);
      final endDt = unlockTimestamp > 0
          ? DateTime.fromMillisecondsSinceEpoch(unlockTimestamp * 1000)
          : (status == 1 ? DateTime.now() : lockDt);
      final diff = endDt.difference(lockDt);
      final h = diff.inHours.toString().padLeft(2, '0');
      final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
      dur = '$h:$m:$s';
    }

    return LockRecord(
      index: 0,
      duration: dur,
      dateTime: lockTimestamp > 0
          ? DateTime.fromMillisecondsSinceEpoch(lockTimestamp * 1000)
          : DateTime.now(),
      id: json['_id'] as String?,
      lockStatus: status,
      unlockType: json['unlock_type'] as int? ?? 0,
      lockTime: lockTimestamp,
      unlockTime: unlockTimestamp,
    );
  }

  factory LockRecord.fromJson(Map<String, dynamic> json) {
    return LockRecord(
      index: json['index'] as int? ?? 0,
      duration: json['duration'] as String? ?? '00:00:00',
      dateTime: DateTime.parse(json['dateTime'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'duration': duration,
      'dateTime': dateTime.toIso8601String(),
    };
  }
}
