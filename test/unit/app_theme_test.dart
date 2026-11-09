import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme & AppColors Central Theme System Tests', () {
    test('Default mode is light and AppColors has correct light palette values', () {
      AppTheme.setThemeMode(ThemeMode.light);
      expect(AppTheme.currentMode, ThemeMode.light);
      expect(AppTheme.isDark, isFalse);

      const light = AppColors.light;
      expect(light.isDark, isFalse);
      expect(light.background, const Color(0xFFF9FAFB));
      expect(light.surface, const Color(0xFFFFFFFF));
      expect(light.textPrimary, const Color(0xFF111827));
      expect(light.primary, const Color(0xFFFF7A36));
      expect(light.cardShadow.isNotEmpty, isTrue);
    });

    test('Dark mode palette has correct dark slate contrast values', () {
      const dark = AppColors.dark;
      expect(dark.isDark, isTrue);
      expect(dark.background, const Color(0xFF111827));
      expect(dark.surface, const Color(0xFF1F2937));
      expect(dark.textPrimary, const Color(0xFFF9FAFB));
      expect(dark.primary, const Color(0xFFFF7A36));
    });

    test('toggleTheme alternates between ThemeMode.light and ThemeMode.dark', () {
      AppTheme.setThemeMode(ThemeMode.light);
      expect(AppTheme.isDark, isFalse);

      AppTheme.toggleTheme();
      expect(AppTheme.currentMode, ThemeMode.dark);
      expect(AppTheme.isDark, isTrue);

      AppTheme.toggleTheme();
      expect(AppTheme.currentMode, ThemeMode.light);
      expect(AppTheme.isDark, isFalse);
    });

    testWidgets('ThemeToggleIconButton renders and toggles theme on tap', (tester) async {
      AppTheme.setThemeMode(ThemeMode.light);

      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: AppTheme.themeModeNotifier,
          builder: (context, mode, _) {
            return MaterialApp(
              themeMode: mode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              home: const Scaffold(
                appBar: PreferredSize(
                  preferredSize: Size.fromHeight(56),
                  child: Row(
                    children: [
                      ThemeToggleIconButton(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // In light mode, icon is dark_mode_rounded (moon) to switch to dark
      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);

      // Tap toggle button
      await tester.tap(find.byType(ThemeToggleIconButton));
      await tester.pumpAndSettle();

      // Now mode is dark, icon is light_mode_rounded (sun)
      expect(AppTheme.isDark, isTrue);
      expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
    });
  });
}
