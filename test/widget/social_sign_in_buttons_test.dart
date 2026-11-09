import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/localization/app_strings.dart';
import 'package:prep404/core/theme/app_theme.dart';
import 'package:prep404/features/auth/presentation/widgets/social_sign_in_buttons.dart';

void main() {
  testWidgets('Google sign-in icon does not require a network image',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SocialSignInButtons(
            strings: const AppStrings(),
            isLoading: false,
            onGoogleSignIn: () {},
            onFacebookSignIn: () {},
          ),
        ),
      ),
    );

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is NetworkImage,
      ),
      findsNothing,
    );
  });
}
