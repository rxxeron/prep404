import 'dart:math';

/// Rating for review attempts
enum FSRSRating {
  again(1),
  hard(2),
  good(3),
  easy(4);

  final int value;
  const FSRSRating(this.value);
}

/// FSRS-4.5 Memory State representation
class FSRSCardState {
  final double stability; // S in days
  final double difficulty; // D from 1 to 10
  final DateTime lastReviewed;
  final int reps;
  final int lapses;

  const FSRSCardState({
    required this.stability,
    required this.difficulty,
    required this.lastReviewed,
    required this.reps,
    required this.lapses,
  });

  factory FSRSCardState.initial() {
    return FSRSCardState(
      stability: 0.0,
      difficulty: 0.0,
      lastReviewed: DateTime.now(),
      reps: 0,
      lapses: 0,
    );
  }

  /// Calculates Retrievability R(t) = (1 + 19 * t / (81 * S)) ^ -0.5.
  /// At t = S, the default FSRS curve returns the target retention of 0.9.
  double calculateRetrievability([DateTime? asOf]) {
    final now = asOf ?? DateTime.now();
    final elapsedDays = max(0, now.difference(lastReviewed).inHours / 24.0);
    if (stability <= 0) return 0.0;
    return pow(1 + 19 * (elapsedDays / (81 * stability)), -0.5).toDouble();
  }
}

/// Free Spaced Repetition Scheduler (FSRS-4.5) implementation
class FSRSAlgorithm {
  // Standard default weights tuned for competitive exam recall
  static const List<double> w = [
    0.4, 0.6, 2.4, 5.8, // Initial stabilities for Again, Hard, Good, Easy
    4.93, 0.94, 0.86, 0.01, // Difficulty update parameters
    1.49, 0.14, 0.94, // Stability update on Good/Easy
    2.18, 0.05, 0.34, 1.26, // Stability update on Again/lapse
    0.29, 2.61 // Review retrievability factors
  ];

  /// Request retention rate (default 90% target retention)
  final double requestRetention;

  const FSRSAlgorithm({this.requestRetention = 0.90});

  /// Computes the next interval in days given target stability
  int calculateNextInterval(double stability) {
    if (stability <= 0) return 1;
    final interval = stability * (log(requestRetention) / log(0.9));
    return max(1, interval.round());
  }

  /// Reviews a card and returns the updated FSRS state
  FSRSCardState review(FSRSCardState current, FSRSRating rating, [DateTime? reviewTime]) {
    final now = reviewTime ?? DateTime.now();

    if (current.reps == 0) {
      // First review initialization
      final initialStability = w[rating.index];
      final initialDifficulty = _clamp(w[4] - w[5] * (rating.value - 3), 1.0, 10.0);
      return FSRSCardState(
        stability: initialStability,
        difficulty: initialDifficulty,
        lastReviewed: now,
        reps: 1,
        lapses: rating == FSRSRating.again ? 1 : 0,
      );
    }

    final retrievability = current.calculateRetrievability(now);
    final nextDifficulty = _calculateNextDifficulty(current.difficulty, rating);
    double nextStability;
    int nextLapses = current.lapses;

    if (rating == FSRSRating.again) {
      nextLapses++;
      nextStability = _calculateLapseStability(current.difficulty, current.stability, retrievability);
    } else {
      nextStability = _calculateRecallStability(current.difficulty, current.stability, retrievability, rating);
    }

    return FSRSCardState(
      stability: nextStability,
      difficulty: nextDifficulty,
      lastReviewed: now,
      reps: current.reps + 1,
      lapses: nextLapses,
    );
  }

  double _calculateNextDifficulty(double d, FSRSRating rating) {
    final rawD = d - w[6] * (rating.value - 3);
    final meanReversion = w[7] * w[4] + (1 - w[7]) * rawD;
    return _clamp(meanReversion, 1.0, 10.0);
  }

  double _calculateRecallStability(double d, double s, double r, FSRSRating rating) {
    final hardPenalty = rating == FSRSRating.hard ? w[15] : 1.0;
    final easyBonus = rating == FSRSRating.easy ? w[16] : 1.0;
    return s * (1 + exp(w[8]) * (11 - d) * pow(s, -w[9]) * (exp((1 - r) * w[10]) - 1) * hardPenalty * easyBonus);
  }

  double _calculateLapseStability(double d, double s, double r) {
    return w[11] * pow(d, -w[12]) * (pow(s + 1, w[13]) - 1) * exp((1 - r) * w[14]);
  }

  double _clamp(double val, double minVal, double maxVal) {
    return max(minVal, min(maxVal, val));
  }
}
