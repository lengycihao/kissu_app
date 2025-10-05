import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 状态设置页面控制器
class LocationStateController extends GetxController {
  /// 当前用户状态（是否有状态）
  final hasStatus = false.obs;
  
  /// 当前状态内容
  final currentStatusText = ''.obs;
  
  /// 当前状态表情
  final currentStatusEmoji = ''.obs;
  
  /// 状态有效期
  final statusExpireTime = Rx<DateTime?>(null);
  
  /// 表情分类数据（后期从接口获取，现在用本地数据）
  final RxList<EmojiCategory> emojiCategories = <EmojiCategory>[].obs;
  
  /// 当前选中的分类索引
  final selectedCategoryIndex = 0.obs;
  
  @override
  void onInit() {
    super.onInit();
    _initLocalEmojiData();
    _loadCurrentStatus();
  }
  
  /// 初始化本地表情数据（临时，后期从接口获取）
  void _initLocalEmojiData() {
    emojiCategories.value = [
      EmojiCategory(
        name: '心情',
        emojis: [
          EmojiItem(emoji: '😊', name: '开心'),
          EmojiItem(emoji: '😍', name: '爱心'),
          EmojiItem(emoji: '🥰', name: '喜欢'),
          EmojiItem(emoji: '😘', name: '亲亲'),
          EmojiItem(emoji: '😎', name: '酷'),
          EmojiItem(emoji: '🤗', name: '拥抱'),
          EmojiItem(emoji: '😴', name: '困'),
          EmojiItem(emoji: '😭', name: '哭'),
          EmojiItem(emoji: '😂', name: '笑哭'),
          EmojiItem(emoji: '🥺', name: '可怜'),
          EmojiItem(emoji: '😤', name: '生气'),
          EmojiItem(emoji: '😱', name: '惊讶'),
        ],
      ),
      EmojiCategory(
        name: '活动',
        emojis: [
          EmojiItem(emoji: '🏃', name: '跑步'),
          EmojiItem(emoji: '🚴', name: '骑车'),
          EmojiItem(emoji: '🏊', name: '游泳'),
          EmojiItem(emoji: '⛹️', name: '打球'),
          EmojiItem(emoji: '🧘', name: '瑜伽'),
          EmojiItem(emoji: '💪', name: '健身'),
          EmojiItem(emoji: '🎮', name: '游戏'),
          EmojiItem(emoji: '🎵', name: '音乐'),
          EmojiItem(emoji: '📚', name: '学习'),
          EmojiItem(emoji: '💻', name: '工作'),
          EmojiItem(emoji: '🎬', name: '看片'),
          EmojiItem(emoji: '✈️', name: '旅行'),
        ],
      ),
      EmojiCategory(
        name: '饮食',
        emojis: [
          EmojiItem(emoji: '🍕', name: '披萨'),
          EmojiItem(emoji: '🍔', name: '汉堡'),
          EmojiItem(emoji: '🍜', name: '面条'),
          EmojiItem(emoji: '🍱', name: '便当'),
          EmojiItem(emoji: '🍰', name: '蛋糕'),
          EmojiItem(emoji: '🍦', name: '冰淇淋'),
          EmojiItem(emoji: '☕', name: '咖啡'),
          EmojiItem(emoji: '🍵', name: '茶'),
          EmojiItem(emoji: '🥤', name: '饮料'),
          EmojiItem(emoji: '🍺', name: '啤酒'),
          EmojiItem(emoji: '🍷', name: '红酒'),
          EmojiItem(emoji: '🍻', name: '干杯'),
        ],
      ),
      EmojiCategory(
        name: '其他',
        emojis: [
          EmojiItem(emoji: '💖', name: '爱心'),
          EmojiItem(emoji: '💝', name: '礼物'),
          EmojiItem(emoji: '🌹', name: '玫瑰'),
          EmojiItem(emoji: '🌟', name: '星星'),
          EmojiItem(emoji: '🎉', name: '庆祝'),
          EmojiItem(emoji: '🎈', name: '气球'),
          EmojiItem(emoji: '🔥', name: '火'),
          EmojiItem(emoji: '⭐', name: '五角星'),
          EmojiItem(emoji: '🌈', name: '彩虹'),
          EmojiItem(emoji: '☀️', name: '太阳'),
          EmojiItem(emoji: '🌙', name: '月亮'),
          EmojiItem(emoji: '⚡', name: '闪电'),
        ],
      ),
    ];
  }
  
  /// 加载当前状态（从本地或接口）
  void _loadCurrentStatus() {
    // TODO: 从接口或本地存储加载当前状态
    // 示例：如果有状态
    // hasStatus.value = true;
    // currentStatusText.value = '今天心情不错';
    // currentStatusEmoji.value = '😊';
    // statusExpireTime.value = DateTime.now().add(Duration(hours: 24));
  }
  
  /// 当前选中的表情（用于底部弹窗）
  final selectedEmoji = Rx<EmojiItem?>(null);
  
  /// 选中的有效期（小时数）- 用于顶部状态区域显示
  final selectedExpireHours = 1.obs;
  
  /// 临时选择的有效期（小时数）- 用于底部弹窗，确认后才同步到 selectedExpireHours
  final tempExpireHours = 1.obs;
  
  /// 选择表情 - 直接显示底部有效期选择弹窗
  void selectEmoji(EmojiItem emoji) {
    selectedEmoji.value = emoji;
    tempExpireHours.value = selectedExpireHours.value; // 使用当前有效期作为初始值
  }
  
  /// 显示替换确认弹窗的回调（由页面设置）
  Function()? onShowReplaceDialog;
  
  /// 显示替换确认弹窗
  void _showReplaceConfirmDialog() {
    onShowReplaceDialog?.call();
  }
  
  /// 确认设置状态 - 在底部弹窗点击确认时调用
  void confirmSetStatus() {
    if (selectedEmoji.value == null) return;
    
    // 如果当前有状态，需要先确认是否替换
    if (hasStatus.value) {
      _showReplaceConfirmDialog();
    } else {
      // 没有状态，直接同步有效期并设置
      selectedExpireHours.value = tempExpireHours.value;
      _doSetStatus();
    }
  }
  
  /// 确认替换状态 - 在替换弹窗点击"确认"时调用
  void confirmReplace() {
    // 在替换确认时才同步临时有效期到正式有效期
    selectedExpireHours.value = tempExpireHours.value;
    _doSetStatus();
  }
  
  /// 取消替换状态
  void cancelReplace() {
    // 取消替换，关闭底部弹窗
    selectedEmoji.value = null;
  }
  
  /// 执行设置状态的实际操作（不返回页面）
  void _doSetStatus() {
    if (selectedEmoji.value == null) return;
    
    currentStatusEmoji.value = selectedEmoji.value!.emoji;
    currentStatusText.value = selectedEmoji.value!.name;
    hasStatus.value = true;
    statusExpireTime.value = DateTime.now().add(
      Duration(hours: selectedExpireHours.value)
    );
    
    // 清空选中状态（关闭底部弹窗）
    selectedEmoji.value = null;
    
    // 注意：不在这里返回页面，等待用户点击"保存"按钮
  }
  
  /// 取消设置状态
  void cancelSetStatus() {
    selectedEmoji.value = null;
  }
  
  /// 删除当前状态
  void deleteStatus() {
    hasStatus.value = false;
    currentStatusText.value = '';
    currentStatusEmoji.value = '';
    statusExpireTime.value = null;
    
    // TODO: 调用接口删除状态
  }
  
  /// 设置有效期
  void setExpireTime(DateTime time) {
    statusExpireTime.value = time;
    // TODO: 调用接口更新有效期
    _saveStatus();
  }
  
  /// 保存状态（公共方法）- 点击顶部保存按钮时调用
  void saveStatus() {
    _saveStatus();
    Get.back(); // 保存后返回上一页
  }
  
  /// 保存状态到接口
  void _saveStatus() {
    // TODO: 调用接口保存状态
    debugPrint('保存状态: ${currentStatusEmoji.value} ${currentStatusText.value}');
    debugPrint('有效期: ${statusExpireTime.value}');
  }
  
  /// 获取有效期剩余时间文本
  String get expireTimeText {
    if (statusExpireTime.value == null) return '';
    
    final now = DateTime.now();
    final expire = statusExpireTime.value!;
    final diff = expire.difference(now);
    
    if (diff.isNegative) {
      return '已过期';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟后过期';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时后过期';
    } else {
      return '${diff.inDays}天后过期';
    }
  }
}

/// 表情分类数据模型
class EmojiCategory {
  final String name;
  final List<EmojiItem> emojis;
  
  EmojiCategory({
    required this.name,
    required this.emojis,
  });
}

/// 表情项数据模型
class EmojiItem {
  final String emoji;
  final String name;
  
  EmojiItem({
    required this.emoji,
    required this.name,
  });
}

