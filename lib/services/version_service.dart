import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:kissu_app/network/public/version_api.dart';
import 'package:kissu_app/widgets/dialogs/version_update_dialog.dart';
import 'package:kissu_app/utils/oktoast_util.dart';

/// 版本更新服务
class VersionService extends GetxService {
  /// 当前应用版本号（数字格式）
  int? _currentVersionNum;
  
  /// 获取当前版本号（数字格式）
  Future<int> getCurrentVersionNum() async {
    if (_currentVersionNum != null) {
      return _currentVersionNum!;
    }
    
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String version = packageInfo.version; // 例如: "1.0.1"
      
      // 将版本号转换为数字格式
      // 1.0.1 -> 1000100
      // 1.0.2 -> 1000200
      List<String> parts = version.split('.');
      if (parts.length == 3) {
        int major = int.tryParse(parts[0]) ?? 0;
        int minor = int.tryParse(parts[1]) ?? 0;
        int patch = int.tryParse(parts[2]) ?? 0;
        _currentVersionNum = major * 1000000 + minor * 1000 + patch;
      } else {
        _currentVersionNum = 0;
      }
      
      return _currentVersionNum!;
    } catch (e) {
      print('获取版本号失败: $e');
      _currentVersionNum = 0;
      return 0;
    }
  }
  
  /// 检查版本更新（首页自动检查，只弹出强更新和弱更新）
  Future<void> checkVersionForHomePage(BuildContext context) async {
    try {
      final versionInfo = await VersionApi.checkVersion();
      if (versionInfo == null) return;
      
      final currentVersionNum = await getCurrentVersionNum();
      
      // 比较版本号
      if (versionInfo.versionNum > currentVersionNum) {
        // 有新版本
        if (versionInfo.isForced || versionInfo.isOptional) {
          // 强更新或弱更新，弹窗提示
          _showUpdateDialog(context, versionInfo);
        }
        // 静默更新不弹窗
      }
    } catch (e) {
      print('检查版本更新失败: $e');
    }
  }
  
  /// 检查版本更新（关于我们页面手动检查，所有类型都弹窗）
  Future<void> checkVersionForAboutPage(BuildContext context) async {
    try {
      final versionInfo = await VersionApi.checkVersion();
      if (versionInfo == null) {
        // 检查失败，提示用户
        OKToastUtil.show('检查更新失败，请稍后重试');
        return;
      }
      
      final currentVersionNum = await getCurrentVersionNum();
      
      // 比较版本号
      if (versionInfo.versionNum > currentVersionNum) {
        // 有新版本，所有类型都弹窗
        _showUpdateDialog(context, versionInfo);
      } else {
        // 已是最新版本
        OKToastUtil.show('当前已是最新版本');
      }
    } catch (e) {
      print('检查版本更新失败: $e');
      OKToastUtil.show('检查更新失败，请稍后重试');
    }
  }
  
  /// 显示更新弹窗
  void _showUpdateDialog(BuildContext context, VersionInfo versionInfo) {
    showDialog(
      context: context,
      barrierDismissible: false, // 禁止点击外部关闭
      builder: (context) => VersionUpdateDialog(
        versionInfo: versionInfo,
      ),
    );
  }
}

