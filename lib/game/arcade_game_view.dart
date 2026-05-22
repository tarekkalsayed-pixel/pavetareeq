import 'dart:math';

import 'package:flutter/material.dart';

import '../models/season_model.dart';
import '../models/skin_model.dart';
import '../models/tile_model.dart';
import '../services/wardrobe_service.dart';
import 'particle_system.dart';
import 'road_painter.dart';
import 'runner_painter.dart';

class ArcadeGameView extends StatelessWidget {
  const ArcadeGameView({
    required this.tiles,
    required this.position,
    required this.season,
    required this.skin,
    required this.runnerPhase,
    required this.particles,
    required this.onTapTile,
    required this.pose,
    this.shake = 0,
    this.darken = 0,
    this.speedIntensity = 1,
    this.loadout,
    super.key,
  });

  final List<RoadTile> tiles;
  final double position;
  final SeasonConfig season;
  final RunnerSkin skin;
  final double runnerPhase;
  final List<GameParticle> particles;
  final ValueChanged<int> onTapTile;
  final RunnerPose pose;
  final double shake;
  final double darken;
  final double speedIntensity;
  final WardrobeLoadout? loadout;

  @override
  Widget build(BuildContext context) {
    final frames = <RoadTileFrame>[];
    return LayoutBuilder(
      builder: (context, constraints) {
        final runnerSize = min(112.0, constraints.maxWidth * .27);
        final runnerLeft = constraints.maxWidth / 2 - runnerSize / 2;
        final runnerTop = constraints.maxHeight * .68 - runnerSize / 2;
        return Transform.translate(
          offset: Offset(sin(runnerPhase * pi * 14) * shake, 0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              for (final frame in frames.reversed) {
                if (frame.path.contains(details.localPosition)) {
                  onTapTile(frame.index);
                  return;
                }
              }
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: ArcadeRoadPainter(
                        tiles: tiles,
                        position: position,
                        season: season,
                        pulse: runnerPhase,
                        dangerPulse: runnerPhase,
                        frames: frames,
                        darken: darken,
                        speedIntensity: speedIntensity,
                        themeColors: loadout == null
                            ? null
                            : [
                                loadout!.roadTheme.primary,
                                loadout!.roadTheme.secondary,
                              ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(painter: ParticlePainter(particles)),
                  ),
                ),
                Positioned(
                  left: runnerLeft,
                  top: runnerTop,
                  child: AnimatedRunner(
                    skin: skin,
                    animationValue: runnerPhase,
                    pose: pose,
                    loadout: loadout,
                    size: runnerSize,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
