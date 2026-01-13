import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/source_page_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissu_app/widgets/dialogs/dialog_manager.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog.dart';
import 'package:kissu_app/widgets/dialogs/custom_bottom_dialog_controller.dart';
import 'package:kissu_app/widgets/dialogs/vip_outtime_dialog.dart';
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
  
  HomePopupService({
    required this.isBound,
    required this.isVip,
    required this.showGuideOverlay,
    required this.currentGuideType,
    required this.isShowingDialog,
    required this.onRefreshAfterBinding,
    required this.getCachedVipData,
  });

  // ==================== 会话级别控制标志 ====================
  
  /// 绑定弹窗是否已在本次会话显示过
  static bool _hasShownBindingDialogThisSession = false;
  
  /// VIP购买弹窗是否已在本次会话显示过
  static bool _hasShownVipDialogThisSession = false;
  
  /// VIP到期弹窗是否已在本次会话检查过
  static bool _hasCheckedVipOuttimeDialogThisSession = false;

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
    debugPrint('🚀 启动弹窗流程...');
    
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
      if (isBound.value) {
        debugPrint('🔗 用户已绑定，不显示绑定弹窗');
        return;
      }

      if (_hasShownBindingDialogThisSession) {
        debugPrint('📱 本次会话已显示过绑定弹窗，不再显示');
        return;
      }

      debugPrint('💕 用户未绑定且本次会话未显示过绑定弹窗，准备显示绑定弹窗');

      Future.delayed(const Duration(milliseconds: 800), () {
        _showBindingDialog();
      });
      
    } catch (e) {
      debugPrint('❌ 检查绑定弹窗时发生错误: $e');
    }
  }

  /// 显示绑定弹窗
  void _showBindingDialog() {
    try {
      final currentContext = Get.context;
      if (currentContext == null) {
        debugPrint('❌ 无法获取Context，跳过显示绑定弹窗');
        return;
      }

      debugPrint('💑 显示绑定弹窗');
      
      // 标记弹窗正在显示，隐藏引导图
      _isShowingPopup.value = true;
      isShowingDialog.value = true;
      if (showGuideOverlay.value) {
        hideGuideOverlay();
        debugPrint('⚠️ 隐藏引导图，显示绑定弹窗');
      }
      
      // 标记本次会话已显示
      _hasShownBindingDialogThisSession = true;
      
      final dialogFuture = CustomBottomDialog.show(
        context: currentContext,
        caller: SourcePageUtilsCaller.home,
        onClose: () {
          debugPrint('💑 绑定弹窗已关闭');
        },
      );
      
      final timeoutFuture = Future.delayed(const Duration(seconds: 10), () {
        debugPrint('⚠️ 绑定弹窗显示超时，强制重置状态');
        _resetPopupState();
      });
      
      Future.any([dialogFuture, timeoutFuture]).then((result) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _resetPopupState();
        });
        
        debugPrint('💑 绑定弹窗已关闭，结果: $result');
        Future.delayed(const Duration(milliseconds: 300), () {
          onRefreshAfterBinding();
        });
      }).catchError((e) {
        _resetPopupState();
        debugPrint('❌ 绑定弹窗显示错误: $e');
      });
      
    } catch (e) {
      _resetPopupState();
      debugPrint('❌ 显示绑定弹窗时发生错误: $e');
    }
  }

  // ==================== VIP购买弹窗 ====================

  /// 检查并显示VIP购买弹窗
  Future<void> checkAndShowVipPurchaseDialog() async {
    try {
      if (!isBound.value) {
        debugPrint('💎 用户未绑定，不显示VIP购买弹窗');
        return;
      }

      if (UserManager.isVip) {
        debugPrint('💎 用户已是VIP会员，不显示VIP购买弹窗');
        return;
      }

      if (_hasShownVipDialogThisSession) {
        debugPrint('💎 本次会话已显示过VIP购买弹窗，不再显示');
        return;
      }

      debugPrint('💎 用户已绑定且非会员，本次会话未显示过VIP购买弹窗，准备显示');

      Future.delayed(const Duration(milliseconds: 800), () {
        _showVipPurchaseDialog();
      });
      
    } catch (e) {
      debugPrint('❌ 检查VIP购买弹窗时发生错误: $e');
    }
  }

  /// 显示VIP购买弹窗
  void _showVipPurchaseDialog() {
    try {
      final currentContext = Get.context;
      if (currentContext == null) {
        debugPrint('❌ 无法获取Context，跳过显示VIP购买弹窗');
        return;
      }

      debugPrint('💎 显示VIP购买弹窗');
      
      _isShowingPopup.value = true;
      isShowingDialog.value = true;
      if (showGuideOverlay.value) {
        hideGuideOverlay();
        debugPrint('⚠️ 隐藏引导图，显示VIP购买弹窗');
      }
      
      _hasShownVipDialogThisSession = true;
      
      final dialogFuture = DialogManager.showVipPurchase(
        context: currentContext,
        onConfirm: () {
          debugPrint('💎 点击了立即查看按钮，跳转到VIP页面，默认选中永久会员');
          _resetPopupState();
          Get.toNamed(
            KissuRoutePath.vip,
            arguments: {
                'defaultVipType': 4, // 永久会员 type = 4
              'source_page': SourcePageUtilsCaller.home,
            },
          );
        },
        barrierDismissible: true,
      );
      
      final timeoutFuture = Future.delayed(const Duration(seconds: 10), () {
        debugPrint('⚠️ VIP购买弹窗显示超时，强制重置状态');
        _resetPopupState();
      });
      
      Future.any([dialogFuture, timeoutFuture]).then((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _resetPopupState();
        });
        debugPrint('💎 VIP购买弹窗已关闭');
      }).catchError((e) {
        _resetPopupState();
        debugPrint('❌ VIP购买弹窗错误: $e');
      });
      
    } catch (e) {
      _resetPopupState();
      debugPrint('❌ 显示VIP购买弹窗时发生错误: $e');
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
      
      debugPrint('🔍 检查VIP推广标识: $shouldShow');
      
      if (shouldShow) {
        debugPrint('🎁 检测到需要显示VIP推广弹窗');
        
        await prefs.remove('should_show_vip_promo');
        debugPrint('🧹 VIP推广标识已清除（在显示弹窗前）');
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          final currentContext = Get.context;
          if (currentContext != null) {
            _isShowingPopup.value = true;
            isShowingDialog.value = true;
            if (showGuideOverlay.value) {
              hideGuideOverlay();
              debugPrint('⚠️ 隐藏引导图，显示VIP推广弹窗');
            }
            
            final dialogFuture = DialogManager.showHuaweiVipPromo(currentContext);
            final timeoutFuture = Future.delayed(const Duration(seconds: 10), () {
              debugPrint('⚠️ VIP推广弹窗显示超时，强制重置状态');
              _resetPopupState();
            });
            
            await Future.any([dialogFuture, timeoutFuture]);
            debugPrint('✅ VIP推广弹窗已显示并关闭');
            
            Future.delayed(const Duration(milliseconds: 300), () {
              _resetPopupState();
            });
          } else {
            _resetPopupState();
          }
        } catch (e) {
          _resetPopupState();
          debugPrint('❌ 显示VIP推广弹窗失败: $e');
        }
      } else {
        debugPrint('ℹ️ 无需显示VIP推广弹窗');
      }
    } catch (e) {
      _resetPopupState();
      debugPrint('❌ 检查VIP推广标识失败: $e');
    }
  }

  // ==================== VIP到期弹窗 ====================

  /// 检查VIP到期弹窗（整个会话期间只执行一次）
  void checkVipOuttimeDialogOnce() {
    if (_hasCheckedVipOuttimeDialogThisSession) {
      debugPrint('📱 VIP到期弹窗今天已检查过，跳过');
      return;
    }
    
    final vipData = getCachedVipData();
    if (vipData == null) {
      if (_vipOuttimeDialogCheckRetryCount >= _maxVipOuttimeDialogCheckRetries) {
        debugPrint('📱 VIP数据加载超时，放弃检查VIP到期弹窗');
        _hasCheckedVipOuttimeDialogThisSession = true;
        return;
      }
      _vipOuttimeDialogCheckRetryCount++;
      debugPrint('📱 VIP数据还未加载，延迟检查VIP到期弹窗 (重试 $_vipOuttimeDialogCheckRetryCount/$_maxVipOuttimeDialogCheckRetries)');
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
        debugPrint('📱 VIP到期弹窗今天已显示过，不再显示');
        return;
      }

      await prefs.setString('vip_outtime_dialog_last_show_date', today);
      debugPrint('✅ VIP到期弹窗已提前记录: $today');

      final context = Get.context;
      if (context == null) {
        debugPrint('⚠️ 无法获取上下文，延迟显示VIP到期弹窗');
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
            debugPrint('⚠️ VIP到期弹窗：无法获取上下文，已放弃显示');
          }
        });
        return;
      }

      await _showVipOuttimeDialog(context, vipData.expireDays);
    } catch (e) {
      debugPrint('❌ 检查VIP到期弹窗异常: $e');
    } finally {
      _vipOuttimeDialogRetryTimer?.cancel();
      _vipOuttimeDialogRetryTimer = null;
    }
  }

  /// 显示VIP到期弹窗
  Future<void> _showVipOuttimeDialog(BuildContext context, int expireDays) async {
    try {
      debugPrint('📱 显示VIP到期弹窗: expireDays=$expireDays');
      final result = await VipOuttimeDialog.show(
        context: context,
        expireDays: expireDays,
        onRenew: () {
          debugPrint('📱 用户点击立即续费，跳转到VIP页面');
          Get.toNamed(
            KissuRoutePath.vip,
            arguments: {
              'source_page': SourcePageUtilsCaller.home,
              },
          );
        },
        onLater: () {
          debugPrint('📱 用户点击下次再说');
        },
      );

      if (result != null) {
        debugPrint('✅ VIP到期弹窗用户操作完成');
      }
    } catch (e) {
      debugPrint('❌ 显示VIP到期弹窗异常: $e');
    }
  }

  // ==================== 引导图 ====================

  /// 检查并显示引导图1（新用户引导）
  Future<void> checkAndShowGuide1() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShownGuide1 = prefs.getBool('has_shown_guide1') ?? false;
      
      debugPrint('🔍 检查引导图1显示状态: $hasShownGuide1 (已绑定: ${isBound.value})');
      
      if (!hasShownGuide1) {
        debugPrint('📱 首次登录，显示引导图1');
        await prefs.setBool('has_shown_guide1', true);
        
        Future.delayed(const Duration(milliseconds: 500), () {
          _showGuide1();
        });
      } else {
        debugPrint('ℹ️ 引导图1已显示过，检查是否需要显示引导图2或VIP购买弹窗 (已绑定: ${isBound.value})');
        
        if (isBound.value) {
          checkAndShowGuide2();
        } else {
          debugPrint('ℹ️ 未绑定老用户，不显示引导图');
        }
      }
    } catch (e) {
      debugPrint('❌ 检查引导图1状态失败: $e');
    }
  }

  /// 显示引导图1
  void _showGuide1() {
    if (_isShowingPopup.value) {
      debugPrint('⚠️ 正在显示弹窗，延迟显示引导图1');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isShowingPopup.value) {
          currentGuideType.value = GuideType.swipe;
          showGuideOverlay.value = true;
          debugPrint('📱 弹窗已关闭，显示引导图1');
        }
      });
      return;
    }
    
    currentGuideType.value = GuideType.swipe;
    showGuideOverlay.value = true;
    debugPrint('📱 显示引导图1');
  }

  /// 引导图1关闭后的回调
  void onGuide1Dismissed() {
    debugPrint('📱 引导图1关闭回调被调用');
    // 🔥 修复：确保状态正确重置
    showGuideOverlay.value = false;
    _resetPopupState();
    debugPrint('📱 引导图1已关闭，检查是否需要显示引导图2 (已绑定: ${isBound.value})');
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (isBound.value && !_isShowingPopup.value) {
        checkAndShowGuide2();
      } else {
        if (_isShowingPopup.value) {
          debugPrint('⚠️ 正在显示弹窗，延迟显示引导图2');
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (isBound.value && !_isShowingPopup.value) {
              checkAndShowGuide2();
            }
          });
        } else {
          debugPrint('✅ 未绑定用户引导流程完成，引导图后不再弹出其他弹窗');
        }
      }
    });
  }

  /// 引导图2关闭后的回调
  void onGuide2Dismissed() {
    debugPrint('📱 引导图2关闭回调被调用');
    // 🔥 修复：确保状态正确重置
    showGuideOverlay.value = false;
    _resetPopupState();
    debugPrint('✅ 引导图2已关闭，引导流程完成，引导图后不再弹出其他弹窗');
  }

  /// 检查并显示引导图2（相恋时间设置引导）
  Future<void> checkAndShowGuide2() async {
    try {
      if (_isShowingPopup.value) {
        debugPrint('⚠️ 正在显示弹窗，延迟检查引导图2');
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!_isShowingPopup.value) {
            checkAndShowGuide2();
          }
        });
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final hasShownGuide2 = prefs.getBool('has_shown_guide2') ?? false;
      
      debugPrint('🔍 检查引导图2显示状态: $hasShownGuide2');
      
      if (!hasShownGuide2) {
        debugPrint('📱 显示引导图2（已绑定且第一次进入首页）');
        await prefs.setBool('has_shown_guide2', true);
        
        if (!_isShowingPopup.value) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!_isShowingPopup.value) {
              displayGuideOverlay();
            }
          });
        } else {
          debugPrint('⚠️ 弹窗正在显示，延迟显示引导图2');
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (!_isShowingPopup.value) {
              displayGuideOverlay();
            }
          });
        }
      } else {
        debugPrint('ℹ️ 引导图2已显示过，检查VIP购买弹窗');
        await checkAndShowVipPurchaseDialog();
      }
    } catch (e) {
      debugPrint('❌ 检查引导图2状态失败: $e');
    }
  }

  /// 显示引导层（引导图2使用）
  void displayGuideOverlay() {
    if (_isShowingPopup.value) {
      debugPrint('⚠️ 正在显示弹窗，延迟显示引导图');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isShowingPopup.value) {
          currentGuideType.value = GuideType.datingTime;
          showGuideOverlay.value = true;
          debugPrint('📱 弹窗已关闭，显示引导层');
        }
      });
      return;
    }
    
    currentGuideType.value = GuideType.datingTime;
    showGuideOverlay.value = true;
    debugPrint('📱 显示引导层');
  }

  /// 隐藏引导层
  void hideGuideOverlay() {
    debugPrint('📱 开始隐藏引导层...');
    showGuideOverlay.value = false;
    
    // 🔥 修复：立即重置弹窗状态，防止卡死
    // 不要延迟检查，直接重置状态
    if (_isShowingPopup.value) {
      debugPrint('⚠️ 引导层关闭时检测到弹窗状态为true，强制重置');
      _resetPopupState();
    }
    
    debugPrint('📱 引导层已隐藏');
  }

  /// 检查并显示引导层（调试模式：一直显示）
  Future<void> checkAndShowGuideDebug() async {
    try {
      debugPrint('🔍 调试模式：强制显示引导层');
      Future.delayed(const Duration(milliseconds: 1000), () {
        displayGuideOverlay();
        debugPrint('✅ 引导层已显示（调试模式）');
      });
    } catch (e) {
      debugPrint('❌ 显示引导层失败: $e');
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
