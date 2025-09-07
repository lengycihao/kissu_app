import 'log_level.dart';

class LogConfig {
  final bool enableConsoleLog;
  final bool enableFileLog;
  final bool enableUpload;
  final LogLevel minLevel;
  final LogLevel minFileLevel;
  final LogLevel minUploadLevel;
  final String logDir;
  final String logFileName;
  final int maxFileSize;
  final int maxFileCount;
  final Duration uploadInterval;
  final String? uploadUrl;
  final Map<String, String>? uploadHeaders;
  final bool compressLogs;
  final Duration logRetentionDays;

  const LogConfig({
    this.enableConsoleLog = true,
    this.enableFileLog = true,
    this.enableUpload = false,
    this.minLevel = LogLevel.debug,
    this.minFileLevel = LogLevel.info,
    this.minUploadLevel = LogLevel.error,
    this.logDir = 'logs',
    this.logFileName = 'app.log',
    this.maxFileSize = 10 * 1024 * 1024, // 10MB
    this.maxFileCount = 5,
    this.uploadInterval = const Duration(hours: 1),
    this.uploadUrl,
    this.uploadHeaders,
    this.compressLogs = true,
    this.logRetentionDays = const Duration(days: 7),
  });

  LogConfig copyWith({
    bool? enableConsoleLog,
    bool? enableFileLog,
    bool? enableUpload,
    LogLevel? minLevel,
    LogLevel? minFileLevel,
    LogLevel? minUploadLevel,
    String? logDir,
    String? logFileName,
    int? maxFileSize,
    int? maxFileCount,
    Duration? uploadInterval,
    String? uploadUrl,
    Map<String, String>? uploadHeaders,
    bool? compressLogs,
    Duration? logRetentionDays,
  }) {
    return LogConfig(
      enableConsoleLog: enableConsoleLog ?? this.enableConsoleLog,
      enableFileLog: enableFileLog ?? this.enableFileLog,
      enableUpload: enableUpload ?? this.enableUpload,
      minLevel: minLevel ?? this.minLevel,
      minFileLevel: minFileLevel ?? this.minFileLevel,
      minUploadLevel: minUploadLevel ?? this.minUploadLevel,
      logDir: logDir ?? this.logDir,
      logFileName: logFileName ?? this.logFileName,
      maxFileSize: maxFileSize ?? this.maxFileSize,
      maxFileCount: maxFileCount ?? this.maxFileCount,
      uploadInterval: uploadInterval ?? this.uploadInterval,
      uploadUrl: uploadUrl ?? this.uploadUrl,
      uploadHeaders: uploadHeaders ?? this.uploadHeaders,
      compressLogs: compressLogs ?? this.compressLogs,
      logRetentionDays: logRetentionDays ?? this.logRetentionDays,
    );
  }
}
