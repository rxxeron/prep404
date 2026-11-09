import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Central Resilient Network Client for Prep404
/// Automatically iterates over candidate hosts with timeout and fallback heuristics
class ResilientApiClient {
  static final ResilientApiClient _instance = ResilientApiClient._internal();
  factory ResilientApiClient() => _instance;
  ResilientApiClient._internal();

  final http.Client _client = http.Client();

  /// Global notifiers for app-wide reactive state management
  static final ValueNotifier<bool> sessionExpiredNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> slowNetworkNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> offlineNotifier = ValueNotifier<bool>(false);

  Map<String, String> get defaultHeaders => {
        'X-Prep404-App-Client': 'prep404-mobile-app',
        'Accept': 'application/json',
      };

  /// Executes GET request across all candidate API hosts until first success
  Future<http.Response?> getWithFallback(
    String endpointPath, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final cleanPath = endpointPath.startsWith('/') ? endpointPath : '/$endpointPath';
    final candidateHosts = AppConfig.candidateApiHosts;

    for (final host in candidateHosts) {
      try {
        final uri = Uri.parse('$host$cleanPath');
        final mergedHeaders = {
          ...defaultHeaders,
          if (headers != null) ...headers,
        };
        final res = await _client.get(uri, headers: mergedHeaders).timeout(timeout);
        if (res.statusCode == 401) {
          sessionExpiredNotifier.value = true;
        }
        if (res.statusCode >= 200 && res.statusCode < 500) {
          slowNetworkNotifier.value = false;
          offlineNotifier.value = false;
          return res;
        }
      } on TimeoutException {
        slowNetworkNotifier.value = true;
      } catch (_) {
        offlineNotifier.value = true;
      }
    }
    return null;
  }

  /// Executes POST request across candidate API hosts
  Future<http.Response?> postWithFallback(
    String endpointPath, {
    Object? body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final cleanPath = endpointPath.startsWith('/') ? endpointPath : '/$endpointPath';
    final candidateHosts = AppConfig.candidateApiHosts;

    for (final host in candidateHosts) {
      try {
        final uri = Uri.parse('$host$cleanPath');
        final mergedHeaders = {
          ...defaultHeaders,
          'Content-Type': 'application/json',
          if (headers != null) ...headers,
        };
        final res = await _client
            .post(uri, headers: mergedHeaders, body: body)
            .timeout(timeout);
        if (res.statusCode == 401) {
          sessionExpiredNotifier.value = true;
        }
        if (res.statusCode >= 200 && res.statusCode < 500) {
          slowNetworkNotifier.value = false;
          offlineNotifier.value = false;
          return res;
        }
      } on TimeoutException {
        slowNetworkNotifier.value = true;
      } catch (_) {
        offlineNotifier.value = true;
      }
    }
    return null;
  }
}
