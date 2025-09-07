import 'dart:convert';
import 'dart:io';
import 'package:synchronized/synchronized.dart';

import 'package:path/path.dart' as path;

import 'dir_util.dart';
import 'encypt_util.dart';
import 'log_util.dart';

/*

  // 存Json数据 - 写入key 与 json 即可，可以选择加入过期时间
  await fileCache.putJsonByKey(
    'hutu',
    {
    "name": "hutu",
    "age": 35,
    },
    expiration: const Duration(hours: 1));


  // 取Json数据 - 根据key就能取到，如果没有或者过期则为null
  final json = await fileCache.getJsonByKey('hutu');


   // 存储基本数据类型
    await fileCache.putValueByKey('county', '凤凰');
    await fileCache.putValueByKey('age', 18);

   // 取出基本数据类型
   final county = await fileCache.getValueByKey<String>('county');
   Log.d('获取county：$county');

   final age = await fileCache.getValueByKey<int>('age');
   Log.d('获取age：$age');

 */
class FileCacheUtil {
  static const maxSizeInBytes = 500 * 1024 * 1024; // 最大限制 500M 文件缓存大小
  // static const maxSizeInBytes = 271360; // 最大限制 500M 文件缓存大小
  static const String _fileCategory = "app_file_cache";
  static final Lock _lock = Lock();

  FileCacheUtil._();

  static FileCacheUtil? _instance;
  static FileCacheUtil get instance => _instance ??= FileCacheUtil._();

  String? cachePath;

  // 初始化 - 获取到缓存路径
  Future _init() async {
    cachePath = DirUtil.getTempPath(category: _fileCategory);
    if (cachePath != null) {
      //尝试异步创建自定义的文件夹
      await DirUtil.createTempDir(category: _fileCategory);
    } else {
      throw Exception('DirUtil 无法获取到Cache文件夹，可能 DirUtil 没有初始化，请检查！');
    }
  }

  /// 移除指定的 Key 对应的缓存文件
  Future<void> removeByKey(String key) async {
    if (cachePath == null) {
      await _init();
    }

    String path = '$cachePath/$key';
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 移除全部的 Key 对应的缓存文件
  Future<void> removeAllKey() async {
    if (cachePath == null) {
      await _init();
    }

    Directory cacheDir = Directory(cachePath!);
    if (await cacheDir.exists()) {
      List<File> cacheFiles = cacheDir.listSync().whereType<File>().toList();
      if (cacheFiles.isNotEmpty) {
        for (File file in cacheFiles) {
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    }
  }

  // 读取文件的全部Json数据
  Future<Map<String, dynamic>?> _readAllJsonFromFile(String key) async {
    String path = '$cachePath/$key';
    final file = File(path);
    if (await file.exists()) {
      String jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return jsonData;
    }
    return null;
  }

  // ============================= Json(对象) 类型 =========================================

  /// 添加Json数据到本地文件缓存
  Future<void> putJsonByKey(
    String key,
    Map<String, dynamic> jsonData, {
    Duration? expiration,
  }) async {
    // 加锁
    await _lock.synchronized(() async {
      if (cachePath == null) {
        await _init();
      } else {
        Directory cacheDir = Directory(cachePath ?? '');
        if (!await cacheDir.exists()) {
          await DirUtil.createTempDir(category: _fileCategory);
        }
      }

      //加密Key
      key = EncryptUtil.encodeMd5(key);

      final file = File('$cachePath/$key');
      Map<String, dynamic> existingData = {};

      //获取到已经存在的 Json
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        existingData = jsonDecode(jsonString) as Map<String, dynamic>;
      }

      //存入现有的 key - value 缓存
      existingData[key] = {
        'data': jsonData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiration': expiration?.inMilliseconds,
      };

      //转化为新的Json文本
      String newJsonString = jsonEncode(existingData);

      //检查限制的总大小并写入到文件
      checkAndWriteFile(file, newJsonString);
    });
  }

  /// 从本都缓存文件读取Json数据
  Future<Map<String, dynamic>?> getJsonByKey(String key) async {
    if (cachePath == null) {
      await _init();
    } else {
      Directory cacheDir = Directory(cachePath ?? '');
      if (!await cacheDir.exists()) {
        await DirUtil.createTempDir(category: _fileCategory);
      }
    }

    //加密Key
    key = EncryptUtil.encodeMd5(key);

    final jsonData = await _readAllJsonFromFile(key);
    if (jsonData == null) {
      return null;
    }

    //取出对应 key 的Json文本
    final jsonEntry = jsonData[key] as Map<String, dynamic>?;
    if (jsonEntry == null || _isExpired(jsonEntry)) {
      return null;
    }

    //返回去除过期时间之后的真正数据
    return jsonEntry['data'] as Map<String, dynamic>?;
  }

  // ============================= 基本数据类型 =========================================

  /// 添加基本数据类型的数据到本地文件缓存
  Future<void> putValueByKey<T>(
    String key,
    T value, {
    Duration? expiration,
  }) async {
    // 加锁
    await _lock.synchronized(() async {
      if (cachePath == null) {
        await _init();
      } else {
        Directory cacheDir = Directory(cachePath ?? '');
        if (!await cacheDir.exists()) {
          await DirUtil.createTempDir(category: _fileCategory);
        }
      }

      //加密Key
      key = EncryptUtil.encodeMd5(key);

      final file = File('$cachePath/$key');
      Map<String, dynamic> existingData = {};

      //获取到已经存在的 Json
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        existingData = jsonDecode(jsonString) as Map<String, dynamic>;
      }

      //存入现有的 key - value 缓存
      existingData[key] = {
        'data': value,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiration': expiration?.inMilliseconds,
      };

      //转化为新的Json文本写入到文件
      String newJsonString = jsonEncode(existingData);

      //检查限制的总大小并写入到文件
      checkAndWriteFile(file, newJsonString);
    });
  }

  /// 从本都缓存文件读取基本数据类型数据
  Future<T?> getValueByKey<T>(String key) async {
    if (cachePath == null) {
      await _init();
    } else {
      Directory cacheDir = Directory(cachePath ?? '');
      if (!await cacheDir.exists()) {
        await DirUtil.createTempDir(category: _fileCategory);
      }
    }

    //加密Key
    key = EncryptUtil.encodeMd5(key);

    final jsonData = await _readAllJsonFromFile(key);
    if (jsonData == null) {
      return null;
    }

    //取出对应 key 的Json文本
    final jsonEntry = jsonData[key] as Map<String, dynamic>?;
    if (jsonEntry == null || _isExpired(jsonEntry)) {
      return null;
    }

    //返回去除过期时间之后的真正数据
    return jsonEntry['data'] as T?;
  }

  // 是否过期了
  bool _isExpired(Map<String, dynamic> jsonEntry) {
    final timestamp = jsonEntry['timestamp'] as int?;
    final expiration = jsonEntry['expiration'] as int?;
    if (timestamp != null && expiration != null) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      return currentTime - timestamp > expiration;
    }
    return false;
  }

  // 检查是否超过最大限制，并写入文件
  Future<void> checkAndWriteFile(File file, String jsonString) async {
    Directory cacheDir = Directory(cachePath!);
    List<File> cacheFiles = cacheDir.listSync().whereType<File>().toList();

    if (cacheFiles.isNotEmpty) {
      // 计算缓存文件夹的总大小
      int totalSizeInBytes = 0;
      for (File file in cacheFiles) {
        totalSizeInBytes += await file.length();
      }

      Log.d(
        "totalSizeInBytes $totalSizeInBytes  maxSizeInBytes：$maxSizeInBytes",
      );

      //如果总大小超过限制，依次删除文件直到满足条件
      while (maxSizeInBytes > 0 && totalSizeInBytes > maxSizeInBytes) {
        File? fileToDelete;
        int oldestTimestamp = 0;

        for (File file in cacheDir.listSync().whereType<File>().toList()) {
          final key = path.basename(file.path);
          //取出全部的 Json 文本与对象
          final jsonString = await file.readAsString();
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>?;
          if (jsonData == null) {
            continue;
          }

          //取出对应 key 的 Json 对象
          final jsonEntry = jsonData[key] as Map<String, dynamic>?;
          if (jsonEntry == null || _isExpired(jsonEntry)) {
            fileToDelete = file;
            Log.d("FileCacheManager 找到过期的文件$file");
            break;
          } else {
            // 最进最少操作的时间戳
            final timestamp =
                (await file.lastModified()).millisecondsSinceEpoch;
            if (oldestTimestamp == 0) {
              oldestTimestamp = timestamp;
              fileToDelete = file;
            }

            if (timestamp < oldestTimestamp) {
              oldestTimestamp = timestamp;
              fileToDelete = file;
            }
          }
        }

        //遍历文件结束之后需要删除处理的逻辑
        Log.d("FileCacheManager 需要删除的文件：$fileToDelete");
        if (fileToDelete != null && await fileToDelete.exists()) {
          await fileToDelete.delete();
          break;
        } else {
          break;
        }
      } //结束While循环

      Log.d("写入的路径：$file");
      //最后写入文件
      await file.writeAsString(jsonString);
    } else {
      // 如果是空文件夹，直接写即可
      await file.writeAsString(jsonString);
    }
  }

  // 根据文件路径计算文件大小
  Future<int> _calculateSize(File file) async {
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }
}
