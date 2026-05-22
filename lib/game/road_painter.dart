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
    _paintReferenceWorlds(canvas, size);
    _paintRoadGlow(canvas, size);
    _paintReferenceCoinTrail(canvas, size);

    final baseIndex = position.floor();
    for (
      var i = min(tiles.length - 1, baseIndex + 11);
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

  void _paintReferenceWorlds(Canvas canvas, Size size) {
    final topHeight = size.height * .34;
    final panels = [
      (const Color(0xFF45B8FF), const Color(0xFFFF67B7)),
      (const Color(0xFFFFB9E8), const Color(0xFFFFE188)),
      (const Color(0xFFFFB15B), const Color(0xFF7B3B20)),
      (const Color(0xFF1A1D66), const Color(0xFFFF4FD8)),
      (const Color(0xFF060D36), const Color(0xFF3DDCFF)),
    ];
    final panelWidth = size.width / 4.15;
    for (var i = 0; i < panels.length; i++) {
      final x = -size.width * .1 + i * panelWidth * .78;
      final panel = Path()
        ..moveTo(x, 0)
        ..lineTo(x + panelWidth, 0)
        ..lineTo(x + panelWidth * .7, topHeight)
        ..lineTo(x - panelWidth * .3, topHeight)
        ..close();
      canvas.drawPath(
        panel,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [panels[i].$1, panels[i].$2],
          ).createShader(Rect.fromLTWH(x, 0, panelWidth, topHeight)),
      );
      canvas.drawPath(
        panel,
        Paint()
          ..color = Colors.white.withValues(alpha: .42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
      _paintPanelMotif(canvas, size, i, x, panelWidth, topHeight);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, topHeight * .62, size.width, topHeight * .5),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, kInk.withValues(alpha: .72)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, topHeight)),
    );
  }

  void _paintPanelMotif(
    Canvas canvas,
    Size size,
    int index,
    double x,
    double w,
    double h,
  ) {
    final cx = x + w * .5;
    if (index == 0) {
      for (var i = 0; i < 4; i++) {
        final rect = Rect.fromLTWH(
          x + w * (.2 + i * .13),
          h * (.33 - i * .02),
          w * .11,
          h * (.24 + i * .04),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(5)),
          Paint()..color = Colors.white.withValues(alpha: .2),
        );
      }
      canvas.drawCircle(
        Offset(cx - w * .15, h * .62),
        w * .07,
        Paint()..color = const Color(0xFFFFD05A).withValues(alpha: .55),
      );
    } else if (index == 1) {
      canvas.drawCircle(
        Offset(cx, h * .48),
        w * .14,
        Paint()..color = const Color(0xFFFF75C8).withValues(alpha: .42),
      );
      for (var i = 0; i < 3; i++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x + w * (.25 + i * .22), h * .25),
            width: w * .25,
            height: h * .09,
          ),
          Paint()..color = Colors.white.withValues(alpha: .38),
        );
      }
    } else if (index == 2) {
      for (var i = 0; i < 3; i++) {
        final py = h * (.62 - i * .14);
        final pyramid = Path()
          ..moveTo(cx - w * (.2 - i * .04), py)
          ..lineTo(cx + w * (.2 - i * .04), py)
          ..lineTo(cx, py - h * (.18 - i * .025))
          ..close();
        canvas.drawPath(
          pyramid,
          Paint()..color = const Color(0xFFFFD05A).withValues(alpha: .24),
        );
      }
    } else if (index == 3) {
      for (var i = 0; i < 5; i++) {
        final rect = Rect.fromLTWH(
          x + w * (.17 + i * .1),
          h * (.25 + (i % 2) * .05),
          w * .07,
          h * (.42 - (i % 3) * .04),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = const Color(0xFF3DDCFF).withValues(alpha: .26),
        );
      }
    } else {
      for (var i = 0; i < 16; i++) {
        canvas.drawCircle(
          Offset(
            x + (i * 29 % max(w, 1)).toDouble(),
            h * (.12 + (i % 7) * .08),
          ),
          1.2 + (i % 2),
          Paint()..color = Colors.white.withValues(alpha: .75),
        );
      }
      canvas.drawCircle(
        Offset(cx + w * .18, h * .28),
        w * .13,
        Paint()..color = const Color(0xFF5B63FF).withValues(alpha: .36),
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
    for (var i = 0; i < 4; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final x0 = size.width / 2 + side * (28 + i * 10);
      final x1 = size.width / 2 + side * size.width * (.43 + i * .02);
      canvas.drawLine(
        Offset(x0, size.height * .14),
        Offset(x1, size.height * .96),
        Paint()
          ..color = (i < 2 ? kGlowBlue : kGlowPink).withValues(alpha: .48)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  void _paintReferenceCoinTrail(Canvas canvas, Size size) {
    final count = 7;
    for (var i = 0; i < count; i++) {
      final p = i / (count - 1);
      final x = size.width * (.58 + p * .2 + sin(pulse * pi * 2 + i) * .01);
      final y = size.height * (.2 + p * .28);
      final r = 8 + p * 9;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = kGold.withValues(alpha: .2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(Offset(x, y), r, Paint()..color = kGold);
      canvas.drawCircle(
        Offset(x - r * .25, y - r * .28),
        r * .28,
        Paint()..color = Colors.white.withValues(alpha: .38),
      );
      _paintStar(canvas, Offset(x, y), r * .52, Colors.white);
    }
    final tap = Offset(size.width * .53, size.height * .78);
    for (var i = 0; i < 3; i++) {
      final radius = 20 + i * 14 + sin(pulse * pi * 2).abs() * 8;
      canvas.drawCircle(
        tap,
        radius,
        Paint()
          ..color = kGlowBlue.withValues(alpha: .22 - i * .045)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
    }
    canvas.drawCircle(
      tap,
      7,
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _paintStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -pi / 2 + i * pi / 5;
      final r = i.isEven ? radius : radius * .42;
      final point = center + Offset(cos(angle) * r, sin(angle) * r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: .88));
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
