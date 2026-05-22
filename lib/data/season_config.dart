import 'package:flutter/material.dart';

import '../models/season_model.dart';

class SeasonVisualConfig {
  const SeasonVisualConfig({
    required this.name,
    required this.backgroundGradient,
    required this.roadStyle,
    required this.platformStyle,
    required this.particleStyle,
    required this.accentColors,
    required this.musicPath,
    required this.levelNodeStyle,
    required this.decorativeElements,
  });

  final String name;
  final List<Color> backgroundGradient;
  final String roadStyle;
  final String platformStyle;
  final String particleStyle;
  final List<Color> accentColors;
  final String musicPath;
  final String levelNodeStyle;
  final String decorativeElements;

  factory SeasonVisualConfig.fromSeason(SeasonConfig season) {
    switch (season.id) {
      case 1:
        return SeasonVisualConfig(
          name: season.name,
          backgroundGradient: season.backgroundGradient,
          roadStyle: 'toy road',
          platformStyle: 'rounded toy blocks',
          particleStyle: season.particleStyle,
          accentColors: season.colors,
          musicPath: season.musicAsset,
          levelNodeStyle: 'block badge',
          decorativeElements: 'toy city blocks and lights',
        );
      case 2:
        return SeasonVisualConfig(
          name: season.name,
          backgroundGradient: season.backgroundGradient,
          roadStyle: 'floating candy road',
          platformStyle: 'pastel candy platforms',
          particleStyle: season.particleStyle,
          accentColors: season.colors,
          musicPath: season.musicAsset,
          levelNodeStyle: 'soft candy badge',
          decorativeElements: 'clouds and candy bubbles',
        );
      case 3:
        return SeasonVisualConfig(
          name: season.name,
          backgroundGradient: season.backgroundGradient,
          roadStyle: 'golden route',
          platformStyle: 'ancient marked stones',
          particleStyle: season.particleStyle,
          accentColors: season.colors,
          musicPath: season.musicAsset,
          levelNodeStyle: 'sun medallion',
          decorativeElements: 'sun glow and sand lines',
        );
      case 4:
        return SeasonVisualConfig(
          name: season.name,
          backgroundGradient: season.backgroundGradient,
          roadStyle: 'cyber grid',
          platformStyle: 'digital neon plates',
          particleStyle: season.particleStyle,
          accentColors: season.colors,
          musicPath: season.musicAsset,
          levelNodeStyle: 'glitch badge',
          decorativeElements: 'grid and glitch lines',
        );
      default:
        return SeasonVisualConfig(
          name: season.name,
          backgroundGradient: season.backgroundGradient,
          roadStyle: 'floating space path',
          platformStyle: 'low gravity plates',
          particleStyle: season.particleStyle,
          accentColors: season.colors,
          musicPath: season.musicAsset,
          levelNodeStyle: 'star badge',
          decorativeElements: 'stars, planets, and glow',
        );
    }
  }
}
