import 'dart:io';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:amap_flutter_location/amap_location_option.dart';
import 'package:flutter/foundation.dart';

/// 华为/鸿蒙系统定位优化服务
/// 
/// 针对华为手机（包括鸿蒙系统）的定位问题提供专门的优化方案
/// 解决华为设备定位失败、权限问题、系统兼容性等问题
class HuaweiLocationOptimizer {
  static HuaweiLocationOptimizer? _instance;
  static HuaweiLocationOptimizer get instance => _instance ??= HuaweiLocationOptimizer._();
  
  HuaweiLocationOptimizer._();
  
  bool _isHuaweiDevice = false;
  bool _isHarmonyOS = false;
  String _deviceBrand = '';
  String _deviceModel = '';
  
  /// 初始化华为设备检测
  Future<void> initialize() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        
        _deviceBrand = androidInfo.brand.toLowerCase();
        _deviceModel = androidInfo.model.toLowerCase();
        
        // 检测华为设备（排除荣耀设备，因为荣耀设备定位功能正常）
        _isHuaweiDevice = (_deviceBrand.contains('huawei') ||
                          _deviceBrand.contains('hw') ||
                          _deviceModel.contains('huawei')) &&
                          // 明确排除荣耀设备
                          !_deviceBrand.contains('honor') &&
                          !_deviceBrand.contains('hny') &&
                          !_deviceModel.contains('honor') &&
                          !_deviceModel.contains('magic');
        
        // 检测鸿蒙系统
        _isHarmonyOS = await _detectHarmonyOS(androidInfo);
        
        if (_isHuaweiDevice || _isHarmonyOS) {
          debugPrint('🔍 检测到华为设备（非荣耀）: $_deviceBrand $_deviceModel');
          debugPrint('🔍 是否鸿蒙系统: $_isHarmonyOS');
          debugPrint('💡 注意：荣耀设备定位功能正常，不需要特殊处理');
        }
      }
    } catch (e) {
      debugPrint('❌ 华为设备检测失败: $e');
    }
  }
  
  /// 检测是否为鸿蒙系统
  Future<bool> _detectHarmonyOS(AndroidDeviceInfo androidInfo) async {
    try {
      // 方法1: 检查系统属性
      String version = androidInfo.version.release;
      if (version.contains('HarmonyOS') || version.contains('OpenHarmony')) {
        return true;
      }
      
      // 方法2: 检查品牌和版本组合（仅华为品牌，排除荣耀）
      if (_isHuaweiDevice && androidInfo.version.sdkInt >= 30) {
        // Android 11+ 的华为设备（非荣耀）很可能是鸿蒙
        return true;
      }
      
      // 方法3: 通过原生方法检测（需要在MainActivity中实现）
      try {
        const platform = MethodChannel('kissu_app/device');
        final result = await platform.invokeMethod('isHarmonyOS');
        return result == true;
      } catch (e) {
        debugPrint('⚠️ 无法通过原生方法检测鸿蒙系统: $e');
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ 鸿蒙系统检测失败: $e');
      return false;
    }
  }
  
  /// 是否为华为设备（排除荣耀，因为荣耀设备定位正常）
  bool get isHuaweiDevice => _isHuaweiDevice || _isHarmonyOS;
  
  /// 是否为鸿蒙系统
  bool get isHarmonyOS => _isHarmonyOS;
  
  /// 获取华为设备专用的定位配置
  AMapLocationOption getHuaweiOptimizedLocationOption({
    int interval = 3000, // 华为设备建议间隔稍长
    double distanceFilter = 30.0, // 华为设备建议距离过滤稍小
  }) {
    AMapLocationOption option = AMapLocationOption();
    
    if (isHuaweiDevice) {
      debugPrint('🔧 应用华为设备专用定位配置（不包括荣耀设备）');
      
      // 华为设备（非荣耀）优化配置
      option.locationMode = AMapLocationMode.Hight_Accuracy; // 强制高精度
      option.locationInterval = interval; // 稍长间隔，减少被系统杀死概率
      option.distanceFilter = distanceFilter; // 较小距离过滤，提高响应性
      option.needAddress = true; // 华为设备地址解析通常正常
      option.onceLocation = false; // 持续定位
      option.geoLanguage = GeoLanguage.ZH; // 明确指定中文
      
      debugPrint('   - 定位模式: 高精度模式（华为优化）');
      debugPrint('   - 定位间隔: ${interval}ms（华为优化）');
      debugPrint('   - 距离过滤: ${distanceFilter}m（华为优化）');
      
    } else {
      // 非华为设备使用标准配置
      option.locationMode = AMapLocationMode.Hight_Accuracy;
      option.locationInterval = 2000;
      option.distanceFilter = 50.0;
      option.needAddress = true;
      option.onceLocation = false;
    }
    
    return option;
  }
  
  /// 华为设备专用权限申请策略
  Future<bool> requestHuaweiLocationPermission() async {
    if (!isHuaweiDevice) {
      debugPrint('⚠️ 非华为设备，使用标准权限申请流程');
      return false;
    }
    
    try {
      debugPrint('🔐 开始华为设备专用权限申请...');
      
      // 1. 先检查基础定位权限
      var locationStatus = await Permission.location.status;
      debugPrint('🔐 华为设备定位权限状态: $locationStatus');
      
      if (locationStatus.isDenied) {
        // 华为设备权限申请前先给用户提示
        debugPrint('💡 华为设备权限申请提示：请在弹窗中选择"始终允许"');
        locationStatus = await Permission.location.request();
        debugPrint('🔐 华为设备权限申请结果: $locationStatus');
      }
      
      if (!locationStatus.isGranted) {
        debugPrint('❌ 华为设备定位权限被拒绝');
        return false;
      }
      
      // 2. 华为设备特殊处理：检查后台权限但不强制要求
      if (isHarmonyOS) {
        debugPrint('🔐 鸿蒙系统后台权限检查...');
        var backgroundStatus = await Permission.locationAlways.status;
        debugPrint('🔐 鸿蒙系统后台权限状态: $backgroundStatus');
        
        if (backgroundStatus.isDenied) {
          debugPrint('💡 鸿蒙系统建议：请在设置中手动开启后台定位权限');
          // 不强制申请，避免重复弹窗
        }
      }
      
      debugPrint('✅ 华为设备权限申请完成');
      return true;
      
    } catch (e) {
      debugPrint('❌ 华为设备权限申请失败: $e');
      return false;
    }
  }
  
  /// 华为设备定位错误处理
  String getHuaweiLocationErrorSuggestion(int errorCode, String? errorInfo) {
    if (!isHuaweiDevice) {
      return '标准错误处理';
    }
    
    // 华为设备特有错误码处理
    switch (errorCode) {
      case 12:
        if (isHarmonyOS) {
          return '鸿蒙系统权限被拒绝，请前往"设置 > 隐私和安全 > 位置 > 应用权限"中开启定位权限';
        }
        return '华为设备权限被拒绝，请在权限管理中开启位置信息权限';
        
      case 13:
        return '华为设备网络异常，请检查网络连接或尝试切换网络';
        
      case 14:
        if (isHarmonyOS) {
          return '鸿蒙系统GPS定位失败，请确保位置服务已开启并尝试在空旷地带定位';
        }
        return '华为设备GPS定位失败，请检查位置服务是否开启';
        
      case 15:
        if (isHarmonyOS) {
          return '鸿蒙系统定位服务关闭，请前往"设置 > 隐私和安全 > 位置"开启位置服务';
        }
        return '华为设备定位服务关闭，请在系统设置中开启定位服务';
        
      case 18:
        return '华为设备定位超时，建议移动到信号较好的地方重试';
        
      // 华为设备可能的特有错误码
      case 1003:
        return '华为设备定位服务异常，请重启定位服务';
        
      case 1004:
        return '华为设备定位权限不足，请检查应用权限设置';
        
      default:
        if (isHarmonyOS) {
          return '鸿蒙系统定位异常（错误码: $errorCode），请尝试重启应用或检查系统设置';
        }
        return '华为设备定位异常（错误码: $errorCode），请尝试重新初始化定位服务';
    }
  }
  
  /// 华为设备定位优化建议
  Map<String, dynamic> getHuaweiOptimizationSuggestions() {
    if (!isHuaweiDevice) {
      return {'isHuawei': false, 'suggestions': []};
    }
    
    List<String> suggestions = [];
    
    if (isHarmonyOS) {
      suggestions.addAll([
        '🔧 鸿蒙系统优化建议：',
        '1. 确保"设置 > 隐私和安全 > 位置 > 访问我的位置"已开启',
        '2. 在"位置 > 应用权限"中设置本应用为"始终允许"',
        '3. 关闭"省电模式"或将本应用加入"受保护应用"列表',
        '4. 在"应用管理"中禁用本应用的"自动管理"，手动设置为允许后台运行',
      ]);
    } else {
      suggestions.addAll([
        '🔧 华为设备优化建议：',
        '1. 在"手机管家"中将本应用设置为"受保护应用"',
        '2. 关闭"智能省电"或将本应用加入白名单',
        '3. 在"权限管理"中确保定位权限为"始终允许"',
        '4. 检查"后台应用刷新"是否允许本应用运行',
      ]);
    }
    
    suggestions.addAll([
      '5. 尝试在空旷地带测试定位功能',
      '6. 重启手机后再次尝试定位',
      '7. 如问题持续，请联系客服并说明设备型号：$_deviceBrand $_deviceModel',
    ]);
    
    return {
      'isHuawei': true,
      'isHarmonyOS': isHarmonyOS,
      'deviceInfo': '$_deviceBrand $_deviceModel',
      'suggestions': suggestions,
    };
  }
  
  /// 华为设备定位诊断
  Future<Map<String, dynamic>> diagnoseHuaweiLocationIssues() async {
    Map<String, dynamic> diagnosis = {
      'isHuaweiDevice': isHuaweiDevice,
      'isHarmonyOS': isHarmonyOS,
      'deviceInfo': '$_deviceBrand $_deviceModel',
      'issues': <String>[],
      'solutions': <String>[],
    };
    
    if (!isHuaweiDevice) {
      return diagnosis;
    }
    
    try {
      // 检查权限状态
      var locationPermission = await Permission.location.status;
      var backgroundPermission = await Permission.locationAlways.status;
      
      if (!locationPermission.isGranted) {
        diagnosis['issues'].add('定位权限未授予');
        diagnosis['solutions'].add('请在权限管理中开启定位权限');
      }
      
      if (!backgroundPermission.isGranted && isHarmonyOS) {
        diagnosis['issues'].add('鸿蒙系统后台定位权限未开启');
        diagnosis['solutions'].add('建议在设置中开启后台定位权限以获得更好体验');
      }
      
      // 检查系统设置建议
      if (isHarmonyOS) {
        diagnosis['solutions'].add('确保鸿蒙系统的位置服务已开启');
        diagnosis['solutions'].add('将应用加入受保护应用列表');
      } else {
        diagnosis['solutions'].add('在华为手机管家中设置应用保护');
        diagnosis['solutions'].add('关闭智能省电对本应用的限制');
      }
      
    } catch (e) {
      diagnosis['issues'].add('诊断过程中出现异常: $e');
    }
    
    return diagnosis;
  }
}
