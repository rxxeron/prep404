import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/features/dashboard/presentation/widgets/chorcha_bottom_nav_bar.dart';
import 'package:prep404/features/dashboard/presentation/screens/learner_support_screen.dart';

void main() {
  testWidgets('dashboard navigation labels follow the selected Bangla locale',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('bn'),
        supportedLocales: const [Locale('en'), Locale('bn')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          bottomNavigationBar: ChorchaBottomNavBar(
            selectedIndex: 0,
            onItemSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('হোম'), findsOneWidget);
    expect(find.text('পরিকল্পনা'), findsOneWidget);
    expect(find.text('প্রশ্নব্যাংক'), findsOneWidget);
    expect(find.text('দৈনিক পরীক্ষা'), findsOneWidget);
    expect(find.text('ইতিহাস'), findsOneWidget);
  });

  testWidgets('learner support form follows the selected Bangla locale',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('bn'),
        supportedLocales: [Locale('en'), Locale('bn')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: LearnerSupportScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('কীভাবে আপনাকে সহায়তা করতে পারি?'), findsOneWidget);
    expect(find.text('অনুরোধের ধরন'), findsOneWidget);
    expect(find.text('বিষয়'), findsOneWidget);
    expect(find.text('বিস্তারিত'), findsOneWidget);
    expect(find.text('How can we help?'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('অ্যাকাউন্টে প্রবেশ'), findsOneWidget);
    expect(find.text('অন্যান্য'), findsNWidgets(2));
    await tester.tap(find.text('অ্যাকাউন্টে প্রবেশ'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('আপনার অনুরোধগুলো'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
