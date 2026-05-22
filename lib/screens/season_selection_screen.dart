import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/pave_background.dart';
import 'level_selection_screen.dart';

class SeasonSelectionScreen extends StatefulWidget {
  const SeasonSelectionScreen({super.key});

  @override
  State<SeasonSelectionScreen> createState() => _SeasonSelectionScreenState();
}

class _SeasonSelectionScreenState extends State<SeasonSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seasons'),
        backgroundColor: Colors.transparent,
      ),
      body: PaveBackground(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: GameData.seasons.length,
          itemBuilder: (context, index) {
            final season = GameData.seasons[index];
            final unlocked = progress.isSeasonUnlocked(season.id);
            final completed = progress.seasonCompletedCount(season.id);
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: unlocked
                      ? season.colors.last.withValues(alpha: .65)
                      : Colors.white12,
                ),
                boxShadow: unlocked
                    ? [
                        BoxShadow(
                          color: season.colors.first.withValues(alpha: .2),
                          blurRadius: 26,
                        ),
                      ]
                    : null,
              ),
              child: InkWell(
                onTap: unlocked
                    ? () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                LevelSelectionScreen(seasonId: season.id),
                          ),
                        );
                        if (mounted) setState(() {});
                      }
                    : null,
                child: CustomPaint(
                  painter: _SeasonCardPainter(
                    colors: season.colors,
                    seasonId: season.id,
                    locked: !unlocked,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              unlocked
                                  ? _iconFor(season.id)
                                  : Icons.lock_rounded,
                              size: 42,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Season ${season.id} | ${season.subtitle}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    season.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FittedBox(
                              child: Text(
                                '${progress.seasonStars(season.id)} stars',
                                style: const TextStyle(
                                  color: kGold,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          season.description,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          season.gameplayModifierDescription,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: completed / 10,
                            minHeight: 9,
                            backgroundColor: Colors.white12,
                            color: unlocked
                                ? season.colors.last
                                : Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$completed/10 levels completed',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _iconFor(int id) {
    switch (id) {
      case 1:
        return Icons.toys_rounded;
      case 2:
        return Icons.add_road_rounded;
      case 3:
        return Icons.temple_buddhist_rounded;
      case 4:
        return Icons.memory_rounded;
      default:
        return Icons.public_rounded;
    }
  }
}

class _SeasonCardPainter extends CustomPainter {
  const _SeasonCardPainter({
    required this.colors,
    required this.seasonId,
    required this.locked,
  });

  final List<Color> colors;
  final int seasonId;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: locked
              ? [const Color(0xFF161A2D), const Color(0xFF080B1D)]
              : [
                  colors.first.withValues(alpha: .55),
                  colors.last.withValues(alpha: .25),
                  const Color(0xFF080B1D),
                ],
        ).createShader(Offset.zero & size),
    );
    final road = Path()
      ..moveTo(size.width * .58, 0)
      ..lineTo(size.width * .94, size.height)
      ..lineTo(size.width * .5, size.height)
      ..lineTo(size.width * .46, 0)
      ..close();
    canvas.drawPath(
      road,
      Paint()..color = Colors.white.withValues(alpha: locked ? .04 : .1),
    );
    if (seasonId == 5) {
      for (var i = 0; i < 18; i++) {
        canvas.drawCircle(
          Offset((i * 37) % size.width, (i * 53) % size.height),
          1.4,
          Paint()..color = Colors.white54,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SeasonCardPainter oldDelegate) => false;
}
