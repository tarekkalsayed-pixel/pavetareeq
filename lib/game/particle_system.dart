import 'dart:math';

import 'package:flutter/material.dart';

class GameParticle {
  GameParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.life,
    required this.size,
    this.text,
  });

  Offset position;
  Offset velocity;
  Color color;
  double life;
  double size;
  String? text;

  void tick(double dt) {
    position += velocity * dt;
    velocity += Offset(0, 38 * dt);
    life -= dt;
  }
}

class ParticleSystem {
  final Random _random = Random();
  final List<GameParticle> particles = [];
  static const int maxGameplayParticles = 52;

  void burst(Offset origin, Color color, {String? text, int count = 14}) {
    final available = maxGameplayParticles - particles.length;
    if (available <= 0) return;
    final cappedCount = min(count, max(0, available - (text == null ? 0 : 1)));
    if (text != null) {
      particles.add(
        GameParticle(
          position: origin,
          velocity: const Offset(0, -70),
          color: color,
          life: .75,
          size: 18,
          text: text,
        ),
      );
    }
    for (var i = 0; i < cappedCount; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = 50 + _random.nextDouble() * 120;
      particles.add(
        GameParticle(
          position: origin,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed - 40),
          color: color,
          life: .45 + _random.nextDouble() * .35,
          size: 3 + _random.nextDouble() * 5,
        ),
      );
    }
  }

  void coin(Offset origin) {
    burst(origin, const Color(0xFFFFD05A), text: '+coins', count: 10);
  }

  void tick(double dt) {
    for (final particle in particles) {
      particle.tick(dt);
    }
    particles.removeWhere((particle) => particle.life <= 0);
  }
}

class ParticlePainter extends CustomPainter {
  const ParticlePainter(this.particles);

  final List<GameParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final alpha = particle.life.clamp(0.0, 1.0);
      if (particle.text != null) {
        final painter = TextPainter(
          text: TextSpan(
            text: particle.text,
            style: TextStyle(
              color: particle.color.withValues(alpha: alpha),
              fontSize: particle.size,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: particle.color.withValues(alpha: .55),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(
          canvas,
          particle.position - Offset(painter.width / 2, painter.height / 2),
        );
      } else {
        canvas.drawCircle(
          particle.position,
          particle.size,
          Paint()..color = particle.color.withValues(alpha: alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
