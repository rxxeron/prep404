import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'supabase_service.dart';

/// Client-side Telemetry & Crash Reporting Service
/// Buffers non-critical logs and immediately dispatches crashes/errors to the server.
class TelemetryService {
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  TelemetryService._internal();

  final List<Map<String, dynamic>> _buffer = [];
  Timer? _flushTimer;
  bool _isFlushing = false;
  static const int _bufferLimit = 20;

  void init() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      flush();
    });

    // Hook Flutter UI framework errors
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      logError(
        details.exceptionAsString(),
        stackTrace: details.stack?.toString(),
        event: 'flutter_framework_error',
      );
      originalOnError?.call(details);
    };

    // Hook platform / async unhandled errors
    PlatformDispatcher.instance.onError = (error, stack) {
      logCrash(
        error.toString(),
        stackTrace: stack.toString(),
        event: 'unhandled_platform_crash',
      );
      return true;
    };
  }

  void logInfo(String event, {String? message, Map<String, dynamic>? metadata}) {
    _record(level: 'info', event: event, message: message, metadata: metadata);
  }

  void logWarn(String event, {String? message, Map<String, dynamic>? metadata}) {
    _record(level: 'warn', event: event, message: message, metadata: metadata);
  }

  void logError(
    String message, {
    String? stackTrace,
    String event = 'app_error',
    Map<String, dynamic>? metadata,
  }) {
    _record(
      level: 'error',
      event: event,
      message: message,
      errorStack: stackTrace,
      metadata: metadata,
      flushImmediately: true,
    );
  }

  void logCrash(
    String message, {
    String? stackTrace,
    String event = 'app_fatal_crash',
    Map<String, dynamic>? metadata,
  }) {
    _record(
      level: 'crash',
      event: event,
      message: message,
      errorStack: stackTrace,
      metadata: metadata,
      flushImmediately: true,
    );
  }

  void _record({
    required String level,
    required String event,
    String? message,
    String? errorStack,
    Map<String, dynamic>? metadata,
    bool flushImmediately = false,
  }) {
    final userId = SupabaseService().currentUser?.id;
    final logItem = {
      'occurredAt': DateTime.now().toUtc().toIso8601String(),
      'level': level,
      'source': 'app',
      'userId': userId,
      'event': event,
      'message': message,
      'errorStack': errorStack,
      'metadata': {
        ...?metadata,
        'platform': defaultTargetPlatform.name,
        'kIsWeb': kIsWeb,
      },
    };

    _buffer.add(logItem);

    if (flushImmediately || _buffer.length >= _bufferLimit) {
      flush();
    }
  }

  Future<void> flush() async {
    if (_isFlushing || _buffer.isEmpty) return;
    _isFlushing = true;

    final batch = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();

    try {
      final success = await ApiClient().submitTelemetryLogs(batch);
      if (!success) {
        // Re-queue up to half the limit to prevent memory unbounded growth
        if (_buffer.length < _bufferLimit) {
          _buffer.addAll(batch.take(10));
        }
      }
    } catch (_) {
      if (_buffer.length < _bufferLimit) {
        _buffer.addAll(batch.take(10));
      }
    } finally {
      _isFlushing = false;
    }
  }

  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }
}
