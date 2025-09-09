import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../log_appender.dart';
import '../log_config.dart';
import '../log_event.dart';
import '../log_level.dart';

class FileAppender extends LogAppender {
  final LogConfig config;
  late Directory _logDirectory;
  File? _currentLogFile;
  IOSink? _sink;
  int _currentFileSize = 0;
  final Completer<void> _initCompleter = Completer<void>();

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

      await _rotateLogIfNeeded();
      await _cleanOldLogs();

      _initCompleter.complete();
    } catch (e) {
      _initCompleter.completeError(e);
    }
  }

  @override
  Future<void> append(LogEvent event) async {
    await _initCompleter.future;

    if (_sink == null) {
      await _openCurrentFile();
    }

    final jsonLine = '${jsonEncode(event.toJson())}\n';
    final bytes = utf8.encode(jsonLine);

    _sink?.add(bytes);
    await _sink?.flush();

    _currentFileSize += bytes.length;

    if (_currentFileSize >= config.maxFileSize) {
      await _rotateLogIfNeeded();
    }
  }

  Future<void> _openCurrentFile() async {
    if (_currentLogFile == null) {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = '${timestamp}_${config.logFileName}';
      _currentLogFile = File(
        '${_logDirectory.path}${Platform.pathSeparator}$fileName',
      );

      if (await _currentLogFile!.exists()) {
        _currentFileSize = await _currentLogFile!.length();
      } else {
        _currentFileSize = 0;
      }
    }

    _sink = _currentLogFile!.openWrite(mode: FileMode.writeOnlyAppend);
  }

  Future<void> _rotateLogIfNeeded() async {
    await _sink?.close();
    _sink = null;

    // Create new log file
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = '${timestamp}_${config.logFileName}';
    _currentLogFile = File(
      '${_logDirectory.path}${Platform.pathSeparator}$fileName',
    );
    _currentFileSize = 0;

    await _openCurrentFile();

    // Remove old files if we exceed the max count
    final logFiles = await _getLogFiles();
    if (logFiles.length > config.maxFileCount) {
      // Sort by creation time and remove oldest
      logFiles.sort(
        (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
      );
      for (int i = 0; i < logFiles.length - config.maxFileCount; i++) {
        try {
          await logFiles[i].delete();
        } catch (e) {
          // Ignore deletion errors
        }
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
        .where(
          (f) => f.path.endsWith('.log') || f.path.contains(config.logFileName),
        )
        .toList();
  }

  Future<List<File>> getLogFiles() async {
    await _initCompleter.future;
    return _getLogFiles();
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

    await _sink?.close();
    _sink = null;

    final logFiles = await _getLogFiles();
    for (final file in logFiles) {
      try {
        await file.delete();
      } catch (e) {
        // Ignore deletion errors
      }
    }

    _currentLogFile = null;
    _currentFileSize = 0;
  }

  @override
  Future<void> dispose() async {
    await _sink?.close();
    _sink = null;
  }
}
