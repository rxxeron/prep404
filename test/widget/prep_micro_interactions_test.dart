import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/widgets/prep_morph_submit_button.dart';
import 'package:prep404/core/widgets/prep_staggered_list.dart';
import 'package:prep404/core/widgets/prep_shake_error.dart';

void main() {
  group('PrepMorphSubmitButton Widget Tests', () {
    testWidgets('renders idle state with text and handles tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrepMorphSubmitButton(
              state: PrepButtonState.idle,
              text: 'Submit Exam',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Submit Exam'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('Submit Exam'));
      expect(tapped, isTrue);
    });

    testWidgets('collapses to circular spinner in loading state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrepMorphSubmitButton(
              state: PrepButtonState.loading,
              text: 'Submit Exam',
              onPressed: null,
            ),
          ),
        ),
      );

      // Loading state displays spinner
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit Exam'), findsNothing);
    });

    testWidgets('shows checkmark in success state and fires completion', (tester) async {
      bool successFinished = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrepMorphSubmitButton(
              state: PrepButtonState.success,
              text: 'Submit Exam',
              onPressed: null,
              successDuration: const Duration(milliseconds: 100),
              onSuccessFinished: () => successFinished = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      expect(successFinished, isTrue);
    });

    testWidgets('shows error icon in error state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrepMorphSubmitButton(
              state: PrepButtonState.error,
              text: 'Submit Exam',
              onPressed: null,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });

  group('PrepStaggeredList & PrepStaggeredItem Tests', () {
    testWidgets('renders all children in PrepStaggeredColumn', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrepStaggeredColumn(
              children: [
                Text('Question 1'),
                Text('Question 2'),
                Text('Question 3'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Question 1'), findsOneWidget);
      expect(find.text('Question 2'), findsOneWidget);
      expect(find.text('Question 3'), findsOneWidget);

      // Advance clock through stagger intervals
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 300));
    });
  });

  group('PrepShakeError Tests', () {
    testWidgets('renders child and triggers shake on shakeTrigger increment', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrepShakeError(
              shakeTrigger: 0,
              onAnimationComplete: () => completed = true,
              child: const Text('Invalid PIN'),
            ),
          ),
        ),
      );

      expect(find.text('Invalid PIN'), findsOneWidget);
      expect(completed, isFalse);

      // Trigger shake via prop update
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrepShakeError(
              shakeTrigger: 1,
              onAnimationComplete: () => completed = true,
              child: const Text('Invalid PIN'),
            ),
          ),
        ),
      );

      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 500)); // Finish shake
      expect(completed, isTrue);
    });

    testWidgets('triggers shake imperatively via GlobalKey', (tester) async {
      final key = GlobalKey<PrepShakeErrorState>();
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrepShakeError(
              key: key,
              onAnimationComplete: () => completed = true,
              child: const Text('Wrong Answer'),
            ),
          ),
        ),
      );

      key.currentState?.shake();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(completed, isTrue);
    });
  });
}
