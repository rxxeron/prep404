import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/models/user_profile.dart';
import 'package:prep404/core/models/university_target.dart';
import 'package:prep404/core/localization/app_strings.dart';
import 'package:prep404/core/providers/app_providers.dart';
import 'package:prep404/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Riverpod App Providers Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Core service providers resolve cleanly', () {
      expect(container.read(cacheServiceProvider), isNotNull);
      expect(container.read(supabaseServiceProvider), isNotNull);
      expect(container.read(apiClientProvider), isNotNull);
      expect(container.read(examRepositoryProvider), isNotNull);
      expect(container.read(institutionRepositoryProvider), isNotNull);
      expect(container.read(universityRepositoryProvider), isNotNull);
      expect(container.read(admissionPlanServiceProvider), isNotNull);
      expect(container.read(universityRoadmapServiceProvider), isNotNull);
      expect(container.read(questionReportServiceProvider), isNotNull);
    });

    test('ThemeModeNotifier toggles and explicitly sets theme mode', () {
      final notifier = container.read(themeModeProvider.notifier);
      expect(container.read(themeModeProvider), ThemeMode.light);

      notifier.toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(AppTheme.isDark, isTrue);

      notifier.toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(AppTheme.isDark, isFalse);

      notifier.setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('App language persists and survives account-data clearing', () async {
      final cache = container.read(cacheServiceProvider);
      await cache.init();
      cache.remove('app_language');
      cache.remove('theme_mode');

      final notifier = container.read(appLanguageProvider.notifier);
      notifier.restore();
      expect(container.read(appLanguageProvider), AppLanguage.english);

      notifier.setLanguage(AppLanguage.bangla);
      cache.write('theme_mode', 'dark');
      expect(cache.read<String>('app_language'), 'bn');

      cache.clearAccountData();
      notifier.restore();

      expect(container.read(appLanguageProvider), AppLanguage.bangla);
      expect(cache.read<String>('theme_mode'), 'dark');
      expect((await SharedPreferences.getInstance()).getString('app_language'),
          'bn');
    });

    test('AuthState and AuthNotifier manage login, token, and sign-out',
        () async {
      final authNotifier = container.read(authStateProvider.notifier);
      expect(container.read(authStateProvider).isAuthenticated, isFalse);
      expect(container.read(authStateProvider).token, isNull);

      authNotifier.setSession(
        token: 'test_jwt_token',
        name: 'Tamim Iqbal',
        phone: '01700000000',
      );

      final state = container.read(authStateProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.token, 'test_jwt_token');
      expect(state.candidateName, 'Tamim Iqbal');
      expect(state.candidatePhone, '01700000000');

      await authNotifier.signOut();
      final signedOutState = container.read(authStateProvider);
      expect(signedOutState.isAuthenticated, isFalse);
      expect(signedOutState.token, isNull);
      expect(signedOutState.candidateName, isEmpty);
    });

    test('UserProfileNotifier stores, updates, and clears profile', () {
      final profileNotifier = container.read(userProfileProvider.notifier);
      expect(container.read(userProfileProvider), isNull);

      const profile = UserProfile(
        id: 'usr_provider_test',
        name: 'Sakib Al Hasan',
        phone: '01800000000',
        medium: StudentMedium.bangla,
        academicBatch: "HSC '25",
        institutionName: 'Dhaka College',
        targetSelections: {
          'du': ['a_unit']
        },
      );

      profileNotifier.setProfile(profile);
      expect(container.read(userProfileProvider)?.name, 'Sakib Al Hasan');
      expect(container.read(userProfileProvider)?.academicBatch, "HSC '25");

      const updated = UserProfile(
        id: 'usr_provider_test',
        name: 'Sakib Al Hasan (Captain)',
        phone: '01800000000',
        medium: StudentMedium.bangla,
        academicBatch: "HSC '25",
        institutionName: 'Dhaka College',
        targetSelections: {
          'du': ['a_unit']
        },
      );
      profileNotifier.updateProfile(updated);
      expect(container.read(userProfileProvider)?.name,
          'Sakib Al Hasan (Captain)');

      profileNotifier.clear();
      expect(container.read(userProfileProvider), isNull);
    });
  });
}
