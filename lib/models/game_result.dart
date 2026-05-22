class GameResult {
  const GameResult({
    required this.completed,
    required this.seasonId,
    required this.level,
    required this.seasonName,
    required this.distance,
    required this.coins,
    required this.availableCoins,
    required this.perfectFlips,
    required this.lastSecondSaves,
    required this.stars,
    required this.accuracyPercent,
    required this.coinPercent,
    required this.perfectStreak,
    required this.mistakes,
    required this.performanceScore,
    required this.perfectRun,
    this.endless = false,
  });

  final bool completed;
  final int seasonId;
  final int level;
  final String seasonName;
  final int distance;
  final int coins;
  final int availableCoins;
  final int perfectFlips;
  final int lastSecondSaves;
  final int stars;
  final double accuracyPercent;
  final double coinPercent;
  final int perfectStreak;
  final int mistakes;
  final int performanceScore;
  final bool perfectRun;
  final bool endless;
}
