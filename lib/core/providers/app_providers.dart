import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/api_client.dart';
import '../services/cache_service.dart';
import '../services/supabase_service.dart';
import '../services/question_report_service.dart';
import '../services/admission_plan_service.dart';
import '../services/university_roadmap_service.dart';
import '../repositories/exam_repository.dart';
import '../repositories/institution_repository.dart';
import '../repositories/university_repository.dart';
import '../theme/app_theme.dart';
import '../localization/app_strings.dart';

// ---------------------------------------------------------------------------
// Singletons & Core Service Providers
// ---------------------------------------------------------------------------

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  return ApiClient(cache: cache);
});

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return ExamRepository();
});

final institutionRepositoryProvider = Provider<InstitutionRepository>((ref) {
  return InstitutionRepository();
});

final universityRepositoryProvider = Provider<UniversityRepository>((ref) {
  return UniversityRepository();
});

final admissionPlanServiceProvider = Provider<AdmissionPlanService>((ref) {
  return AdmissionPlanService();
});

final universityRoadmapServiceProvider =
    Provider<UniversityRoadmapService>((ref) {
  return UniversityRoadmapService();
});

final questionReportServiceProvider = Provider<QuestionReportService>((ref) {
  return QuestionReportService();
});

// ---------------------------------------------------------------------------
// Theme Mode State & Notifier
// ---------------------------------------------------------------------------

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final CacheService _cache;
  late final VoidCallback _listener;

  ThemeModeNotifier(this._cache) : super(AppTheme.currentMode) {
    _listener = () {
      if (state != AppTheme.currentMode) {
        state = AppTheme.currentMode;
      }
    };
    AppTheme.themeModeNotifier.addListener(_listener);
  }

  void toggleTheme() {
    AppTheme.toggleTheme();
    state = AppTheme.currentMode;
    _cache.write('theme_mode', state == ThemeMode.dark ? 'dark' : 'light');
  }

  void setThemeMode(ThemeMode mode) {
    AppTheme.setThemeMode(mode);
    state = mode;
    _cache.write('theme_mode', mode == ThemeMode.dark ? 'dark' : 'light');
  }

  @override
  void dispose() {
    AppTheme.themeModeNotifier.removeListener(_listener);
    super.dispose();
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  return ThemeModeNotifier(cache);
});

// ---------------------------------------------------------------------------
// App Language State & Notifier
// ---------------------------------------------------------------------------

class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  final CacheService _cache;

  AppLanguageNotifier(this._cache) : super(_readLanguage(_cache));

  static AppLanguage _readLanguage(CacheService cache) =>
      cache.read<String>('app_language') == 'bn'
          ? AppLanguage.bangla
          : AppLanguage.english;

  /// Called after SharedPreferences is initialized during app startup.
  void restore() => state = _readLanguage(_cache);

  void setLanguage(AppLanguage language) {
    if (state == language) return;
    state = language;
    _cache.write('app_language', language == AppLanguage.bangla ? 'bn' : 'en');
  }
}

final appLanguageProvider =
    StateNotifierProvider<AppLanguageNotifier, AppLanguage>((ref) {
  return AppLanguageNotifier(ref.watch(cacheServiceProvider));
});

// ---------------------------------------------------------------------------
// Auth State & Notifier
// ---------------------------------------------------------------------------

@immutable
class AuthState {
  final bool isInitialized;
  final bool isAuthenticated;
  final String? token;
  final String candidateName;
  final String candidatePhone;

  const AuthState({
    this.isInitialized = false,
    this.isAuthenticated = false,
    this.token,
    this.candidateName = '',
    this.candidatePhone = '',
  });

  AuthState copyWith({
    bool? isInitialized,
    bool? isAuthenticated,
    String? token,
    String? candidateName,
    String? candidatePhone,
  }) {
    return AuthState(
      isInitialized: isInitialized ?? this.isInitialized,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      candidateName: candidateName ?? this.candidateName,
      candidatePhone: candidatePhone ?? this.candidatePhone,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final CacheService _cache;
  final SupabaseService _supabase;
  final ApiClient _apiClient;

  AuthNotifier({
    required CacheService cache,
    required SupabaseService supabase,
    required ApiClient apiClient,
  })  : _cache = cache,
        _supabase = supabase,
        _apiClient = apiClient,
        super(const AuthState());

  void restoreSession() {
    final token = _cache.read<String>('auth_token');
    final authUser = _supabase.currentUser;
    final accessToken = _supabase.currentAccessToken;
    final isAuth = authUser != null && accessToken != null;

    String name = '';
    String phone = '';

    if (authUser != null && accessToken != null) {
      _cache.write('auth_token', accessToken);
      name = authUser.userMetadata?['full_name'] as String? ??
          authUser.userMetadata?['name'] as String? ??
          '';
      phone = authUser.phone ?? '';
    } else if (token != null && token.isNotEmpty) {
      _cache.write('auth_token', '');
    }

    state = AuthState(
      isInitialized: true,
      isAuthenticated: isAuth,
      token: isAuth ? accessToken : null,
      candidateName: name,
      candidatePhone: phone,
    );
  }

  void setSession({
    required String token,
    required String name,
    required String phone,
  }) {
    _cache.write('auth_token', token);
    state = AuthState(
      isInitialized: true,
      isAuthenticated: true,
      token: token,
      candidateName: name,
      candidatePhone: phone,
    );
  }

  Future<void> signOut() async {
    try {
      await _supabase.signOut();
    } catch (_) {}
    _cache.clearAccountData();
    state = const AuthState(
      isInitialized: true,
      isAuthenticated: false,
      token: null,
      candidateName: '',
      candidatePhone: '',
    );
  }

  Future<void> deleteAccount(String reason) async {
    try {
      await _apiClient.deleteAccount(reason: reason);
    } catch (_) {
      rethrow;
    }
    await signOut();
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(
    cache: cache,
    supabase: supabase,
    apiClient: apiClient,
  );
});

// ---------------------------------------------------------------------------
// User Profile State & Notifier
// ---------------------------------------------------------------------------

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  final CacheService _cache;

  UserProfileNotifier(this._cache) : super(null);

  void loadFromCache({String? expectedUserId}) {
    final cached = _cache.loadProfile();
    if (expectedUserId != null && cached?.id != expectedUserId) {
      state = null;
    } else {
      state = cached;
    }
  }

  void setProfile(UserProfile? profile) {
    if (profile != null) {
      _cache.saveProfile(profile);
    }
    state = profile;
  }

  void updateProfile(UserProfile profile) {
    _cache.saveProfile(profile);
    state = profile;
  }

  void clear() {
    state = null;
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  final notifier = UserProfileNotifier(cache);
  ref.listen<AuthState>(authStateProvider, (prev, next) {
    if (next.isInitialized && !next.isAuthenticated) {
      notifier.clear();
    }
  });
  return notifier;
});
