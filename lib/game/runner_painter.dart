import 'dart:math';

import 'package:flutter/material.dart';

import '../models/skin_model.dart';
import '../models/wardrobe_item.dart';
import '../services/wardrobe_service.dart';

enum RunnerPose { idle, running, jumping, falling, celebrating }

class AnimatedRunner extends StatelessWidget {
  const AnimatedRunner({
    required this.skin,
    required this.animationValue,
    required this.pose,
    this.loadout,
    this.size = 96,
    this.rearView = false,
    super.key,
  });

  final RunnerSkin skin;
  final double animationValue;
  final RunnerPose pose;
  final WardrobeLoadout? loadout;
  final double size;
  final bool rearView;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: RunnerPainter(
            skin: skin,
            runPhase: animationValue,
            pose: pose,
            loadout: loadout,
            rearView: rearView,
          ),
        ),
      ),
    );
  }
}

class RunnerPainter extends CustomPainter {
  const RunnerPainter({
    required this.skin,
    required this.runPhase,
    required this.pose,
    this.loadout,
    this.rearView = false,
  });

  final RunnerSkin skin;
  final double runPhase;
  final RunnerPose pose;
  final WardrobeLoadout? loadout;
  final bool rearView;

  @override
  void paint(Canvas canvas, Size size) {
    if (rearView) {
      _paintRearRunner(canvas, size);
      return;
    }
    final t = runPhase * pi * 2;
    final run = pose == RunnerPose.running || pose == RunnerPose.jumping;
    final fall = pose == RunnerPose.falling ? min(1.0, runPhase) : 0.0;
    final celebrate = pose == RunnerPose.celebrating ? sin(t) : 0.0;
    final jump = pose == RunnerPose.jumping ? sin(runPhase * pi) : 0.0;
    final idle = pose == RunnerPose.idle ? sin(t) * size.height * .012 : 0.0;
    final bob = run ? sin(t * 2) * size.height * .025 : idle;
    final squash = run ? 1 + sin(t * 2).abs() * .025 : 1.0;

    final character = loadout?.character;
    final hair = loadout?.hair;
    final outfit = loadout?.outfit;
    final top = loadout?.top;
    final jacketItem = loadout?.jacket;
    final pantsItem = loadout?.pants;
    final hat = loadout?.hat;
    final glasses = loadout?.glasses;
    final shoes = loadout?.shoes;
    final trail = loadout?.trail;
    final skinTone = _skinTone(character?.id ?? skin.id);
    final hairColor = hair?.primary ?? _hairColor(character?.id ?? skin.id);
    final jacket =
        jacketItem?.primary ??
        outfit?.primary ??
        character?.primary ??
        skin.primary;
    final trim =
        top?.secondary ??
        jacketItem?.secondary ??
        outfit?.secondary ??
        character?.secondary ??
        skin.secondary;
    final shirt = top?.primary ?? Color.lerp(jacket, Colors.white, .18)!;
    final pants = pantsItem?.primary ?? Color.lerp(jacket, Colors.black, .42)!;

    canvas.save();
    canvas.translate(
      size.width / 2,
      size.height / 2 +
          bob +
          fall * size.height * .28 -
          jump * size.height * .18,
    );
    canvas.rotate(fall * .8);
    canvas.scale(1 / squash, squash);
    canvas.translate(-size.width / 2, -size.height / 2);

    _paintTrail(canvas, size, trail, t, run || pose == RunnerPose.celebrating);
    _paintGroundShadow(canvas, size, fall);

    final hip = Offset(size.width * .5, size.height * .64);
    final neck = Offset(size.width * .5, size.height * .37);
    final head = Offset(size.width * .5, size.height * .235);
    final swing = sin(t) * size.width * .12;
    final legLift = cos(t) * size.height * .055;
    final armLift = pose == RunnerPose.celebrating
        ? size.height * (.09 + celebrate.abs() * .025)
        : 0.0;

    _paintLeg(
      canvas,
      size,
      start: hip + Offset(-size.width * .07, size.height * .05),
      knee: Offset(
        size.width * (.4 - swing * .002),
        size.height * .76 + legLift,
      ),
      foot: Offset(
        size.width * (.32 - swing * .002),
        size.height * .91 - legLift * .25,
      ),
      pants: pants,
      shoe: shoes,
      front: false,
    );
    _paintLeg(
      canvas,
      size,
      start: hip + Offset(size.width * .07, size.height * .05),
      knee: Offset(
        size.width * (.6 + swing * .002),
        size.height * .76 - legLift,
      ),
      foot: Offset(
        size.width * (.68 + swing * .002),
        size.height * .91 + legLift * .25,
      ),
      pants: Color.lerp(pants, Colors.white, .05)!,
      shoe: shoes,
      front: true,
    );

    _paintArm(
      canvas,
      size,
      shoulder: neck + Offset(-size.width * .14, size.height * .08),
      hand: Offset(size.width * .25 + swing, size.height * (.61 - armLift)),
      color: jacket,
      skinTone: skinTone,
    );
    _paintArm(
      canvas,
      size,
      shoulder: neck + Offset(size.width * .14, size.height * .08),
      hand: Offset(size.width * .75 - swing, size.height * (.61 - armLift)),
      color: Color.lerp(jacket, Colors.white, .08)!,
      skinTone: skinTone,
    );

    _paintBackGear(canvas, size, loadout);
    _paintTorso(canvas, size, jacket, trim, character?.id);
    _paintShirt(canvas, size, shirt, trim, character?.id, loadout);
    _paintHead(canvas, size, head, skinTone, hairColor, character?.id, t);
    _paintHat(canvas, size, hat, hairColor);
    _paintGlasses(canvas, size, glasses);
    _paintAccessories(canvas, size, loadout);
    _paintEffect(canvas, size, loadout?.effect, t);
    canvas.restore();
  }

  void _paintRearRunner(Canvas canvas, Size size) {
    final t = runPhase * pi * 2;
    final run = pose == RunnerPose.running || pose == RunnerPose.jumping;
    final fall = pose == RunnerPose.falling ? min(1.0, runPhase) : 0.0;
    final bob = run ? sin(t * 2) * size.height * .025 : sin(t) * 1.4;
    final swing = sin(t) * size.width * .12;
    final legLift = cos(t) * size.height * .055;
    final jacket =
        loadout?.jacket.primary ?? loadout?.outfit.primary ?? skin.primary;
    final trim =
        loadout?.top.secondary ?? loadout?.outfit.secondary ?? skin.secondary;
    final pants = loadout?.pants.primary ?? const Color(0xFF172033);
    final shoe = loadout?.shoes.primary ?? const Color(0xFFFFA229);
    final hairColor = loadout?.hair.primary ?? const Color(0xFF171827);
    final skinTone = _skinTone(loadout?.character.id ?? skin.id);

    canvas.save();
    canvas.translate(
      size.width / 2,
      size.height / 2 + bob + fall * size.height * .28,
    );
    canvas.rotate(fall * .75);
    canvas.translate(-size.width / 2, -size.height / 2);

    _paintTrail(canvas, size, loadout?.trail, t, run);
    _paintGroundShadow(canvas, size, fall);

    final glowPaint = Paint()
      ..color = const Color(0xFF3DDCFF).withValues(alpha: .14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .62),
        width: size.width * .72,
        height: size.height * .86,
      ),
      glowPaint,
    );

    final hip = Offset(size.width * .5, size.height * .64);
    _paintRearLeg(
      canvas,
      size,
      hip + Offset(-size.width * .07, size.height * .04),
      Offset(size.width * (.39 - swing * .002), size.height * .77 + legLift),
      Offset(
        size.width * (.31 - swing * .002),
        size.height * .91 - legLift * .25,
      ),
      Color.lerp(pants, Colors.black, .12)!,
      shoe,
    );
    _paintRearLeg(
      canvas,
      size,
      hip + Offset(size.width * .07, size.height * .04),
      Offset(size.width * (.61 + swing * .002), size.height * .77 - legLift),
      Offset(
        size.width * (.69 + swing * .002),
        size.height * .91 + legLift * .25,
      ),
      pants,
      shoe,
    );

    _paintRearArm(
      canvas,
      size,
      Offset(size.width * .35, size.height * .42),
      Offset(size.width * .24 + swing, size.height * .66),
      jacket,
      skinTone,
    );
    _paintRearArm(
      canvas,
      size,
      Offset(size.width * .65, size.height * .42),
      Offset(size.width * .76 - swing, size.height * .66),
      Color.lerp(jacket, Colors.white, .08)!,
      skinTone,
    );

    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .53),
        width: size.width * .44,
        height: size.height * .35,
      ),
      Radius.circular(size.width * .09),
    );
    canvas.drawRRect(
      torso,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(jacket, Colors.white, .16)!,
            jacket,
            Color.lerp(jacket, Colors.black, .25)!,
          ],
        ).createShader(Offset.zero & size),
    );
    _paintTinyNumber(canvas, size, '7', Color.lerp(trim, Colors.white, .2)!);

    final neck = Rect.fromCenter(
      center: Offset(size.width * .5, size.height * .34),
      width: size.width * .16,
      height: size.height * .08,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(neck, Radius.circular(size.width * .04)),
      Paint()..color = skinTone,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .25),
        width: size.width * .38,
        height: size.height * .34,
      ),
      Paint()..color = hairColor,
    );
    for (var i = 0; i < 7; i++) {
      final angle = -pi * .95 + i * pi * .32;
      final base = Offset(size.width * .5, size.height * .21);
      final tip =
          base +
          Offset(cos(angle) * size.width * .2, sin(angle) * size.height * .18);
      final spike = Path()
        ..moveTo(base.dx, base.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(
          base.dx + cos(angle + .55) * size.width * .12,
          base.dy + sin(angle + .55) * size.height * .1,
        )
        ..close();
      canvas.drawPath(spike, Paint()..color = hairColor);
    }
    canvas.restore();
  }

  void _paintRearLeg(
    Canvas canvas,
    Size size,
    Offset start,
    Offset knee,
    Offset foot,
    Color pants,
    Color shoe,
  ) {
    canvas.drawLine(
      start,
      knee,
      Paint()
        ..color = pants
        ..strokeWidth = size.width * .078
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      knee,
      foot,
      Paint()
        ..color = pants
        ..strokeWidth = size.width * .072
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: foot + Offset(0, size.height * .02),
          width: size.width * .22,
          height: size.height * .085,
        ),
        Radius.circular(size.width * .04),
      ),
      Paint()..color = shoe,
    );
  }

  void _paintRearArm(
    Canvas canvas,
    Size size,
    Offset shoulder,
    Offset hand,
    Color sleeve,
    Color skinTone,
  ) {
    final elbow = Offset(
      (shoulder.dx + hand.dx) / 2,
      shoulder.dy + size.height * .14,
    );
    canvas.drawLine(
      shoulder,
      elbow,
      Paint()
        ..color = sleeve
        ..strokeWidth = size.width * .07
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      elbow,
      hand,
      Paint()
        ..color = skinTone
        ..strokeWidth = size.width * .052
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(hand, size.width * .04, Paint()..color = skinTone);
  }

  void _paintGroundShadow(Canvas canvas, Size size, double fall) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .93),
        width: size.width * (.62 - fall * .16),
        height: size.height * .12,
      ),
      Paint()..color = Colors.black.withValues(alpha: .2),
    );
  }

  void _paintTorso(
    Canvas canvas,
    Size size,
    Color jacket,
    Color trim,
    String? characterId,
  ) {
    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .51),
        width: size.width * .42,
        height: size.height * .35,
      ),
      Radius.circular(size.width * .1),
    );
    canvas.drawRRect(
      torso,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(jacket, Colors.white, .18)!,
            jacket,
            Color.lerp(jacket, Colors.black, .22)!,
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(
      torso.deflate(size.width * .025),
      Paint()..color = Colors.white.withValues(alpha: .08),
    );
    canvas.drawLine(
      Offset(size.width * .5, size.height * .37),
      Offset(size.width * .5, size.height * .63),
      Paint()
        ..color = trim.withValues(alpha: .85)
        ..strokeWidth = size.width * .025
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(size.width * .43, size.height * .43),
      size.width * .018,
      Paint()..color = trim,
    );
    canvas.drawCircle(
      Offset(size.width * .57, size.height * .43),
      size.width * .018,
      Paint()..color = trim,
    );
    if (characterId == 'road_builder' || characterId == 'default') {
      final vest = Path()
        ..moveTo(size.width * .38, size.height * .37)
        ..lineTo(size.width * .5, size.height * .5)
        ..lineTo(size.width * .62, size.height * .37)
        ..lineTo(size.width * .62, size.height * .64)
        ..lineTo(size.width * .38, size.height * .64)
        ..close();
      canvas.drawPath(
        vest,
        Paint()..color = const Color(0xFFFFD05A).withValues(alpha: .32),
      );
      canvas.drawLine(
        Offset(size.width * .39, size.height * .59),
        Offset(size.width * .61, size.height * .59),
        Paint()
          ..color = Colors.white.withValues(alpha: .65)
          ..strokeWidth = size.width * .012
          ..strokeCap = StrokeCap.round,
      );
    }
    if (characterId == 'astronaut') {
      canvas.drawCircle(
        Offset(size.width * .5, size.height * .5),
        size.width * .055,
        Paint()..color = trim.withValues(alpha: .85),
      );
    }
    if (characterId == 'robot' || characterId == 'cyber_runner') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * .5, size.height * .52),
            width: size.width * .2,
            height: size.height * .075,
          ),
          const Radius.circular(7),
        ),
        Paint()..color = trim.withValues(alpha: .5),
      );
    }
  }

  void _paintShirt(
    Canvas canvas,
    Size size,
    Color shirt,
    Color trim,
    String? characterId,
    WardrobeLoadout? loadout,
  ) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .5),
        width: size.width * .25,
        height: size.height * .22,
      ),
      Radius.circular(size.width * .06),
    );
    canvas.drawRRect(rect, Paint()..color = shirt.withValues(alpha: .82));
    canvas.drawLine(
      Offset(size.width * .5, size.height * .4),
      Offset(size.width * .5, size.height * .6),
      Paint()
        ..color = trim.withValues(alpha: .78)
        ..strokeWidth = size.width * .012
        ..strokeCap = StrokeCap.round,
    );
    final logoColor = Color.lerp(trim, Colors.white, .28)!;
    if (characterId == 'football_kid') {
      _paintTinyNumber(canvas, size, '7', logoColor);
    } else if (characterId == 'pharaoh' ||
        loadout?.outfit.id == 'pharaoh_outfit') {
      canvas.drawCircle(
        Offset(size.width * .5, size.height * .49),
        size.width * .032,
        Paint()..color = logoColor,
      );
      canvas.drawCircle(
        Offset(size.width * .5, size.height * .49),
        size.width * .018,
        Paint()..color = const Color(0xFF00C2A8),
      );
    } else if (characterId == 'cyber_runner' || characterId == 'cyber_girl') {
      canvas.drawLine(
        Offset(size.width * .42, size.height * .49),
        Offset(size.width * .58, size.height * .49),
        Paint()
          ..color = logoColor
          ..strokeWidth = size.width * .014
          ..strokeCap = StrokeCap.round,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * .5, size.height * .5),
            width: size.width * .1,
            height: size.height * .045,
          ),
          Radius.circular(size.width * .018),
        ),
        Paint()..color = logoColor.withValues(alpha: .85),
      );
    }
  }

  void _paintHead(
    Canvas canvas,
    Size size,
    Offset center,
    Color skinTone,
    Color hairColor,
    String? characterId,
    double t,
  ) {
    final headRect = Rect.fromCenter(
      center: center,
      width: size.width * .39,
      height: size.height * .36,
    );
    canvas.drawOval(
      headRect.translate(size.width * .015, size.height * .02),
      Paint()..color = Colors.black.withValues(alpha: .16),
    );
    _paintBackHair(canvas, size, hairColor, characterId, t);
    canvas.drawOval(
      headRect,
      Paint()
        ..shader = LinearGradient(
          colors: [Color.lerp(skinTone, Colors.white, .2)!, skinTone],
        ).createShader(headRect),
    );
    _paintHair(canvas, size, hairColor, characterId, t);
    if (characterId == 'robot') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * .5, size.height * .25),
            width: size.width * .29,
            height: size.height * .11,
          ),
          Radius.circular(size.width * .035),
        ),
        Paint()..color = const Color(0xFF111827),
      );
      canvas.drawCircle(
        Offset(size.width * .43, size.height * .25),
        size.width * .026,
        Paint()..color = const Color(0xFF2AF598),
      );
      canvas.drawCircle(
        Offset(size.width * .57, size.height * .25),
        size.width * .026,
        Paint()..color = const Color(0xFFFF5A6E),
      );
      return;
    }
    final eye = Paint()..color = const Color(0xFF172033);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .43, size.height * .25),
        width: size.width * .035,
        height: size.height * .046,
      ),
      eye,
    );
    canvas.drawCircle(
      Offset(size.width * .438, size.height * .238),
      size.width * .009,
      Paint()..color = Colors.white.withValues(alpha: .85),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .57, size.height * .25),
        width: size.width * .035,
        height: size.height * .046,
      ),
      eye,
    );
    canvas.drawCircle(
      Offset(size.width * .578, size.height * .238),
      size.width * .009,
      Paint()..color = Colors.white.withValues(alpha: .85),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .31),
        width: size.width * .12,
        height: size.height * .055,
      ),
      .15,
      pi - .3,
      false,
      Paint()
        ..color = Colors.black.withValues(alpha: .34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .012
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintHair(
    Canvas canvas,
    Size size,
    Color hairColor,
    String? characterId,
    double t,
  ) {
    if (characterId == 'astronaut' || characterId == 'robot') return;
    final hair = Path()
      ..moveTo(size.width * .31, size.height * .19)
      ..quadraticBezierTo(
        size.width * .42,
        size.height * .055,
        size.width * .64,
        size.height * .14,
      )
      ..quadraticBezierTo(
        size.width * .71,
        size.height * .17,
        size.width * .69,
        size.height * .235,
      )
      ..quadraticBezierTo(
        size.width * .5,
        size.height * .185,
        size.width * .31,
        size.height * .245,
      )
      ..close();
    canvas.drawPath(hair, Paint()..color = hairColor);
  }

  void _paintBackHair(
    Canvas canvas,
    Size size,
    Color hairColor,
    String? characterId,
    double t,
  ) {
    if (characterId != 'princess_runner' && characterId != 'street_girl') {
      return;
    }
    final sway = sin(t) * size.width * .018;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * .5 + sway, size.height * .265),
          width: size.width * .45,
          height: size.height * .3,
        ),
        Radius.circular(size.width * .13),
      ),
      Paint()..color = hairColor,
    );
  }

  void _paintArm(
    Canvas canvas,
    Size size, {
    required Offset shoulder,
    required Offset hand,
    required Color color,
    required Color skinTone,
  }) {
    final elbow = Offset(
      (shoulder.dx + hand.dx) / 2,
      shoulder.dy + size.height * .12,
    );
    final sleeve = Paint()
      ..color = color
      ..strokeWidth = size.width * .07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(shoulder, elbow, sleeve);
    canvas.drawLine(
      elbow,
      hand,
      Paint()
        ..color = skinTone
        ..strokeWidth = size.width * .052
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(hand, size.width * .04, Paint()..color = skinTone);
  }

  void _paintLeg(
    Canvas canvas,
    Size size, {
    required Offset start,
    required Offset knee,
    required Offset foot,
    required Color pants,
    required WardrobeItem? shoe,
    required bool front,
  }) {
    final leg = Paint()
      ..color = pants
      ..strokeWidth = size.width * .075
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, knee, leg);
    canvas.drawLine(
      knee,
      foot,
      leg..color = front ? pants : Color.lerp(pants, Colors.black, .12)!,
    );
    _paintShoe(canvas, size, foot, shoe, front: front);
  }

  void _paintShoe(
    Canvas canvas,
    Size size,
    Offset foot,
    WardrobeItem? shoe, {
    required bool front,
  }) {
    final primary = shoe?.primary ?? Colors.white;
    final secondary = shoe?.secondary ?? const Color(0xFF3DDCFF);
    final rect = Rect.fromCenter(
      center:
          foot +
          Offset(
            front ? size.width * .03 : -size.width * .02,
            size.height * .015,
          ),
      width: size.width * .23,
      height: size.height * .085,
    );
    if (shoe?.id.contains('boots') ?? false) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.inflate(size.width * .012),
          Radius.circular(size.width * .035),
        ),
        Paint()..color = primary,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          rect.left + rect.width * .18,
          rect.top - rect.height * .52,
          rect.width * .52,
          rect.height * .7,
        ),
        Paint()..color = primary,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(size.width * .045)),
        Paint()..color = primary,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: rect.centerRight,
        width: rect.width * .38,
        height: rect.height * .72,
      ),
      Paint()..color = secondary,
    );
    canvas.drawLine(
      rect.centerLeft + Offset(size.width * .05, 0),
      rect.center + Offset(size.width * .01, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: .75)
        ..strokeWidth = size.width * .012
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintTrail(
    Canvas canvas,
    Size size,
    WardrobeItem? trail,
    double t,
    bool active,
  ) {
    if (trail == null || trail.id == 'no_trail') return;
    final count = trail.id.contains('electric') || trail.id.contains('star')
        ? 5
        : 4;
    for (var i = 0; i < count; i++) {
      final p = i / count;
      final pulse = active ? sin(t + i).abs() : .35;
      final center = Offset(
        size.width * (.48 - p * .2),
        size.height * (.78 + sin(t + i) * size.height * .012),
      );
      final paint = Paint()
        ..color = Color.lerp(
          trail.primary,
          trail.secondary,
          p,
        )!.withValues(alpha: (.22 - p * .035) * (.65 + pulse * .35));
      if (trail.id.contains('fire')) {
        final flame = Path()
          ..moveTo(center.dx - size.width * (.11 - p * .02), center.dy)
          ..quadraticBezierTo(
            center.dx,
            center.dy - size.height * (.12 - p * .018),
            center.dx + size.width * (.12 - p * .02),
            center.dy,
          )
          ..quadraticBezierTo(
            center.dx,
            center.dy + size.height * .045,
            center.dx - size.width * (.11 - p * .02),
            center.dy,
          )
          ..close();
        canvas.drawPath(flame, paint);
      } else {
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: size.width * (.5 - p * .1),
            height: size.height * (.11 - p * .018),
          ),
          paint,
        );
      }
      if (trail.id.contains('electric')) {
        canvas.drawLine(
          center + Offset(-size.width * .08, -size.height * .018),
          center + Offset(size.width * .035, size.height * .018),
          Paint()
            ..color = trail.secondary.withValues(alpha: .7)
            ..strokeWidth = size.width * .012
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _paintHat(Canvas canvas, Size size, WardrobeItem? hat, Color hairColor) {
    if (hat == null || hat.id == 'no_hat') return;
    final paint = Paint()..color = hat.primary;
    final accent = Paint()..color = hat.secondary;
    if (hat.id.contains('pharaoh')) {
      final path = Path()
        ..moveTo(size.width * .28, size.height * .19)
        ..lineTo(size.width * .37, size.height * .065)
        ..lineTo(size.width * .5, size.height * .145)
        ..lineTo(size.width * .63, size.height * .065)
        ..lineTo(size.width * .72, size.height * .19)
        ..lineTo(size.width * .66, size.height * .245)
        ..lineTo(size.width * .34, size.height * .245)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawCircle(
        Offset(size.width * .5, size.height * .16),
        size.width * .028,
        accent,
      );
    } else if (hat.id.contains('crown')) {
      final path = Path()
        ..moveTo(size.width * .31, size.height * .15)
        ..lineTo(size.width * .38, size.height * .045)
        ..lineTo(size.width * .5, size.height * .14)
        ..lineTo(size.width * .62, size.height * .045)
        ..lineTo(size.width * .69, size.height * .15)
        ..lineTo(size.width * .67, size.height * .21)
        ..lineTo(size.width * .33, size.height * .21)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawCircle(
        Offset(size.width * .5, size.height * .13),
        size.width * .03,
        accent,
      );
    } else if (hat.id.contains('helmet')) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width * .5, size.height * .22),
          width: size.width * .48,
          height: size.height * .34,
        ),
        pi,
        pi,
        true,
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * .5, size.height * .25),
            width: size.width * .38,
            height: size.height * .08,
          ),
          const Radius.circular(10),
        ),
        accent..color = hat.secondary.withValues(alpha: .42),
      );
      if (hat.id.contains('space')) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * .5, size.height * .25),
            width: size.width * .34,
            height: size.height * .12,
          ),
          Paint()..color = const Color(0xFF172033).withValues(alpha: .28),
        );
      }
    } else if (hat.id.contains('bandana') || hat.id.contains('hood')) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width * .5, size.height * .22),
          width: size.width * .43,
          height: size.height * .22,
        ),
        pi * .95,
        pi * 1.1,
        false,
        paint..strokeWidth = size.width * .085,
      );
      canvas.drawCircle(
        Offset(size.width * .67, size.height * .2),
        size.width * .035,
        accent,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * .49, size.height * .14),
            width: size.width * .39,
            height: size.height * .1,
          ),
          const Radius.circular(10),
        ),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * .67, size.height * .17),
          width: size.width * .22,
          height: size.height * .055,
        ),
        accent,
      );
    }
  }

  void _paintGlasses(Canvas canvas, Size size, WardrobeItem? glasses) {
    if (glasses == null || glasses.id == 'no_glasses') return;
    final isVisor = glasses.id.contains('visor');
    final fill = Paint()
      ..color = glasses.primary.withValues(alpha: isVisor ? .55 : .32);
    final stroke = Paint()
      ..color = glasses.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .022
      ..strokeCap = StrokeCap.round;
    if (isVisor) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * .5, size.height * .255),
            width: size.width * .28,
            height: size.height * .07,
          ),
          const Radius.circular(9),
        ),
        fill,
      );
      canvas.drawLine(
        Offset(size.width * .37, size.height * .25),
        Offset(size.width * .63, size.height * .25),
        stroke,
      );
      return;
    }
    final left = Rect.fromCenter(
      center: Offset(size.width * .43, size.height * .255),
      width: size.width * .105,
      height: size.height * .06,
    );
    final right = Rect.fromCenter(
      center: Offset(size.width * .57, size.height * .255),
      width: size.width * .105,
      height: size.height * .06,
    );
    final radius = glasses.id.contains('round') ? 99.0 : 6.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(left, Radius.circular(radius)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(right, Radius.circular(radius)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(left, Radius.circular(radius)),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(right, Radius.circular(radius)),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * .49, size.height * .255),
      Offset(size.width * .51, size.height * .255),
      stroke,
    );
  }

  void _paintEffect(Canvas canvas, Size size, WardrobeItem? effect, double t) {
    if (effect == null || effect.id == 'no_effect') return;
    if (effect.id.contains('magnet') || effect.id.contains('aura')) {
      for (var i = 0; i < 2; i++) {
        canvas.drawCircle(
          Offset(size.width * .5, size.height * .52),
          size.width * (.32 + i * .08 + sin(t + i).abs() * .025),
          Paint()
            ..color = Color.lerp(
              effect.primary,
              effect.secondary,
              i / 2,
            )!.withValues(alpha: .11 - i * .035)
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.width * .018,
        );
      }
      return;
    }
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .52),
      size.width * (.34 + sin(t).abs() * .025),
      Paint()
        ..color = effect.primary.withValues(alpha: .1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .018,
    );
  }

  void _paintAccessories(Canvas canvas, Size size, WardrobeLoadout? loadout) {
    if (loadout == null) return;
    if (loadout.watch.id != 'no_watch') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * .73, size.height * .59),
            width: size.width * .075,
            height: size.height * .045,
          ),
          const Radius.circular(5),
        ),
        Paint()..color = loadout.watch.primary,
      );
      canvas.drawCircle(
        Offset(size.width * .73, size.height * .59),
        size.width * .018,
        Paint()..color = loadout.watch.secondary,
      );
    }
    if (loadout.bag.id != 'no_bag') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * .68, size.height * .55),
            width: size.width * .16,
            height: size.height * .18,
          ),
          Radius.circular(size.width * .035),
        ),
        Paint()..color = loadout.bag.primary.withValues(alpha: .9),
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width * .61, size.height * .45),
          width: size.width * .22,
          height: size.height * .24,
        ),
        -pi * .45,
        pi * .7,
        false,
        Paint()
          ..color = loadout.bag.secondary
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * .018,
      );
    }
    if (loadout.earrings.id != 'no_earrings') {
      canvas.drawCircle(
        Offset(size.width * .34, size.height * .27),
        size.width * .018,
        Paint()..color = loadout.earrings.primary,
      );
      canvas.drawCircle(
        Offset(size.width * .66, size.height * .27),
        size.width * .018,
        Paint()..color = loadout.earrings.primary,
      );
    }
    if (loadout.necklace.id != 'no_necklace') {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width * .5, size.height * .38),
          width: size.width * .18,
          height: size.height * .1,
        ),
        .1,
        pi - .2,
        false,
        Paint()
          ..color = loadout.necklace.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * .014,
      );
    }
    if (loadout.bracelet.id != 'no_bracelet') {
      canvas.drawCircle(
        Offset(size.width * .27, size.height * .6),
        size.width * .024,
        Paint()
          ..color = loadout.bracelet.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * .012,
      );
    }
  }

  void _paintBackGear(Canvas canvas, Size size, WardrobeLoadout? loadout) {
    if (loadout == null) return;
    if (loadout.character.id == 'road_builder' ||
        loadout.outfit.id == 'paver_uniform' ||
        loadout.bag.id == 'tool_satchel') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * .31, size.height * .53),
            width: size.width * .16,
            height: size.height * .24,
          ),
          Radius.circular(size.width * .035),
        ),
        Paint()..color = const Color(0xFF223047).withValues(alpha: .95),
      );
      canvas.drawLine(
        Offset(size.width * .29, size.height * .42),
        Offset(size.width * .2, size.height * .63),
        Paint()
          ..color = const Color(0xFFFFD05A)
          ..strokeWidth = size.width * .018
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintTinyNumber(Canvas canvas, Size size, String text, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size.width * .11,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(size.width * .5 - painter.width / 2, size.height * .45),
    );
  }

  Color _skinTone(String id) {
    if (id.contains('robot')) return const Color(0xFFB9C8D7);
    if (id.contains('astronaut')) return const Color(0xFFD7A06F);
    if (id.contains('street_girl') || id.contains('skater')) {
      return const Color(0xFFB87958);
    }
    if (id.contains('pharaoh') || id.contains('golden')) {
      return const Color(0xFFDFA05E);
    }
    return const Color(0xFFE8B07D);
  }

  Color _hairColor(String id) {
    if (id.contains('ninja') || id.contains('cyber')) {
      return const Color(0xFF111827);
    }
    if (id.contains('street_girl')) return const Color(0xFF2B1B2B);
    if (id.contains('princess')) return const Color(0xFF7A3D14);
    if (id.contains('golden')) return const Color(0xFFFFD05A);
    return const Color(0xFF3C2431);
  }

  @override
  bool shouldRepaint(covariant RunnerPainter oldDelegate) =>
      oldDelegate.runPhase != runPhase ||
      oldDelegate.pose != pose ||
      oldDelegate.skin != skin ||
      oldDelegate.loadout != loadout ||
      oldDelegate.rearView != rearView;
}
