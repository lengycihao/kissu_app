import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> with WidgetsBindingObserver {
  MobileScannerController? controller;
  bool isHandling = false;
  bool hasPermission = false;
  bool isInitialized = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid && controller != null) {
      controller!.stop();
      controller!.start();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScanner();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 从设置页面返回时重新检查权限
      _checkPermissionAndRefresh();
    }
  }

  Future<void> _initializeScanner() async {
    await _checkPermissionAndRefresh();
  }

  Future<void> _checkPermissionAndRefresh() async {
    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      if (!hasPermission) {
        // 权限状态从无到有，需要重新初始化
        setState(() {
          hasPermission = true;
        });
        await _initializeController();
      }
    } else if (status.isDenied) {
      // 权限被拒绝，申请权限
      final result = await Permission.camera.request();
      if (result.isGranted) {
        setState(() {
          hasPermission = true;
        });
        await _initializeController();
      } else {
        setState(() {
          hasPermission = false;
        });
      }
    } else if (status.isPermanentlyDenied) {
      // 权限被永久拒绝，提示用户去设置
      setState(() {
        hasPermission = false;
      });
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _initializeController() async {
    if (controller != null) {
      await controller!.dispose();
    }
    
    controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
    );
    
    setState(() {
      isInitialized = true;
    });
  }

  void _showPermissionDeniedDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('需要相机权限'),
        content: const Text('扫码功能需要相机权限，请前往设置开启相机权限后再试。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('扫码绑定'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!hasPermission) {
      return _buildPermissionDeniedView();
    }

    if (!isInitialized || controller == null) {
      return _buildLoadingView();
    }

    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: controller!,
                onDetect: (capture) {
                  if (isHandling) return;
                  final barcodes = capture.barcodes;
                  if (barcodes.isEmpty) return;
                  final code = barcodes.first.rawValue ?? '';
                  if (code.isEmpty) return;
                  isHandling = true;
                  controller!.stop();
                  Get.back(result: code);
                },
              ),
              // 简单的扫描框样式
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFFF69B4), width: 3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              '将二维码对准扫描框即可自动识别',
              style: TextStyle(color: Colors.white.withOpacity(0.9)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            '需要相机权限',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '扫码功能需要访问相机\n请授予相机权限后重试',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _checkPermissionAndRefresh(),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFF69B4).withOpacity(0.2),
                  side: const BorderSide(color: Color(0xFFFF69B4)),
                ),
                child: const Text(
                  '重新授权',
                  style: TextStyle(color: Color(0xFFFF69B4)),
                ),
              ),
              const SizedBox(width: 20),
              TextButton(
                onPressed: () => openAppSettings(),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFF69B4),
                ),
                child: const Text(
                  '去设置',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFFFF69B4),
          ),
          const SizedBox(height: 20),
          Text(
            '初始化相机中...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // MobileScanner 直接在 onDetect 中处理

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }
}


