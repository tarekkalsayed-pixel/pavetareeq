import 'package:flutter/material.dart';

import '../game/difficulty_config.dart';
import 'tile_model.dart';

class SeasonConfig {
  const SeasonConfig({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundGradient,
    required this.particleStyle,
    required this.musicAsset,
    required this.gameplayModifierDescription,
    required this.levelDifficultyModifier,
    required this.allowedTiles,
  });

  final int id;
  final String name;
  final String subtitle;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final List<Color> backgroundGradient;
  final String particleStyle;
  final String musicAsset;
  final String gameplayModifierDescription;
  final double levelDifficultyModifier;
  final List<TileType> allowedTiles;

  List<Color> get colors => [primaryColor, secondaryColor];
}

class LevelConfig {
  const LevelConfig({
    required this.season,
    required this.level,
    required this.tiles,
    required this.speed,
    required this.difficulty,
  });

  final SeasonConfig season;
  final int level;
  final List<TileType> tiles;
  final double speed;
  final GameDifficultyConfig difficulty;

  bool get isBoss => level == 10;
  String get id => '${season.id}-$level';
  int get availableCoins => tiles.where((type) => type == TileType.coin).length;
}
