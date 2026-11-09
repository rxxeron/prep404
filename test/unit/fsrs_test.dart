import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/algorithms/fsrs.dart';

void main() {
  group('FSRSAlgorithm Unit Tests', () {
    const fsrs = FSRSAlgorithm(requestRetention: 0.90);

    test('Initial review initializes stability and difficulty correctly', () {
      final initial = FSRSCardState.initial();
      expect(initial.stability, 0.0);
      expect(initial.reps, 0);

      final reviewedAgain = fsrs.review(initial, FSRSRating.again);
      expect(reviewedAgain.stability, FSRSAlgorithm.w[0]);
      expect(reviewedAgain.reps, 1);
      expect(reviewedAgain.lapses, 1);

      final reviewedGood = fsrs.review(initial, FSRSRating.good);
      expect(reviewedGood.stability, FSRSAlgorithm.w[2]);
      expect(reviewedGood.reps, 1);
      expect(reviewedGood.lapses, 0);

      final reviewedEasy = fsrs.review(initial, FSRSRating.easy);
      expect(reviewedEasy.stability, FSRSAlgorithm.w[3]);
      expect(reviewedEasy.reps, 1);
      expect(reviewedEasy.lapses, 0);
    });

    test('calculateRetrievability decays over time', () {
      final now = DateTime.now();
      final state = FSRSCardState(
        stability: 5.0, // 5 days stability
        difficulty: 4.0,
        lastReviewed: now,
        reps: 1,
        lapses: 0,
      );

      // At t=0, retrievability should be 1.0 (100%)
      final r0 = state.calculateRetrievability(now);
      expect(r0, closeTo(1.0, 0.001));

      // After 5 days (t = S), R should be around 0.9
      final in5Days = now.add(const Duration(days: 5));
      final r5 = state.calculateRetrievability(in5Days);
      expect(r5, closeTo(0.9, 0.05));

      // After 20 days, R should be significantly lower
      final in20Days = now.add(const Duration(days: 20));
      final r20 = state.calculateRetrievability(in20Days);
      expect(r20, lessThan(r5));
    });

    test('Repeated successful reviews grow stability', () {
      final t0 = DateTime(2026, 1, 1);
      var state = fsrs.review(FSRSCardState.initial(), FSRSRating.good, t0);
      final s1 = state.stability;

      final t1 = t0.add(Duration(days: fsrs.calculateNextInterval(state.stability)));
      state = fsrs.review(state, FSRSRating.good, t1);
      expect(state.stability, greaterThan(s1));

      final t2 = t1.add(Duration(days: fsrs.calculateNextInterval(state.stability)));
      state = fsrs.review(state, FSRSRating.easy, t2);
      expect(state.stability, greaterThan(s1 * 1.5));
    });

    test('Lapses on review increment lapse counter and clamp difficulty', () {
      final t0 = DateTime(2026, 1, 1);
      var state = fsrs.review(FSRSCardState.initial(), FSRSRating.good, t0);
      expect(state.lapses, 0);

      final t1 = t0.add(const Duration(days: 3));
      state = fsrs.review(state, FSRSRating.again, t1);
      expect(state.lapses, 1);
      expect(state.difficulty, inInclusiveRange(1.0, 10.0));
    });
  });
}
