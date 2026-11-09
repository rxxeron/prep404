import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prep404_logo.dart';

/// Top header banner with clean brand logo and theme toggle
class AuthHeader extends StatelessWidget {
  final AppLanguage language;
  final AppStrings strings;
  final bool showControls;

  const AuthHeader({
    super.key,
    this.language = AppLanguage.english,
    required this.strings,
    this.showControls = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showControls) ...[
          // Top Controls: Theme Toggle
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ThemeToggleIconButton(),
            ],
          ),
          const SizedBox(height: 10),
        ],

        // Clean Confirmed Brand Logo (Includes wordmark & "Failure Not Found" tagline)
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Prep404Logo(height: 56),
          ),
        ),
      ],
    );
  }
}
