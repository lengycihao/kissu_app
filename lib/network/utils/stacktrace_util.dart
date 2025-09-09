import 'dart:math';

class StacktraceUtil {
  static final _deviceStackTraceRegex = RegExp(r'#[0-9]+\s+(.+) \((\S+)\)');
  static final _webStackTraceRegex = RegExp(r'^((packages|dart-sdk)/\S+/)');
  static final _browserStackTraceRegex = RegExp(
    r'^(?:package:)?(dart:\S+|\S+)',
  );

  static String format(StackTrace stackTrace, int methodCount) {
    List<String> lines = stackTrace
        .toString()
        .split('\n')
        .where(
          (line) =>
              !_discardDeviceStacktraceLine(line) &&
              !_discardWebStacktraceLine(line) &&
              !_discardBrowserStacktraceLine(line) &&
              line.isNotEmpty,
        )
        .toList();

    if (lines.isEmpty) return "";
    List<String> formatted = [];
    for (int count = 0; count < min(lines.length, methodCount); count++) {
      var line = lines[count];
      if (count < 0) {
        continue;
      }
      formatted.add('#$count   ${line.replaceFirst(RegExp(r'#\d+\s+'), '')}');
    }
    return formatted.join('\n');
  }

  static bool _discardDeviceStacktraceLine(String line) {
    var match = _deviceStackTraceRegex.matchAsPrefix(line);
    if (match == null) {
      return false;
    }
    final segment = match.group(2)!;
    if (segment.startsWith('package:logger')) {
      return true;
    }
    return false;
  }

  static bool _discardWebStacktraceLine(String line) {
    var match = _webStackTraceRegex.matchAsPrefix(line);
    if (match == null) {
      return false;
    }
    final segment = match.group(1)!;
    if (segment.startsWith('packages/logger') ||
        segment.startsWith('dart-sdk/lib')) {
      return true;
    }
    return false;
  }

  static bool _discardBrowserStacktraceLine(String line) {
    var match = _browserStackTraceRegex.matchAsPrefix(line);
    if (match == null) {
      return false;
    }
    final segment = match.group(1)!;
    if (segment.startsWith('package:logger') || segment.startsWith('dart:')) {
      return true;
    }
    return false;
  }
}
