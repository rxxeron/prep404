import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:google_fonts/google_fonts.dart';
import '../services/cache_service.dart';

/// Central Theme Management & Reactive Dark/White Mode Controller
/// Signature Prep404 Brand Identity: Clean White (#FFFFFF / #F9FAFB) + Emerald Green (#059669) + Tangerine (#F97316) + Crimson (#EF4444)
class AppTheme {
  static final TextStyle _notoSansBengali = GoogleFonts.notoSansBengali();

  static TextTheme _textThemeFor(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    final inter = GoogleFonts.interTextTheme(base);
    final bengaliFamily = _notoSansBengali.fontFamily!;

    TextStyle? withBengaliFallback(TextStyle? style) => style?.copyWith(
          fontFamilyFallback: [bengaliFamily],
        );

    return inter.copyWith(
      displayLarge: withBengaliFallback(inter.displayLarge),
      displayMedium: withBengaliFallback(inter.displayMedium),
      displaySmall: withBengaliFallback(inter.displaySmall),
      headlineLarge: withBengaliFallback(inter.headlineLarge),
      headlineMedium: withBengaliFallback(inter.headlineMedium),
      headlineSmall: withBengaliFallback(inter.headlineSmall),
      titleLarge: withBengaliFallback(inter.titleLarge),
      titleMedium: withBengaliFallback(inter.titleMedium),
      titleSmall: withBengaliFallback(inter.titleSmall),
      bodyLarge: withBengaliFallback(inter.bodyLarge),
      bodyMedium: withBengaliFallback(inter.bodyMedium),
      bodySmall: withBengaliFallback(inter.bodySmall),
      labelLarge: withBengaliFallback(inter.labelLarge),
      labelMedium: withBengaliFallback(inter.labelMedium),
      labelSmall: withBengaliFallback(inter.labelSmall),
    );
  }

  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  /// Initialize theme mode from local storage cache
  static void init() {
    final savedMode = CacheService().read<String>('theme_mode');
    if (savedMode == 'dark') {
      themeModeNotifier.value = ThemeMode.dark;
    } else {
      // Default to crisp white & emerald theme (Prep404 standard)
      themeModeNotifier.value = ThemeMode.light;
    }
  }

  /// Check whether the active theme mode is currently dark
  static bool get isDark => themeModeNotifier.value == ThemeMode.dark;

  /// Current theme mode value
  static ThemeMode get currentMode => themeModeNotifier.value;

  /// Toggle between Light (Clean White & Emerald) and Dark (Deep Nocturnal Slate/Plum)
  static void toggleTheme() {
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    themeModeNotifier.value = next;
    CacheService()
        .write('theme_mode', next == ThemeMode.dark ? 'dark' : 'light');
  }

  /// Explicitly set theme mode
  static void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
    CacheService()
        .write('theme_mode', mode == ThemeMode.dark ? 'dark' : 'light');
  }

  /// Crisp Clean White & Emerald Light Theme (Prep404 Design System)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      textTheme: _textThemeFor(Brightness.light),
      scaffoldBackgroundColor:
          const Color(0xFFF9FAFB), // Clean Off-White Canvas
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE5E7EB),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFFF7A36), // Prep404 Tangerine Orange
        onPrimary: Color(0xFF542747),
        primaryContainer: Color(0xFFFFF3E6), // Light Cream Wash
        onPrimaryContainer: Color(0xFF542747), // Deep Plum
        secondary: Color(0xFFFFD166), // Sunshine
        onSecondary: Color(0xFF542747),
        secondaryContainer: Color(0xFFFFF3E6),
        onSecondaryContainer: Color(0xFF542747),
        tertiary: Color(0xFF542747), // Deep Plum
        onTertiary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF111827), // Deep Charcoal
        surfaceContainerHighest: Color(0xFFF3F4F6),
        error: Color(0xFFEF4444),
        onError: Colors.white,
        outline: Color(0xFFE5E7EB),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF111827),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF111827)),
        titleTextStyle: TextStyle(
          color: Color(0xFF111827),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF3F4F6),
        selectedColor: const Color(0xFFFFF3E6),
        checkmarkColor: const Color(0xFF542747),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7A36),
          foregroundColor: const Color(0xFF542747),
          disabledBackgroundColor: const Color(0xFFE5E7EB),
          disabledForegroundColor: const Color(0xFF6B7280),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF542747),
          side: const BorderSide(color: Color(0xFFFF7A36)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF542747)),
      ),
      // Keep icon controls easy to tap on phones without enlarging the icon.
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF7A36), width: 1.6),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? const Color(0xFFFF7A36)
                : null),
        side: const BorderSide(color: Color(0xFF9CA3AF)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? const Color(0xFFFF7A36)
                : const Color(0xFF6B7280)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.white
                : const Color(0xFF6B7280)),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? const Color(0xFFFF7A36)
                : const Color(0xFFE5E7EB)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFFFF7A36),
        linearTrackColor: Color(0xFFFFF3E6),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFF542747),
        unselectedLabelColor: Color(0xFF6B7280),
        indicatorColor: Color(0xFFFF7A36),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFF7A36),
        foregroundColor: Color(0xFF542747),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF542747),
        contentTextStyle: TextStyle(color: Color(0xFFFFF3E6)),
        behavior: SnackBarBehavior.floating,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Color(0xFFFF7A36),
        inactiveTrackColor: Color(0xFFFFF3E6),
        thumbColor: Color(0xFFFF7A36),
        overlayColor: Color(0x22FF7A36),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFFFF7A36),
        selectionColor: Color(0x66FFD166),
        selectionHandleColor: Color(0xFFFF7A36),
      ),
      splashColor: const Color(0x22FF7A36),
      highlightColor: const Color(0x11FF7A36),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        indicatorColor: const Color(0xFFFF7A36).withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF7A36),
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFFFF7A36));
          }
          return const IconThemeData(color: Color(0xFF6B7280));
        }),
      ),
    );
  }

  /// Nocturnal Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      textTheme: _textThemeFor(Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF111827), // Deep Charcoal Slate
      cardColor: const Color(0xFF1F2937),
      dividerColor: const Color(0xFF374151),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF7A36), // Bright Tangerine
        onPrimary: Color(0xFF542747),
        primaryContainer: Color(0xFF542747), // Deep Plum
        onPrimaryContainer: Color(0xFFFFF3E6), // Cream
        secondary: Color(0xFFFFD166), // Sunshine
        onSecondary: Color(0xFF1F2937),
        surface: Color(0xFF1F2937),
        onSurface: Color(0xFFF9FAFB),
        surfaceContainerHighest: Color(0xFF374151),
        error: Color(0xFFEF4444),
        onError: Colors.white,
        outline: Color(0xFF374151),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F2937),
        foregroundColor: Color(0xFFF9FAFB),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFFF9FAFB)),
        titleTextStyle: TextStyle(
          color: Color(0xFFF9FAFB),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1F2937),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF374151), width: 1.2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF374151),
        selectedColor: const Color(0xFF542747),
        checkmarkColor: const Color(0xFFFFF3E6),
        side: const BorderSide(color: Color(0xFF374151)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7A36),
          foregroundColor: const Color(0xFF542747),
          disabledBackgroundColor: const Color(0xFF374151),
          disabledForegroundColor: const Color(0xFF9CA3AF),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFFF3E6),
          side: const BorderSide(color: Color(0xFFFF7A36)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFD166)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF7A36), width: 1.6),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? const Color(0xFFFF7A36)
                : null),
        side: const BorderSide(color: Color(0xFF9CA3AF)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? const Color(0xFFFF7A36)
                : const Color(0xFF9CA3AF)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.white
                : const Color(0xFF9CA3AF)),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? const Color(0xFFFF7A36)
                : const Color(0xFF374151)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFFFF7A36),
        linearTrackColor: Color(0xFF542747),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFFFFF3E6),
        unselectedLabelColor: Color(0xFF9CA3AF),
        indicatorColor: Color(0xFFFF7A36),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFF7A36),
        foregroundColor: Color(0xFF542747),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1F2937),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1F2937),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF542747),
        contentTextStyle: TextStyle(color: Color(0xFFFFF3E6)),
        behavior: SnackBarBehavior.floating,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Color(0xFFFF7A36),
        inactiveTrackColor: Color(0xFF542747),
        thumbColor: Color(0xFFFF7A36),
        overlayColor: Color(0x22FF7A36),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFFFF7A36),
        selectionColor: Color(0x66FFD166),
        selectionHandleColor: Color(0xFFFF7A36),
      ),
      splashColor: const Color(0x33FFD166),
      highlightColor: const Color(0x22FFD166),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        indicatorColor: const Color(0xFFFF7A36).withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF7A36),
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9CA3AF),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFFFF7A36));
          }
          return const IconThemeData(color: Color(0xFF9CA3AF));
        }),
      ),
    );
  }
}

/// Dynamic Semantic Palette accessor responsive to current Theme brightness
class AppColors {
  final bool isDark;
  const AppColors._(this.isDark);

  static const AppColors light = AppColors._(false);
  static const AppColors dark = AppColors._(true);

  static AppColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? dark : light;
  }

  // Base canvases: Clean Off-White in Light, Dark Charcoal in Dark
  Color get background =>
      isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
  Color get surface =>
      isDark ? const Color(0xFF1F2937) : const Color(0xFFFFFFFF);
  Color get surfaceElevated =>
      isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);
  Color get border =>
      isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
  Color get borderSubtle =>
      isDark ? const Color(0xFF2D3748) : const Color(0xFFF3F4F6);

  // Typography
  Color get textPrimary =>
      isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
  Color get textSecondary =>
      isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563);
  Color get textMuted =>
      isDark ? const Color(0xFFA9B1BC) : const Color(0xFF626B78);

  Color get inputFill =>
      isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
  Color get inputBorder =>
      isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

  // Identity Palette (Signature Prep404 Identity: Tangerine + Cream + Deep Plum + Sunshine)
  Color get primary => const Color(0xFFFF7A36); // Prep404 Tangerine Orange
  Color get primaryLight =>
      isDark ? const Color(0xFF542747) : const Color(0xFFFFF3E6);
  Color get deepPlum => const Color(0xFF542747);
  Color get cream => const Color(0xFFFFF3E6);
  Color get tangerine => const Color(0xFFFF7A36);
  Color get accentSunshine => const Color(0xFFFFD166);
  Color get accentAmber => const Color(0xFFFFD166);
  Color get accentEmerald => const Color(0xFF10B981);
  Color get accentPurple => const Color(0xFF542747);
  Color get dangerRed => const Color(0xFFEF4444);

  List<BoxShadow> get cardShadow => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ]
      : [
          const BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ];
}

/// BuildContext Helper Extension
extension ThemeContextExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  AppColors get colors => AppColors.of(this);
}

/// Central Theme Mode Toggle Button
class ThemeToggleIconButton extends StatelessWidget {
  final Color? color;
  final double size;

  const ThemeToggleIconButton({
    super.key,
    this.color,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        return IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF4B5563),
              size: size,
            ),
          ),
          tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          onPressed: () => AppTheme.toggleTheme(),
        );
      },
    );
  }
}
