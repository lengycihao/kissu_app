import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'anti_spy_controller.dart';
import 'widgets/radar_selector.dart';

class AntiSpyPage extends GetView<AntiSpyController> {
  const AntiSpyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF8F9FA),
                    Color(0xFFE9ECEF),
                  ],
                ),
              ),
            ),
          ),
          
          // 内容
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        _buildRadarSection(),
                        const SizedBox(height: 20),
                        _buildStatusSection(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                _buildActionButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 顶部导航栏
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: controller.onBackTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Color(0xFF333333),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "防偷拍检测",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: controller.openRadarAnimationSelector,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.settings,
                size: 18,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 雷达扫描区域
  Widget _buildRadarSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 雷达扫描器
          LayoutBuilder(
            builder: (context, constraints) {
              // 计算合适的雷达大小，最小200，最大280
              final availableWidth = constraints.maxWidth;
              final radarSize = (availableWidth * 0.8).clamp(200.0, 280.0);
              return Obx(() => RadarSelector(
                size: radarSize,
                type: controller.radarAnimationType.value,
              ));
            },
          ),
          
          const SizedBox(height: 20),
          
          // 进度指示器
          Obx(() => controller.scanState.value == ScanState.scanning
              ? Column(
                  children: [
                    LinearProgressIndicator(
                      value: controller.scanProgress.value,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF5B9BD5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '正在扫描中... ${(controller.scanProgress.value * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  // 状态信息区域
  Widget _buildStatusSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWifiInfo(),
          const SizedBox(height: 15),
          _buildScanResult(),
        ],
      ),
    );
  }

  // WiFi信息
  Widget _buildWifiInfo() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "网络摄像头检测",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              "当前连接Wi-Fi：",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
            Text(
              controller.currentWifiName.value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ],
    ));
  }

  // 扫描结果
  Widget _buildScanResult() {
    return Obx(() {
      final state = controller.scanState.value;
      
      switch (state) {
        case ScanState.initial:
          return _buildInitialState();
        case ScanState.scanning:
          return _buildScanningState();
        case ScanState.success:
          return _buildSuccessState();
        case ScanState.suspicious:
          return _buildSuspiciousState();
        case ScanState.failed:
          return _buildFailedState();
      }
    });
  }

  Widget _buildInitialState() {
    return const Text(
      "点击开始检测按钮，开始扫描当前WiFi网络下的设备",
      style: TextStyle(
        fontSize: 14,
        color: Color(0xFF666666),
      ),
    );
  }

  Widget _buildScanningState() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "正在扫描网络中的设备，请稍候...",
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF5B9BD5),
          ),
        ),
        
        // 实时显示发现的设备
        if (controller.discoveredDevices.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            "已发现 ${controller.discoveredDevices.length} 个设备:",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: controller.discoveredDevices.map((device) {
                  final isSuspicious = controller.suspiciousDevices.contains(device);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(
                          AntiSpyController.getDeviceIcon(device.type),
                          size: 16,
                          color: isSuspicious ? Colors.red : const Color(0xFF5B9BD5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${device.name}　${device.ip}${device.openPorts.isNotEmpty ? ':${device.openPorts.first}' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isSuspicious ? Colors.red : const Color(0xFF666666),
                              fontWeight: isSuspicious ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSuspicious)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '可疑',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
        
        // 显示可疑设备提示
        if (controller.suspiciousDevices.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning,
                  size: 16,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '发现 ${controller.suspiciousDevices.length} 个可疑设备！',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ));
  }

  Widget _buildSuccessState() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              '检测成功（未发现风险）',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '风险结果：0 个可疑设备',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        if (controller.discoveredDevices.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            "发现设备:",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: controller.discoveredDevices.map((device) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        AntiSpyController.getDeviceIcon(device.type),
                        size: 16,
                        color: const Color(0xFF5B9BD5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${device.name}　${device.ip}${device.openPorts.isNotEmpty ? ':${device.openPorts.first}' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ],
    ));
  }

  Widget _buildSuspiciousState() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              '检测成功（发现风险）',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '风险结果：${controller.suspiciousDevices.length} 个可疑设备',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "可疑设备:",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 100),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: controller.suspiciousDevices.map((device) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(
                      AntiSpyController.getDeviceIcon(device.type),
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${device.name}　${device.ip}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ),
        
        // 显示所有发现的设备
        if (controller.discoveredDevices.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            "所有发现的设备:",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: controller.discoveredDevices.map((device) {
                  final isSuspicious = controller.suspiciousDevices.contains(device);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(
                          AntiSpyController.getDeviceIcon(device.type),
                          size: 16,
                          color: isSuspicious ? Colors.red : const Color(0xFF5B9BD5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${device.name}　${device.ip}${device.openPorts.isNotEmpty ? ':${device.openPorts.first}' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isSuspicious ? Colors.red : const Color(0xFF666666),
                              fontWeight: isSuspicious ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSuspicious)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '可疑',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 8),
        const Text(
          "室内可能存在可疑设备，请小心检查。可通过查找对方WiFi名称手机连接到此网络。",
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
          ),
        ),
      ],
    ));
  }

  Widget _buildFailedState() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              '检测失败',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "可能失败的原因：环境干扰较强，请稍后重试",
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        
        // 如果在失败前已发现一些设备，也显示出来
        if (controller.discoveredDevices.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            "已发现的设备:",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: controller.discoveredDevices.map((device) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        AntiSpyController.getDeviceIcon(device.type),
                        size: 16,
                        color: const Color(0xFF5B9BD5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${device.name}　${device.ip}${device.openPorts.isNotEmpty ? ':${device.openPorts.first}' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ],
    ));
  }

  // 操作按钮
  Widget _buildActionButton() {
    return Obx(() {
      final state = controller.scanState.value;
      final isScanning = state == ScanState.scanning;
      
      String buttonText;
      Color buttonColor;
      VoidCallback? onPressed;
      
      switch (state) {
        case ScanState.initial:
          buttonText = "开始检测";
          buttonColor = const Color(0xFF5B9BD5);
          onPressed = controller.startScan;
          break;
        case ScanState.scanning:
          buttonText = "检测中...";
          buttonColor = const Color(0xFF999999);
          onPressed = null;
          break;
        case ScanState.success:
        case ScanState.suspicious:
        case ScanState.failed:
          buttonText = "重新检测";
          buttonColor = const Color(0xFF5B9BD5);
          onPressed = controller.restartScan;
          break;
      }
      
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: isScanning ? 0 : 2,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
        ],
      );
    });
  }
}
