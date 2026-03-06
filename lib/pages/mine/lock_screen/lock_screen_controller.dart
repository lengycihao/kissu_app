import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:kissu_app/services/tencent_im_service.dart';
import 'package:kissu_app/services/lock_screen_overlay_service.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';

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

  // ==================== 权限状态 ====================
  final isOverlayGranted = false.obs;
  final isPartnerPermissionGranted = false.obs; // 后期通过接口判断，现在默认未开启

  // ==================== 锁定状态 ====================
  final lockStartTime = DateTime.now().obs;
  final lockDuration = '00:00:00'.obs;
  Timer? _lockTimer;
  final lockRecords = <LockRecord>[].obs;

  // ==================== 系统随机问题库 ====================
  final List<Map<String, dynamic>> questionBank = [
    {
      'question': '什么马不能骑？',
      'answers': ['海马', '河马', '斑马', '木马'],
      'correctIndex': 0,
    },
    {
      'question': '什么水不能喝？',
      'answers': ['薪水', '泉水', '矿泉水', '纯净水'],
      'correctIndex': 0,
    },
    {
      'question': '什么门不能关？',
      'answers': ['澳门', '厦门', '房门', '大门'],
      'correctIndex': 0,
    },
    {
      'question': '什么路不能走？',
      'answers': ['电路', '公路', '马路', '小路'],
      'correctIndex': 0,
    },
    {
      'question': '什么桥不能过？',
      'answers': ['鹊桥', '石桥', '木桥', '铁桥'],
      'correctIndex': 0,
    },
    {
      'question': '什么鱼不能吃？',
      'answers': ['木鱼', '鲫鱼', '鲤鱼', '草鱼'],
      'correctIndex': 0,
    },
    {
      'question': '什么花不能摘？',
      'answers': ['浪花', '玫瑰', '百合', '菊花'],
      'correctIndex': 0,
    },
    {
      'question': '什么锁最难开？',
      'answers': ['心锁', '门锁', '密码锁', '挂锁'],
      'correctIndex': 0,
    },
    {
      'question': '什么房不能住？',
      'answers': ['牢房', '卧房', '书房', '客房'],
      'correctIndex': 0,
    },
    {
      'question': '什么球不能打？',
      'answers': ['地球', '篮球', '足球', '乒乓球'],
      'correctIndex': 0,
    },
  ];

  // ==================== 计算属性 ====================
  bool get isStep1Complete =>
      lockText.value.isNotEmpty && selectedImageIndex.value >= 0;

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
    randomQuestion();
    _loadLockRecords();
    _checkLockState();
    _checkOverlayPermission();
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
    }
  }

  void goBackToStep1() {
    currentStep.value = 1;
  }

  // ==================== Step2 操作 ====================
  void selectAnswer(int index) {
    selectedAnswerIndex.value = index;
  }

  void randomQuestion() {
    final random = DateTime.now().millisecondsSinceEpoch % questionBank.length;
    final q = questionBank[random];
    questionController.text = q['question'] as String;
    final answerList = q['answers'] as List<String>;
    for (int i = 0; i < 4; i++) {
      answerControllers[i].text = answerList[i];
    }
    selectedAnswerIndex.value = q['correctIndex'] as int;
  }

  void clearAll() {
    questionController.clear();
    for (var c in answerControllers) {
      c.clear();
    }
    selectedAnswerIndex.value = -1;
  }

  // ==================== 权限相关 ====================
  Future<void> _checkOverlayPermission() async {
    final granted = await LockScreenOverlayService.checkOverlayPermission();
    isOverlayGranted.value = granted;
  }

  void goToPermissionSettings() {
    Get.toNamed(KissuRoutePath.systemPermission);
  }

  void showRemindDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 关闭按钮
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  child: const Icon(Icons.close, size: 20, color: Color(0xFF999999)),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ta还未开启相关权限',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 6),
              const Text(
                '还不能锁机哦～',
                style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
              ),
              const SizedBox(height: 24),
              // 去提醒按钮
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _sendLockPhoneReminder();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7ECE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    elevation: 0,
                  ),
                  child: const Text('去提醒', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendLockPhoneReminder() async {
    final partnerId = UserManager.currentUser?.halfUserInfo?.uniqueId;
    if (partnerId == null || partnerId.isEmpty) return;
    final im = TencentIMService.instance;
    await im.sendCustomMessage(
      receiverID: partnerId,
      customData: jsonEncode({'type': 'lock_phone'}),
    );
    debugPrint('已发送锁机提醒消息给对方');
  }

  // ==================== 锁机操作 ====================
  void confirmLock() async {
    if (!isStep2Complete) return;

    // 通过IM发送锁机指令给对方（自定义消息携带问题数据）
    final partnerId = UserManager.currentUser?.halfUserInfo?.uniqueId;
    if (partnerId != null && partnerId.isNotEmpty) {
      final im = TencentIMService.instance;
      final lockData = {
        'type': 'lock_screen_command',
        'question': question.value,
        'answers': answers.map((a) => a.value).toList(),
        'correctIndex': selectedAnswerIndex.value,
        'lockText': lockText.value,
        'minutes': 5,
        // 背景图片索引（0,1,2为预设图片）
        'bgImageIndex': selectedImageIndex.value,
      };
      await im.sendCustomMessage(
        receiverID: partnerId,
        customData: jsonEncode(lockData),
      );
      debugPrint('已发送锁机指令给对方: $partnerId');
    } else {
      debugPrint('无法发送锁机指令：未找到对方IM ID');
    }

    // 记录锁定
    final now = DateTime.now();
    lockStartTime.value = now;
    pageState.value = 'locked';

    // 添加锁定记录
    final recordIndex = lockRecords.length + 1;
    lockRecords.insert(
      0,
      LockRecord(
        index: recordIndex,
        duration: '00:00:00',
        dateTime: now,
      ),
    );
    _saveLockRecords();
    _saveLockState(true);

    // 启动计时器
    _startLockTimer();
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

  void unlockDevice() {
    _lockTimer?.cancel();
    pageState.value = 'setup';
    currentStep.value = 1;

    // 重置所有状态
    lockTextController.clear();
    selectedImageIndex.value = 0;
    customImagePath.value = '';
    questionController.clear();
    for (var c in answerControllers) {
      c.clear();
    }
    selectedAnswerIndex.value = -1;
    lockDuration.value = '00:00:00';

    _saveLockRecords();
    _saveLockState(false);
  }

  // ==================== 持久化 ====================
  Future<void> _loadLockRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('lock_records');
      if (jsonStr != null) {
        final list = jsonDecode(jsonStr) as List;
        lockRecords.value = list.map((e) => LockRecord.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('加载锁定记录失败: $e');
    }
  }

  Future<void> _saveLockRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr =
          jsonEncode(lockRecords.map((e) => e.toJson()).toList());
      await prefs.setString('lock_records', jsonStr);
    } catch (e) {
      debugPrint('保存锁定记录失败: $e');
    }
  }

  Future<void> _checkLockState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLocked = prefs.getBool('is_locked') ?? false;
      if (isLocked) {
        final startTimeStr = prefs.getString('lock_start_time');
        if (startTimeStr != null) {
          lockStartTime.value = DateTime.parse(startTimeStr);
          pageState.value = 'locked';
          _startLockTimer();
        }
      }
    } catch (e) {
      debugPrint('检查锁定状态失败: $e');
    }
  }

  Future<void> _saveLockState(bool isLocked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_locked', isLocked);
      if (isLocked) {
        await prefs.setString(
            'lock_start_time', lockStartTime.value.toIso8601String());
      } else {
        await prefs.remove('lock_start_time');
      }
    } catch (e) {
      debugPrint('保存锁定状态失败: $e');
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

  LockRecord({
    required this.index,
    required this.duration,
    required this.dateTime,
  });

  factory LockRecord.fromJson(Map<String, dynamic> json) {
    return LockRecord(
      index: json['index'] as int,
      duration: json['duration'] as String,
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
