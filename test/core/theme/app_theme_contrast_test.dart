import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/theme/app_theme.dart';

double _contrast(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('semantic text colors meet WCAG AA on app surfaces in both themes', () {
    final themeSurfaces = [
      ('light', AppColors.light, AppColors.light.background),
      ('light', AppColors.light, AppColors.light.surface),
      ('light', AppColors.light, AppColors.light.surfaceElevated),
      ('dark', AppColors.dark, AppColors.dark.background),
      ('dark', AppColors.dark, AppColors.dark.surface),
      ('dark', AppColors.dark, AppColors.dark.surfaceElevated),
    ];

    for (final (themeName, colors, surface) in themeSurfaces) {
      for (final (label, foreground) in [
        ('primary', colors.textPrimary),
        ('secondary', colors.textSecondary),
        ('muted', colors.textMuted),
      ]) {
        expect(
          _contrast(foreground, surface),
          greaterThanOrEqualTo(4.5),
          reason: '$themeName $label text on $surface must meet WCAG AA',
        );
      }
    }
  });

  test('brand button text meets WCAG AA on the primary color', () {
    final buttonForeground = AppColors.light.deepPlum;
    final buttonBackground = AppColors.light.primary;

    expect(_contrast(buttonForeground, buttonBackground),
        greaterThanOrEqualTo(4.5));
  });
}
