import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// 厂商白名单引导工具类
/// 
/// 使用示例：
/// ```dart
/// // 检查并显示引导
/// await WhitelistHelper.checkAndShowGuidance();
/// 
/// // 或者手动触发
/// WhitelistHelper.showGuidanceDialog();
/// ```
class WhitelistHelper {
  static const MethodChannel _channel = MethodChannel('kissu_app/whitelist');
  
  /// 获取厂商名称
  static Future<String> getManufacturer() async {
    try {
      return await _channel.invokeMethod('getManufacturer') ?? '其他';
    } catch (e) {
      print('❌ 获取厂商名称失败: $e');
      return '其他';
    }
  }
  
  /// 是否需要白名单引导
  static Future<bool> needsWhitelistGuidance() async {
    try {
      return await _channel.invokeMethod('needsWhitelistGuidance') ?? false;
    } catch (e) {
      print('❌ 检查白名单需求失败: $e');
      return false;
    }
  }
  
  /// 获取详细引导文本
  static Future<String> getGuidanceText() async {
    try {
      return await _channel.invokeMethod('getGuidanceText') ?? '';
    } catch (e) {
      print('❌ 获取引导文本失败: $e');
      return '';
    }
  }
  
  /// 获取简短引导
  static Future<String> getShortGuidance() async {
    try {
      return await _channel.invokeMethod('getShortGuidance') ?? '';
    } catch (e) {
      print('❌ 获取简短引导失败: $e');
      return '';
    }
  }
  
  /// 打开白名单设置页面
  static Future<bool> openWhitelistSettings() async {
    try {
      return await _channel.invokeMethod('openWhitelistSettings') ?? false;
    } catch (e) {
      print('❌ 打开白名单设置失败: $e');
      return false;
    }
  }
  
  /// 检查并显示引导对话框（首次启动定位时调用）
  /// 
  /// [forceShow] - 强制显示，忽略 "已提示过" 的标记
  static Future<void> checkAndShowGuidance({bool forceShow = false}) async {
    try {
      // 1. 检查是否需要引导
      bool needsGuidance = await needsWhitelistGuidance();
      
      if (!needsGuidance && !forceShow) {
        print('📱 当前设备不需要白名单引导');
        return;
      }
      
      // 2. 检查是否已经提示过（避免每次都弹）
      final storage = Get.find<dynamic>(); // 替换为你的存储服务
      // bool hasShown = await storage.read('whitelist_guidance_shown') ?? false;
      
      // if (hasShown && !forceShow) {
      //   print('📱 白名单引导已提示过，跳过');
      //   return;
      // }
      
      // 3. 显示引导对话框
      await showGuidanceDialog();
      
      // 4. 标记已提示
      // await storage.write('whitelist_guidance_shown', true);
      
    } catch (e) {
      print('❌ 检查白名单引导失败: $e');
    }
  }
  
  /// 显示引导对话框
  static Future<void> showGuidanceDialog() async {
    try {
      final manufacturer = await getManufacturer();
      final guidance = await getGuidanceText();
      
      if (guidance.isEmpty) {
        print('📱 当前设备不需要白名单引导');
        return;
      }
      
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$manufacturer 手机后台设置',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '为确保定位服务能在后台持续运行，请按以下步骤设置：',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  guidance,
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '这样可以确保您的位置数据及时上报',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('稍后设置'),
            ),
            ElevatedButton(
              onPressed: () async {
                Get.back();
                final success = await openWhitelistSettings();
                if (success) {
                  Get.snackbar(
                    '提示',
                    '请在设置页面中允许 Kissu 后台运行',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: Duration(seconds: 3),
                  );
                } else {
                  Get.snackbar(
                    '提示',
                    '请手动前往设置中允许 Kissu 后台运行',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: Duration(seconds: 3),
                  );
                }
              },
              child: Text('去设置'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      print('❌ 显示引导对话框失败: $e');
    }
  }
  
  /// 显示简短的提示（Snackbar）
  static Future<void> showShortTip() async {
    try {
      final shortGuidance = await getShortGuidance();
      
      if (shortGuidance.isEmpty) return;
      
      Get.snackbar(
        '后台运行提示',
        shortGuidance,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 5),
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.black87,
        icon: Icon(Icons.settings_suggest, color: Colors.orange),
        mainButton: TextButton(
          onPressed: () {
            Get.back(); // 关闭 Snackbar
            showGuidanceDialog();
          },
          child: Text('查看详情'),
        ),
      );
    } catch (e) {
      print('❌ 显示简短提示失败: $e');
    }
  }
}



