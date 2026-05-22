import 'package:flutter/material.dart';

import '../theme.dart';

class PaveBackground extends StatelessWidget {
  const PaveBackground({
    required this.child,
    this.showRoadGlow = false,
    this.gradientColors,
    super.key,
  });

  final Widget child;
  final bool showRoadGlow;
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              gradientColors ??
              const [kInk, Color(0xFF11133A), Color(0xFF090D22)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _AmbientGlow(showRoadGlow: showRoadGlow)),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.showRoadGlow});

  final bool showRoadGlow;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AmbientGlowPainter(showRoadGlow: showRoadGlow),
    );
  }
}

class _AmbientGlowPainter extends CustomPainter {
  const _AmbientGlowPainter({required this.showRoadGlow});

  final bool showRoadGlow;

  @override
  void paint(Canvas canvas, Size size) {
    final blobs = [
      (
        Offset(size.width * .12, size.height * .18),
        size.width * .42,
        kGlowBlue,
      ),
      (
        Offset(size.width * .88, size.height * .34),
        size.width * .36,
        kGlowPink,
      ),
      (Offset(size.width * .45, size.height * .92), size.width * .5, kGold),
    ];
    for (final blob in blobs) {
      canvas.drawCircle(
        blob.$1,
        blob.$2,
        Paint()
          ..color = blob.$3.withValues(alpha: .055)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 42),
      );
    }
    for (var i = 0; i < 42; i++) {
      final x = (i * 73 + 19) % size.width;
      final y = (i * 47 + 31) % size.height;
      canvas.drawCircle(
        Offset(x.toDouble(), y.toDouble()),
        1.1 + (i % 3) * .55,
        Paint()
          ..color = (i.isEven ? kGlowBlue : Colors.white).withValues(
            alpha: .12,
          ),
      );
    }
    if (!showRoadGlow) return;
    final path = Path()
      ..moveTo(size.width * .08, size.height * .95)
      ..quadraticBezierTo(
        size.width * .36,
        size.height * .58,
        size.width * .48,
        size.height * .25,
      )
      ..quadraticBezierTo(
        size.width * .62,
        size.height * .05,
        size.width * .92,
        size.height * .02,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = kGlowBlue.withValues(alpha: .12)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientGlowPainter oldDelegate) =>
      oldDelegate.showRoadGlow != showRoadGlow;
}
