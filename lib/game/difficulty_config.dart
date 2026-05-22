import 'dart:math';

class GameDifficultyConfig {
  const GameDifficultyConfig({
    required this.speedMultiplier,
    required this.brokenChance,
    required this.coinChance,
    required this.speedTileChance,
    required this.reactionTime,
    required this.tileGap,
    required this.warningDuration,
    required this.cameraShakeStrength,
    required this.rewardMultiplier,
    required this.difficultyLevel,
    required this.difficultyLabel,
  });

  final double speedMultiplier;
  final double brokenChance;
  final double coinChance;
  final double speedTileChance;
  final double reactionTime;
  final double tileGap;
  final double warningDuration;
  final double cameraShakeStrength;
  final int rewardMultiplier;
  final int difficultyLevel;
  final String difficultyLabel;

  int completionBonus({required int seasonId, required int level}) {
    final base = 10 + (level * 3) + ((seasonId - 1) * 10);
    final bossBonus = level == 10 ? 25 + seasonId * 8 : 0;
    return ((base + bossBonus) * rewardMultiplier).round();
  }

  int coinValue({required int seasonId, required int level}) {
    return max(2, (2 + seasonId * .6 + level * .25).round());
  }

  int perfectBonus({required bool lastSecond}) {
    return (lastSecond ? 4 : 2) * rewardMultiplier;
  }
}

GameDifficultyConfig difficultyForLevel(
  int seasonIndex,
  int levelIndex, {
  double? seasonCurveModifier,
}) {
  final season = seasonIndex.clamp(1, 5);
  final level = levelIndex.clamp(1, 10);
  final zeroSeason = season - 1;
  final zeroLevel = level - 1;
  final isBoss = level == 10;
  final bossBoost = isBoss ? .06 : 0.0;
  // Keep the curve gentle. The game should feel readable first; mastery comes
  // from timing clean saves, not from overwhelming speed or visual noise.
  final speed =
      (.86 +
              zeroSeason * .035 +
              zeroLevel * .02 +
              bossBoost +
              (seasonCurveModifier ?? _seasonCurveModifier(season)) * .35)
          .clamp(.86, 1.34);
  final brokenChance =
      (.08 + zeroSeason * .01 + zeroLevel * .012 + (isBoss ? .035 : 0)).clamp(
        .08,
        .24,
      );
  final coinChance = (.28 - zeroLevel * .004 + zeroSeason * .004).clamp(
    .2,
    .31,
  );
  final speedTileChance = 0.0;
  final reactionTime = max(
    season <= 2 ? .95 : .88,
    1.55 - zeroLevel * .035 - zeroSeason * .025 - (isBoss ? .05 : 0),
  );
  final tileGap = (1.08 - zeroLevel * .006 - zeroSeason * .006).clamp(
    .96,
    1.08,
  );
  final warningDuration = (reactionTime + .26).clamp(1.05, 1.82);
  final shake = (2.8 + zeroSeason * .25 + zeroLevel * .14 + (isBoss ? .9 : 0))
      .clamp(2.8, 5.2);
  final difficultyLevel = (level + zeroSeason * 2).clamp(1, 10);
  return GameDifficultyConfig(
    speedMultiplier: speed.toDouble(),
    brokenChance: brokenChance.toDouble(),
    coinChance: coinChance.toDouble(),
    speedTileChance: speedTileChance.toDouble(),
    reactionTime: reactionTime.toDouble(),
    tileGap: tileGap.toDouble(),
    warningDuration: warningDuration.toDouble(),
    cameraShakeStrength: shake.toDouble(),
    rewardMultiplier: 1 + (difficultyLevel ~/ 4) + (isBoss ? 2 : 0),
    difficultyLevel: difficultyLevel,
    difficultyLabel: _labelForLevel(level),
  );
}

String _labelForLevel(int level) {
  if (level <= 2) return 'Flow';
  if (level <= 4) return 'Pulse';
  if (level <= 6) return 'Rush';
  if (level <= 9) return 'Storm';
  return 'Boss';
}

double _seasonCurveModifier(int season) {
  switch (season) {
    case 2:
      return .015;
    case 3:
      return .03;
    case 4:
      return .045;
    case 5:
      return .06;
    default:
      return 0;
  }
}

List<String> buildBalanceDebugNotes() {
  return [
    for (var season = 1; season <= 5; season++)
      for (var level = 1; level <= 10; level++)
        'Season $season Level $level speed: '
            '${difficultyForLevel(season, level).speedMultiplier.toStringAsFixed(2)}',
  ];
}
