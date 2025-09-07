import 'log_level.dart';

class LogEvent {
  final LogLevel level;
  final String message;
  final String tag;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? extra;

  LogEvent({
    required this.level,
    required this.message,
    required this.tag,
    DateTime? timestamp,
    this.error,
    this.stackTrace,
    this.extra,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'message': message,
      'tag': tag,
      'timestamp': timestamp.toIso8601String(),
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
      'extra': extra,
    };
  }

  String toFormattedString() {
    final buffer = StringBuffer();
    buffer.write('[${level.shortName}]');
    buffer.write('[${timestamp.toIso8601String()}]');
    buffer.write('[$tag]');
    buffer.write(' $message');

    if (error != null) {
      buffer.write('\n  Error: $error');
    }

    if (stackTrace != null) {
      buffer.write('\n  StackTrace:\n$stackTrace');
    }

    if (extra != null && extra!.isNotEmpty) {
      buffer.write('\n  Extra: $extra');
    }

    return buffer.toString();
  }
}
