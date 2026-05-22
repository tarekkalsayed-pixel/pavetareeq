import 'dart:math';

import 'package:flutter/material.dart';

import '../models/season_model.dart';
import '../models/tile_model.dart';
import '../theme.dart';

class RoadTileFrame {
  const RoadTileFrame({
    required this.index,
    required this.path,
    required this.center,
    required this.scale,
  });

  final int index;
  final Path path;
  final Offset center;
  final double scale;
}

class ArcadeRoadPainter extends CustomPainter {
  ArcadeRoadPainter({
    required this.tiles,
    required this.position,
    required this.season,
    required this.pulse,
    required this.dangerPulse,
    required this.frames,
    this.darken = 0,
    this.speedIntensity = 1,
    this.themeColors,
  });

  final List<RoadTile> tiles;
  final double position;
  final SeasonConfig season;
  final double pulse;
  final double dangerPulse;
  final List<RoadTileFrame> frames;
  final double darken;
  final double speedIntensity;
  final List<Color>? themeColors;

  @override
  void paint(Canvas canvas, Size size) {
    frames.clear();
    _paintSky(canvas, size);
    _paintRoadGlow(canvas, size);

    final baseIndex = position.floor();
    for (
      var i = min(tiles.length - 1, baseIndex + 8);
      i >= max(0, baseIndex - 1);
      i--
    ) {
      final depth = i - position;
      final frame = _frameFor(size, i, depth);
      if (frame == null) continue;
      frames.add(frame);
      _paintTile(canvas, frame, tiles[i], i == baseIndex + 1);
    }

    if (darken > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: darken * .55),
      );
    }
  }

  RoadTileFrame? _frameFor(Size size, int index, double depth) {
    final z = 1 - (depth / 11).clamp(0.0, 1.0);
    final y = _easeInCubic(z) * size.height * .84 + size.height * .08;
    if (y < -40 || y > size.height + 80) return null;
    final curve = sin((index + pulse * .7) * .7) * 20 * (1 - z);
    final centerX = size.width / 2 + curve;
    final widthNear = size.width * (.34 + z * .48);
    final height = 26 + z * 74;
    final topWidth = widthNear * (.56 + z * .14);
    final bottomWidth = widthNear;
    final path = Path()
      ..moveTo(centerX - topWidth / 2, y - height / 2)
      ..lineTo(centerX + topWidth / 2, y - height / 2)
      ..lineTo(centerX + bottomWidth / 2, y + height / 2)
      ..lineTo(centerX - bottomWidth / 2, y + height / 2)
      ..close();
    return RoadTileFrame(
      index: index,
      path: path,
      center: Offset(centerX, y),
      scale: z,
    );
  }

  void _paintSky(Canvas canvas, Size size) {
    final colors = _backgroundColors();
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(Offset.zero & size),
    );
    if (season.id == 1) {
      _paintToyCity(canvas, size);
    } else if (season.id == 5) {
      final starPaint = Paint()..color = Colors.white.withValues(alpha: .65);
      for (var i = 0; i < 38; i++) {
        final x = (i * 47 + 19) % size.width;
        final y = (i * 83 + pulse * 18) % (size.height * .62);
        canvas.drawCircle(Offset(x, y), 1 + (i % 3) * .5, starPaint);
      }
      canvas.drawCircle(
        Offset(size.width * .82, size.height * .18),
        34,
        Paint()..color = _themeColors.first.withValues(alpha: .18),
      );
    } else if (season.id == 2) {
      final cloud = Paint()..color = Colors.white.withValues(alpha: .55);
      for (var i = 0; i < 6; i++) {
        final x = (i * 92 + pulse * 10) % (size.width + 110) - 55;
        final y = size.height * (.15 + i * .07);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 110, height: 34),
          cloud,
        );
        canvas.drawCircle(
          Offset(x + 34, y - 10),
          13,
          Paint()..color = const Color(0xFFFF7AC8).withValues(alpha: .28),
        );
      }
    } else if (season.id == 3) {
      canvas.drawCircle(
        Offset(size.width * .2, size.height * .16),
        48,
        Paint()..color = const Color(0xFFFFB347).withValues(alpha: .22),
      );
      for (var i = 0; i < 12; i++) {
        final y = size.height * (.2 + i * .045);
        canvas.drawLine(
          Offset(0, y + sin(pulse * pi + i) * 4),
          Offset(size.width, y + 14 + sin(pulse * pi + i) * 4),
          Paint()
            ..color = const Color(0xFFFFE082).withValues(alpha: .055)
            ..strokeWidth = 2,
        );
      }
    } else if (season.id == 4) {
      final grid = Paint()
        ..color = _themeColors.first.withValues(alpha: .16)
        ..strokeWidth = 1;
      for (var x = 0.0; x < size.width; x += 38) {
        canvas.drawLine(
          Offset(x, size.height * .08),
          Offset(x + 80, size.height),
          grid,
        );
      }
      for (var y = size.height * .22; y < size.height; y += 42) {
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y + sin(pulse * pi) * 3),
          grid,
        );
      }
    }
  }

  void _paintToyCity(Canvas canvas, Size size) {
    final blockPaint = Paint()..color = Colors.white.withValues(alpha: .18);
    for (var i = 0; i < 8; i++) {
      final w = 34.0 + (i % 3) * 18;
      final h = 58.0 + (i % 4) * 20;
      final x = ((i * 67) % max(size.width, 1)).toDouble();
      final rect = Rect.fromLTWH(x, size.height * .28 - h * .2, w, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        blockPaint,
      );
      canvas.drawCircle(
        rect.topCenter + const Offset(0, 10),
        4,
        Paint()..color = _themeColors.last.withValues(alpha: .35),
      );
    }
  }

  void _paintRoadGlow(Canvas canvas, Size size) {
    final top = Offset(size.width / 2, size.height * .1);
    final left = Offset(size.width * .11, size.height * .94);
    final right = Offset(size.width * .89, size.height * .94);
    final glow = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(
      glow,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                _themeColors.first.withValues(alpha: .18),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width / 2, size.height * .62),
                radius: size.width,
              ),
            ),
    );
    for (final x in [left, right]) {
      canvas.drawLine(
        top,
        x,
        Paint()
          ..color = _themeColors.last.withValues(
            alpha: (.1 + speedIntensity * .025).clamp(.12, .24),
          )
          ..strokeWidth = 2.5 + speedIntensity * .8
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            4 + speedIntensity * 1.4,
          ),
      );
    }
    for (var i = 0; i < 9; i++) {
      final p = ((i / 9) + pulse * speedIntensity * .7) % 1;
      final y = size.height * (.12 + p * p * .85);
      final w = size.width * (.08 + p * .78);
      canvas.drawLine(
        Offset(size.width / 2 - w / 2, y),
        Offset(size.width / 2 + w / 2, y),
        Paint()
          ..color = _themeColors.first.withValues(
            alpha: (.04 + p * .08 * speedIntensity).clamp(.04, .2),
          )
          ..strokeWidth = 1 + p * 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintTile(
    Canvas canvas,
    RoadTileFrame frame,
    RoadTile tile,
    bool approaching,
  ) {
    final bounds = frame.path.getBounds();
    final color = _tileColor(tile);
    final danger = tile.isDanger && !tile.fixed;
    final glowAmount = danger && approaching
        ? .45 + sin(dangerPulse * pi * 2).abs() * .35
        : .18;
    canvas.drawPath(
      frame.path,
      Paint()
        ..color = color.withValues(alpha: .28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, danger ? 8 : 4),
    );
    canvas.drawShadow(frame.path, Colors.black, 10 + frame.scale * 8, false);
    canvas.drawPath(
      frame.path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: .94),
            Color.lerp(color, Colors.black, .38)!,
          ],
        ).createShader(bounds),
    );
    canvas.drawPath(
      frame.path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 + frame.scale * 2
        ..color = (danger ? kDangerRed : _themeColors.last).withValues(
          alpha: glowAmount,
        ),
    );

    _paintTileDetails(canvas, frame, tile, bounds);
  }

  void _paintTileDetails(
    Canvas canvas,
    RoadTileFrame frame,
    RoadTile tile,
    Rect bounds,
  ) {
    final center = frame.center;
    final s = frame.scale;
    final white = Paint()
      ..color = Colors.white.withValues(alpha: .78)
      ..strokeWidth = 2 + s * 2
      ..strokeCap = StrokeCap.round;
    if (tile.fixed) {
      canvas.drawCircle(
        center,
        10 + s * 14,
        Paint()..color = kSafeGreen.withValues(alpha: .32),
      );
      canvas.drawLine(
        center + Offset(-10 - s * 8, 0),
        center + Offset(-2, 9 + s * 3),
        white,
      );
      canvas.drawLine(
        center + Offset(-2, 9 + s * 3),
        center + Offset(14 + s * 8, -10 - s * 4),
        white,
      );
      return;
    }
    switch (tile.type) {
      case TileType.safe:
        canvas.drawLine(
          Offset(bounds.left + bounds.width * .22, center.dy),
          Offset(bounds.right - bounds.width * .22, center.dy),
          white..color = Colors.white.withValues(alpha: .18),
        );
      case TileType.broken:
      case TileType.fallingBridge:
        for (var i = 0; i < 4; i++) {
          final x = bounds.left + bounds.width * (.25 + i * .14);
          canvas.drawLine(
            Offset(x, bounds.top + bounds.height * .22),
            Offset(
              x + 18 * (i.isEven ? 1 : -1),
              bounds.bottom - bounds.height * .2,
            ),
            white..color = Colors.black.withValues(alpha: .42),
          );
        }
      case TileType.coin:
        final r = 9 + s * 15;
        canvas.drawCircle(
          center + Offset(0, -12 - s * 14),
          r,
          Paint()..color = kGold,
        );
        canvas.drawCircle(
          center + Offset(0, -12 - s * 14),
          r * .55,
          Paint()..color = Colors.white.withValues(alpha: .28),
        );
      case TileType.ramp:
        canvas.drawLine(
          center + Offset(-24 * s, 12 * s),
          center + Offset(0, -16 * s),
          white,
        );
        canvas.drawLine(
          center + Offset(0, -16 * s),
          center + Offset(24 * s, 12 * s),
          white,
        );
      case TileType.speed:
        for (var i = 0; i < 3; i++) {
          final dx = (i - 1) * 16 * s;
          canvas.drawLine(
            center + Offset(dx - 8, 12),
            center + Offset(dx + 4, 0),
            white,
          );
          canvas.drawLine(
            center + Offset(dx + 4, 0),
            center + Offset(dx - 8, -12),
            white,
          );
        }
      case TileType.slow:
        canvas.drawCircle(
          center,
          12 + s * 10,
          white..style = PaintingStyle.stroke,
        );
      case TileType.locked:
        final rect = Rect.fromCenter(
          center: center,
          width: 28 + s * 20,
          height: 24 + s * 14,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(7)),
          white..style = PaintingStyle.stroke,
        );
        _text(canvas, '${tile.tapsLeft}', center, 16 + s * 16, Colors.white);
      case TileType.moving:
        canvas.drawCircle(
          center,
          16 + s * 10,
          white..style = PaintingStyle.stroke,
        );
        canvas.drawLine(
          center + Offset(-18 * s, 0),
          center + Offset(18 * s, 0),
          white,
        );
      case TileType.laserWarning:
        canvas.drawLine(
          Offset(bounds.left + 12, bounds.top + 10),
          Offset(bounds.right - 12, bounds.bottom - 10),
          white..color = kDangerRed,
        );
        canvas.drawLine(
          Offset(bounds.right - 12, bounds.top + 10),
          Offset(bounds.left + 12, bounds.bottom - 10),
          white..color = kDangerRed,
        );
      case TileType.teleport:
        canvas.drawCircle(
          center,
          16 + s * 16,
          white..style = PaintingStyle.stroke,
        );
        canvas.drawCircle(
          center,
          7 + s * 8,
          white..style = PaintingStyle.stroke,
        );
      case TileType.gravity:
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: 16 + s * 14),
          pulse * pi,
          pi * 1.3,
          false,
          white..style = PaintingStyle.stroke,
        );
      case TileType.finish:
        _paintFinishGate(canvas, bounds, s);
    }
  }

  void _paintFinishGate(Canvas canvas, Rect bounds, double scale) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4 + scale * 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(bounds.left + 14, bounds.bottom),
      Offset(bounds.left + 14, bounds.top - 34 * scale),
      paint,
    );
    canvas.drawLine(
      Offset(bounds.right - 14, bounds.bottom),
      Offset(bounds.right - 14, bounds.top - 34 * scale),
      paint,
    );
    canvas.drawLine(
      Offset(bounds.left + 14, bounds.top - 30 * scale),
      Offset(bounds.right - 14, bounds.top - 30 * scale),
      paint,
    );
    for (var i = 0; i < 6; i++) {
      final rect = Rect.fromLTWH(
        bounds.left + 20 + i * bounds.width / 7,
        bounds.top - 45 * scale,
        bounds.width / 8,
        16 * scale,
      );
      canvas.drawRect(
        rect,
        Paint()..color = i.isEven ? Colors.white : Colors.black,
      );
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  Color _tileColor(RoadTile tile) {
    if (tile.fixed) return kSafeGreen;
    switch (tile.type) {
      case TileType.safe:
        return Color.lerp(_themeColors.first, const Color(0xFF214B8F), .25)!;
      case TileType.coin:
        return kGold;
      case TileType.ramp:
        return const Color(0xFF38E54D);
      case TileType.speed:
        return const Color(0xFFFF8F00);
      case TileType.slow:
        return const Color(0xFF72D6FF);
      case TileType.teleport:
        return const Color(0xFF9B5DE5);
      case TileType.gravity:
        return const Color(0xFF00C2A8);
      case TileType.finish:
        return const Color(0xFF00E676);
      case TileType.broken:
      case TileType.fallingBridge:
      case TileType.locked:
      case TileType.moving:
      case TileType.laserWarning:
        return kDangerRed;
    }
  }

  List<Color> _backgroundColors() {
    return season.backgroundGradient;
  }

  List<Color> get _themeColors => themeColors ?? season.colors;

  double _easeInCubic(double x) => x * x * x;

  @override
  bool shouldRepaint(covariant ArcadeRoadPainter oldDelegate) => true;
}
