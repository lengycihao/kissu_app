import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../log_appender.dart';
import '../log_event.dart';
import '../log_level.dart';

class ConsoleAppender extends LogAppender {
  final bool useColoredOutput;
  final bool showTimestamp;
  final bool showTag;

  ConsoleAppender({
    super.name = 'ConsoleAppender',
    super.minLevel = LogLevel.debug,
    this.useColoredOutput = true,
    this.showTimestamp = true,
    this.showTag = true,
  });

  @override
  Future<void> append(LogEvent event) async {
    if (!kDebugMode) return; // Only log to console in debug mode

    final formattedMessage = _formatMessage(event);

    if (useColoredOutput) {
      final coloredMessage = _applyColor(formattedMessage, event.level);
      if (kDebugMode) {
        print(coloredMessage);
      }
    } else {
      if (kDebugMode) {
        print(formattedMessage);
      }
    }

    // Also log to developer console for better integration with Flutter tools
    developer.log(
      event.message,
      time: event.timestamp,
      level: _getDeveloperLogLevel(event.level),
      name: event.tag,
      error: event.error,
      stackTrace: event.stackTrace,
    );
  }

  String _formatMessage(LogEvent event) {
    final buffer = StringBuffer();

    if (showTimestamp) {
      buffer.write('[${_formatTimestamp(event.timestamp)}] ');
    }

    buffer.write('[${event.level.shortName}] ');

    if (showTag) {
      buffer.write('[${event.tag}] ');
    }

    buffer.write(event.message);

    if (event.error != null) {
      buffer.write(' | Error: ${event.error}');
    }

    if (event.extra != null && event.extra!.isNotEmpty) {
      buffer.write(' | Extra: ${event.extra}');
    }

    return buffer.toString();
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }

  String _applyColor(String message, LogLevel level) {
    const String reset = '\x1B[0m';
    String color;

    switch (level) {
      case LogLevel.verbose:
        color = '\x1B[37m'; // White
        break;
      case LogLevel.debug:
        color = '\x1B[36m'; // Cyan
        break;
      case LogLevel.info:
        color = '\x1B[32m'; // Green
        break;
      case LogLevel.warning:
        color = '\x1B[33m'; // Yellow
        break;
      case LogLevel.error:
        color = '\x1B[31m'; // Red
        break;
      case LogLevel.fatal:
        color = '\x1B[35m'; // Magenta
        break;
    }

    return '$color$message$reset';
  }

  int _getDeveloperLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return 500;
      case LogLevel.debug:
        return 700;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.fatal:
        return 1200;
    }
  }
}
