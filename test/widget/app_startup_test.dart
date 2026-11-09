import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/main.dart';

void main() {
  testWidgets('shows an announced startup state before sign-in is ready',
      (tester) async {
    final initialization = Completer<void>();
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        Prep404App(initializeApp: () => initialization.future),
      );

      expect(find.text('Preparing your study space…'), findsOneWidget);
      expect(find.bySemanticsLabel('Loading Prep404'), findsOneWidget);

      initialization.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Create Account'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
}
