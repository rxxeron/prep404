import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/supabase_service.dart';
import 'core/services/api_client.dart';
import 'core/services/telemetry_service.dart';
import 'core/services/university_roadmap_service.dart';
import 'core/services/fcm_service.dart';
import 'core/models/user_profile.dart';
import 'core/services/cache_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/prep404_entry_splash.dart';
import 'core/providers/app_providers.dart';
import 'core/localization/app_strings.dart';
import 'core/routing/app_router.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import 'features/dashboard/presentation/screens/main_dashboard_screen.dart';

export 'core/widgets/prep404_logo.dart';
export 'core/widgets/prep404_entry_splash.dart';
export 'core/providers/app_providers.dart';
export 'core/routing/app_router.dart';
export 'features/dashboard/presentation/screens/main_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  TelemetryService().init();
  runApp(
    const ProviderScope(
      child: Prep404App(),
    ),
  );
}

class Prep404App extends StatelessWidget {
  /// Optional startup override for tests. Production passes nothing, so the
  /// app initializes Supabase, the cache and the theme as usual.
  final Future<void> Function()? initializeApp;

  const Prep404App({super.key, this.initializeApp});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: _Prep404AppBody(initializeApp: initializeApp),
    );
  }
}

class _Prep404AppBody extends ConsumerWidget {
  final Future<void> Function()? initializeApp;

  const _Prep404AppBody({this.initializeApp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final appLanguage = ref.watch(appLanguageProvider);
    final router = ref.watch(appRouterProvider(initializeApp));

    return MaterialApp.router(
      title: 'Prep404 • Exam Prep Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: AppStrings(appLanguage).locale,
      supportedLocales: const [Locale('en'), Locale('bn')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}

/// Root Navigation Flow Controller
class RootFlowController extends ConsumerStatefulWidget {
  final Future<void> Function()? initializeApp;

  const RootFlowController({super.key, this.initializeApp});

  @override
  ConsumerState<RootFlowController> createState() => _RootFlowControllerState();
}

class _RootFlowControllerState extends ConsumerState<RootFlowController> {
  bool _isReady = false;
  bool _isAuthenticated = false;
  UserProfile? _userProfile;
  String _candidateName = '';
  String _candidatePhone = '';

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (widget.initializeApp != null) {
      try {
        await widget.initializeApp!();
      } catch (_) {}
    } else {
      try {
        if (!dotenv.isInitialized) {
          await dotenv.load(fileName: '.env');
        }
        await SupabaseService().initialize();
        unawaited(UniversityRoadmapService().syncFromDatabase());
        unawaited(FcmService().initialize());
      } catch (_) {}

      await CacheService().init();
      AppTheme.init();
    }

    ref.read(appLanguageProvider.notifier).restore();

    if (!mounted) return;

    _restoreSession();
    _syncWithRiverpod();
    setState(() => _isReady = true);
  }

  void _restoreSession() {
    final cache = CacheService();
    final token = cache.read<String>('auth_token');
    final authUser = SupabaseService().currentUser;
    final accessToken = SupabaseService().currentAccessToken;
    _isAuthenticated = authUser != null && accessToken != null;
    if (authUser != null && accessToken != null) {
      cache.write('auth_token', accessToken);
      _candidateName = authUser.userMetadata?['full_name'] as String? ??
          authUser.userMetadata?['name'] as String? ??
          '';
      _candidatePhone = authUser.phone ?? '';
    } else if (token != null && token.isNotEmpty) {
      cache.write('auth_token', '');
    }
    final cachedProfile = _isAuthenticated ? cache.loadProfile() : null;
    _userProfile = cachedProfile?.id == authUser?.id ? cachedProfile : null;
    if (_isAuthenticated && _userProfile == null && authUser != null) {
      unawaited(_fetchRemoteProfile(authUser.id));
    }
  }

  Future<void> _fetchRemoteProfile(String uid) async {
    try {
      final remoteProfile = await ApiClient().fetchUserProfile() ??
          await SupabaseService().fetchUserProfile(uid);
      if (remoteProfile != null && mounted) {
        CacheService().saveProfile(remoteProfile);
        setState(() {
          _userProfile = remoteProfile;
        });
        _syncWithRiverpod();
      }
    } catch (_) {}
  }

  void _syncWithRiverpod() {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      if (_isAuthenticated) {
        final token = CacheService().read<String>('auth_token') ?? '';
        container.read(authStateProvider.notifier).setSession(
              token: token,
              name: _candidateName,
              phone: _candidatePhone,
            );
      }
      if (_userProfile != null) {
        container.read(userProfileProvider.notifier).setProfile(_userProfile);
      }
    } catch (_) {
      // Standalone widget test without ProviderScope
    }
  }

  Future<void> _handleSignOut() async {
    TelemetryService().logInfo('user_sign_out', message: 'Candidate signed out');
    await SupabaseService().signOut();
    CacheService().clearAccountData();
    if (!mounted) return;
    setState(() {
      _isAuthenticated = false;
      _userProfile = null;
    });
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      await container.read(authStateProvider.notifier).signOut();
      container.read(userProfileProvider.notifier).clear();
    } catch (_) {}
  }

  Future<void> _handleDeleteAccount(String reason) async {
    try {
      await ApiClient().deleteAccount(reason: reason);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
      return;
    }
    await SupabaseService().signOut();
    CacheService().clearAccountData();
    if (!mounted) return;
    setState(() {
      _isAuthenticated = false;
      _userProfile = null;
    });
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      container.read(authStateProvider.notifier).signOut();
      container.read(userProfileProvider.notifier).clear();
    } catch (_) {}
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Your account and study data have been permanently deleted.'),
        backgroundColor: Color(0xFFDC2626),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return const Prep404EntrySplash();
    final language = ref.watch(appLanguageProvider);
    final auth = ref.watch(authStateProvider);
    final profile = ref.watch(userProfileProvider);

    final isAuthenticated =
        auth.isInitialized ? auth.isAuthenticated : _isAuthenticated;
    final userProfile =
        isAuthenticated ? (profile ?? _userProfile) : null;

    // Stage 1: Authentication Screen (Social & Mobile OTP)
    if (!isAuthenticated) {
      return AuthScreen(
        language: language,
        onLanguageChanged: ref.read(appLanguageProvider.notifier).setLanguage,
        onAuthSuccess: (token, userJson) {
          CacheService().write('auth_token', token);
          setState(() {
            _isAuthenticated = true;
            _candidateName = userJson['name'] as String? ?? '';
            _candidatePhone = userJson['phone'] as String? ?? '';
          });
          _syncWithRiverpod();
          TelemetryService().logInfo(
            'user_sign_in',
            message: 'Candidate authenticated successfully',
            metadata: {'name': _candidateName, 'phone': _candidatePhone},
          );
          final uid = SupabaseService().currentUser?.id;
          if (uid != null) {
            unawaited(_fetchRemoteProfile(uid));
          }
        },
      );
    }

    // Stage 2: Onboarding Flow (Target Selection & Batch)
    if (userProfile == null) {
      return OnboardingFlowScreen(
        language: language,
        onLanguageChanged: ref.read(appLanguageProvider.notifier).setLanguage,
        initialName: _candidateName,
        initialPhone: _candidatePhone,
        onSignOut: _handleSignOut,
        onCompleted: (completedProfile) {
          CacheService().saveProfile(completedProfile);
          setState(() {
            _userProfile = completedProfile;
          });
          _syncWithRiverpod();
        },
      );
    }

    // Stage 3: Main Application Dashboard Shell
    return MainDashboardScreen(
      profile: userProfile,
      onProfileUpdated: (updatedProfile) {
        CacheService().saveProfile(updatedProfile);
        setState(() {
          _userProfile = updatedProfile;
        });
        _syncWithRiverpod();
      },
      onResetProfile: () {
        CacheService().clearAccountData();
        setState(() {
          _isAuthenticated = false;
          _userProfile = null;
        });
        try {
          final container = ProviderScope.containerOf(context, listen: false);
          container.read(authStateProvider.notifier).signOut();
          container.read(userProfileProvider.notifier).clear();
        } catch (_) {}
      },
      onDeleteAccount: _handleDeleteAccount,
    );
  }
}


