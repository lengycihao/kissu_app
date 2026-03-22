import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kissu_app/network/tools/logging/log_manager.dart';
import 'package:kissu_app/utils/oktoast_util.dart';
import 'package:kissu_app/utils/user_manager.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'dart:async';
import 'package:fluwx/fluwx.dart';
import 'package:kissu_app/constants/app_constants.dart';

/// 支付服务类 - 使用 fluwx 处理微信支付，MethodChannel 处理支付宝支付
class PaymentService extends GetxService {
  static PaymentService get to => Get.find();

  final Logger _logger = Logger();

  // MethodChannel 用于支付宝支付
  static const MethodChannel _channel = MethodChannel('kissu_payment');

  // fluwx 实例用于微信支付
  final Fluwx _fluwx = Fluwx();

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
    logger.debug('支付服务已注册（按需初始化）');

    // 监听应用生命周期
    _setupAppLifecycleListener();

    // 设置 fluwx 微信支付回调监听
    _setupFluwxCallbackHandler();

    // 设置支付宝支付回调处理器
    _setupAlipayCallbackHandler();
  }

  /// 设置应用生命周期监听
  void _setupAppLifecycleListener() {
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
  }

  // fluwx 回调监听器
  FluwxCancelable? _fluwxCancelable;

  /// 设置 fluwx 微信支付回调监听
  void _setupFluwxCallbackHandler() {
    _fluwxCancelable = _fluwx.addSubscriber((response) {
      logger.debug(
        '📱 收到 fluwx 微信支付回调: ${response.isSuccessful}, errCode: ${response.errCode}',
      );
      if (response is WeChatPaymentResponse) {
        _handleFluwxWechatResponse(response);
      }
    });

    logger.debug('✅ fluwx 微信支付回调监听器已设置');
  }

  /// 设置支付宝支付回调处理器
  void _setupAlipayCallbackHandler() {
    _channel.setMethodCallHandler((call) async {
      logger.debug('📱 收到原生回调: ${call.method}, 参数: ${call.arguments}');

      switch (call.method) {
        case 'onAlipayResponse':
          _handleAlipayResponse(call.arguments);
          break;
        default:
          logger.warning('未知的原生回调方法: ${call.method}');
      }
    });

    logger.debug('✅ 支付宝支付回调处理器已设置');
  }

  /// 处理通用支付结果
  void _handlePaymentResult(dynamic arguments) {
    try {
      final Map<String, dynamic> result = Map<String, dynamic>.from(arguments);
      logger.debug('💰 处理支付结果: $result');

      // 通知所有监听者
      _paymentResultController.add(result);

      // 处理支付结果
      final success = result['success'] ?? false;
      final message = result['message'] ?? '';
      final payType = result['payType'] ?? '';

      if (success) {
        logger.debug('✅ 支付成功 - 类型: $payType');
        _onPaymentSuccess(payType);
      } else {
        logger.warning('❌ 支付失败 - 类型: $payType, 原因: $message');
        _onPaymentFailed(message);
      }
    } catch (e) {
      logger.error('处理支付结果时出错: $e');
    }
  }

  /// 处理 fluwx 微信支付响应
  void _handleFluwxWechatResponse(WeChatPaymentResponse response) {
    try {
      _logger.i(
        '🔵 fluwx 微信支付响应: isSuccessful=${response.isSuccessful}, errCode=${response.errCode}, errStr=${response.errStr}',
      );

      Map<String, dynamic> result = {
        'payType': 'wechat',
        'errCode': response.errCode,
        'errStr': response.errStr ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // 根据错误码判断支付结果
      if (response.isSuccessful || response.errCode == 0) {
        result['success'] = true;
        result['message'] = '支付成功';
      } else if (response.errCode == -2) {
        result['success'] = false;
        result['message'] = '用户取消支付';
      } else {
        result['success'] = false;
        result['message'] = (response.errStr?.isNotEmpty ?? false)
            ? response.errStr!
            : '支付失败';
      }

      _handlePaymentResult(result);
    } catch (e) {
      logger.error('处理 fluwx 微信支付响应时出错: $e');
    }
  }

  /// 处理支付宝响应
  void _handleAlipayResponse(dynamic arguments) {
    try {
      final Map<String, dynamic> response = Map<String, dynamic>.from(
        arguments,
      );
      logger.debug('🟦 支付宝响应: $response');

      final resultStatus = response['resultStatus'] ?? '';
      final result = response['result'] ?? '';
      final memo = response['memo'] ?? '';

      Map<String, dynamic> payResult = {
        'payType': 'alipay',
        'resultStatus': resultStatus,
        'result': result,
        'memo': memo,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // 根据状态码判断支付结果
      if (resultStatus == '9000') {
        payResult['success'] = true;
        payResult['message'] = '支付成功';
      } else if (resultStatus == '6001') {
        payResult['success'] = false;
        payResult['message'] = '用户取消支付';
      } else {
        payResult['success'] = false;
        payResult['message'] = memo.isNotEmpty ? memo : '支付失败';
      }

      _handlePaymentResult(payResult);
    } catch (e) {
      logger.error('处理支付宝响应时出错: $e');
    }
  }

  /// 支付成功处理
  void _onPaymentSuccess(String payType) {
    // 隐藏进度
    _hideProgress();

    // 重置支付状态
    _paymentInProgress.value = false;

    // 通知原生取消超时定时器
    _cancelNativePaymentTimeout();

    // 触发VIP状态变化回调
    if (_onVipStatusChanged != null) {
      logger.debug('📢 触发VIP状态变化回调（支付成功）');
      _onVipStatusChanged!(true);
      _onVipStatusChanged = null;
    }

    // 刷新用户信息
    UserManager.refreshUserInfo().then((success) {
      if (success) {
        logger.debug('✅ 用户信息已刷新');
      }
    });
  }

  /// 支付失败处理
  void _onPaymentFailed(String message) {
    // 隐藏进度
    _hideProgress();

    // 重置支付状态
    _paymentInProgress.value = false;

    // 显示错误信息
    _showError(message);

    // 触发VIP状态变化回调
    if (_onVipStatusChanged != null) {
      logger.debug('📢 触发VIP状态变化回调（支付失败）');
      _onVipStatusChanged!(false);
      _onVipStatusChanged = null;
    }
  }

  // VIP状态变化回调（保留用于兼容）
  Function(bool)? _onVipStatusChanged;

  // 应用后台时间记录（用于判断用户是否真的从微信支付返回）
  int _backgroundTimestamp = 0;

  // 支付结果流控制器
  final StreamController<Map<String, dynamic>> _paymentResultController =
      StreamController<Map<String, dynamic>>.broadcast();

  // 获取支付结果流
  Stream<Map<String, dynamic>> get paymentResultStream =>
      _paymentResultController.stream;

  // 支付结果监听器
  StreamSubscription<Map<String, dynamic>>? listenToPaymentResult(
    void Function(Map<String, dynamic> result) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return paymentResultStream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
    );
  }

  /// 初始化支付服务
  Future<void> _initializePayment() async {
    try {
      logger.debug('支付服务初始化中...');

      // 检查是否为 Android 平台
      if (!Platform.isAndroid) {
        logger.debug('当前平台不支持支付功能，仅支持 Android');
        _isInitialized.value = false;
        return;
      }

      // 初始化原生微信支付
      await _initWechatPay();

      _isInitialized.value = true;
      logger.debug('支付服务初始化成功（Android 平台）');
    } catch (e) {
      logger.error('支付服务初始化失败: $e');
      _isInitialized.value = false;
    }
  }

  /// 初始化微信支付（使用 fluwx）
  Future<void> _initWechatPay() async {
    try {
      // 使用 fluwx 注册微信 API
      final registered = await _fluwx.registerApi(
        appId: AppConstants.weChatAppId,
        doOnAndroid: true,
        doOnIOS: false,
      );

      if (registered) {
       logger.debug('✅ fluwx 微信支付 SDK 初始化成功');
      } else {
        logger.error('❌ fluwx 微信支付 SDK 初始化失败');
        throw Exception('微信支付 SDK 初始化失败');
      }
    } catch (e) {
      logger.error('微信支付 SDK 初始化失败: $e');
      rethrow;
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
    Function(bool)? onVipStatusChanged, // 新增：VIP状态变化回调
  }) async {
    Timer? timeoutTimer;

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
        logger.debug('检测到支付状态异常，强制重置并继续');
        _forceResetPaymentState();
      }

     logger.debug('发起微信支付请求');
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

      // 保存VIP状态变化回调
      _onVipStatusChanged = onVipStatusChanged;

      // 显示支付进度
      _showPaymentProgress('正在跳转微信支付...');
      _paymentInProgress.value = true;

      // 设置支付超时机制 - 60秒超时
      timeoutTimer = Timer(const Duration(seconds: 60), () {
        if (_paymentInProgress.value) {
          logger.debug('微信支付超时（60秒）');
          _resetPaymentState();
          _showError('支付超时，请重试');
        }
      });

      try {
        // 使用 fluwx 调用微信支付
        logger.debug('正在使用 fluwx 调用微信支付...');

        // 将 timeStamp 从 String 转换为 int
        final timestampInt = int.tryParse(timeStamp) ?? 0;

        // 使用 Payment 对象调用支付
        final result = await _fluwx.pay(
          which: Payment(
            appId: appId,
            partnerId: partnerId,
            prepayId: prepayId,
            packageValue: packageValue,
            nonceStr: nonceStr,
            timestamp: timestampInt,
            sign: sign,
          ),
        );

        logger.debug('fluwx 微信支付调用返回: $result');

        if (result) {
          // 成功唤起微信支付，等待用户操作
          logger.debug('✅ 成功唤起微信支付，等待支付结果回调...');
          // 注意：不要在这里返回结果，也不要隐藏进度
          // 实际支付结果通过 _handleFluwxWechatResponse 回调处理
          // 这里不返回，让方法继续等待（实际上方法会结束，但状态保持）
        } else {
          // fluwx 返回失败（如：微信未安装、版本过低等）
          logger.error('❌ fluwx 调用失败');
          timeoutTimer.cancel();
          _hideProgress();
          _paymentInProgress.value = false;
          _showError('支付失败，请检查微信是否已安装');
          return false;
        }
        
        // 成功唤起微信后，不返回任何值，让方法自然结束
        // 支付结果将通过回调异步处理
        return true; // 仅表示成功唤起，不表示支付成功
      } catch (e) {
        timeoutTimer.cancel();
        logger.error('微信支付调用异常: $e');
        _hideProgress();
        _paymentInProgress.value = false;
        _showError('支付调用失败: $e');
        return false;
      }
    } catch (e) {
      timeoutTimer?.cancel();
      logger.error('微信支付异常: $e');
      _hideProgress();
      _paymentInProgress.value = false;
      return false;
    }
  }

  /// 支付宝支付
  Future<bool> payWithAlipay({required String orderInfo}) async {
    try {
      logger.debug('开始支付宝支付流程，orderInfo长度: ${orderInfo.length}');

      // 检查平台和初始化状态
      if (!Platform.isAndroid) {
        // logger.debug('当前平台不支持支付宝支付，当前平台: ${Platform.operatingSystem}');
        _showError('当前平台不支持支付宝支付');
        return false;
      }

      // 按需初始化支付服务
      if (!_isInitialized.value) {
        logger.debug('支付服务未初始化，开始初始化...');
        await _initializePayment();
        if (!_isInitialized.value) {
          logger.warning('支付服务初始化失败');
          _showError('支付服务初始化失败，请重试');
          return false;
        }
      }

      if (_paymentInProgress.value) {
        logger.warning('检测到支付状态异常，强制重置并继续');
        _forceResetPaymentState();
      }

      // 检查订单信息
      if (orderInfo.isEmpty) {
        logger.warning('支付宝订单信息为空');
        _showError('订单信息错误，请重试');
        return false;
      }

      // 检查支付宝是否已安装
      // logger.debug('检查支付宝安装状态...');
      bool alipayInstalled = await isAlipayInstalled();
      // logger.debug('支付宝安装状态: $alipayInstalled');

      if (!alipayInstalled) {
        logger.warning('支付宝未安装');
        _showError('请先安装支付宝客户端');
        return false;
      }

      // 显示支付进度
      _showPaymentProgress('正在跳转支付宝支付...');
      _paymentInProgress.value = true;

      try {
        // 调用原生支付宝支付
      //  logger.debug(
      //     '正在调用原生支付宝支付，orderInfo前100字符: ${orderInfo.substring(0, orderInfo.length > 100 ? 100 : orderInfo.length)}...',
      //   );
        final result = await _channel.invokeMethod('payWithAlipay', {
          'orderInfo': orderInfo,
        });

        // logger.debug('支付宝支付调用完成，返回结果类型: ${result.runtimeType}');
        // logger.debug('支付宝支付返回结果: $result');

        // 注意：不要在这里隐藏进度和重置状态，让 _onPaymentSuccess/_onPaymentFailed 处理

        if (result != null && result is Map) {
          final success = result['success'];
          final message = result['message'] ?? '未知错误';
          final resultData = result['result'];

         logger.debug('支付宝支付结果解析: success=$success, message=$message');
          if (resultData != null) {
            logger.debug('支付宝支付详细结果: $resultData');
          }

          if (success == true) {
            logger.debug('支付宝支付成功');
            // 触发支付成功处理（会隐藏进度、重置状态、刷新用户信息）
            _onPaymentSuccess('alipay');
            return true;
          } else {
            logger.error('支付宝支付失败: $message');
            // 触发支付失败处理（会隐藏进度、重置状态、显示错误）
            _onPaymentFailed(message);
            return false;
          }
        } else {
          logger.error('支付宝支付返回结果格式错误: $result');
          _onPaymentFailed('返回结果格式错误');
          return false;
        }
      } catch (e) {
        _hideProgress();
        _paymentInProgress.value = false;
       logger.error('支付宝支付调用失败: $e');
        _showError('支付调用失败: $e');
        return false;
      }
    } catch (e) {
      logger.error('支付宝支付异常: $e');
      _hideProgress();
      _paymentInProgress.value = false;
      _showError('支付异常: $e');
      return false;
    }
  }

  /// 检查微信是否已安装（使用 fluwx）
  Future<bool> isWechatInstalled() async {
    if (!Platform.isAndroid) {
      return false;
    }

    // 确保支付服务已初始化
    if (!_isInitialized.value) {
      await _initializePayment();
    }

    try {
      // 使用原生方法检查微信是否安装
      final result = await _channel.invokeMethod('isWechatInstalled');
      logger.debug('微信安装检测结果: $result');
      return result == true;
    } catch (e) {
      logger.error('检查微信安装状态失败: $e');
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
      logger.debug('支付宝安装检测结果: $result');
      return result == true;
    } catch (e) {
      logger.error('检查支付宝安装状态失败: $e');
      return false;
    }
  }

  /// 显示支付进度对话框
  void _showPaymentProgress(String message) {
    Get.dialog(
      Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 60),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
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
        logger.debug('无法显示Toast: context为null');
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
      logger.error('显示错误消息失败: $e');
    }
  }

  /// 记录支付参数（调试用）
  void _logPaymentParams(String paymentType, Map<String, dynamic> params) {
    logger.debug('$paymentType 参数:');
    params.forEach((key, value) {
      if (key != 'sign') {
        // 不记录敏感的签名信息
       logger.debug('  $key: $value');
      } else {
        logger.debug('  $key: ${value.toString().substring(0, 8)}...');
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

  /// 重置支付状态
  void _resetPaymentState() {
    logger.debug('重置支付状态');
    _paymentInProgress.value = false;
    try {
      _hideProgress();
    } catch (e) {
      logger.error('重置支付状态时隐藏进度失败: $e');
    }
  }

  /// 强制重置支付状态（用于异常情况）
  void forceResetPaymentState() {
   logger.debug('强制重置支付状态');
    _resetPaymentState();
  }

  /// 强制重置支付状态（内部方法，更彻底的重置）
  void _forceResetPaymentState() {
    logger.debug('强制重置支付状态（内部方法）');
    _paymentInProgress.value = false;
    try {
      _hideProgress();
    } catch (e) {
      logger.error('强制重置时隐藏进度失败: $e');
    }
    // 确保状态完全重置
    Future.delayed(const Duration(milliseconds: 100), () {
      _paymentInProgress.value = false;
    });
  }

  /// 检查并重置异常支付状态
  void checkAndResetPaymentState() {
    if (_paymentInProgress.value) {
      logger.warning('检测到异常支付状态，自动重置');
      _resetPaymentState();
    }
  }

  /// 彻底检查并重置支付状态（用于支付前检查）
  void thoroughCheckAndResetPaymentState() {
    logger.debug('开始彻底检查支付状态...');
    logger.debug('当前支付状态: ${_paymentInProgress.value}');

    if (_paymentInProgress.value) {
      logger.warning('检测到异常支付状态，执行彻底重置');
      _forceResetPaymentState();

      // 延迟再次检查，确保状态完全重置
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_paymentInProgress.value) {
          logger.warning('延迟检查发现状态仍未重置，再次强制重置');
          _forceResetPaymentState();
        }
      });
    }

    logger.debug('支付状态检查完成，当前状态: ${_paymentInProgress.value}');
  }

  /// 立即检查是否收到了支付取消的通知
  void _checkForImmediatePaymentCancellation() {
    logger.debug('🔍 立即检查支付取消状态...');

    // 检查是否从后台回来的时间过短（可能用户直接取消了支付）
    if (_backgroundTimestamp > 0) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeDiff = currentTime - _backgroundTimestamp;

     logger.debug('从后台到前台的时间差: ${timeDiff}ms');

      // 如果时间差小于3秒，很可能是用户直接取消了支付
      if (timeDiff < 3000) {
        logger.warning('⚡ 检测到快速返回（${timeDiff}ms < 3000ms），可能是用户取消支付');

        // 延迟1秒后检查，给微信回调一点时间
        Future.delayed(const Duration(seconds: 1), () {
          if (_paymentInProgress.value) {
            logger.debug('快速返回且1秒后仍在支付中，判断为用户取消支付');
            _resetPaymentState();
            _showError('支付已取消');
          }
        });
      }

      // 重置后台时间戳
      _backgroundTimestamp = 0;
    }
  }

  /// 🔧 通知原生取消支付超时定时器（仅用于支付宝）
  Future<void> _cancelNativePaymentTimeout() async {
    try {
      logger.debug('🔔 通知原生层取消支付超时定时器（仅支付宝）');
      await _channel.invokeMethod('cancelPaymentTimeout');
      logger.debug('✅ 已成功通知原生层取消超时');
    } catch (e) {
      logger.error('⚠️ 通知原生层取消超时失败（可能不支持此方法）: $e');
      // 不抛出异常，因为这不是关键操作
    }
  }

  /// 清理资源
  @override
  void onClose() {
    _paymentInProgress.value = false;
    _hideProgress();
    _paymentResultController.close();
    super.onClose();
  }
}

/// 应用生命周期观察者
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final PaymentService _paymentService;

  _AppLifecycleObserver(this._paymentService);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paymentService._logger.i('应用生命周期变化: $state');

    if (state == AppLifecycleState.resumed) {
      // 应用回到前台时，检查支付状态
      _paymentService._logger.i(
        '应用回到前台，检查支付状态: ${_paymentService._paymentInProgress.value}',
      );

      if (_paymentService._paymentInProgress.value) {
        // 🚀 用户从支付应用返回
        _paymentService._logger.i('💰 用户从支付应用返回，等待支付结果回调...');

        // 检查是否快速返回（可能是用户取消）
        _paymentService._checkForImmediatePaymentCancellation();

        // 优化：给一定时间等待原生回调
        _paymentService._logger.i('检测到支付进行中，等待原生支付结果回调');

        // 设置一个合理的等待时间，如果超时仍未收到回调，则重置状态
        Future.delayed(const Duration(seconds: 10), () {
          if (_paymentService._paymentInProgress.value) {
            _paymentService._logger.w('10秒后仍未收到支付回调，可能支付已取消');
            _paymentService._resetPaymentState();
            _paymentService._showError('支付超时或已取消');
          } else {
            _paymentService._logger.i('支付状态已正常结束');
          }
        });
      }
    }

    // 当应用进入后台时，记录时间戳
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_paymentService._paymentInProgress.value) {
        _paymentService._backgroundTimestamp =
            DateTime.now().millisecondsSinceEpoch;
        _paymentService._logger.i(
          '应用进入后台，支付进行中，记录时间戳: ${_paymentService._backgroundTimestamp}',
        );
      }
    }
  }
}
