import 'package:flutter/material.dart';

enum TileType {
  safe,
  broken,
  coin,
  ramp,
  speed,
  slow,
  fallingBridge,
  locked,
  moving,
  laserWarning,
  teleport,
  gravity,
  finish,
}

class RoadTile {
  RoadTile({
    required this.type,
    this.fixed = false,
    this.collected = false,
    int? tapsLeft,
  }) : tapsLeft = tapsLeft ?? (type == TileType.locked ? 2 : 1);

  final TileType type;
  bool fixed;
  bool collected;
  int tapsLeft;

  bool get isDanger =>
      type == TileType.broken ||
      type == TileType.fallingBridge ||
      type == TileType.locked ||
      type == TileType.laserWarning;

  bool get canTap => isDanger || type == TileType.moving;

  bool get isPassable => !isDanger || fixed;

  IconData get icon {
    switch (type) {
      case TileType.safe:
        return Icons.check_rounded;
      case TileType.broken:
        return Icons.construction_rounded;
      case TileType.coin:
        return Icons.monetization_on_rounded;
      case TileType.ramp:
        return Icons.trending_up_rounded;
      case TileType.speed:
        return Icons.bolt_rounded;
      case TileType.slow:
        return Icons.slow_motion_video_rounded;
      case TileType.fallingBridge:
        return Icons.warning_rounded;
      case TileType.locked:
        return Icons.lock_rounded;
      case TileType.moving:
        return Icons.open_with_rounded;
      case TileType.laserWarning:
        return Icons.flash_on_rounded;
      case TileType.teleport:
        return Icons.switch_access_shortcut_rounded;
      case TileType.gravity:
        return Icons.public_rounded;
      case TileType.finish:
        return Icons.flag_rounded;
    }
  }
}
