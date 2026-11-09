import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

/// Compact, keyboard- and screen-reader-accessible app language selector.
class AppLanguageMenuButton extends StatelessWidget {
  final AppLanguage language;
  final ValueChanged<AppLanguage> onChanged;
  final Color? foregroundColor;

  const AppLanguageMenuButton({
    super.key,
    required this.language,
    required this.onChanged,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(language);
    return PopupMenuButton<AppLanguage>(
      tooltip: strings.appLanguageLabel,
      icon: Icon(Icons.language_rounded, color: foregroundColor),
      onSelected: onChanged,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: AppLanguage.english,
          child: Text(strings.languageEnglish),
        ),
        PopupMenuItem(
          value: AppLanguage.bangla,
          child: Text(strings.languageBangla),
        ),
      ],
    );
  }
}
