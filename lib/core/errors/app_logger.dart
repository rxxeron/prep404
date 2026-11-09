import 'package:flutter/foundation.dart';

/// Lightweight logging abstraction for Prep404
class AppLogger {
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[Prep404 ERROR] $message${error != null ? ': $error' : ''}');
      if (stackTrace != null) debugPrint('$stackTrace');
    }
  }

  static void warn(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[Prep404 WARN] $message${error != null ? ': $error' : ''}');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[Prep404 INFO] $message');
    }
  }
}
