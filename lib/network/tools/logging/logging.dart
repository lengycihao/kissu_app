// Convenient API for logging throughout the application
export 'log_manager.dart';
export 'log_config.dart';
export 'log_level.dart';
export 'log_event.dart';

// Re-export the global logger instance for convenience
import 'log_manager.dart';

// Global logging functions for convenience
void logVerbose(
  String message, {
  String tag = 'App',
  Object? error,
  StackTrace? stackTrace,
  Map<String, dynamic>? extra,
}) => logger.verbose(
  message,
  tag: tag,
  error: error,
  stackTrace: stackTrace,
  extra: extra,
);

void logDebug(
  String message, {
  String tag = 'App',
  Object? error,
  StackTrace? stackTrace,
  Map<String, dynamic>? extra,
}) => logger.debug(
  message,
  tag: tag,
  error: error,
  stackTrace: stackTrace,
  extra: extra,
);

void logInfo(
  String message, {
  String tag = 'App',
  Object? error,
  StackTrace? stackTrace,
  Map<String, dynamic>? extra,
}) => logger.info(
  message,
  tag: tag,
  error: error,
  stackTrace: stackTrace,
  extra: extra,
);

void logWarning(
  String message, {
  String tag = 'App',
  Object? error,
  StackTrace? stackTrace,
  Map<String, dynamic>? extra,
}) => logger.warning(
  message,
  tag: tag,
  error: error,
  stackTrace: stackTrace,
  extra: extra,
);

void logError(
  String message, {
  String tag = 'App',
  Object? error,
  StackTrace? stackTrace,
  Map<String, dynamic>? extra,
}) => logger.error(
  message,
  tag: tag,
  error: error,
  stackTrace: stackTrace,
  extra: extra,
);

void logFatal(
  String message, {
  String tag = 'App',
  Object? error,
  StackTrace? stackTrace,
  Map<String, dynamic>? extra,
}) => logger.fatal(
  message,
  tag: tag,
  error: error,
  stackTrace: stackTrace,
  extra: extra,
);

// Short aliases
void logV(
  String message, {
  String tag = 'App',
  Object? error,
  StackTrace? stackTrace,
  Map<String, dynamic>? extra,
}) => logger.v(
  message,
  tag: tag,
  error: error,
  stackTrace: stackTrace,
  extra: extra,
);

void logD(
  String message, {
  String tag = 'App',
  Object? error,
  StackTrace? stackTrace,
  Map<String, dynamic>? extra,
}) => logger.d(
  message,
  tag: tag,
  error: error,
  stackTrace: stackTrace,
  extra: extra,
);

void logI(
  String message, {
  String tag = 'App',
  Object? error,
  StackTrace? stackTrace,
  Map<String, dynamic>? extra,
}) => logger.i(
  message,
  tag: tag,
  error: error,
  stackTrace: stackTrace,
  extra: extra,
);

void logW(
  String message, {
  String tag = 'App',
  Object? error,
  StackTrace? stackTrace,
  Map<String, dynamic>? extra,
}) => logger.w(
  message,
  tag: tag,
  error: error,
  stackTrace: stackTrace,
  extra: extra,
);

void logE(
  String message, {
  String tag = 'App',
  Object? error,
  StackTrace? stackTrace,
  Map<String, dynamic>? extra,
}) => logger.e(
  message,
  tag: tag,
  error: error,
  stackTrace: stackTrace,
  extra: extra,
);

void logF(
  String message, {
  String tag = 'App',
  Object? error,
  StackTrace? stackTrace,
  Map<String, dynamic>? extra,
}) => logger.f(
  message,
  tag: tag,
  error: error,
  stackTrace: stackTrace,
  extra: extra,
);
