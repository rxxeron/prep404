import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized Environment Configuration for Prep404.
/// All secrets and endpoints are dynamically loaded from the `.env` file.
class AppConfig {
  AppConfig._();

  static String _get(String key, {String defaultValue = ''}) {
    if (dotenv.isInitialized) {
      final value = dotenv.env[key];
      if (value != null && value.isNotEmpty) return value;
    }
    final fromEnv = String.fromEnvironment(key);
    if (fromEnv.isNotEmpty) return fromEnv;
    return defaultValue;
  }

  /// Web public URL for sharing results, exams, and deep links
  static String get webBaseUrl =>
      _get('WEB_BASE_URL', defaultValue: 'https://prep404.com');

  /// Supabase project URL
  static String get supabaseUrl => _get('SUPABASE_URL');

  /// Supabase anonymous public API key
  static String get supabaseAnonKey => _get('SUPABASE_ANON_KEY');

  /// OAuth callback URI matched to the Android application ID scheme.
  static String get authRedirectUri => _get(
        'AUTH_REDIRECT_URI',
        defaultValue: 'com.rxxxeron.prep404://login-callback',
      );

  /// Google Client ID for native in-app Google Sign-In.
  static String get googleClientId =>
      _get('GOOGLE_CLIENT_ID', defaultValue: _get('GOOGLE_WEB_CLIENT_ID'));

  /// Google OAuth Web Client ID for native in-app Google Sign-In / token verification.
  static String get googleWebClientId =>
      _get('GOOGLE_WEB_CLIENT_ID', defaultValue: _get('GOOGLE_CLIENT_ID'));

  /// HTTP REST API base host (e.g. http://10.0.2.2:4040, http://localhost:4040, or production backend)
  static String get apiHost {
    final configured = _get('API_HOST');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) return 'http://127.0.0.1:4040';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4040';
    }
    return 'http://127.0.0.1:4040';
  }

  /// REST API v1 Base URL
  static String get apiBaseUrl {
    final configured = _get('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    return '$apiHost/api/v1';
  }

  /// WebSocket URL for real-time 1v1 PvP battles
  static String get wsBattleUrl {
    final configured = _get('WS_BATTLE_URL');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) return 'ws://127.0.0.1:4040/ws/battle';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ws://10.0.2.2:4040/ws/battle';
    }
    return 'ws://127.0.0.1:4040/ws/battle';
  }

  /// List of candidate fallback endpoints to query when trying to discover local/remote backend
  static List<String> get candidateApiHosts {
    final configured = _get('API_HOST');
    if (configured.isNotEmpty) return [configured];
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const [
        'http://10.0.2.2:4040',
        'http://127.0.0.1:4040',
        'http://localhost:4040',
      ];
    }
    return const [
      'http://127.0.0.1:4040',
      'http://localhost:4040',
      'http://10.0.2.2:4040',
    ];
  }
}
