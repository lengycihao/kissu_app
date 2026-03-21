import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../log_appender.dart';
import '../log_config.dart';
import '../log_event.dart';
import '../log_level.dart';

/// 每个日志分类对应的文件状态
class _CategoryFileState {
  File? file;
  IOSink? sink;
  int currentSize = 0;
  /// 当前文件对应的日期（yyyy-MM-dd），用于跨天自动切换文件
  String? fileDate;
}

class FileAppender extends LogAppender {
  final LogConfig config;
  late Directory _logDirectory;
  final Completer<void> _initCompleter = Completer<void>();
  Completer<void>? _writeLock;

  /// 按分类维护独立的文件状态：key = 分类名（'app', 'location', 'app_usage'）
  final Map<String, _CategoryFileState> _categoryStates = {};

  /// 定期 flush 定时器
  Timer? _flushTimer;

  FileAppender({
    required this.config,
    super.name = 'FileAppender',
    LogLevel? minLevel,
  }) : super(minLevel: minLevel ?? config.minFileLevel);

  @override
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationSupportDirectory();
      _logDirectory = Directory(
        '${appDir.path}${Platform.pathSeparator}${config.logDir}',
      );

      if (!await _logDirectory.exists()) {
        await _logDirectory.create(recursive: true);
      }

      await _cleanOldLogs();
      _startFlushTimer();

      _initCompleter.complete();
    } catch (e) {
      _initCompleter.completeError(e);
    }
  }

  /// 根据 LogEvent 的 tag 确定日志分类名
  String _getCategoryName(LogEvent event) {
    final tagLower = event.tag.toLowerCase();
    for (final category in config.logCategories) {
      for (final pattern in category.tagPatterns) {
        if (tagLower.contains(pattern.toLowerCase())) {
          return category.name;
        }
      }
    }
    // 默认分类：app
    return 'app';
  }

  /// 获取分类对应的文件后缀名
  String _getFileSuffix(String categoryName) {
    return '_$categoryName.log';
  }

  @override
  Future<void> append(LogEvent event) async {
    await _initCompleter.future;

    // 🔥 如果正在写入，等待当前写入完成
    while (_writeLock != null) {
      await _writeLock!.future;
    }

    // 🔥 获取写入锁
    _writeLock = Completer<void>();
    try {
      await _writeEvent(event);
    } finally {
      // 🔥 释放写入锁
      final lock = _writeLock;
      _writeLock = null;
      lock?.complete();
    }
  }

  Future<void> _writeEvent(LogEvent event) async {
    final categoryName = _getCategoryName(event);
    final state = _getOrCreateState(categoryName);
    final today = _todayString();

    // 🔥 跨天自动切换文件
    if (state.fileDate != null && state.fileDate != today) {
      await _closeSink(state);
    }

    // 打开或复用今天的文件
    if (state.sink == null) {
      await _openFileForCategory(categoryName, state);
    }

    final jsonLine = '${jsonEncode(event.toJson())}\n';
    final bytes = utf8.encode(jsonLine);

    state.sink?.add(bytes);
    state.currentSize += bytes.length;

    // 文件大小超限时轮转
    if (state.currentSize >= config.maxFileSize) {
      await state.sink?.flush();
      await _rotateCategory(categoryName, state);
    }
  }

  _CategoryFileState _getOrCreateState(String categoryName) {
    return _categoryStates.putIfAbsent(categoryName, () => _CategoryFileState());
  }

  /// 🔥 复用今天已有的日志文件，避免创建大量小文件
  Future<void> _openFileForCategory(String categoryName, _CategoryFileState state) async {
    if (state.sink != null) return;

    final today = _todayString();
    final suffix = _getFileSuffix(categoryName);

    // 查找今天已有的该分类日志文件
    File? existingFile;
    try {
      final files = _logDirectory.listSync().whereType<File>();
      for (final f in files) {
        final name = f.path.split(Platform.pathSeparator).last;
        if (name.startsWith(today) && name.endsWith(suffix)) {
          existingFile = f;
          break;
        }
      }
    } catch (_) {}

    if (existingFile != null) {
      state.file = existingFile;
      state.currentSize = await existingFile.length();
    } else {
      // 创建新文件
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = '$timestamp$suffix';
      state.file = File(
        '${_logDirectory.path}${Platform.pathSeparator}$fileName',
      );
      state.currentSize = 0;
    }

    state.fileDate = today;
    state.sink = state.file!.openWrite(mode: FileMode.writeOnlyAppend);
  }

  /// 文件大小超限时轮转：关闭当前文件，创建新文件
  Future<void> _rotateCategory(String categoryName, _CategoryFileState state) async {
    await _closeSink(state);

    final suffix = _getFileSuffix(categoryName);
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = '$timestamp$suffix';
    state.file = File(
      '${_logDirectory.path}${Platform.pathSeparator}$fileName',
    );
    state.currentSize = 0;
    state.fileDate = _todayString();
    state.sink = state.file!.openWrite(mode: FileMode.writeOnlyAppend);

    // 清理该分类的旧文件
    await _cleanOldFilesForCategory(categoryName);
  }

  /// 清理某个分类下超出数量限制的旧文件
  Future<void> _cleanOldFilesForCategory(String categoryName) async {
    final suffix = _getFileSuffix(categoryName);
    final categoryFiles = _logDirectory
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith(suffix))
        .toList();

    if (categoryFiles.length > config.maxFileCount) {
      categoryFiles.sort(
        (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
      );
      for (int i = 0; i < categoryFiles.length - config.maxFileCount; i++) {
        try {
          await categoryFiles[i].delete();
        } catch (_) {}
      }
    }
  }

  Future<void> _cleanOldLogs() async {
    final cutoffTime = DateTime.now().subtract(config.logRetentionDays);
    final logFiles = await _getLogFiles();

    for (final file in logFiles) {
      try {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoffTime)) {
          await file.delete();
        }
      } catch (e) {
        // Ignore errors when cleaning old logs
      }
    }
  }

  Future<List<File>> _getLogFiles() async {
    if (!await _logDirectory.exists()) {
      return [];
    }

    return _logDirectory
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.log'))
        .toList();
  }

  Future<List<File>> getLogFiles() async {
    await _initCompleter.future;
    return _getLogFiles();
  }

  /// 获取指定分类的日志文件
  Future<List<File>> getLogFilesByCategory(String categoryName) async {
    await _initCompleter.future;
    final suffix = _getFileSuffix(categoryName);
    if (!await _logDirectory.exists()) return [];
    return _logDirectory
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith(suffix))
        .toList();
  }

  Future<String> readLogFile(File file) async {
    if (!await file.exists()) {
      return '';
    }
    return file.readAsString();
  }

  Future<List<LogEvent>> readLogEvents(File file) async {
    final content = await readLogFile(file);
    if (content.isEmpty) {
      return [];
    }

    final lines = content.split('\n').where((line) => line.isNotEmpty);
    final events = <LogEvent>[];

    for (final line in lines) {
      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        final event = LogEvent(
          level: LogLevel.values.firstWhere((l) => l.name == json['level']),
          message: json['message'] ?? '',
          tag: json['tag'] ?? '',
          timestamp: DateTime.parse(json['timestamp']),
          error: json['error'],
          stackTrace: json['stackTrace'] != null
              ? StackTrace.fromString(json['stackTrace'])
              : null,
          extra: json['extra'],
        );
        events.add(event);
      } catch (e) {
        // Skip malformed log entries
        continue;
      }
    }

    return events;
  }

  Future<void> clearLogs() async {
    await _initCompleter.future;

    for (final state in _categoryStates.values) {
      await _closeSink(state);
      state.file = null;
      state.currentSize = 0;
      state.fileDate = null;
    }
    _categoryStates.clear();

    final logFiles = await _getLogFiles();
    for (final file in logFiles) {
      try {
        await file.delete();
      } catch (e) {
        // Ignore deletion errors
      }
    }
  }

  /// 🔥 定期 flush，防止数据丢失
  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(config.flushInterval, (_) async {
      await flushAll();
    });
  }

  /// flush 所有分类的 sink
  Future<void> flushAll() async {
    for (final state in _categoryStates.values) {
      try {
        await state.sink?.flush();
      } catch (_) {}
    }
  }

  Future<void> _closeSink(_CategoryFileState state) async {
    try {
      await state.sink?.flush();
      await state.sink?.close();
    } catch (_) {}
    state.sink = null;
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> dispose() async {
    _flushTimer?.cancel();
    _flushTimer = null;

    for (final state in _categoryStates.values) {
      await _closeSink(state);
    }
    _categoryStates.clear();
  }
}
