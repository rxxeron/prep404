import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/features/dashboard/presentation/widgets/prep_bottom_nav_bar.dart';
import 'package:prep404/features/exam/presentation/widgets/exam_bottom_action_bar.dart';

void main() {
  testWidgets('navigation and exam filters expose state and fit at 200% text',
      (tester) async {
    var selectedIndex = 0;
    var selectedFilter = ExamFilterType.all;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 800),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: ExamFilterBar(
                totalCount: 20,
                answeredCount: 4,
                currentFilter: ExamFilterType.all,
                onFilterChanged: (filter) => selectedFilter = filter,
              ),
            ),
            bottomNavigationBar: PrepBottomNavBar(
              selectedIndex: selectedIndex,
              onItemSelected: (index) => selectedIndex = index,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final homeNode = tester.getSemantics(find.bySemanticsLabel('Home'));
    final homeData = homeNode.getSemanticsData();
    expect(homeData.flagsCollection.isButton, isTrue);
    expect(homeData.flagsCollection.isSelected, ui.Tristate.isTrue);
    expect(homeData.hasAction(ui.SemanticsAction.tap), isTrue);

    final allNode = tester.getSemantics(find.bySemanticsLabel('All (20)'));
    final allData = allNode.getSemanticsData();
    expect(allData.flagsCollection.isButton, isTrue);
    expect(allData.flagsCollection.isSelected, ui.Tristate.isTrue);
    expect(allData.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(find.text('Unanswered (16)'), findsOneWidget);

    final answeredNode = tester.getSemantics(
      find.bySemanticsLabel('Answered (4)'),
    );
    final answeredData = answeredNode.getSemanticsData();
    expect(answeredData.flagsCollection.isButton, isTrue);
    expect(answeredData.flagsCollection.isSelected, ui.Tristate.isFalse);
    expect(answeredData.hasAction(ui.SemanticsAction.tap), isTrue);

    await tester.tap(find.bySemanticsLabel('Answered (4)'));
    expect(selectedFilter, ExamFilterType.answered);
    await tester.tap(find.bySemanticsLabel('Plan'));
    expect(selectedIndex, 1);
  }, semanticsEnabled: true);
}
