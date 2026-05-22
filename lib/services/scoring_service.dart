import 'dart:math';

import '../models/score_breakdown.dart';

class ScoringService {
  const ScoringService._();

  static ScoreBreakdown calculate({
    required bool completed,
    required int successfulFlips,
    required int requiredFlips,
    required int collectedCoins,
    required int availableCoins,
    required int perfectStreak,
    required int mistakes,
    required Duration elapsed,
    required Duration targetTime,
  }) {
    if (!completed) {
      return const ScoreBreakdown(
        completed: false,
        stars: 0,
        performanceScore: 0,
        accuracyPercent: 0,
        coinPercent: 0,
        streakPercent: 0,
        timePercent: 0,
        mistakePenalty: 0,
        perfectRun: false,
        coinReward: 0,
      );
    }

    final accuracyPercent = requiredFlips == 0
        ? 100.0
        : (successfulFlips / requiredFlips * 100).clamp(0.0, 100.0);
    final coinPercent = availableCoins == 0
        ? 100.0
        : (collectedCoins / availableCoins * 100).clamp(0.0, 100.0);
    final streakPercent = requiredFlips == 0
        ? 100.0
        : (perfectStreak / max(1, requiredFlips) * 100).clamp(0.0, 100.0);
    final targetMs = max(1, targetTime.inMilliseconds);
    final timeRatio = targetMs / max(targetMs, elapsed.inMilliseconds);
    final timePercent = (timeRatio * 100).clamp(0.0, 100.0);
    final mistakePenalty = (mistakes * 8).clamp(0, 35).toDouble();
    final rawScore =
        (accuracyPercent * .50) +
        (coinPercent * .25) +
        (streakPercent * .15) +
        (timePercent * .10) -
        mistakePenalty;
    final performanceScore = rawScore.clamp(0.0, 100.0).round();
    final stars = performanceScore >= 85
        ? 3
        : performanceScore >= 60
        ? 2
        : 1;
    final perfectRun = mistakes == 0 && accuracyPercent >= 100;
    final starBonus = switch (stars) {
      3 => 50,
      2 => 25,
      _ => 10,
    };
    return ScoreBreakdown(
      completed: true,
      stars: stars,
      performanceScore: performanceScore,
      accuracyPercent: accuracyPercent,
      coinPercent: coinPercent,
      streakPercent: streakPercent,
      timePercent: timePercent,
      mistakePenalty: mistakePenalty,
      perfectRun: perfectRun,
      coinReward: collectedCoins + starBonus + (perfectRun ? 30 : 0),
    );
  }
}
