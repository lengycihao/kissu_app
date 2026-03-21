import 'log_level.dart';

/// 日志分类定义
class LogCategory {
  /// 分类名称（用于文件后缀，如 'location' -> _location.log）
  final String name;
  /// 匹配的 tag 列表（包含匹配，不区分大小写）
  final List<String> tagPatterns;

  const LogCategory({required this.name, required this.tagPatterns});
}

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

  /// 日志分类列表，按优先级匹配（先匹配到的分类优先）
  /// 未匹配到任何分类的日志写入默认文件（logFileName, 即 _app.log）
  final List<LogCategory> logCategories;

  /// 定期 flush 间隔，防止数据丢失
  final Duration flushInterval;

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
    this.logCategories = const [
      LogCategory(
        name: 'location',
        tagPatterns: ['Location', 'NativeLocation', 'NativeKeepAlive', 'ForegroundLocation', 'Geofence'],
      ),
      LogCategory(
        name: 'app_usage',
        tagPatterns: ['AppUsage', 'NativeAppUsage', 'AppUsageReportService', 'AppUsageAutoReportService', 'ScreenUsage'],
      ),
    ],
    this.flushInterval = const Duration(seconds: 30),
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
    List<LogCategory>? logCategories,
    Duration? flushInterval,
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
      logCategories: logCategories ?? this.logCategories,
      flushInterval: flushInterval ?? this.flushInterval,
    );
  }
}
