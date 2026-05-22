import 'package:flutter/material.dart';

import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/game_button.dart';
import '../widgets/pave_background.dart';
import 'character_selection_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    ProgressService.instance.init().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaveBackground(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _SplashArcadePainter(_controller.value),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
                        colors: [kGlowBlue, kGlowPink, kGold, kGlowBlue],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kGlowBlue.withValues(alpha: .4),
                          blurRadius: 34,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      size: 70,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [Colors.white, kGlowBlue, kGlowPink],
                    ).createShader(rect),
                    child: Text(
                      'PaveTareeq',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontSize: 50, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Flip fast. Choose right. Master the road.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withValues(alpha: .78),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Transform.scale(
                    scale:
                        1 +
                        (_controller.value < .5
                                ? _controller.value
                                : 1 - _controller.value) *
                            .08,
                    child: SizedBox(
                      width: 280,
                      child: GameButton(
                        label: _ready ? 'Start' : 'Loading',
                        icon: Icons.play_arrow_rounded,
                        onPressed: _ready
                            ? () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ProgressService.instance.hasChosenRunner
                                      ? const HomeScreen()
                                      : const CharacterSelectionScreen(),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'No ads during active gameplay.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashArcadePainter extends CustomPainter {
  const _SplashArcadePainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 34; i++) {
      final p = (i * .073 + t) % 1;
      final x = (i * 47) % size.width;
      final y = size.height * p;
      canvas.drawCircle(
        Offset(x.toDouble(), y),
        1.5 + (i % 4),
        Paint()
          ..color = (i.isEven ? kGlowBlue : kGlowPink).withValues(
            alpha: .16 + p * .18,
          ),
      );
    }
    final top = Offset(size.width / 2, size.height * .24);
    final path = Path()
      ..moveTo(top.dx - 28, top.dy)
      ..lineTo(size.width * .09, size.height)
      ..lineTo(size.width * .91, size.height)
      ..lineTo(top.dx + 28, top.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            kGlowBlue.withValues(alpha: .08),
            kGlowPink.withValues(alpha: .28),
          ],
        ).createShader(Offset.zero & size),
    );
    for (var i = 0; i < 12; i++) {
      final p = (i / 12 + t) % 1;
      final y = top.dy + p * p * size.height * .8;
      final w = 34 + p * size.width * .72;
      canvas.drawLine(
        Offset(size.width / 2 - w / 2, y),
        Offset(size.width / 2 + w / 2, y),
        Paint()
          ..color = Colors.white.withValues(alpha: .06 + p * .18)
          ..strokeWidth = 2 + p * 6,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashArcadePainter oldDelegate) => true;
}
