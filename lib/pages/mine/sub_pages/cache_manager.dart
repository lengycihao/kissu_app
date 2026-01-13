import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kissu_app/utils/oktoast_util.dart';

/// 缓存管理工具类
class CacheManager {
  /// 缓存大小（响应式）
  static final cacheSize = '计算中...'.obs;

  /// 计算缓存大小（包括临时目录、应用缓存、日志文件等）
  static Future<void> calculateCacheSize() async {
    try {
      int totalSize = 0;
      
      // 1. 计算临时目录大小
      try {
        final tempDir = await getTemporaryDirectory();
        totalSize += await _calculateDirectorySize(tempDir);
        debugPrint('临时目录大小: ${_formatBytes(totalSize)}');
      } catch (e) {
        debugPrint('计算临时目录大小失败: $e');
      }
      
      // 2. 计算应用缓存目录大小（仅Android）
      if (Platform.isAndroid) {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          // 查找缓存相关目录
          final cacheSubDirs = ['cache', 'image_cache', 'http_cache'];
          for (var subDir in cacheSubDirs) {
            final dir = Directory('${appDir.parent.path}/$subDir');
            if (await dir.exists()) {
              totalSize += await _calculateDirectorySize(dir);
            }
          }
        } catch (e) {
          debugPrint('计算应用缓存目录大小失败: $e');
        }
      }
      
      // 3. 计算日志文件大小
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        // 查找所有日志文件
        final logFiles = [
          'analytics_log.txt',
          'log.txt',
          'app_log.txt',
          'error_log.txt',
        ];
        
        for (var logFileName in logFiles) {
          final logFile = File('${appDocDir.path}/$logFileName');
          if (await logFile.exists()) {
            totalSize += await logFile.length();
            debugPrint('日志文件 $logFileName: ${_formatBytes(await logFile.length())}');
          }
        }
        
        // 查找外部存储的日志文件（Android）
        if (Platform.isAndroid) {
          try {
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              for (var logFileName in logFiles) {
                final logFile = File('${externalDir.path}/$logFileName');
                if (await logFile.exists()) {
                  totalSize += await logFile.length();
                  debugPrint('外部日志文件 $logFileName: ${_formatBytes(await logFile.length())}');
                }
              }
            }
          } catch (e) {
            debugPrint('计算外部日志文件大小失败: $e');
          }
        }
      } catch (e) {
        debugPrint('计算日志文件大小失败: $e');
      }
      
      // 4. 计算图片缓存（如果使用了cached_network_image）
      try {
        final tempDir = await getTemporaryDirectory();
        final imageCacheDir = Directory('${tempDir.path}/libCachedImageData');
        if (await imageCacheDir.exists()) {
          final imageSize = await _calculateDirectorySize(imageCacheDir);
          totalSize += imageSize;
          debugPrint('图片缓存大小: ${_formatBytes(imageSize)}');
        }
      } catch (e) {
        debugPrint('计算图片缓存大小失败: $e');
      }
      
      // 格式化缓存大小
      cacheSize.value = _formatBytes(totalSize);
      debugPrint('总缓存大小: ${cacheSize.value}');
    } catch (e) {
      debugPrint('计算缓存大小失败: $e');
      cacheSize.value = '未知';
    }
  }
  
  /// 计算目录大小（递归）
  static Future<int> _calculateDirectorySize(Directory directory) async {
    int totalSize = 0;
    
    try {
      if (!await directory.exists()) {
        return 0;
      }
      
      await for (var entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            totalSize += await entity.length();
          } catch (e) {
            // 忽略无法访问的文件
          }
        }
      }
    } catch (e) {
      debugPrint('计算目录大小失败 ${directory.path}: $e');
    }
    
    return totalSize;
  }

  /// 格式化字节大小
  static String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// 清除缓存（包括临时目录、应用缓存、日志文件、图片缓存）
  static Future<void> clearCache() async {
    try {
      // 显示确认对话框
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('清除缓存'),
          content: Text('确定要清除缓存吗？\n当前缓存大小：${cacheSize.value}\n\n将清除：\n• 临时文件\n• 图片缓存\n• 日志文件\n• 应用缓存'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('确定'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // 显示加载提示
      cacheSize.value = '清除中...';

      int deletedCount = 0;

      // 1. 清除临时目录
      try {
        final tempDir = await getTemporaryDirectory();
        deletedCount += await _clearDirectory(tempDir);
        debugPrint('已清除临时目录');
      } catch (e) {
        debugPrint('清除临时目录失败: $e');
      }

      // 2. 清除应用缓存目录（仅Android）
      if (Platform.isAndroid) {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final cacheSubDirs = ['cache', 'image_cache', 'http_cache'];
          for (var subDir in cacheSubDirs) {
            final dir = Directory('${appDir.parent.path}/$subDir');
            if (await dir.exists()) {
              deletedCount += await _clearDirectory(dir);
              debugPrint('已清除 $subDir 目录');
            }
          }
        } catch (e) {
          debugPrint('清除应用缓存目录失败: $e');
        }
      }

      // 3. 清除日志文件
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final logFiles = [
          'analytics_log.txt',
          'log.txt',
          'app_log.txt',
          'error_log.txt',
        ];
        
        for (var logFileName in logFiles) {
          final logFile = File('${appDocDir.path}/$logFileName');
          if (await logFile.exists()) {
            await logFile.delete();
            deletedCount++;
            debugPrint('已删除日志文件: $logFileName');
          }
        }
        
        // 清除外部存储的日志文件（Android）
        if (Platform.isAndroid) {
          try {
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              for (var logFileName in logFiles) {
                final logFile = File('${externalDir.path}/$logFileName');
                if (await logFile.exists()) {
                  await logFile.delete();
                  deletedCount++;
                  debugPrint('已删除外部日志文件: $logFileName');
                }
              }
            }
          } catch (e) {
            debugPrint('清除外部日志文件失败: $e');
          }
        }
      } catch (e) {
        debugPrint('清除日志文件失败: $e');
      }

      // 4. 清除图片缓存
      try {
        final tempDir = await getTemporaryDirectory();
        final imageCacheDir = Directory('${tempDir.path}/libCachedImageData');
        if (await imageCacheDir.exists()) {
          deletedCount += await _clearDirectory(imageCacheDir);
          debugPrint('已清除图片缓存');
        }
      } catch (e) {
        debugPrint('清除图片缓存失败: $e');
      }

      // 重新计算缓存大小
      await calculateCacheSize();

      debugPrint('缓存清除完成，共删除 $deletedCount 个文件/目录');
      OKToastUtil.show('缓存清除成功');
    } catch (e) {
      debugPrint('清除缓存失败: $e');
      OKToastUtil.show('清除缓存失败');
      cacheSize.value = '未知';
    }
  }
  
  /// 清除目录内容（不删除目录本身）
  static Future<int> _clearDirectory(Directory directory) async {
    int deletedCount = 0;
    
    try {
      if (!await directory.exists()) {
        return 0;
      }
      
      await for (var entity in directory.list(recursive: false, followLinks: false)) {
        try {
          if (entity is File) {
            await entity.delete();
            deletedCount++;
          } else if (entity is Directory) {
            await entity.delete(recursive: true);
            deletedCount++;
          }
        } catch (e) {
          debugPrint('删除文件失败 ${entity.path}: $e');
        }
      }
    } catch (e) {
      debugPrint('清除目录失败 ${directory.path}: $e');
    }
    
    return deletedCount;
  }
}
