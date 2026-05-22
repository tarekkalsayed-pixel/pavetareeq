import 'package:flutter/material.dart';

import '../game/difficulty_config.dart';
import '../models/season_model.dart';
import '../models/skin_model.dart';
import '../models/tile_model.dart';

class GameData {
  static const seasons = <SeasonConfig>[
    SeasonConfig(
      id: 1,
      name: 'Toy City',
      subtitle: 'Colorful arcade city',
      description: 'Toy blocks, city lights, and clean arcade rhythm.',
      primaryColor: Color(0xFFFF5A6E),
      secondaryColor: Color(0xFFFFD166),
      backgroundGradient: [
        Color(0xFF4CC9F0),
        Color(0xFFFFF1A8),
        Color(0xFFFF7AC8),
      ],
      particleStyle: 'confetti sparks',
      musicAsset: 'audio/music/season_1_toy_city.mp3',
      gameplayModifierDescription: 'Standard clean rhythm',
      levelDifficultyModifier: 0,
      allowedTiles: [TileType.safe, TileType.broken, TileType.coin],
    ),
    SeasonConfig(
      id: 2,
      name: 'Candy Sky',
      subtitle: 'Pastel floating candy clouds',
      description: 'Candy clouds, floating platforms, and soft sky motion.',
      primaryColor: Color(0xFFFF7AC8),
      secondaryColor: Color(0xFF7AF7FF),
      backgroundGradient: [
        Color(0xFF8EDCFF),
        Color(0xFFFFC6E7),
        Color(0xFFFFF3B0),
      ],
      particleStyle: 'candy bubbles',
      musicAsset: 'audio/music/season_2_candy_sky.mp3',
      gameplayModifierDescription: 'Soft floating transitions',
      levelDifficultyModifier: .015,
      allowedTiles: [
        TileType.safe,
        TileType.broken,
        TileType.coin,
        TileType.ramp,
        TileType.speed,
        TileType.slow,
      ],
    ),
    SeasonConfig(
      id: 3,
      name: 'Desert Rush',
      subtitle: 'Warm desert route',
      description: 'Golden roads with mild wind and locked tiles.',
      primaryColor: Color(0xFFFFB347),
      secondaryColor: Color(0xFFFFE082),
      backgroundGradient: [
        Color(0xFF3A2134),
        Color(0xFF6E3D20),
        Color(0xFF100A14),
      ],
      particleStyle: 'soft sand wind',
      musicAsset: 'audio/music/season_3_desert_tareeq.mp3',
      gameplayModifierDescription:
          'Mild visual wind particles without obstruction',
      levelDifficultyModifier: .03,
      allowedTiles: [
        TileType.safe,
        TileType.broken,
        TileType.coin,
        TileType.fallingBridge,
        TileType.locked,
      ],
    ),
    SeasonConfig(
      id: 4,
      name: 'Neon Night',
      subtitle: 'Dark cyber city',
      description: 'Digital platforms with fair moving danger.',
      primaryColor: Color(0xFF40C4FF),
      secondaryColor: Color(0xFF9B5DE5),
      backgroundGradient: [
        Color(0xFF050613),
        Color(0xFF101B45),
        Color(0xFF070B1D),
      ],
      particleStyle: 'digital pixels',
      musicAsset: 'audio/music/season_4_neon_night.mp3',
      gameplayModifierDescription: 'Subtle platform movement, still fair',
      levelDifficultyModifier: .045,
      allowedTiles: [
        TileType.safe,
        TileType.broken,
        TileType.coin,
        TileType.moving,
        TileType.laserWarning,
        TileType.speed,
      ],
    ),
    SeasonConfig(
      id: 5,
      name: 'Space Road',
      subtitle: 'Stars and floating road',
      description: 'Floating cosmic routes with gravity pulses.',
      primaryColor: Color(0xFF7C4DFF),
      secondaryColor: Color(0xFF40C4FF),
      backgroundGradient: [
        Color(0xFF06071B),
        Color(0xFF141047),
        Color(0xFF02030A),
      ],
      particleStyle: 'stars and dust',
      musicAsset: 'audio/music/season_5_space_road.mp3',
      gameplayModifierDescription: 'Slightly floaty animation feel',
      levelDifficultyModifier: .06,
      allowedTiles: [
        TileType.safe,
        TileType.broken,
        TileType.coin,
        TileType.gravity,
        TileType.teleport,
        TileType.fallingBridge,
        TileType.locked,
      ],
    ),
  ];

  static const skins = <RunnerSkin>[
    RunnerSkin(
      id: 'default',
      name: 'Default Runner',
      primary: Color(0xFF3DDCFF),
      secondary: Color(0xFFFFFFFF),
      unlockText: 'Unlocked',
      coinCost: 0,
    ),
    RunnerSkin(
      id: 'skater',
      name: 'Skater',
      primary: Color(0xFFFF4FD8),
      secondary: Color(0xFF2AF598),
      unlockText: 'Unlock with 120 coins',
      coinCost: 120,
    ),
    RunnerSkin(
      id: 'robot',
      name: 'Robot',
      primary: Color(0xFFB0BEC5),
      secondary: Color(0xFFFFD05A),
      unlockText: 'Unlock with 220 coins',
      coinCost: 220,
    ),
    RunnerSkin(
      id: 'ninja',
      name: 'Ninja',
      primary: Color(0xFF1A1F36),
      secondary: Color(0xFFFF5A6E),
      unlockText: 'Unlock with 360 coins',
      coinCost: 360,
    ),
    RunnerSkin(
      id: 'pharaoh',
      name: 'Little Pharaoh',
      primary: Color(0xFFFFD05A),
      secondary: Color(0xFF00C2A8),
      unlockText: 'Complete Season 3',
      coinCost: 0,
      requiredSeason: 3,
    ),
    RunnerSkin(
      id: 'astronaut',
      name: 'Astronaut',
      primary: Color(0xFFFFFFFF),
      secondary: Color(0xFF7C4DFF),
      unlockText: 'Complete Season 5',
      coinCost: 0,
      requiredSeason: 5,
    ),
  ];

  static LevelConfig level(int seasonId, int level) {
    final season = seasons.firstWhere((item) => item.id == seasonId);
    final difficulty = difficultyForLevel(
      seasonId,
      level,
      seasonCurveModifier: season.levelDifficultyModifier,
    );
    return LevelConfig(
      season: season,
      level: level,
      speed: difficulty.speedMultiplier,
      difficulty: difficulty,
      tiles: _buildTiles(season, level, difficulty),
    );
  }

  static List<LevelConfig> levelsForSeason(int seasonId) =>
      List.generate(10, (index) => level(seasonId, index + 1));

  static List<TileType> _buildTiles(
    SeasonConfig season,
    int level,
    GameDifficultyConfig difficulty,
  ) {
    final length =
        15 + level + season.id + (level >= 7 ? 3 : 0) + (level == 10 ? 4 : 0);
    final tiles = <TileType>[
      TileType.safe,
      TileType.safe,
      TileType.safe,
      TileType.coin,
    ];
    for (var i = 3; i < length - 1; i++) {
      final roll = _roll(season.id, level, i);
      final previousDanger = tiles.isNotEmpty && _isDanger(tiles.last);
      final allowBackToBackDanger = false;
      if (roll < difficulty.brokenChance &&
          (!previousDanger || allowBackToBackDanger)) {
        tiles.add(_dangerTile(season, i, level));
      } else if (roll < difficulty.brokenChance + difficulty.speedTileChance &&
          season.allowedTiles.contains(TileType.speed)) {
        tiles.add(TileType.speed);
      } else if (roll <
              difficulty.brokenChance + difficulty.speedTileChance + .07 &&
          season.allowedTiles.length > 3) {
        tiles.add(_specialTile(season, i, level));
      } else if (roll <
          difficulty.brokenChance +
              difficulty.speedTileChance +
              .07 +
              difficulty.coinChance) {
        tiles.add(TileType.coin);
      } else {
        tiles.add(TileType.safe);
      }
    }
    if (level == 10) {
      tiles.insertAll(tiles.length - 1, _bossPattern(season));
    }
    tiles.add(TileType.finish);
    return tiles;
  }

  static double _roll(int seasonId, int level, int index) {
    final value =
        (seasonId * 73 + level * 41 + index * 29 + index * level * 7) % 100;
    return value / 100;
  }

  static TileType _dangerTile(SeasonConfig season, int index, int level) {
    final danger = season.allowedTiles
        .where(
          (type) =>
              type == TileType.broken ||
              type == TileType.fallingBridge ||
              type == TileType.locked ||
              type == TileType.laserWarning,
        )
        .toList();
    return danger[(index + level + season.id) % danger.length];
  }

  static TileType _specialTile(SeasonConfig season, int index, int level) {
    final specials = season.allowedTiles
        .where(
          (type) =>
              type != TileType.safe &&
              type != TileType.broken &&
              type != TileType.coin &&
              type != TileType.fallingBridge &&
              type != TileType.locked &&
              type != TileType.laserWarning,
        )
        .toList();
    if (specials.isEmpty) return TileType.safe;
    return specials[(index + level + season.id) % specials.length];
  }

  static bool _isDanger(TileType type) =>
      type == TileType.broken ||
      type == TileType.fallingBridge ||
      type == TileType.locked ||
      type == TileType.laserWarning;

  static List<TileType> _bossPattern(SeasonConfig season) {
    final dangerA = _dangerTile(season, 3, 10);
    final dangerB = _dangerTile(season, 7, 10);
    final hasSpeed = season.allowedTiles.contains(TileType.speed);
    final hasMoving = season.allowedTiles.contains(TileType.moving);
    final hasGravity = season.allowedTiles.contains(TileType.gravity);
    final hasTeleport = season.allowedTiles.contains(TileType.teleport);
    return [
      TileType.coin,
      dangerA,
      TileType.safe,
      if (hasSpeed) TileType.speed else TileType.coin,
      TileType.safe,
      dangerB,
      if (hasMoving) TileType.moving else TileType.safe,
      TileType.coin,
      if (hasGravity) TileType.gravity else if (hasTeleport) TileType.teleport,
      dangerA,
      TileType.safe,
      TileType.coin,
    ];
  }
}
