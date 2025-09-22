import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:logger/logger.dart';
import 'dart:io';

/// 支付服务类 - 使用 MethodChannel 直接与 Android 原生通信
class PaymentService extends GetxService {
  static PaymentService get to => Get.find();
  
  final Logger _logger = Logger();
  
  // MethodChannel 用于与 Android 原生代码通信
  static const MethodChannel _channel = MethodChannel('kissu_payment');
  
  // 支付状态
  final RxBool _isInitialized = false.obs;
  final RxBool _paymentInProgress = false.obs;
  
  bool get isInitialized => _isInitialized.value;
  bool get paymentInProgress => _paymentInProgress.value;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    // 🔒 隐私合规：不在服务初始化时自动启动支付SDK
    // 等待实际使用时再初始化
    // await _initializePayment(); // 移除自动初始化
    debugPrint('支付服务已注册（按需初始化）');
  }
  
  /// 初始化支付服务
  Future<void> _initializePayment() async {
    try {
      _logger.i('支付服务初始化中...');
      
      // 检查是否为 Android 平台
      if (!Platform.isAndroid) {
        _logger.w('当前平台不支持支付功能，仅支持 Android');
        _isInitialized.value = false;
        return;
      }
      
      // 初始化微信支付
      await _initWechatPay();
      
      _isInitialized.value = true;
      _logger.i('支付服务初始化成功（Android 平台）');
    } catch (e) {
      _logger.e('支付服务初始化失败: $e');
      _isInitialized.value = false;
    }
  }
  
  /// 初始化微信支付
  Future<void> _initWechatPay() async {
    try {
      await _channel.invokeMethod('initWechat', {
        'appId': 'wxca15128b8c388c13',
      });
      _logger.i('微信支付 SDK 初始化成功');
    } catch (e) {
      _logger.e('微信支付 SDK 初始化失败: $e');
    }
  }
  
  /// 微信支付
  Future<bool> payWithWechat({
    required String appId,
    required String partnerId,
    required String prepayId,
    required String packageValue,
    required String nonceStr,
    required String timeStamp,
    required String sign,
  }) async {
    try {
      // 检查平台和初始化状态
      if (!Platform.isAndroid) {
        _showError('当前平台不支持微信支付');
        return false;
      }
      
      // 按需初始化支付服务
      if (!_isInitialized.value) {
        _logger.i('支付服务未初始化，开始初始化...');
        await _initializePayment();
        if (!_isInitialized.value) {
          _showError('支付服务初始化失败，请重试');
          return false;
        }
      }
      
      if (_paymentInProgress.value) {
        _showError('支付正在进行中，请稍候');
        return false;
      }
      
      _logger.i('发起微信支付请求');
      _logPaymentParams('微信支付', {
        'appId': appId,
        'partnerId': partnerId,
        'prepayId': prepayId,
        'packageValue': packageValue,
        'nonceStr': nonceStr,
        'timeStamp': timeStamp,
      });
      
      // 检查微信是否已安装
      bool wechatInstalled = await isWechatInstalled();
      if (!wechatInstalled) {
        _showError('请先安装微信客户端');
        return false;
      }
      
      // 显示支付进度
      _showPaymentProgress('正在跳转微信支付...');
      _paymentInProgress.value = true;
      
      try {
        // 调用原生微信支付
        _logger.i('正在调用原生微信支付...');
        final result = await _channel.invokeMethod('payWithWechat', {
          'appId': appId,
          'partnerId': partnerId,
          'prepayId': prepayId,
          'packageValue': packageValue,
          'nonceStr': nonceStr,
          'timeStamp': timeStamp,
          'sign': sign,
        });
        
        _hideProgress();
        _paymentInProgress.value = false;
        
        _logger.i('微信支付原生调用完成，结果: $result');
        
        if (result != null && result['success'] == true) {
          _logger.i('微信支付成功');
          return true;
        } else {
          String errorMsg = result?['message'] ?? '微信支付失败';
          _logger.e('微信支付失败: $errorMsg');
          return false;
        }
        
      } catch (e) {
        _hideProgress();
        _paymentInProgress.value = false;
        _logger.e('微信支付调用异常: $e');
        return false;
      }
      
    } catch (e) {
      _hideProgress();
      _paymentInProgress.value = false;
      _logger.e('微信支付异常: $e');
      return false;
    }
  }
  
  /// 支付宝支付
  Future<bool> payWithAlipay({
    required String orderInfo,
  }) async {
    try {
      
      // 检查平台和初始化状态
      if (!Platform.isAndroid) {
        _showError('当前平台不支持支付宝支付');
        return false;
      }
      
      // 按需初始化支付服务
      if (!_isInitialized.value) {
        _logger.i('支付服务未初始化，开始初始化...');
        await _initializePayment();
        if (!_isInitialized.value) {
          _showError('支付服务初始化失败，请重试');
          return false;
        }
      }
      
      if (_paymentInProgress.value) {
        _showError('支付正在进行中，请稍候');
        return false;
      }
      
      
      // 检查支付宝是否已安装
      bool alipayInstalled = await isAlipayInstalled();
      
      if (!alipayInstalled) {
        _showError('请先安装支付宝客户端');
        return false;
      }
      
      // 显示支付进度
      _showPaymentProgress('正在跳转支付宝支付...');
      _paymentInProgress.value = true;
      
      try {
        // 调用原生支付宝支付
        _logger.i('正在调用原生支付宝支付...');
        final result = await _channel.invokeMethod('payWithAlipay', {
          'orderInfo': orderInfo,
        });
        
        _logger.i('支付宝支付调用完成，返回结果: $result');
        
        _hideProgress();
        _paymentInProgress.value = false;
        
        if (result != null && result['success'] == true) {
          _logger.i('支付宝支付成功');
          return true;
        } else {
          String errorMsg = result?['message'] ?? '支付宝支付失败';
          _logger.e('支付宝支付失败: $errorMsg, success: ${result?['success']}');
          return false;
        }
        
      } catch (e) {
        _hideProgress();
        _paymentInProgress.value = false;
        _logger.e('支付宝支付调用失败: $e');
        return false;
      }
      
    } catch (e) {
      _logger.e('支付宝支付异常: $e');
      _hideProgress();
      _paymentInProgress.value = false;
      return false;
    }
  }
  
  /// 检查微信是否已安装
  Future<bool> isWechatInstalled() async {
    if (!Platform.isAndroid) {
      return false;
    }
    
    // 确保支付服务已初始化
    if (!_isInitialized.value) {
      await _initializePayment();
    }
    
    try {
      final result = await _channel.invokeMethod('isWechatInstalled');
      _logger.d('微信安装检测结果: $result');
      return result == true;
    } catch (e) {
      _logger.e('检查微信安装状态失败: $e');
      return false;
    }
  }
  
  /// 检查支付宝是否已安装
  Future<bool> isAlipayInstalled() async {
    if (!Platform.isAndroid) {
      return false;
    }
    
    // 确保支付服务已初始化
    if (!_isInitialized.value) {
      await _initializePayment();
    }
    
    try {
      final result = await _channel.invokeMethod('isAlipayInstalled');
      _logger.d('支付宝安装检测结果: $result');
      return result == true;
    } catch (e) {
      _logger.e('检查支付宝安装状态失败: $e');
      return false;
    }
  }
  
  /// 显示支付进度对话框
  void _showPaymentProgress(String message) {
    Get.dialog(
      AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Flexible(child: Text(message)),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
  
  /// 隐藏进度对话框
  void _hideProgress() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }
  
  
  /// 显示错误消息
  void _showError(String message) {
    try {
      if (Get.context != null) {
        // CustomToast.show(
        //   Get.context!,
        //   message,
        // );
        OKToastUtil.show(message);
      } else {
        _logger.w('无法显示Toast: context为null');
        // 使用Get.snackbar作为fallback
        Get.snackbar(
          '支付失败',
          message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xffF44336),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      _logger.e('显示错误消息失败: $e');
    }
  }
  
  /// 记录支付参数（调试用）
  void _logPaymentParams(String paymentType, Map<String, dynamic> params) {
    _logger.i('$paymentType 参数:');
    params.forEach((key, value) {
      if (key != 'sign') { // 不记录敏感的签名信息
        _logger.i('  $key: $value');
      } else {
        _logger.i('  $key: ${value.toString().substring(0, 8)}...');
      }
    });
  }
  
  /// 获取支付方式可用性状态
  Future<Map<String, bool>> getPaymentAvailability() async {
    return {
      'wechat': await isWechatInstalled(),
      'alipay': await isAlipayInstalled(),
    };
  }
  
  /// 清理资源
  @override
  void onClose() {
    _paymentInProgress.value = false;
    _hideProgress();
    super.onClose();
  }
}