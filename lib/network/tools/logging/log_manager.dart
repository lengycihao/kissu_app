import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'log_appender.dart';
import 'log_config.dart';
import 'log_event.dart';
import 'log_level.dart';
import 'appenders/console_appender.dart';
import 'appenders/file_appender.dart';
import 'appenders/upload_appender.dart';

class LogManager {
  static LogManager? _instance;
  static LogManager get instance => _instance ??= LogManager._();

  LogManager._();

  LogConfig _config = const LogConfig();
  final List<LogAppender> _appenders = [];
  bool _isInitialized = false;

  LogConfig get config => _config;
  bool get isInitialized => _isInitialized;

  Future<void> initialize(LogConfig config) async {
    if (_isInitialized) {
      await dispose();
    }

    _config = config;
    _appenders.clear();

    // Add console appender if enabled
    if (_config.enableConsoleLog) {
      final consoleAppender = ConsoleAppender(
        minLevel: _config.minLevel,
        useColoredOutput: true,
        showTimestamp: true,
        showTag: true,
      );
      _appenders.add(consoleAppender);
      await consoleAppender.initialize();
    }

    // Add file appender if enabled
    if (_config.enableFileLog) {
      final fileAppender = FileAppender(
        config: _config,
        minLevel: _config.minFileLevel,
      );
      _appenders.add(fileAppender);
      await fileAppender.initialize();
    }

    // Add upload appender if enabled
    if (_config.enableUpload && _config.uploadUrl != null) {
      final uploadAppender = UploadAppender(
        config: _config,
        minLevel: _config.minUploadLevel,
      );
      _appenders.add(uploadAppender);
      await uploadAppender.initialize();
    }

    _isInitialized = true;
  }

  void _log(
    LogLevel level,
    String message,
    String tag, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('[LogManager] Not initialized. Message: $message');
      }
      return;
    }

    final event = LogEvent(
      level: level,
      message: message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      extra: extra,
    );

    for (final appender in _appenders) {
      if (appender.shouldLog(level)) {
        // Don't await to avoid blocking the calling code
        appender.append(event).catchError((error) {
          if (kDebugMode) {
            print('[LogManager] Error in appender ${appender.name}: $error');
          }
        });
      }
    }
  }

  // Convenience methods for different log levels
  void verbose(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    _log(
      LogLevel.verbose,
      message,
      tag,
      error: error,
      stackTrace: stackTrace,
      extra: extra,
    );
  }

  void debug(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    _log(
      LogLevel.debug,
      message,
      tag,
      error: error,
      stackTrace: stackTrace,
      extra: extra,
    );
  }

  void info(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    _log(
      LogLevel.info,
      message,
      tag,
      error: error,
      stackTrace: stackTrace,
      extra: extra,
    );
  }

  void warning(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    _log(
      LogLevel.warning,
      message,
      tag,
      error: error,
      stackTrace: stackTrace,
      extra: extra,
    );
  }

  void error(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    _log(
      LogLevel.error,
      message,
      tag,
      error: error,
      stackTrace: stackTrace,
      extra: extra,
    );
  }

  void fatal(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    _log(
      LogLevel.fatal,
      message,
      tag,
      error: error,
      stackTrace: stackTrace,
      extra: extra,
    );
  }

  // Convenience methods with shorter names
  void v(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) => verbose(
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
    extra: extra,
  );

  void d(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) => debug(
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
    extra: extra,
  );

  void i(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) => info(
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
    extra: extra,
  );

  void w(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) => warning(
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
    extra: extra,
  );

  void e(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) => this.error(
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
    extra: extra,
  );

  void f(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) => fatal(
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
    extra: extra,
  );

  // Advanced methods
  Future<void> forceUpload() async {
    for (final appender in _appenders) {
      if (appender is UploadAppender) {
        await appender.forceUpload();
      }
    }
  }

  Future<List<File>> getLogFiles() async {
    for (final appender in _appenders) {
      if (appender is FileAppender) {
        return await appender.getLogFiles();
      }
    }
    return [];
  }

  Future<String> readLogFile(File file) async {
    for (final appender in _appenders) {
      if (appender is FileAppender) {
        return await appender.readLogFile(file);
      }
    }
    return '';
  }

  Future<List<LogEvent>> readLogEvents(File file) async {
    for (final appender in _appenders) {
      if (appender is FileAppender) {
        return await appender.readLogEvents(file);
      }
    }
    return [];
  }

  Future<void> clearLogs() async {
    for (final appender in _appenders) {
      if (appender is FileAppender) {
        await appender.clearLogs();
      }
    }
  }

  Future<void> uploadLogFile(File logFile) async {
    for (final appender in _appenders) {
      if (appender is UploadAppender) {
        await appender.uploadLogFile(logFile);
        break;
      }
    }
  }

  Future<void> dispose() async {
    for (final appender in _appenders) {
      await appender.dispose();
    }
    _appenders.clear();
    _isInitialized = false;
  }
}

// Global instance for convenience
final logger = LogManager.instance;
