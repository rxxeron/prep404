import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';

/// Social OAuth sign-in buttons for Google and Facebook placed cleanly side by side
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

    return Row(
      children: [
        // Google OAuth Button (Left)
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : onGoogleSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.surface,
              foregroundColor: colors.textPrimary,
              elevation: context.isDark ? 0 : 1,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: colors.border),
              ),
              shadowColor: Colors.black.withValues(alpha: 0.05),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.g_mobiledata,
                  color: Colors.redAccent,
                  size: 26,
                ),
                const SizedBox(width: 6),
                Text(
                  'Google',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Facebook OAuth Button (Right)
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : onFacebookSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2), // Official Facebook Blue
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              shadowColor: const Color(0xFF1877F2).withValues(alpha: 0.3),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.facebook,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 6),
                Text(
                  'Facebook',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
