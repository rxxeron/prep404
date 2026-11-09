import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';

/// Social OAuth sign-in buttons for Google and Facebook
class SocialSignInButtons extends StatelessWidget {
  final AppStrings strings;
  final bool isLoading;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onFacebookSignIn;

  const SocialSignInButtons({
    super.key,
    required this.strings,
    required this.isLoading,
    required this.onGoogleSignIn,
    required this.onFacebookSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        // Google OAuth Button
        ElevatedButton(
          onPressed: isLoading ? null : onGoogleSignIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.surface,
            foregroundColor: colors.textPrimary,
            elevation: context.isDark ? 0 : 1,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: colors.border,
              ),
            ),
            shadowColor: Colors.black.withValues(alpha: 0.05),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.g_mobiledata,
                color: Colors.redAccent,
                size: 24,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  strings.continueWithGoogle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Facebook OAuth Button
        ElevatedButton(
          onPressed: isLoading ? null : onFacebookSignIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1877F2), // Official Facebook Blue
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            shadowColor: const Color(0xFF1877F2).withValues(alpha: 0.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.facebook,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  strings.continueWithFacebook,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
