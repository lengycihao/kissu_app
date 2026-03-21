import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/source_page_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/widgets/dialogs/dialog_manager.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/services/analytics/analytics_events.dart';
import 'package:kissu_app/widgets/dialogs/vip_outtime_dialog.dart';
import 'package:kissu_app/widgets/dialogs/vip_expire_reminder_dialog.dart';
import 'package:kissu_app/widgets/guide_overlay_widget.dart';
import 'package:kissu_app/routers/kissu_route_path.dart';
import 'package:kissu_app/network/public/index_api.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:intl/intl.dart';
import 'dart:async';

/// 首页弹窗和引导图服务
/// 
/// 管理首页的弹窗和引导图显示逻辑，包括：
/// - 绑定弹窗（最高优先级）
/// - VIP购买弹窗
/// - VIP推广弹窗
/// - VIP到期弹窗
/// - 引导图1（新用户引导）
/// - 引导图2（相恋时间设置引导）
/// 
/// 优先级顺序：绑定弹窗 > VIP购买弹窗 > VIP推广弹窗 > 引导图
/// 
/// 竞态条件控制：
/// - isShowingPopup: 防止弹窗和引导图同时显示
/// - 会话级别标志位: 确保每种弹窗在会话期间只显示一次
class HomePopupService {
  /// 绑定状态
  final RxBool isBound;
  
  /// 会员状态
  final RxBool isVip;
  
  /// 引导层显示状态
  final RxBool showGuideOverlay;
  
  /// 当前引导图类型
  final Rx<GuideType> currentGuideType;
  
  /// 弹窗显示状态（与 controller 共享）
  final RxBool isShowingDialog;
  
  /// 绑定成功后的回调
  final VoidCallback onRefreshAfterBinding;
  
  /// 获取缓存的VIP数据
  final VipData? Function() getCachedVipData;
  
  /// 跳转到下一页前的回调（用于触发首页离开埋点）
  final VoidCallback? onNavigateToNextPage;
  
  HomePopupService({
    required this.isBound,
    required this.isVip,
    required this.showGuideOverlay,
    required this.currentGuideType,
    required this.isShowingDialog,
    required this.onRefreshAfterBinding,
    required this.getCachedVipData,
    this.onNavigateToNextPage,
  });

  // ==================== 会话级别控制标志 ====================
  
  /// 绑定弹窗是否已在本次会话显示过
  static bool _hasShownBindingDialogThisSession = false;
  
  /// VIP购买弹窗是否已在本次会话显示过
  static bool _hasShownVipDialogThisSession = false;
  
  /// VIP到期弹窗是否已在本次会话检查过
  static bool _hasCheckedVipOuttimeDialogThisSession = false;
  
  /// VIP过期提醒弹窗是否已在本次会话检查过
  static bool _hasCheckedVipExpireReminderDialogThisSession = false;

  // ==================== 实例级别状态 ====================
  
  /// 当前是否正在显示弹窗或引导图（防止同时显示）
  final RxBool _isShowingPopup = false.obs;
  bool get isShowingPopup => _isShowingPopup.value;
  
  /// VIP到期弹窗检查重试次数
  int _vipOuttimeDialogCheckRetryCount = 0;
  static const int _maxVipOuttimeDialogCheckRetries = 5;
  
  /// VIP到期弹窗重试定时器
  Timer? _vipOuttimeDialogRetryTimer;

  // ==================== 弹窗流程入口 ====================

  /// 启动弹窗流程（按优先级顺序检查并显示）
  /// 
  /// 优先级：绑定弹窗 > VIP购买弹窗 > VIP推广弹窗 > 引导图
  Future<void> startPopupFlow() async {
    // logDebug('🚀 启动弹窗流程...');
    
    // 1. 检查绑定弹窗（最高优先级）
    await checkAndShowBindingDialog();
    
    // 2. 绑定弹窗处理完成后，延迟检查VIP购买弹窗
    Future.delayed(const Duration(milliseconds: 500), () async {
      await checkAndShowVipPurchaseDialog();
      
      // 3. VIP购买弹窗处理完成后，延迟检查VIP推广弹窗
      Future.delayed(const Duration(milliseconds: 500), () async {
        await checkAndShowVipPromo();
        
        // 4. VIP推广弹窗处理完成后，延迟检查引导图（最低优先级）
        Future.delayed(const Duration(milliseconds: 500), () {
          checkAndShowGuide1();
        });
      });
    });
  }

  // ==================== 绑定弹窗 ====================

  /// 检查并显示绑定弹窗
  Future<void> checkAndShowBindingDialog() async {
    try {
      // logDebug('🔍 检查绑定弹窗条件: isBound=${isBound.value}, hasShown=$_hasShownBindingDialogThisSession');
      
      if (isBound.value) {
        // logDebug('🔗 用户已绑定，不显示绑定弹窗');
        return;
      }

      if (_hasShownBindingDialogThisSession) {
        // logDebug('📱 本次会话已显示过绑定弹窗，不再显示');
        return;
      }

      // logDebug('💕 用户未绑定且本次会话未显示过绑定弹窗，准备显示绑定弹窗');

      Future.delayed(const Duration(milliseconds: 800), () {
        // logDebug('⏰ 延迟800ms后，开始显示绑定弹窗');
        _showBindingDialog();
      });
      
    } catch (e) {
      logError('❌ 检查绑定弹窗时发生错误: $e');
    }
  }

  /// 显示绑定弹窗
  void _showBindingDialog() {
    try {
      final currentContext = Get.context;
      if (currentContext == null) {
        logWarning('❌ 无法获取Context，跳过显示绑定弹窗');
        return;
      }

      // 🔥 修复：显示弹窗前再次检查最新的绑定状态（避免使用过期的本地缓存数据）
      // 因为在延迟800ms期间，服务器可能已经返回了最新的用户信息
      final latestBindStatus = UserManager.currentUser?.bindStatus.toString() == "1";
      if (latestBindStatus) {
        // logDebug('🔗 延迟后再次检查：用户已绑定，取消显示绑定弹窗');
        isBound.value = true; // 同步更新绑定状态
        return;
      }

      // logDebug('💑 显示绑定弹窗');
      
      // 标记弹窗正在显示，隐藏引导图
      _isShowingPopup.value = true;
      isShowingDialog.value = true;
      if (showGuideOverlay.value) {
        hideGuideOverlay();
        // logDebug('⚠️ 隐藏引导图，显示绑定弹窗');
      }
      
      // 标记本次会话已显示
      _hasShownBindingDialogThisSession = true;
      
      final dialogFuture = CustomBottomDialog.show(
        context: currentContext,
        caller: SourcePageUtilsCaller.home,
        sourceEvent: HomeEvents.page, // 首页自动弹出，传首页页面事件ID
        onClose: () {
          // logDebug('💑 绑定弹窗已关闭');
        },
      );
      
      final timeoutFuture = Future.delayed(const Duration(seconds: 10), () {
        // logDebug('⚠️ 绑定弹窗显示超时，强制重置状态');
        _resetPopupState();
      });
      
      Future.any([dialogFuture, timeoutFuture]).then((result) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _resetPopupState();
        });
        
        // logDebug('💑 绑定弹窗已关闭，结果: $result');
        Future.delayed(const Duration(milliseconds: 300), () {
          onRefreshAfterBinding();
        });
      }).catchError((e) {
        _resetPopupState();
        logError('❌ 绑定弹窗显示错误: $e');
      });
      
    } catch (e) {
      _resetPopupState();
      logError('❌ 显示绑定弹窗时发生错误: $e');
    }
  }

  // ==================== VIP购买弹窗 ====================

  /// 检查并显示VIP购买弹窗
  Future<void> checkAndShowVipPurchaseDialog() async {
    try {
      if (!isBound.value) {
        // logDebug('💎 用户未绑定，不显示VIP购买弹窗');
        return;
      }

      if (UserManager.isVip) {
        // logDebug('💎 用户已是VIP会员，不显示VIP购买弹窗');
        return;
      }

      if (_hasShownVipDialogThisSession) {
        // logDebug('💎 本次会话已显示过VIP购买弹窗，不再显示');
        return;
      }

      // logDebug('💎 用户已绑定且非会员，本次会话未显示过VIP购买弹窗，准备显示');

      Future.delayed(const Duration(milliseconds: 800), () {
        _showVipPurchaseDialog();
      });
      
    } catch (e) {
      logError('❌ 检查VIP购买弹窗时发生错误: $e');
    }
  }

  /// 显示VIP购买弹窗
  void _showVipPurchaseDialog() {
    try {
      final currentContext = Get.context;
      if (currentContext == null) {
        logWarning('❌ 无法获取Context，跳过显示VIP购买弹窗');
        return;
      }

      // logDebug('💎 显示VIP购买弹窗');
      
      _isShowingPopup.value = true;
      isShowingDialog.value = true;
      if (showGuideOverlay.value) {
        hideGuideOverlay();
        // logDebug('⚠️ 隐藏引导图，显示VIP购买弹窗');
      }
      
      _hasShownVipDialogThisSession = true;
      
      final dialogFuture = DialogManager.showVipPurchase(
        context: currentContext,
        onConfirm: () {
          // logDebug('💎 点击了立即查看按钮，跳转到VIP页面，默认选中永久会员');
          _resetPopupState();
          
          // 埋点：首页离开（进入下一页）
          onNavigateToNextPage?.call();
          
          Get.toNamed(
            KissuRoutePath.vip,
            arguments: {
                'defaultVipType': 4, // 永久会员 type = 4
              'source_page': SourcePageUtilsCaller.home,
              'source_event': HomeEvents.vipRechargeDialog,
            },
          );
        },
        barrierDismissible: true,
      );
      
      final timeoutFuture = Future.delayed(const Duration(seconds: 10), () {
        // logDebug('⚠️ VIP购买弹窗显示超时，强制重置状态');
        _resetPopupState();
      });
      
      Future.any([dialogFuture, timeoutFuture]).then((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _resetPopupState();
        });
        // logDebug('💎 VIP购买弹窗已关闭');
      }).catchError((e) {
        _resetPopupState();
        logError('❌ VIP购买弹窗错误: $e');
      });
      
    } catch (e) {
      _resetPopupState();
      logError('❌ 显示VIP购买弹窗时发生错误: $e');
    }
  }

  /// 显示VIP开通弹窗（调试用）
  void showVipPurchaseDialogForDebug() {
    _showVipPurchaseDialog();
  }

  // ==================== VIP推广弹窗 ====================

  /// 检查并显示VIP推广弹窗
  Future<void> checkAndShowVipPromo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shouldShow = prefs.getBool('should_show_vip_promo') ?? false;
      
      // logDebug('🔍 检查VIP推广标识: $shouldShow');
      
      if (shouldShow) {
        // logDebug('🎁 检测到需要显示VIP推广弹窗');
        
        await prefs.remove('should_show_vip_promo');
        // logDebug('🧹 VIP推广标识已清除（在显示弹窗前）');
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          final currentContext = Get.context;
          if (currentContext != null) {
            _isShowingPopup.value = true;
            isShowingDialog.value = true;
            if (showGuideOverlay.value) {
              hideGuideOverlay();
              // logDebug('⚠️ 隐藏引导图，显示VIP推广弹窗');
            }
            
            final dialogFuture = DialogManager.showHuaweiVipPromo(currentContext);
            final timeoutFuture = Future.delayed(const Duration(seconds: 10), () {
              // logDebug('⚠️ VIP推广弹窗显示超时，强制重置状态');
              _resetPopupState();
            });
            
            await Future.any([dialogFuture, timeoutFuture]);
            // logDebug('✅ VIP推广弹窗已显示并关闭');
            
            Future.delayed(const Duration(milliseconds: 300), () {
              _resetPopupState();
            });
          } else {
            _resetPopupState();
          }
        } catch (e) {
          _resetPopupState();
          logError('❌ 显示VIP推广弹窗失败: $e');
        }
      } else {
        // logDebug('ℹ️ 无需显示VIP推广弹窗');
      }
    } catch (e) {
      _resetPopupState();
      logError('❌ 检查VIP推广标识失败: $e');
    }
  }

  // ==================== VIP到期弹窗 ====================

  /// 检查VIP到期弹窗（整个会话期间只执行一次）
  void checkVipOuttimeDialogOnce() {
    if (_hasCheckedVipOuttimeDialogThisSession) {
      // logDebug('📱 VIP到期弹窗今天已检查过，跳过');
      return;
    }
    
    final vipData = getCachedVipData();
    if (vipData == null) {
      if (_vipOuttimeDialogCheckRetryCount >= _maxVipOuttimeDialogCheckRetries) {
        // logDebug('📱 VIP数据加载超时，放弃检查VIP到期弹窗');
        _hasCheckedVipOuttimeDialogThisSession = true;
        return;
      }
      _vipOuttimeDialogCheckRetryCount++;
      // logDebug('📱 VIP数据还未加载，延迟检查VIP到期弹窗 (重试 $_vipOuttimeDialogCheckRetryCount/$_maxVipOuttimeDialogCheckRetries)');
      Future.delayed(const Duration(milliseconds: 1000), () {
        checkVipOuttimeDialogOnce();
      });
      return;
    }
    
    _hasCheckedVipOuttimeDialogThisSession = true;
    _checkAndShowVipOuttimeDialog(vipData);
  }

  /// 检查并显示VIP到期弹窗
  Future<void> _checkAndShowVipOuttimeDialog(VipData? vipData) async {
    try {
      
      if (vipData == null || vipData.type != 1) {
        return;
      }

      if (![1, 3, 7].contains(vipData.expireDays)) {
        return;
      }

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final lastShowDate = prefs.getString('vip_outtime_dialog_last_show_date');
      
      if (lastShowDate == today) {
        // logDebug('📱 VIP到期弹窗今天已显示过，不再显示');
        return;
      }

      await prefs.setString('vip_outtime_dialog_last_show_date', today);
      // logDebug('✅ VIP到期弹窗已提前记录: $today');

      final context = Get.context;
      if (context == null) {
        // logDebug('⚠️ 无法获取上下文，延迟显示VIP到期弹窗');
        _vipOuttimeDialogRetryTimer?.cancel();
        int retryCount = 0;
        _vipOuttimeDialogRetryTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
          retryCount++;
          final currentContext = Get.context;
          if (currentContext != null) {
            timer.cancel();
            _vipOuttimeDialogRetryTimer = null;
            _showVipOuttimeDialog(currentContext, vipData.expireDays);
          } else if (retryCount >= 6) {
            timer.cancel();
            _vipOuttimeDialogRetryTimer = null;
            logWarning('⚠️ VIP到期弹窗：无法获取上下文，已放弃显示');
          }
        });
        return;
      }

      await _showVipOuttimeDialog(context, vipData.expireDays);
    } catch (e) {
      logError('❌ 检查VIP到期弹窗异常: $e');
    } finally {
      _vipOuttimeDialogRetryTimer?.cancel();
      _vipOuttimeDialogRetryTimer = null;
    }
  }

  /// 显示VIP到期弹窗
  Future<void> _showVipOuttimeDialog(BuildContext context, int expireDays) async {
    try {
      // logDebug('📱 显示VIP到期弹窗: expireDays=$expireDays');
      final result = await VipOuttimeDialog.show(
        context: context,
        expireDays: expireDays,
        onRenew: () {
          // logDebug('📱 用户点击立即续费，跳转到VIP页面');
          Get.toNamed(
            KissuRoutePath.vip,
            arguments: {
              'source_page': SourcePageUtilsCaller.home,
              'source_event': HomeEvents.renewalReminderDialog,
              },
          );
        },
        onLater: () {
          // logDebug('📱 用户点击下次再说');
        },
      );

      if (result != null) {
        // logDebug('✅ VIP到期弹窗用户操作完成');
      }
    } catch (e) {
      logError('❌ 显示VIP到期弹窗异常: $e');
    }
  }

  // ==================== VIP过期提醒弹窗 ====================

  /// 检查VIP过期提醒弹窗（整个会话期间只执行一次）
  void checkVipExpireReminderDialogOnce() {
    
    if (_hasCheckedVipExpireReminderDialogThisSession) {
      // logDebug('📱 VIP过期提醒弹窗今天已检查过，跳过');
      return;
    }
    
    final vipData = getCachedVipData();
    if (vipData == null) {
      // logDebug('📱 VIP数据还未加载，跳过VIP过期提醒弹窗检查');
      return;
    }
    
    _hasCheckedVipExpireReminderDialogThisSession = true;
    _checkAndShowVipExpireReminderDialog(vipData);
  }

  /// 检查并显示VIP过期提醒弹窗
  Future<void> _checkAndShowVipExpireReminderDialog(VipData? vipData) async {
    try {
      // 只有当type=2时才显示
      if (vipData == null || vipData.type != 2) {
        return;
      }

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final lastShowDate = prefs.getString('vip_expire_reminder_dialog_last_show_date');
      
      if (lastShowDate == today) {
        // logDebug('📱 VIP过期提醒弹窗今天已显示过，不再显示');
        return;
      }

      await prefs.setString('vip_expire_reminder_dialog_last_show_date', today);
      // logDebug('✅ VIP过期提醒弹窗已提前记录: $today');

      final context = Get.context;
      if (context == null) {
        logWarning('⚠️ 无法获取上下文，跳过VIP过期提醒弹窗');
        return;
      }

      await _showVipExpireReminderDialog(context, vipData.desc, vipData.expireDays);
    } catch (e) {
      logError('❌ 检查VIP过期提醒弹窗异常: $e');
    }
  }

  /// 显示VIP过期提醒弹窗
  Future<void> _showVipExpireReminderDialog(BuildContext context, String desc, int expireDays) async {
    try {
      // logDebug('📱 显示VIP过期提醒弹窗: desc=$desc, expireDays=$expireDays');
      
      final result = await VipExpireReminderDialog.show(
        context: context,
        desc: desc,
        expireDays: expireDays,
        onRenewal: () {
          // logDebug('📱 用户点击立即续费，跳转到VIP页面');
          onNavigateToNextPage?.call();
          Get.toNamed(
            KissuRoutePath.vip,
            arguments: {
              'source_page': SourcePageUtilsCaller.home,
              'source_event': HomeEvents.expiryTipDialog,
            },
          );
        },
        onCancel: () {
          // logDebug('📱 用户点击下次再说');
        },
      );

      if (result != null) {
        // logDebug('✅ VIP过期提醒弹窗用户操作完成');
      }
    } catch (e) {
      logError('❌ 显示VIP过期提醒弹窗异常: $e');
    }
  }

  // ==================== 引导图 ====================

  /// 检查并显示引导图1（新用户引导）
  Future<void> checkAndShowGuide1() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShownGuide1 = prefs.getBool('has_shown_guide1') ?? false;
      
      // logDebug('🔍 检查引导图1显示状态: $hasShownGuide1 (已绑定: ${isBound.value})');
      
      if (!hasShownGuide1) {
        // logDebug('📱 首次登录，显示引导图1');
        await prefs.setBool('has_shown_guide1', true);
        
        Future.delayed(const Duration(milliseconds: 500), () {
          _showGuide1();
        });
      } else {
        // logDebug('ℹ️ 引导图1已显示过，检查是否需要显示引导图2或VIP购买弹窗 (已绑定: ${isBound.value})');
        
        if (isBound.value) {
          checkAndShowGuide2();
        } else {
          // logDebug('ℹ️ 未绑定老用户，不显示引导图');
        }
      }
    } catch (e) {
      logError('❌ 检查引导图1状态失败: $e');
    }
  }

  /// 显示引导图1
  void _showGuide1() {
    if (_isShowingPopup.value) {
      // logDebug('⚠️ 正在显示弹窗，延迟显示引导图1');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isShowingPopup.value) {
          currentGuideType.value = GuideType.swipe;
          showGuideOverlay.value = true;
          // logDebug('📱 弹窗已关闭，显示引导图1');
        }
      });
      return;
    }
    
    currentGuideType.value = GuideType.swipe;
    showGuideOverlay.value = true;
    // logDebug('📱 显示引导图1');
  }

  /// 引导图1关闭后的回调
  void onGuide1Dismissed() {
    // logDebug('📱 引导图1关闭回调被调用');
    // 🔥 修复：确保状态正确重置
    showGuideOverlay.value = false;
    _resetPopupState();
    // logDebug('📱 引导图1已关闭，检查是否需要显示引导图2 (已绑定: ${isBound.value})');
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (isBound.value && !_isShowingPopup.value) {
        checkAndShowGuide2();
      } else {
        if (_isShowingPopup.value) {
          // logDebug('⚠️ 正在显示弹窗，延迟显示引导图2');
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (isBound.value && !_isShowingPopup.value) {
              checkAndShowGuide2();
            }
          });
        } else {
          // logDebug('✅ 未绑定用户引导流程完成，引导图后不再弹出其他弹窗');
        }
      }
    });
  }

  /// 引导图2关闭后的回调
  void onGuide2Dismissed() {
    // logDebug('📱 引导图2关闭回调被调用');
    // 🔥 修复：确保状态正确重置
    showGuideOverlay.value = false;
    _resetPopupState();
    // logDebug('✅ 引导图2已关闭，引导流程完成，引导图后不再弹出其他弹窗');
  }

  /// 检查并显示引导图2（相恋时间设置引导）
  Future<void> checkAndShowGuide2() async {
    try {
      if (_isShowingPopup.value) {
        // logDebug('⚠️ 正在显示弹窗，延迟检查引导图2');
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!_isShowingPopup.value) {
            checkAndShowGuide2();
          }
        });
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final hasShownGuide2 = prefs.getBool('has_shown_guide2') ?? false;
      
      // logDebug('🔍 检查引导图2显示状态: $hasShownGuide2');
      
      if (!hasShownGuide2) {
        // logDebug('📱 显示引导图2（已绑定且第一次进入首页）');
        await prefs.setBool('has_shown_guide2', true);
        
        if (!_isShowingPopup.value) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!_isShowingPopup.value) {
              displayGuideOverlay();
            }
          });
        } else {
          // logDebug('⚠️ 弹窗正在显示，延迟显示引导图2');
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (!_isShowingPopup.value) {
              displayGuideOverlay();
            }
          });
        }
      } else {
        // logDebug('ℹ️ 引导图2已显示过，检查VIP购买弹窗');
        await checkAndShowVipPurchaseDialog();
      }
    } catch (e) {
      logError('❌ 检查引导图2状态失败: $e');
    }
  }

  /// 显示引导层（引导图2使用）
  void displayGuideOverlay() {
    if (_isShowingPopup.value) {
      // logDebug('⚠️ 正在显示弹窗，延迟显示引导图');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isShowingPopup.value) {
          currentGuideType.value = GuideType.datingTime;
          showGuideOverlay.value = true;
          // logDebug('📱 弹窗已关闭，显示引导层');
        }
      });
      return;
    }
    
    currentGuideType.value = GuideType.datingTime;
    showGuideOverlay.value = true;
    // logDebug('📱 显示引导层');
  }

  /// 隐藏引导层
  void hideGuideOverlay() {
    // logDebug('📱 开始隐藏引导层...');
    showGuideOverlay.value = false;
    
    // 🔥 修复：立即重置弹窗状态，防止卡死
    // 不要延迟检查，直接重置状态
    if (_isShowingPopup.value) {
      // logDebug('⚠️ 引导层关闭时检测到弹窗状态为true，强制重置');
      _resetPopupState();
    }
    
    // logDebug('📱 引导层已隐藏');
  }

  /// 检查并显示引导层（调试模式：一直显示）
  Future<void> checkAndShowGuideDebug() async {
    try {
      // logDebug('🔍 调试模式：强制显示引导层');
      Future.delayed(const Duration(milliseconds: 1000), () {
        displayGuideOverlay();
        // logDebug('✅ 引导层已显示（调试模式）');
      });
    } catch (e) {
      logError('❌ 显示引导层失败: $e');
    }
  }

  // ==================== 辅助方法 ====================

  /// 重置弹窗状态
  void _resetPopupState() {
    _isShowingPopup.value = false;
    isShowingDialog.value = false;
  }

  /// 重置会话标志（用于测试或重新登录）
  static void resetSessionFlags() {
    _hasShownBindingDialogThisSession = false;
    _hasShownVipDialogThisSession = false;
    _hasCheckedVipOuttimeDialogThisSession = false;
  }

  /// 获取绑定弹窗会话标志
  static bool get hasShownBindingDialogThisSession => _hasShownBindingDialogThisSession;
  
  /// 获取VIP弹窗会话标志
  static bool get hasShownVipDialogThisSession => _hasShownVipDialogThisSession;

  /// 清理资源
  void dispose() {
    _vipOuttimeDialogRetryTimer?.cancel();
    _vipOuttimeDialogRetryTimer = null;
  }
}
