import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Prep404 smoke test - builds root app', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Skip real Supabase start-up: it opens network timers a widget test
    // cannot settle. app_startup_test covers the start-up sequence itself.
    await tester.pumpWidget(Prep404App(initializeApp: () async {}));
    await tester.pump();
    expect(find.byType(Prep404App), findsOneWidget);
    expect(find.byType(RootFlowController), findsOneWidget);
  });
}
