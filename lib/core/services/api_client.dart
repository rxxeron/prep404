import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../models/user_profile.dart';
import '../models/university_target.dart';
import '../network/resilient_api_client.dart';
import '../repositories/university_repository.dart';
import 'cache_service.dart';
import 'supabase_service.dart';

/// Network API Client for Prep404
/// Decouples network I/O from presentation layers
class ApiClient {
  static const Uuid _uuid = Uuid();
  final String baseUrl;
  final http.Client _httpClient;
  final CacheService _cache;

  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    CacheService? cache,
  })  : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _httpClient = httpClient ?? http.Client(),
        _cache = cache ?? CacheService();

  /// Headers with JSON content and optional JWT
  Map<String, String> _headers([String? token]) {
    final accessToken = token ?? SupabaseService().currentAccessToken;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }

  /// Submit Onboarding profile through Resilient Core API (with direct Supabase fallback + pending-sync tracking)
  Future<bool> submitOnboarding(UserProfile profile) async {
    final token = _cache.read<String>('auth_token') ??
        SupabaseService().currentAccessToken;
    if ((token != null && token.startsWith('guest-')) ||
        profile.id.startsWith('guest-')) {
      _cache.saveProfile(profile);
      return true;
    }

    try {
      final response = await ResilientApiClient().postWithFallback(
        '/api/v1/user/onboarding',
        headers: _headers(token),
        body: jsonEncode(profile.toJson()),
        timeout: const Duration(seconds: 7),
      );

      if (response != null &&
          response.statusCode >= 200 &&
          response.statusCode < 300) {
        _cache.write('profile_needs_cloud_sync', false);
        _cache.saveProfile(profile);
        return true;
      }
    } catch (e) {
      debugPrint('Core API onboarding submission failed, trying direct Supabase fallback: $e');
    }

    // Fallback directly to Supabase if the local server is unreachable
    try {
      final saved = await SupabaseService().saveUserProfile(profile);
      if (saved) {
        _cache.write('profile_needs_cloud_sync', false);
        _cache.saveProfile(profile);
        return true;
      }
    } catch (_) {}

    // Offline resilience: save locally and flag for automatic cloud sync on next launch
    _cache.write('profile_needs_cloud_sync', true);
    _cache.saveProfile(profile);
    return true;
  }

  /// Automatically syncs any local-only profile (or pending cloud sync) up to Supabase public.users
  Future<void> syncPendingProfileIfNeeded() async {
    final currentUser = SupabaseService().currentUser;
    if (currentUser == null) return;

    final localProfile = _cache.loadProfile();
    if (localProfile == null || localProfile.id.startsWith('guest-')) return;

    final needsSync = _cache.read<bool>('profile_needs_cloud_sync') ?? false;
    final alignedProfile = localProfile.id == currentUser.id
        ? localProfile
        : localProfile.copyWith(id: currentUser.id);

    if (needsSync) {
      await submitOnboarding(alignedProfile);
      return;
    }

    // Also heal accounts that have a local profile with academics/targets but a sparse DB row
    try {
      final remote = await SupabaseService().fetchUserProfile(currentUser.id);
      if (remote == null ||
          (remote.targetSelections.isEmpty &&
              alignedProfile.targetSelections.isNotEmpty)) {
        await submitOnboarding(alignedProfile);
      }
    } catch (_) {}
  }

  /// Fetch Candidate Profile strictly through Fastify Core API (with Supabase fallback)
  Future<UserProfile?> fetchUserProfile() async {
    final token = _cache.read<String>('auth_token') ??
        SupabaseService().currentAccessToken;
    if (token == null || token.isEmpty || token.startsWith('guest-')) {
      return null;
    }

    try {
      final response = await _httpClient
          .get(
            Uri.parse('$baseUrl/user/profile'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        if (body is Map && body['profile'] != null) {
          return UserProfile.fromJson(
              Map<String, dynamic>.from(body['profile'] as Map));
        }
      }
    } catch (e) {
      debugPrint('Core API profile fetch error: $e');
    }

    try {
      return await SupabaseService().fetchUserProfile();
    } catch (_) {
      return null;
    }
  }

  /// Fetch Private University Catalog dynamically from database
  Future<List<PrivateUniversity>> fetchUniversityCatalog() async {
    return UniversityRepository().getUniversities();
  }

  Future<List<Map<String, dynamic>>> fetchSupportRequests() async {
    final response = await _httpClient
        .get(Uri.parse('$baseUrl/support/requests'), headers: _headers())
        .timeout(const Duration(seconds: 8));
    final body = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(body is Map
          ? '${body['error'] ?? 'Support requests are unavailable.'}'
          : 'Support requests are unavailable.');
    }
    final requests = body is Map ? body['requests'] : null;
    return requests is List
        ? requests.map((row) => Map<String, dynamic>.from(row as Map)).toList()
        : <Map<String, dynamic>>[];
  }

  Future<void> submitSupportRequest({
    required String category,
    required String subject,
    required String message,
    required String idempotencyKey,
  }) async {
    final response = await _httpClient
        .post(
          Uri.parse('$baseUrl/support/requests'),
          headers: _headers(),
          body: jsonEncode({
            'category': category,
            'subject': subject.trim(),
            'message': message.trim(),
            'idempotencyKey': idempotencyKey,
          }),
        )
        .timeout(const Duration(seconds: 8));
    final body = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(body is Map
          ? '${body['error'] ?? 'Your request could not be saved.'}'
          : 'Your request could not be saved.');
    }
  }

  Future<bool?> fetchAnalyticsConsent() async {
    try {
      final response = await _httpClient
          .get(Uri.parse('$baseUrl/user/analytics-consent'), headers: _headers())
          .timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) return true;
      final body = jsonDecode(response.body);
      return body is Map ? (body['enabled'] ?? true) == true : true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> updateAnalyticsConsent(bool enabled) async {
    final response = await _httpClient
        .put(Uri.parse('$baseUrl/user/analytics-consent'),
            headers: _headers(), body: jsonEncode({'enabled': enabled}))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        body = null;
      }
      throw StateError(body is Map
          ? '${body['error'] ?? 'Analytics settings could not be saved.'}'
          : 'Analytics settings could not be saved.');
    }
    return true;
  }

  Future<List<Map<String, dynamic>>> fetchLearnerQuestionReports(
      {String? userId}) async {
    try {
      final uri = Uri.parse('$baseUrl/user/question-reports').replace(
        queryParameters: userId != null ? {'userId': userId} : null,
      );
      final response = await _httpClient
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 8));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        if (body is Map && body['reports'] is List) {
          return List<Map<String, dynamic>>.from(body['reports']);
        }
      }
    } catch (_) {}
    return const [];
  }

  Future<bool> submitLearnerQuestionReport({
    required String questionId,
    required String category,
    required String description,
    String? userId,
  }) async {
    try {
      final response = await _httpClient
          .post(
            Uri.parse('$baseUrl/user/question-reports'),
            headers: _headers(),
            body: jsonEncode({
              'questionId': questionId,
              'category': category,
              'description': description.trim(),
              if (userId != null) 'userId': userId,
            }),
          )
          .timeout(const Duration(seconds: 8));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<void> recordAppOpen() async {
    try {
      final deviceType = kIsWeb
          ? 'web'
          : switch (defaultTargetPlatform) {
              TargetPlatform.android => 'android',
              TargetPlatform.iOS => 'ios',
              _ => 'other',
            };
      const appVersion =
          String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0+1');
      final locale =
          ui.PlatformDispatcher.instance.locale.toLanguageTag().toLowerCase();
      await _httpClient
          .post(Uri.parse('$baseUrl/user/analytics-events/app-open'),
              headers: _headers(),
              body: jsonEncode({
                'deviceType': deviceType,
                'appVersion': appVersion,
                'locale': locale
              }))
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Optional analytics must never interrupt the learner experience.
    }
  }

  Future<Map<String, dynamic>> submitPracticeAttempt({
    required String questionId,
    required String selectedOptionId,
    String? attemptId,
  }) async {
    final response = await _httpClient
        .post(
          Uri.parse('$baseUrl/practice/attempts'),
          headers: _headers(),
          body: jsonEncode({
            'attemptId': attemptId ?? _uuid.v4(),
            'questionId': questionId,
            'selectedOptionId': selectedOptionId,
          }),
        )
        .timeout(const Duration(seconds: 12));
    final body = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map ? body['error']?.toString() : null;
      throw StateError(
          message ?? 'Your answer could not be scored. Try again.');
    }
    if (body is! Map<String, dynamic>) {
      throw StateError('The practice service returned an invalid response.');
    }
    return body;
  }

  Future<void> deleteAccount({required String reason}) async {
    final response = await _httpClient
        .delete(
          Uri.parse('$baseUrl/user/account'),
          headers: _headers(),
          body: jsonEncode({'reason': reason}),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        body = null;
      }
      throw StateError(body is Map
          ? '${body['error'] ?? 'Your account could not be deleted.'}'
          : 'Your account could not be deleted.');
    }
  }

  Future<void> reportTutorResponse({
    required String category,
    required String responseText,
    required String questionId,
  }) async {
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(questionId)) {
      throw StateError('This hint cannot be linked to a saved question.');
    }
    final payload = <String, dynamic>{
      'category': category,
      'responseText': responseText,
      'questionId': questionId,
    };
    final response = await _httpClient
        .post(
          Uri.parse('$baseUrl/ai/response-reports'),
          headers: _headers(),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 8));
    final body = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(body is Map
          ? '${body['error'] ?? 'This response could not be reported.'}'
          : 'This response could not be reported.');
    }
  }

  /// Submit client-side telemetry and crash logs to the Core API
  Future<bool> submitTelemetryLogs(List<Map<String, dynamic>> logs) async {
    if (logs.isEmpty) return true;
    try {
      final response = await _httpClient
          .post(
            Uri.parse('$baseUrl/telemetry/logs'),
            headers: _headers(),
            body: jsonEncode({'logs': logs}),
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Close client
  void dispose() {
    _httpClient.close();
  }
}
