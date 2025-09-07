import 'dart:async';
import 'log_event.dart';
import 'log_level.dart';

abstract class LogAppender {
  final String name;
  final LogLevel minLevel;

  LogAppender({required this.name, this.minLevel = LogLevel.debug});

  Future<void> initialize() async {}

  bool shouldLog(LogLevel level) => level >= minLevel;

  Future<void> append(LogEvent event);

  Future<void> dispose() async {}
}
