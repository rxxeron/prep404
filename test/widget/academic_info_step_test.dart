import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/services/cache_service.dart';
import 'package:prep404/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:prep404/features/onboarding/presentation/widgets/academic_info_step.dart';

void main() {
  group('AcademicInfoStep & Education History Widget Tests', () {
    setUp(() {
      final cache = CacheService();
      cache.write('geo_divisions', jsonEncode([
        {'id': 'div_dhaka', 'name_en': 'Dhaka', 'name_bn': ''},
      ]));
      cache.write('geo_districts_div_dhaka', jsonEncode([
        {'id': 'dist_dhaka', 'division_id': 'div_dhaka', 'name_en': 'Dhaka', 'name_bn': ''},
      ]));
      cache.write('inst_preload_hsc', jsonEncode([
        {'id': 'hsc_107977', 'eiin': '107977', 'name_en': 'NOTRE DAME COLLEGE', 'is_college': true, 'is_school': false},
        {'id': 'hsc_107975', 'eiin': '107975', 'name_en': 'DHAKA COLLEGE', 'is_college': true, 'is_school': false},
      ]));
      cache.write('inst_preload_ssc', jsonEncode([
        {'id': 'ssc_108277', 'eiin': '108277', 'name_en': 'IDEAL SCHOOL AND COLLEGE', 'is_college': true, 'is_school': true},
      ]));
    });

    testWidgets('renders Education History header, Division/District on top, Gender, SSC and HSC sections', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = OnboardingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedBuilder(
              animation: controller,
              builder: (context, _) => AcademicInfoStep(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text('Enter Your Education History'), findsOneWidget);

      // Verify Division & District are rendered on top
      expect(find.text('Division *'), findsOneWidget);
      expect(find.text('District *'), findsOneWidget);

      // Verify Gender
      expect(find.text('Gender *'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);

      // Verify Mobile Number field
      expect(find.text('Confirm Mobile Number *'), findsOneWidget);

      // Tap Female gender
      await tester.tap(find.text('Female'));
      await tester.pumpAndSettle();
      expect(controller.gender, 'female');

      // Verify SSC section (Optional, no asterisks)
      expect(find.text('SSC / Dakhil History (Optional)'), findsOneWidget);
      expect(find.text('SSC Group'), findsOneWidget);
      expect(find.text('Passing Year'), findsOneWidget);
      expect(find.text('School / Madrasah'), findsOneWidget);

      // Verify HSC section (Optional, no asterisks)
      expect(find.text('HSC / Alim History (Optional)'), findsOneWidget);
      expect(find.text('HSC Group'), findsOneWidget);
      expect(find.text('College / Madrasah'), findsOneWidget);

      // Tap HSC College dropdown to open modal
      final collegePicker = find.text('Tap to select college or madrasah...');
      expect(collegePicker, findsOneWidget);
      await tester.tap(collegePicker);
      await tester.pumpAndSettle();

      // Verify modal opened with searchable list
      expect(find.text('NOTRE DAME COLLEGE'), findsOneWidget);
      expect(find.text('DHAKA COLLEGE'), findsOneWidget);

      // Select Notre Dame College
      await tester.tap(find.text('NOTRE DAME COLLEGE'));
      await tester.pumpAndSettle();

      expect(controller.hscInstitution, 'NOTRE DAME COLLEGE');
      expect(controller.hscEiin, '107977');

      // Tap SSC School dropdown to open modal
      final schoolPicker = find.text('Tap to select school or madrasah...');
      expect(schoolPicker, findsOneWidget);
      await tester.tap(schoolPicker);
      await tester.pumpAndSettle();

      // Verify modal opened with searchable SSC list
      expect(find.text('IDEAL SCHOOL AND COLLEGE'), findsOneWidget);

      // Select Ideal School
      await tester.tap(find.text('IDEAL SCHOOL AND COLLEGE'));
      await tester.pumpAndSettle();

      expect(controller.sscInstitution, 'IDEAL SCHOOL AND COLLEGE');
      expect(controller.sscEiin, '108277');
    });

    testWidgets('allows proceeding when candidate name and phone are filled, without requiring SSC/HSC', (tester) async {
      final controller = OnboardingController(
        initialName: 'Test Student',
        initialPhone: '01711223344',
      );

      // SSC and HSC are empty
      expect(controller.sscInstitution, isEmpty);
      expect(controller.hscInstitution, isEmpty);

      // But can proceed because name and mobile are confirmed!
      expect(controller.canProceedToStep2, isTrue);
    });

    testWidgets('HSC GPA is typable and supports Appeared or Will Appear tickmark toggle', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = OnboardingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedBuilder(
              animation: controller,
              builder: (context, _) => AcademicInfoStep(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Appeared / Will Appear tickmark
      final tickmark = find.text('Appeared or Will Appear');
      expect(tickmark, findsOneWidget);

      // Initially unticked, starts empty and GPA is typable
      expect(controller.hscGpa, '');

      // Tap tickmark to mark as Appearing
      await tester.tap(tickmark);
      await tester.pumpAndSettle();

      expect(controller.hscGpa, 'Appearing');

      // Tap again to uncheck and restore typable GPA
      await tester.tap(tickmark);
      await tester.pumpAndSettle();

      expect(controller.hscGpa, '');
    });
  });
}
