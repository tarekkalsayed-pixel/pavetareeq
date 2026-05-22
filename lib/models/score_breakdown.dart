class ScoreBreakdown {
  const ScoreBreakdown({
    required this.completed,
    required this.stars,
    required this.performanceScore,
    required this.accuracyPercent,
    required this.coinPercent,
    required this.streakPercent,
    required this.timePercent,
    required this.mistakePenalty,
    required this.perfectRun,
    required this.coinReward,
  });

  final bool completed;
  final int stars;
  final int performanceScore;
  final double accuracyPercent;
  final double coinPercent;
  final double streakPercent;
  final double timePercent;
  final double mistakePenalty;
  final bool perfectRun;
  final int coinReward;
}
