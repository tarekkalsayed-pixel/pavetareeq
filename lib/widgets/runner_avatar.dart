import 'package:flutter/material.dart';

import '../game/runner_painter.dart';
import '../models/skin_model.dart';

class RunnerAvatar extends StatelessWidget {
  const RunnerAvatar({required this.skin, this.size = 54, super.key});

  final RunnerSkin skin;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedRunner(
      skin: skin,
      animationValue: .18,
      pose: RunnerPose.idle,
      size: size,
    );
  }
}
