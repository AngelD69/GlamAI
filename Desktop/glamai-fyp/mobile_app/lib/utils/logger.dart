import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static const String _reset = '\x1B[0m';
  static const String _grey = '\x1B[90m';
  static const String _cyan = '\x1B[36m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';

  static void debug(String tag, String message) =>
      _log(LogLevel.debug, tag, message);

  static void info(String tag, String message) =>
      _log(LogLevel.info, tag, message);

  static void warning(String tag, String message) =>
      _log(LogLevel.warning, tag, message);

  static void error(String tag, String message, [Object? exception, StackTrace? stack]) {
    _log(LogLevel.error, tag, message);
    if (exception != null) _log(LogLevel.error, tag, 'Exception: $exception');
    if (stack != null && kDebugMode) {
      debugPrint('$_red$stack$_reset');
    }
  }

  static void _log(LogLevel level, String tag, String message) {
    if (!kDebugMode) return; // suppress logs in release builds
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final color = _colorFor(level);
    final label = _labelFor(level);
    debugPrint('$color[$time][$label][$tag] $message$_reset');
  }

  static String _colorFor(LogLevel level) => switch (level) {
        LogLevel.debug => _grey,
        LogLevel.info => _cyan,
        LogLevel.warning => _yellow,
        LogLevel.error => _red,
      };

  static String _labelFor(LogLevel level) => switch (level) {
        LogLevel.debug => 'DEBUG',
        LogLevel.info => 'INFO ',
        LogLevel.warning => 'WARN ',
        LogLevel.error => 'ERROR',
      };
}
