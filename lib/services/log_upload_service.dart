import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:kissu_app/network/public/api_request.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kissu_app/network/http_managerN.dart';
import 'package:kissu_app/network/http_resultN.dart';
import 'package:kissu_app/network/tools/logging/logging.dart';
import 'package:kissu_app/utils/user_manager.dart';

/// 日志上传服务
/// 负责收集、打包、压缩和上传应用日志
class LogUploadService {
  static LogUploadService? _instance;
  static LogUploadService get instance => _instance ??= LogUploadService._();

  LogUploadService._();

  /// 日志上传API路径（使用通用文件上传接口）

  /// 获取日志目录
  Future<Directory> _getLogDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    return Directory('${appDir.path}${Platform.pathSeparator}logs');
  }

  /// 获取所有日志文件
  Future<List<File>> getLogFiles() async {
    try {
      final logDir = await _getLogDirectory();
      if (!await logDir.exists()) {
        return [];
      }

      final files = logDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.log'))
          .toList();

      // 按修改时间排序，最新的在前
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      return files;
    } catch (e) {
      logError('获取日志文件失败', tag: 'LogUpload', error: e);
      return [];
    }
  }

  /// 获取日志文件总大小（格式化字符串）
  Future<String> getLogFilesSize() async {
    try {
      final files = await getLogFiles();
      int totalSize = 0;
      for (final file in files) {
        totalSize += await file.length();
      }
      return _formatFileSize(totalSize);
    } catch (e) {
      return '0 B';
    }
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// 获取设备信息
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    final Map<String, dynamic> info = {
      'appVersion': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'packageName': packageInfo.packageName,
      'platform': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
      'dartVersion': Platform.version,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 添加用户信息（脱敏）
    if (UserManager.userId != null) {
      info['userId'] = UserManager.userId;
    }
    if (UserManager.userPhone != null && UserManager.userPhone!.length >= 7) {
      // 手机号脱敏：138****1234
      final phone = UserManager.userPhone!;
      info['userPhone'] = phone;
    }

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info['deviceModel'] = androidInfo.model;
        info['deviceBrand'] = androidInfo.brand;
        info['manufacturer'] = androidInfo.manufacturer;
        info['androidVersion'] = androidInfo.version.release;
        info['sdkInt'] = androidInfo.version.sdkInt;
        info['display'] = androidInfo.display;
        info['fingerprint'] = androidInfo.fingerprint;
        info['host'] = androidInfo.host;
        
        // 鸿蒙系统检测：多种方式综合判断
        final brand = androidInfo.brand.toLowerCase();
        final displayLower = androidInfo.display.toLowerCase();
        final fingerprintLower = androidInfo.fingerprint.toLowerCase();
        final hostLower = androidInfo.host.toLowerCase();
        final osVersion = Platform.operatingSystemVersion.toLowerCase();
        final versionRelease = androidInfo.version.release;
        
        // 方式1：包含 harmony / ohos 关键字
        final containsHarmony = displayLower.contains('harmony') ||
            fingerprintLower.contains('harmony') ||
            hostLower.contains('harmony') ||
            displayLower.contains('ohos') ||
            fingerprintLower.contains('ohos') ||
            osVersion.contains('harmony') ||
            osVersion.contains('ohos');
        
        // 方式2：华为/荣耀设备 display/osVersion 以 "system" 开头
        final isHuaweiOrHonor = brand.contains('huawei') || brand.contains('honor');
        final displayStartsWithSystem = displayLower.startsWith('system') || osVersion.startsWith('system');
        
        bool isHarmonyOS = false;
        
        if (containsHarmony) {
          isHarmonyOS = true;
        } else if (isHuaweiOrHonor && displayStartsWithSystem) {
          isHarmonyOS = true;
        } else if (isHuaweiOrHonor) {
          final parts = versionRelease.split('.');
          final majorVersion = int.tryParse(parts[0]) ?? 0;
          if (majorVersion >= 5 && parts.length > 1) {
            isHarmonyOS = true;
          }
        }
        
        info['isHarmonyOS'] = isHarmonyOS;
        info['osType'] = isHarmonyOS ? 'HarmonyOS' : 'Android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info['deviceModel'] = iosInfo.model;
        info['deviceName'] = iosInfo.name;
        info['systemVersion'] = iosInfo.systemVersion;
        info['osType'] = 'iOS';
      }
    } catch (e) {
      logWarning('获取设备详细信息失败', tag: 'LogUpload', error: e);
    }

    return info;
  }

  /// 打包所有日志文件为 ZIP
  /// [maxDays] 最多打包最近几天的日志，默认 7 天
  Future<File?> _packageAllLogs({int maxDays = 7}) async {
    try {
      final logFiles = await getLogFiles();
      if (logFiles.isEmpty) {
        logWarning('没有日志文件可上传', tag: 'LogUpload');
        return null;
      }

      // 创建 Archive
      final archive = Archive();
      
      // 添加设备信息文件
      final deviceInfo = await _getDeviceInfo();
      final deviceInfoJson = const JsonEncoder.withIndent('  ').convert(deviceInfo);
      final deviceInfoBytes = utf8.encode(deviceInfoJson);
      archive.addFile(ArchiveFile(
        'device_info.json',
        deviceInfoBytes.length,
        deviceInfoBytes,
      ));

      // 添加日志文件（最近 maxDays 天的）
      final cutoffTime = DateTime.now().subtract(Duration(days: maxDays));
      int totalSize = 0;
      int fileCount = 0;
      
      for (final logFile in logFiles) {
        try {
          final stat = await logFile.stat();
          if (stat.modified.isAfter(cutoffTime)) {
            final bytes = await logFile.readAsBytes();
            final fileName = logFile.path.split(Platform.pathSeparator).last;
            archive.addFile(ArchiveFile(
              'logs/$fileName',
              bytes.length,
              bytes,
            ));
            totalSize += bytes.length;
            fileCount++;
          }
        } catch (e) {
          logWarning('读取日志文件失败: ${logFile.path}', tag: 'LogUpload', error: e);
        }
      }

      if (fileCount == 0) {
        logWarning('没有符合条件的日志文件', tag: 'LogUpload');
        return null;
      }

      // 压缩为 ZIP
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null || zipData.isEmpty) {
        logError('压缩日志文件失败', tag: 'LogUpload');
        return null;
      }

      // 保存 ZIP 文件
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final zipFile = File('${tempDir.path}${Platform.pathSeparator}logs_$timestamp.zip');
      await zipFile.writeAsBytes(zipData);

      logInfo(
        '日志打包完成: $fileCount 个文件, 原始大小: ${_formatFileSize(totalSize)}, 压缩后: ${_formatFileSize(zipData.length)}',
        tag: 'LogUpload',
      );
      return zipFile;
    } catch (e) {
      logError('打包日志文件失败', tag: 'LogUpload', error: e);
      return null;
    }
  }

  /// 上传日志
  /// [remark] 用户备注（可选）
  /// [onProgress] 上传进度回调
  /// [clearAfterUpload] 上传成功后是否清除日志文件，默认为 true
  /// [maxDays] 最多上传最近几天的日志，默认 7 天
  Future<HttpResultN> uploadLogs({
    String? remark,
    void Function(int sent, int total)? onProgress,
    bool clearAfterUpload = true,
    int maxDays = 7,
  }) async {
    File? zipFile;
    try {
      logInfo('开始上传日志...', tag: 'LogUpload');

      // 打包所有日志文件
      zipFile = await _packageAllLogs(maxDays: maxDays);
      if (zipFile == null) {
        return HttpResultN(
          isSuccess: false,
          code: -1,
          msg: '没有可上传的日志文件',
        );
      }

      // 获取设备信息用于请求参数
      final deviceInfo = await _getDeviceInfo();

      // 上传文件（使用通用文件上传接口）
      final result = await HttpManagerN.instance.executePost(
        ApiRequest.fileUpload,
        paths: {'file': zipFile.path},
        paramEncrypt: false,
        send: onProgress,
      );
      
      // 清理临时 ZIP 文件
      try {
        await zipFile.delete();
      } catch (e) {
        // 忽略清理错误
      }
      
      // 记录设备信息和备注到日志（因为文件上传接口不接受额外参数）
      if (result.isSuccess) {
        logInfo(
          '日志上传成功，设备信息: ${jsonEncode(deviceInfo)}${remark != null && remark.isNotEmpty ? '，备注: $remark' : ''}',
          tag: 'LogUpload',
        );
        
        // 上传成功后清除日志文件
        if (clearAfterUpload) {
          await clearLogs();
          logInfo('日志文件已清除', tag: 'LogUpload');
        }
      } else {
        logError('日志上传失败: ${result.msg}', tag: 'LogUpload');
      }

      return result;
    } catch (e) {
      // 清理临时 ZIP 文件
      if (zipFile != null) {
        try {
          await zipFile.delete();
        } catch (_) {
          // 忽略清理错误
        }
      }
      
      logError('上传日志异常', tag: 'LogUpload', error: e);
      return HttpResultN(
        isSuccess: false,
        code: -1,
        msg: '上传失败: $e',
      );
    }
  }

  /// 清理所有日志文件
  Future<void> clearLogs() async {
    try {
      final logDir = await _getLogDirectory();
      if (await logDir.exists()) {
        final files = logDir.listSync().whereType<File>();
        for (final file in files) {
          try {
            await file.delete();
          } catch (e) {
            // 忽略单个文件删除错误
          }
        }
        logInfo('日志文件已清理', tag: 'LogUpload');
      }
    } catch (e) {
      logError('清理日志文件失败', tag: 'LogUpload', error: e);
    }
  }

  /// 获取日志文件数量
  Future<int> getLogFileCount() async {
    final files = await getLogFiles();
    return files.length;
  }
}
