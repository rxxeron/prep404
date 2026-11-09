import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/features/dashboard/presentation/screens/community_links_screen.dart';

void main() {
  group('CommunityLinksScreen Tests', () {
    testWidgets('renders all official community channels and header banner',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: CommunityLinksScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Prep404 Community'), findsOneWidget);

      // Verify Hero Banner
      expect(find.text('Connect with Prep404'), findsOneWidget);
      expect(find.text('Official Channels'), findsOneWidget);

      // Verify Social Channels
      expect(find.text('Facebook Community Group'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('LinkedIn Official'), findsOneWidget);
      expect(find.text('X (formerly Twitter)'), findsOneWidget);
      expect(find.text('YouTube Channel'), findsOneWidget);
    });
  });
}
