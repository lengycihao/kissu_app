import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:device_info_plus/device_info_plus.dart';
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
  static const String _uploadLogApi = '/file/upload';

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
      info['userPhone'] = '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
    }

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info['deviceModel'] = androidInfo.model;
        info['deviceBrand'] = androidInfo.brand;
        info['androidVersion'] = androidInfo.version.release;
        info['sdkInt'] = androidInfo.version.sdkInt;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info['deviceModel'] = iosInfo.model;
        info['deviceName'] = iosInfo.name;
        info['systemVersion'] = iosInfo.systemVersion;
      }
    } catch (e) {
      logWarning('获取设备详细信息失败', tag: 'LogUpload', error: e);
    }

    return info;
  }

  /// 创建设备信息文件
  Future<File> _createDeviceInfoFile(Directory tempDir) async {
    final deviceInfo = await _getDeviceInfo();
    final file = File('${tempDir.path}${Platform.pathSeparator}device_info.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(deviceInfo),
    );
    return file;
  }

  /// 打包日志文件为ZIP
  Future<File?> _packageLogs({String? remark}) async {
    try {
      final logFiles = await getLogFiles();
      if (logFiles.isEmpty) {
        logWarning('没有日志文件可上传', tag: 'LogUpload');
        return null;
      }

      // 创建临时目录
      final tempDir = await getTemporaryDirectory();
      final packageDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}log_package_${DateTime.now().millisecondsSinceEpoch}',
      );
      await packageDir.create(recursive: true);

      // 创建Archive
      final archive = Archive();

      // 添加设备信息文件
      final deviceInfoFile = await _createDeviceInfoFile(packageDir);
      final deviceInfoBytes = await deviceInfoFile.readAsBytes();
      archive.addFile(ArchiveFile(
        'device_info.json',
        deviceInfoBytes.length,
        deviceInfoBytes,
      ));

      // 添加备注文件（如果有）
      if (remark != null && remark.isNotEmpty) {
        final remarkBytes = utf8.encode(remark);
        archive.addFile(ArchiveFile(
          'user_remark.txt',
          remarkBytes.length,
          remarkBytes,
        ));
      }

      // 添加日志文件（最多保留最近7天的）
      final cutoffTime = DateTime.now().subtract(const Duration(days: 7));
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
          }
        } catch (e) {
          logWarning('读取日志文件失败: ${logFile.path}', tag: 'LogUpload', error: e);
        }
      }

      // 压缩为ZIP
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null || zipData.isEmpty) {
        logError('压缩日志文件失败', tag: 'LogUpload');
        return null;
      }

      // 保存ZIP文件
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final zipFile = File('${tempDir.path}${Platform.pathSeparator}logs_$timestamp.zip');
      await zipFile.writeAsBytes(zipData);

      // 清理临时目录
      try {
        await packageDir.delete(recursive: true);
      } catch (e) {
        // 忽略清理错误
      }

      logInfo('日志打包完成: ${zipFile.path}, 大小: ${_formatFileSize(zipData.length)}', tag: 'LogUpload');
      return zipFile;
    } catch (e) {
      logError('打包日志文件失败', tag: 'LogUpload', error: e);
      return null;
    }
  }

  /// 上传日志
  /// [remark] 用户备注（可选）
  /// [onProgress] 上传进度回调
  Future<HttpResultN> uploadLogs({
    String? remark,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      logInfo('开始上传日志...', tag: 'LogUpload');

      // 打包日志
      final zipFile = await _packageLogs(remark: remark);
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
        _uploadLogApi,
        paths: {'file': zipFile.path},
        paramEncrypt: false,
        send: onProgress,
      );
      
      // 记录设备信息和备注到日志（因为文件上传接口不接受额外参数）
      if (result.isSuccess) {
        logInfo(
          '日志上传成功，设备信息: ${jsonEncode(deviceInfo)}${remark != null && remark.isNotEmpty ? '，备注: $remark' : ''}',
          tag: 'LogUpload',
        );
      }

      // 清理临时ZIP文件
      try {
        await zipFile.delete();
      } catch (e) {
        // 忽略清理错误
      }

      if (result.isSuccess) {
        logInfo('日志上传成功', tag: 'LogUpload');
      } else {
        logError('日志上传失败: ${result.msg}', tag: 'LogUpload');
      }

      return result;
    } catch (e) {
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
