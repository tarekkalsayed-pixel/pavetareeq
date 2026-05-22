import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../game/runner_painter.dart';
import '../services/wardrobe_service.dart';

class RunnerPreview extends StatelessWidget {
  const RunnerPreview({
    required this.loadout,
    this.animationValue = .18,
    this.size = 150,
    super.key,
  });

  final WardrobeLoadout loadout;
  final double animationValue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallbackSkin = GameData.skins.firstWhere(
      (skin) => skin.id == loadout.character.id,
      orElse: () => GameData.skins.first,
    );
    return AnimatedRunner(
      skin: fallbackSkin,
      animationValue: animationValue,
      pose: RunnerPose.running,
      loadout: loadout,
      size: size,
    );
  }
}
