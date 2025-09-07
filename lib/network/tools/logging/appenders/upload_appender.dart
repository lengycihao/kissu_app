import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../log_appender.dart';
import '../log_config.dart';
import '../log_event.dart';
import '../log_level.dart';

class UploadAppender extends LogAppender {
  final LogConfig config;
  final Dio _dio;
  final List<LogEvent> _pendingEvents = [];
  Timer? _uploadTimer;
  bool _isUploading = false;

  UploadAppender({
    required this.config,
    Dio? dio,
    super.name = 'UploadAppender',
    LogLevel? minLevel,
  }) : _dio = dio ?? Dio(),
       super(minLevel: minLevel ?? config.minUploadLevel);

  @override
  Future<void> initialize() async {
    if (config.enableUpload && config.uploadUrl != null) {
      _setupPeriodicUpload();
    }
  }

  void _setupPeriodicUpload() {
    _uploadTimer = Timer.periodic(config.uploadInterval, (_) {
      _uploadPendingLogs();
    });
  }

  @override
  Future<void> append(LogEvent event) async {
    if (!config.enableUpload || config.uploadUrl == null) {
      return;
    }

    _pendingEvents.add(event);

    // If we have too many pending events, trigger immediate upload
    if (_pendingEvents.length >= 100) {
      unawaited(_uploadPendingLogs());
    }
  }

  Future<void> _uploadPendingLogs() async {
    if (_isUploading || _pendingEvents.isEmpty) {
      return;
    }

    _isUploading = true;
    final eventsToUpload = List<LogEvent>.from(_pendingEvents);
    _pendingEvents.clear();

    try {
      await _uploadEvents(eventsToUpload);
    } catch (e) {
      // If upload fails, add events back to the queue (up to a limit)
      if (_pendingEvents.length < 1000) {
        _pendingEvents.insertAll(0, eventsToUpload);
      }
    } finally {
      _isUploading = false;
    }
  }

  Future<void> _uploadEvents(List<LogEvent> events) async {
    if (config.uploadUrl == null) {
      return;
    }

    final payload = {
      'logs': events.map((e) => e.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
      'device_info': await _getDeviceInfo(),
    };

    final options = Options(
      headers: {'Content-Type': 'application/json', ...?config.uploadHeaders},
    );

    await _dio.post(config.uploadUrl!, data: payload, options: options);
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'dart_version': Platform.version,
    };
  }

  Future<void> uploadLogFile(File logFile) async {
    if (config.uploadUrl == null) {
      throw Exception('Upload URL not configured');
    }

    if (!await logFile.exists()) {
      throw Exception('Log file does not exist');
    }

    final fileName = logFile.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(logFile.path, filename: fileName),
      'timestamp': DateTime.now().toIso8601String(),
      'device_info': jsonEncode(await _getDeviceInfo()),
    });

    final options = Options(headers: config.uploadHeaders);

    await _dio.post(
      '${config.uploadUrl}/upload-file',
      data: formData,
      options: options,
    );
  }

  Future<void> forceUpload() async {
    await _uploadPendingLogs();
  }

  @override
  Future<void> dispose() async {
    _uploadTimer?.cancel();
    await _uploadPendingLogs(); // Try to upload any remaining logs
    _dio.close();
  }
}
