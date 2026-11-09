import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/models/user_profile.dart';
import 'package:prep404/core/models/university_target.dart';
import 'package:prep404/main.dart';

void main() {
  group('Universal English Language Tests Across All Curriculum Types', () {
    testWidgets('renders all 5 tabs and navbar in English when English Medium', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const englishProfile = UserProfile(
        id: 'eng_user_01',
        name: 'Zayan Khan',
        phone: '01700112233',
        medium: StudentMedium.english,
        nctbVersion: NctbVersion.english,
        academicBatch: 'A-Level 25',
        institutionName: 'Scholastica',
        targetSelections: {'iub': ['set_cse']},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MainDashboardScreen(
            profile: englishProfile,
            onResetProfile: () {},
          ),
        ),
      );

      await tester.pump();

      // Check Bottom Nav Bar labels are strictly in English
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Question Bank'), findsOneWidget);
      expect(find.text('Daily Test'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);

      // Streak number must be English '0' for new candidate
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('renders all 5 tabs and navbar in English even when Bangla Medium', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const banglaProfile = UserProfile(
        id: 'ban_user_01',
        name: 'Rafi Ahmed',
        phone: '01800112233',
        medium: StudentMedium.bangla,
        nctbVersion: NctbVersion.bangla,
        academicBatch: 'HSC 25',
        institutionName: 'Dhaka College',
        targetSelections: {'brac': ['cse']},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MainDashboardScreen(
            profile: banglaProfile,
            onResetProfile: () {},
          ),
        ),
      );

      await tester.pump();

      // Check Bottom Nav Bar labels are strictly in English (NO Bangla labels)
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Question Bank'), findsOneWidget);
      expect(find.text('Daily Test'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);

      expect(find.text('হোম'), findsNothing);
      expect(find.text('প্ল্যান'), findsNothing);
      expect(find.text('প্রশ্নব্যাংক'), findsNothing);
      expect(find.text('ডেইলি টেস্ট'), findsNothing);
      expect(find.text('হিস্ট্রি'), findsNothing);

      // Streak number must be English '0' for new candidate
      expect(find.text('0'), findsOneWidget);
      expect(find.text('৭'), findsNothing);
    });
  });
}
