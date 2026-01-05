import 'package:get/get.dart';
import 'package:kissu_app/network/public/face_status_api.dart';
import 'package:kissu_app/utils/debug_util.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/utils/emoji_cache_manager.dart';
import 'package:kissu_app/pages/location/location_v2_controller.dart';

/// 状态设置页面控制器
class LocationStateController extends GetxController {
 
  
 
  /// 当前用户状态（是否有状态）
  final hasStatus = false.obs;
  
  /// 当前状态内容
  final currentStatusText = ''.obs;
  
  /// 当前状态表情图片 URL
  final currentStatusEmoji = ''.obs;
  
  /// 当前状态 ID
  final currentStatusId = 0.obs;
  
  /// 状态有效期
  final statusExpireTime = Rx<DateTime?>(null);
  
  /// 表情分类数据
  final RxList<EmojiCategory> emojiCategories = <EmojiCategory>[].obs;
  
  /// 当前选中的分类索引
  final selectedCategoryIndex = 0.obs;
  
  /// 加载状态
  final isLoading = true.obs;
  
  /// API 实例
  final FaceStatusApi _api = FaceStatusApi();
  
  /// 缓存管理器实例
  final EmojiCacheManager _cacheManager = EmojiCacheManager.instance;
  
  @override
  void onInit() {
    super.onInit();
   
  
    _loadFaceStatusWithCache();
  }
  
  @override
  void onClose() {
    
    super.onClose();
  }
  
 
  /// 带缓存的加载表情状态数据
  Future<void> _loadFaceStatusWithCache() async {
    try {
      isLoading.value = true;
      
      // 1. 先加载缓存数据
      final hasCache = await _loadFromCache();
      
      // 2. 如果有缓存，立即显示并关闭加载状态
      if (hasCache) {
        isLoading.value = false;
        DebugUtil.info('✅ 缓存数据加载完成，页面可交互');
      }
      
      // 3. 在后台请求接口获取最新数据
      _loadFaceStatusFromApi().then((_) {
        if (!hasCache) {
          isLoading.value = false;
        }
      });
      
    } catch (e) {
      DebugUtil.error('❌ 加载表情状态数据异常: $e');
      OKToastUtil.showError('加载数据异常');
      isLoading.value = false;
    }
  }
  
  /// 从缓存加载数据
  /// 返回是否成功加载到缓存数据
  Future<bool> _loadFromCache() async {
    try {
      bool hasData = false;
      
      // 加载缓存的表情分类数据
      final cachedCategories = await _cacheManager.getCachedEmojiCategories();
      if (cachedCategories != null && cachedCategories.isNotEmpty) {
        emojiCategories.value = cachedCategories;
        hasData = true;
        DebugUtil.info('✅ 从缓存加载表情分类数据成功，共 ${cachedCategories.length} 个分类');
      }
      
      // 加载缓存的当前状态数据
      final cachedStatus = await _cacheManager.getCachedCurrentStatus();
      if (cachedStatus != null) {
        _applyStatusData(cachedStatus);
        DebugUtil.info('✅ 从缓存加载当前状态数据成功');
      }
      
      return hasData;
    } catch (e) {
      DebugUtil.error('❌ 从缓存加载数据失败: $e');
      return false;
    }
  }
  
  /// 应用状态数据到UI
  void _applyStatusData(CurrentStatusData statusData) {
    hasStatus.value = statusData.hasStatus;
    currentStatusId.value = statusData.currentStatusId;
    currentStatusText.value = statusData.currentStatusText;
    currentStatusEmoji.value = statusData.currentStatusEmoji;
    statusExpireTime.value = statusData.statusExpireTime;
    selectedExpireHours.value = statusData.selectedExpireHours;
    topExpireHours.value = statusData.topExpireHours;
  }
  
  /// 从接口加载表情状态数据
  Future<void> _loadFaceStatusFromApi() async {
    try {
      final result = await _api.getFaceStatus();
      
      if (result.isSuccess && result.data != null) {
        final data = result.data!;
        
        // 转换并设置表情分类数据
        final newCategories = data.faceList.map((category) {
          return EmojiCategory(
            name: category.className,
            classId: category.classId,
            emojis: category.faceList.map((face) {
              return EmojiItem(
                id: face.id,
                emoji: face.faceUrl, // 使用图片URL
                name: face.faceText,
              );
            }).toList(),
          );
        }).toList();
        
        // 更新表情分类数据
        emojiCategories.value = newCategories;
        
        // 缓存表情分类数据
        await _cacheManager.cacheEmojiCategories(newCategories);
        
        // 设置当前状态（需要检查nowFace是否有效：不为null且有内容）
        if (data.nowFace != null && 
            data.nowFace!.faceText.isNotEmpty && 
            data.nowFace!.faceUrl.isNotEmpty) {
          final nowFace = data.nowFace!;
          hasStatus.value = true;
          currentStatusId.value = nowFace.id;
          currentStatusText.value = nowFace.faceText;
          currentStatusEmoji.value = nowFace.faceUrl;
          statusExpireTime.value = nowFace.createDateTime;
          selectedExpireHours.value = nowFace.faceExpire; // 设置当前有效期
          topExpireHours.value = nowFace.faceExpire; // 同步到顶部有效期
          
          DebugUtil.info('✅ 当前状态: ${nowFace.faceText}, 有效期: ${nowFace.faceExpire}小时');
        } else {
          // 没有状态时，清空所有状态相关字段
          hasStatus.value = false;
          currentStatusId.value = 0;
          currentStatusText.value = '';
          currentStatusEmoji.value = '';
          statusExpireTime.value = null;
          selectedExpireHours.value = 1; // 重置为默认值
          topExpireHours.value = 1; // 重置为默认值
          DebugUtil.info('ℹ️ 当前没有设置状态');
        }
        
        // 缓存当前状态数据
        final statusData = CurrentStatusData(
          hasStatus: hasStatus.value,
          currentStatusId: currentStatusId.value,
          currentStatusText: currentStatusText.value,
          currentStatusEmoji: currentStatusEmoji.value,
          statusExpireTime: statusExpireTime.value,
          selectedExpireHours: selectedExpireHours.value,
          topExpireHours: topExpireHours.value,
        );
        await _cacheManager.cacheCurrentStatus(statusData);
        
        DebugUtil.info('✅ 从接口加载表情数据成功，共 ${emojiCategories.length} 个分类');
      } else {
        DebugUtil.warning('⚠️ 加载表情数据失败: ${result.msg}');
        OKToastUtil.showWarning(result.msg ?? '加载失败');
      }
    } catch (e) {
      DebugUtil.error('❌ 加载表情数据异常: $e');
      OKToastUtil.showError('加载数据异常');
    }
  }
  
  /// 当前选中的表情（用于底部弹窗）
  final selectedEmoji = Rx<EmojiItem?>(null);
  
  /// 选中的有效期（小时数）- 用于顶部状态区域显示
  final selectedExpireHours = 1.obs;
  
  /// 临时选择的有效期（小时数）- 用于底部弹窗，确认后才同步到 selectedExpireHours
  final tempExpireHours = 1.obs;
  
  /// 顶部有效期选择状态（独立于底部弹窗）
  final topExpireHours = 1.obs;
  
  /// 临时选中的表情（用于有状态时的临时选择）
  final tempSelectedEmoji = Rx<EmojiItem?>(null);

  /// 是否有临时状态（已选择新表情但未保存）
  final hasTempStatus = false.obs;
  
  /// 临时选中的有效期（用于有状态时的临时选择）
  final tempSelectedExpireHours = Rx<int?>(null);
  
  /// 原始状态（用于取消时恢复）
  final originalStatusEmoji = Rx<String?>(null);
  final originalStatusText = Rx<String?>(null);
  
  /// 选择表情
  /// - 新设置时：显示底部有效期选择弹窗
  /// - 编辑时：直接回显到顶部状态区域，点击保存按钮保存
  void selectEmoji(EmojiItem emoji) {
    DebugUtil.info('🎯 选择表情: ${emoji.name}, hasStatus: ${hasStatus.value}');
    
    if (hasStatus.value) {
      // 编辑模式：直接回显到顶部状态区域
      DebugUtil.info('✏️ 编辑模式：直接回显到顶部');
      
      // 保存原始状态（用于取消时恢复）
      if (!hasTempStatus.value) {
        originalStatusEmoji.value = currentStatusEmoji.value;
        originalStatusText.value = currentStatusText.value;
      }
      
      // 直接更新顶部状态显示
      currentStatusEmoji.value = emoji.emoji;
      currentStatusText.value = emoji.name;
      
      // 设置临时状态
      tempSelectedEmoji.value = emoji;
      tempSelectedExpireHours.value = topExpireHours.value;
      hasTempStatus.value = true;
      
      // 不显示底部弹窗（selectedEmoji保持为null）
    } else {
      // 新设置模式：显示底部弹窗选择有效期
      DebugUtil.info('🆕 新设置模式：显示底部弹窗');
      selectedEmoji.value = emoji;
      tempExpireHours.value = 1; // 默认1小时
    }
  }
  
  
  /// 确认设置状态 - 在底部弹窗点击确认时调用
  /// 新设置时不回显到顶部，只刷新父页面
  void confirmSetStatus() {
    if (selectedEmoji.value == null) return;

    selectedExpireHours.value = tempExpireHours.value;
    topExpireHours.value = tempExpireHours.value;
    _doSetStatus(isNewStatus: !hasStatus.value); // 如果当前无状态，则为新设置
  }
  
  /// 确认替换状态 - 在替换弹窗点击"确认"时调用
  void confirmReplace() {
    if (tempSelectedEmoji.value == null) return;
    
    // 使用临时保存的有效期
    if (tempSelectedExpireHours.value != null) {
      selectedExpireHours.value = tempSelectedExpireHours.value!;
      topExpireHours.value = tempSelectedExpireHours.value!; // 同步到顶部有效期
    }
    selectedEmoji.value = tempSelectedEmoji.value;
    
     
    
    _doSetStatus();
  }
  
  
  
  /// 取消替换状态
  void cancelReplace() {
    // 取消替换，保持当前临时状态，让保存按钮仍然可点击
    // 不清空临时状态，用户可以继续编辑或重新保存
    selectedEmoji.value = null; // 只关闭底部弹窗
  }
  
  /// 执行设置状态的实际操作（保存成功后返回定位页面并刷新）
  Future<void> _doSetStatus({bool isNewStatus = false, EmojiItem? emoji}) async {
    // 如果没有传入emoji，使用selectedEmoji
    final emojiToUse = emoji ?? selectedEmoji.value;
    if (emojiToUse == null) return;
    
    try {
      // 调用接口设置状态
      final result = await _api.setFaceStatus(
        faceId: emojiToUse.id,
        faceExpire: selectedExpireHours.value,
      );

      if (result.isSuccess) {
        if (!isNewStatus) {
          // 编辑模式：更新本地状态
          currentStatusId.value = emojiToUse.id;
          currentStatusEmoji.value = emojiToUse.emoji;
          currentStatusText.value = emojiToUse.name;
          hasStatus.value = true;
          statusExpireTime.value = DateTime.now().add(
            Duration(hours: selectedExpireHours.value)
          );

          // 更新缓存
          final statusData = CurrentStatusData(
            hasStatus: hasStatus.value,
            currentStatusId: currentStatusId.value,
            currentStatusText: currentStatusText.value,
            currentStatusEmoji: currentStatusEmoji.value,
            statusExpireTime: statusExpireTime.value,
            selectedExpireHours: selectedExpireHours.value,
            topExpireHours: topExpireHours.value,
          );
          await _cacheManager.cacheCurrentStatus(statusData);
        }

        DebugUtil.info('✅ 设置状态成功');
        OKToastUtil.show('状态已设置');

        // 返回定位页面并刷新数据
        _returnToLocationPageAndRefresh();
      } else {
        DebugUtil.warning('⚠️ 设置状态失败: ${result.msg}');
        OKToastUtil.showWarning(result.msg ?? '设置失败');
      }
    } catch (e) {
      DebugUtil.error('❌ 设置状态异常: $e');
      OKToastUtil.showError('设置状态异常');
    } finally {
      // 清空选中状态（关闭底部弹窗）
      selectedEmoji.value = null;
      // 清空临时状态
      tempSelectedEmoji.value = null;
      hasTempStatus.value = false;
    }
  }
  
  /// 取消设置状态
  void cancelSetStatus() {
    selectedEmoji.value = null;
  }
  
  /// 检查是否有未保存的更改
  bool get hasUnsavedChanges {
    return hasTempStatus.value || (hasStatus.value && topExpireHours.value != selectedExpireHours.value);
  }
  
  /// 返回时的确认处理
  void handleBack() {
    if (hasUnsavedChanges) {
      _showBackConfirmDialog();
    } else {
      Get.back();
    }
  }
  
  /// 显示返回确认弹窗的回调（由页面设置）
  Function()? onShowBackDialog;
  
  /// 显示返回确认弹窗
  void _showBackConfirmDialog() {
    onShowBackDialog?.call();
  }
  
  /// 确认返回（放弃临时状态）
  void confirmBack() {
    // 恢复原始状态显示
    if (originalStatusEmoji.value != null) {
      currentStatusEmoji.value = originalStatusEmoji.value!;
      currentStatusText.value = originalStatusText.value!;
    }
    // 清空临时状态
    tempSelectedEmoji.value = null;
    tempSelectedExpireHours.value = null;
    hasTempStatus.value = false;
    Get.back();
  }
  
  /// 取消返回（继续编辑）
  void cancelBack() {
    // 不做任何操作，继续停留在当前页面
  }
  
  /// 删除当前状态
  Future<void> deleteStatus() async {
    try {
    
      // 调用接口删除状态
      final result = await _api.deleteFaceStatus();
      
      if (result.isSuccess) {
        // 删除成功，清空本地状态
        hasStatus.value = false;
        currentStatusId.value = 0;
        currentStatusText.value = '';
        currentStatusEmoji.value = '';
        statusExpireTime.value = null;
        selectedExpireHours.value = 1;
        topExpireHours.value = 1;
        
        // 清空临时状态
        tempSelectedEmoji.value = null;
        tempSelectedExpireHours.value = null;
        hasTempStatus.value = false;
        originalStatusEmoji.value = null;
        originalStatusText.value = null;
        
        // 更新缓存（标记为无状态）
        final statusData = CurrentStatusData(
          hasStatus: false,
          currentStatusId: 0,
          currentStatusText: '',
          currentStatusEmoji: '',
          statusExpireTime: null,
          selectedExpireHours: 1,
          topExpireHours: 1,
        );
        await _cacheManager.cacheCurrentStatus(statusData);
        
        DebugUtil.info('✅ 删除状态成功');
        OKToastUtil.show('状态已删除');
        
        // 返回定位页面并刷新数据
        _returnToLocationPageAndRefresh();
      } else {
        DebugUtil.warning('⚠️ 删除状态失败: ${result.msg}');
        OKToastUtil.showWarning(result.msg ?? '删除失败');
      }
    } catch (e) {
      DebugUtil.error('❌ 删除状态异常: $e');
      OKToastUtil.showError('删除状态异常');
    }
  }
  
  /// 设置有效期（仅在已有状态时修改有效期）
  void setExpireTime(int hours) {
    if (!hasStatus.value) return;
    
    // 只更新顶部有效期，不调用接口，只激活保存按钮
    topExpireHours.value = hours;
    
    // 如果有临时状态，更新临时有效期
    if (hasTempStatus.value) {
      tempSelectedExpireHours.value = hours;
    }
  }
  
  /// 保存状态（公共方法）- 点击顶部保存按钮时调用
  /// 直接调用设置接口，不再弹出二次确认弹窗
  void saveStatus() {
    // 如果有临时状态，直接调用接口设置（编辑模式）
    if (hasTempStatus.value && tempSelectedEmoji.value != null) {
      selectedExpireHours.value = tempSelectedExpireHours.value ?? topExpireHours.value;
      topExpireHours.value = selectedExpireHours.value;
      // 直接传入emoji，不设置selectedEmoji，避免弹窗显示
      _doSetStatus(isNewStatus: false, emoji: tempSelectedEmoji.value);
    } else if (hasStatus.value && topExpireHours.value != selectedExpireHours.value) {
      // 只有有效期变化，使用设置状态接口更新
      _setStatusWithExpireOnly();
    } else {
      // 没有临时状态，直接返回
      Get.back();
    }
  }
  
  /// 只更新有效期（使用设置状态接口）
  Future<void> _setStatusWithExpireOnly() async {
    try {
      final result = await _api.setFaceStatus(
        faceId: currentStatusId.value,
        faceExpire: topExpireHours.value,
      );
      
      if (result.isSuccess) {
        selectedExpireHours.value = topExpireHours.value;
        statusExpireTime.value = DateTime.now().add(Duration(hours: topExpireHours.value));
        
        // 更新缓存
        final statusData = CurrentStatusData(
          hasStatus: hasStatus.value,
          currentStatusId: currentStatusId.value,
          currentStatusText: currentStatusText.value,
          currentStatusEmoji: currentStatusEmoji.value,
          statusExpireTime: statusExpireTime.value,
          selectedExpireHours: selectedExpireHours.value,
          topExpireHours: topExpireHours.value,
        );
        await _cacheManager.cacheCurrentStatus(statusData);
        
        DebugUtil.info('✅ 更新有效期成功');
        OKToastUtil.show('有效期已更新');
        
        // 返回定位页面并刷新数据
        _returnToLocationPageAndRefresh();
      } else {
        DebugUtil.warning('⚠️ 更新有效期失败: ${result.msg}');
        OKToastUtil.showWarning(result.msg ?? '更新失败');
      }
    } catch (e) {
      DebugUtil.error('❌ 更新有效期异常: $e');
      OKToastUtil.showError('更新有效期异常');
    }
  }
  
  /// 手动刷新数据（清除缓存后重新加载）
  Future<void> refreshData() async {
    try {
      // 清除所有缓存
      await _cacheManager.clearAllCache();
      DebugUtil.info('🗑️ 已清除所有缓存');
      
      // 重新加载数据
      await _loadFaceStatusWithCache();
      DebugUtil.info('🔄 数据刷新完成');
    } catch (e) {
      DebugUtil.error('❌ 刷新数据失败: $e');
      OKToastUtil.showError('刷新数据失败');
    }
  }
  
  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    return await _cacheManager.getCacheStats();
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
  
  /// 返回定位页面并刷新数据
  void _returnToLocationPageAndRefresh() {
    try {
      DebugUtil.info('🔄 表情设置保存成功，准备返回定位页面并刷新数据');
      
      // 返回到定位页面
      Get.back();
      
      // 刷新定位页面数据
      _refreshLocationPageData();
      
      DebugUtil.success('✅ 已返回定位页面并触发数据刷新');
    } catch (e) {
      DebugUtil.error('❌ 返回定位页面并刷新数据失败: $e');
      // 即使刷新失败，也要返回页面
      Get.back();
    }
  }
  
  /// 刷新定位页面数据
  void _refreshLocationPageData() {
    try {
      // 尝试获取定位页面控制器并刷新数据
      // 检查是否存在LocationV2Controller
      if (Get.isRegistered<LocationV2Controller>()) {
        final locationController = Get.find<LocationV2Controller>();
        locationController.refreshLocationData();
        DebugUtil.info('🔄 已触发LocationV2Controller数据刷新');
      } else {
        DebugUtil.warning('⚠️ 未找到定位页面控制器，无法刷新数据');
      }
    } catch (e) {
      DebugUtil.error('❌ 刷新定位页面数据异常: $e');
    }
  }
}


