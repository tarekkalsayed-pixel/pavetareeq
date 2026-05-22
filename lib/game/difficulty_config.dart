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
  final bossBoost = isBoss ? .10 : 0.0;
  // Tuning point: keep this curve linear and capped. Boss levels add a small
  // readable bump; challenge should come from patterns, not impossible speed.
  final speed =
      (1.0 +
              zeroSeason * .08 +
              zeroLevel * .035 +
              bossBoost +
              (seasonCurveModifier ?? _seasonCurveModifier(season)))
          .clamp(1.0, 1.85);
  final brokenChance =
      (.11 + zeroSeason * .018 + zeroLevel * .018 + (isBoss ? .045 : 0)).clamp(
        .12,
        .36,
      );
  final coinChance = (.24 - zeroLevel * .007 + zeroSeason * .005).clamp(
    .15,
    .27,
  );
  final speedTileChance =
      (.045 + zeroSeason * .008 + zeroLevel * .007 + (level >= 6 ? .018 : 0))
          .clamp(.04, .14);
  final reactionTime = max(
    season <= 2 ? .68 : .64,
    1.22 - zeroLevel * .038 - zeroSeason * .035 - (isBoss ? .08 : 0),
  );
  final tileGap = (.99 - zeroLevel * .012 - zeroSeason * .014).clamp(.82, .99);
  final warningDuration = (reactionTime + .22).clamp(.78, 1.48);
  final shake = (5.5 + zeroSeason * .75 + zeroLevel * .32 + (isBoss ? 1.8 : 0))
      .clamp(5.5, 11.5);
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
