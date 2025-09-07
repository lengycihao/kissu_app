import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sprintf/sprintf.dart';
import 'dart:convert';
import 'dart:io';

// ignore: non_constant_identifier_names
final Log = LogUtil.instance;

class LogUtil {
  LogUtil._();

  static LogUtil? _instance;
  late final Logger _logger;
  late final Logger _fileLogger;
  late final String _logPath;

  static LogUtil get instance => _instance ??= LogUtil._();

  Future<void> init() async {
    _logger = Logger();
    try {
      final dir = await getApplicationSupportDirectory();
      _logPath =
          "${dir.path}${Platform.pathSeparator}log${Platform.pathSeparator}ydlog.txt";
      final file = File(_logPath);
      await file.create(recursive: true);
      final lastModifiedDateTime = await file.lastModified();
      final nowDateTime = DateTime.now();
      final duration = nowDateTime.difference(lastModifiedDateTime);
      if (duration.inHours >= 72) {
        await file.writeAsString("", mode: FileMode.writeOnly, flush: true);
        await file.setLastModified(nowDateTime);
      }
      _fileLogger = Logger(
        output: _FileLogOutput(file: file),
        printer: _FileLogPrinter(),
      );
      // _fileLogger = Logger(output: _FileLogOutput(file: file));
    } catch (e) {
      _logger.e('Error: $e');
    }
  }

  // Future<String?> uploadLogFile() async {
  //   final file = File(_logPath);
  //   final exists = await file.exists();
  //   if (!exists) return null;
  //   final content = await file.readAsString();
  //   if (content.trim().isEmpty) return null;

  //   final time = DateTime.now();
  //   final timeNow = sprintf('%02i%02i%02i_%02i%02i%02i', [time.year, time.month, time.day, time.hour, time.minute, time.second]);
  //   final tempPath = _logPath.replaceFirst(".txt", "_$timeNow.txt");
  //   final tempFile = await file.copy(tempPath);
  //   var ossFilePath = await OssUploadManager.getInstance().uploadLogFile(tempFile);
  //   await tempFile.delete();
  //   return ossFilePath;
  // }

  Future<List<String>> readFileLogAsLines() async {
    final filepath = _logPath;
    final file = File(filepath);
    final exists = await file.exists();
    if (!exists) return [];
    return await file.readAsLines();
  }

  Future<void> clearFileLog() async {
    final filepath = _logPath;
    final file = File(filepath);
    final exists = await file.exists();
    if (!exists) return;
    await file.writeAsString("", mode: FileMode.writeOnly, flush: true);
    await file.setLastModified(DateTime.now());
  }

  void i(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    bool writeFile = false,
  }) {
    _logger.i(message, time: time, error: error, stackTrace: stackTrace);
    if (!writeFile) return;
    _fileLogger.i(
      message,
      time: time ?? DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  void d(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    bool writeFile = false,
  }) {
    _logger.d(message, time: time, error: error, stackTrace: stackTrace);
    if (!writeFile) return;
    _fileLogger.d(
      message,
      time: time ?? DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  void e(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    bool writeFile = true,
  }) {
    _logger.e(message, time: time, error: error, stackTrace: stackTrace);
    if (!writeFile) return;
    final dateTime = DateTime.now().toString();
    final content = "❌ [$dateTime]: $message";
    _fileLogger.e(
      content,
      time: time ?? DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }
}

class _FileLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    if (event.error != null && event.stackTrace != null) {
      return [
        event.message.toString(),
        event.error.toString(),
        event.stackTrace.toString(),
      ];
    }
    if (event.error != null) {
      return [event.message.toString(), event.error.toString()];
    }
    if (event.stackTrace != null) {
      return [event.message.toString(), event.stackTrace.toString()];
    }
    return [event.message.toString()];
  }
}

class _FileLogOutput extends LogOutput {
  final File file;
  IOSink? _sink;

  _FileLogOutput({required this.file});

  @override
  Future<void> init() async {
    _sink = file.openWrite(mode: FileMode.writeOnlyAppend, encoding: utf8);
  }

  @override
  void output(OutputEvent event) {
    if (event.lines.isNotEmpty) {
      _sink?.writeAll(event.lines, '\n');
      _sink?.writeln();
    }
  }

  @override
  Future<void> destroy() async {
    await _sink?.flush();
    await _sink?.close();
  }
}
