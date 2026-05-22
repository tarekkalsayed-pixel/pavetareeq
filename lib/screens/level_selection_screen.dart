import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../services/audio_service.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/pave_background.dart';
import 'gameplay_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({required this.seasonId, super.key});

  final int seasonId;

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    unawaited(
      AudioService.instance.playSeasonMusic(widget.seasonId, volumeScale: .72),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    final season = GameData.seasons.firstWhere(
      (item) => item.id == widget.seasonId,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('${season.name} | Season ${season.id}'),
        backgroundColor: Colors.transparent,
      ),
      body: PaveBackground(
        gradientColors: season.backgroundGradient,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final horizontalPadding = width < 380 ? 12.0 : 16.0;
            final availableWidth = width - horizontalPadding * 2;
            final cardWidth = min(availableWidth * .46, 166.0);
            final bossWidth = min(availableWidth * .78, 240.0);
            final cardHeight = width < 380 ? 116.0 : 124.0;
            final bossHeight = width < 380 ? 138.0 : 150.0;
            final levelGap = width < 380 ? 138.0 : 150.0;
            final mapHeight = max(
              constraints.maxHeight + 80,
              levelGap * 9 + bossHeight + 180,
            );
            final nodes = [
              for (var i = 0; i < 10; i++)
                _NodeLayout(
                  level: i + 1,
                  size: Size(
                    i == 9 ? bossWidth : cardWidth,
                    i == 9 ? bossHeight : cardHeight,
                  ),
                  top:
                      mapHeight -
                      92 -
                      (i * levelGap) -
                      (i == 9 ? bossHeight : cardHeight),
                  centerX: _nodeCenterX(
                    i,
                    availableWidth,
                    horizontalPadding,
                    i == 9 ? bossWidth : cardWidth,
                  ),
                ),
            ];
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                26,
              ),
              child: SizedBox(
                height: mapHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _MapPathPainter(
                          colors: season.colors,
                          centers: [
                            for (final node in nodes)
                              Offset(
                                node.centerX,
                                node.top + node.size.height / 2,
                              ),
                          ],
                        ),
                      ),
                    ),
                    for (var i = 0; i < 10; i++) ...[
                      Builder(
                        builder: (context) {
                          final level = i + 1;
                          final node = nodes[i];
                          final unlocked = progress.isLevelUnlocked(
                            widget.seasonId,
                            level,
                          );
                          final stars = progress.starsFor(
                            widget.seasonId,
                            level,
                          );
                          final completed = stars > 0;
                          final active =
                              unlocked &&
                              !completed &&
                              (level == 1 ||
                                  progress.starsFor(
                                        widget.seasonId,
                                        level - 1,
                                      ) >
                                      0);
                          final size = node.size;
                          final left = (node.centerX - size.width / 2).clamp(
                            horizontalPadding,
                            width - horizontalPadding - size.width,
                          );
                          final top = node.top.clamp(
                            0.0,
                            mapHeight - size.height,
                          );
                          final config = GameData.level(widget.seasonId, level);
                          return Positioned(
                            left: left,
                            top: top,
                            width: size.width,
                            height: size.height,
                            child: _LevelNode(
                              level: level,
                              seasonId: widget.seasonId,
                              unlocked: unlocked,
                              completed: completed,
                              active: active,
                              stars: stars,
                              colors: season.colors,
                              difficulty: config.difficulty.difficultyLevel,
                              label: config.difficulty.difficultyLabel,
                              pulse: _pulseController,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        GameplayScreen(config: config),
                                  ),
                                );
                                if (mounted) setState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _nodeCenterX(
    int index,
    double availableWidth,
    double horizontalPadding,
    double nodeWidth,
  ) {
    const offsets = [-.28, .24, 0.0, -.24, .28, -.18, .24, 0.0, -.22, 0.0];
    final center = horizontalPadding + availableWidth / 2;
    final travel = max(0.0, (availableWidth - nodeWidth) / 2);
    return center + offsets[index] * travel * 1.6;
  }
}

class _NodeLayout {
  const _NodeLayout({
    required this.level,
    required this.size,
    required this.top,
    required this.centerX,
  });

  final int level;
  final Size size;
  final double top;
  final double centerX;
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.level,
    required this.seasonId,
    required this.unlocked,
    required this.completed,
    required this.active,
    required this.stars,
    required this.colors,
    required this.difficulty,
    required this.label,
    required this.pulse,
    required this.onTap,
  });

  final int level;
  final int seasonId;
  final bool unlocked;
  final bool completed;
  final bool active;
  final int stars;
  final List<Color> colors;
  final int difficulty;
  final String label;
  final Animation<double> pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBoss = level == 10;
    final muted = !unlocked;
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final glow = active ? 18.0 + pulse.value * 16 : (unlocked ? 16.0 : 0.0);
        return InkWell(
          onTap: unlocked ? onTap : null,
          borderRadius: BorderRadius.circular(isBoss ? 24 : 20),
          child: Container(
            padding: EdgeInsets.all(isBoss ? 12 : 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isBoss ? 24 : 20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: muted
                    ? const [Color(0xFF24283A), Color(0xFF101321)]
                    : completed
                    ? [
                        Color.lerp(colors.first, kSafeGreen, .34)!,
                        Color.lerp(colors.last, kSafeGreen, .42)!,
                      ]
                    : [colors.first, colors.last],
              ),
              border: Border.all(
                color: active
                    ? kGold
                    : (unlocked ? Colors.white38 : Colors.white12),
                width: active ? 2.2 : 1.2,
              ),
              boxShadow: [
                if (unlocked)
                  BoxShadow(
                    color: (active ? kGold : colors.first).withValues(
                      alpha: active ? .38 : .22,
                    ),
                    blurRadius: glow,
                  ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: SizedBox(
                width: isBoss ? 190 : 128,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          completed
                              ? Icons.check_circle_rounded
                              : (unlocked
                                    ? (isBoss
                                          ? Icons.local_fire_department_rounded
                                          : Icons.route_rounded)
                                    : Icons.lock_rounded),
                          color: completed ? kSafeGreen : Colors.white,
                          size: isBoss ? 30 : 24,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            isBoss ? 'Boss Level' : 'Level $level',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isBoss ? 20 : 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _NodeBadge(text: label),
                        const SizedBox(width: 6),
                        _NodeBadge(text: 'D$difficulty'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (star) => Icon(
                          Icons.star_rounded,
                          size: isBoss ? 22 : 18,
                          color: star < stars ? kGold : Colors.white24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      completed
                          ? 'Completed'
                          : (unlocked
                                ? (active ? 'Current' : 'Unlocked')
                                : 'Locked'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted ? Colors.white38 : Colors.white70,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NodeBadge extends StatelessWidget {
  const _NodeBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .2),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _MapPathPainter extends CustomPainter {
  const _MapPathPainter({required this.colors, required this.centers});

  final List<Color> colors;
  final List<Offset> centers;

  @override
  void paint(Canvas canvas, Size size) {
    final points = centers;
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final mid = Offset(
        (points[i - 1].dx + points[i].dx) / 2,
        (points[i - 1].dy + points[i].dy) / 2,
      );
      path.quadraticBezierTo(
        points[i - 1].dx,
        points[i - 1].dy,
        mid.dx,
        mid.dy,
      );
      path.quadraticBezierTo(mid.dx, mid.dy, points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = colors.last.withValues(alpha: .18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = colors.first.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MapPathPainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.centers != centers;
}
