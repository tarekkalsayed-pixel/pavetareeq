import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/game_result.dart';
import '../models/season_model.dart';
import '../widgets/game_button.dart';
import '../widgets/pave_background.dart';
import 'gameplay_screen.dart';
import 'level_selection_screen.dart';

class LevelFailedScreen extends StatelessWidget {
  const LevelFailedScreen({
    required this.result,
    required this.retryConfig,
    super.key,
  });

  final GameResult result;
  final LevelConfig retryConfig;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaveBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(
                Icons.warning_rounded,
                size: 84,
                color: Color(0xFFFF5A6E),
              ),
              const SizedBox(height: 16),
              Text(
                'Road Failed',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              Text('Distance: ${result.distance}m'),
              Text('Coins collected: ${result.coins}'),
              const SizedBox(height: 28),
              GameButton(
                label: 'Try Again',
                icon: Icons.refresh_rounded,
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => GameplayScreen(config: retryConfig),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GameButton(
                label: 'Back to Levels',
                icon: Icons.grid_view_rounded,
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        LevelSelectionScreen(seasonId: result.seasonId),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class LevelCompleteScreen extends StatelessWidget {
  const LevelCompleteScreen({required this.result, super.key});

  final GameResult result;

  @override
  Widget build(BuildContext context) {
    final hasNext = result.level < 10 || result.seasonId < 5;
    final nextSeason = result.level == 10
        ? result.seasonId + 1
        : result.seasonId;
    final nextLevel = result.level == 10 ? 1 : result.level + 1;
    return Scaffold(
      body: PaveBackground(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 42),
            const Icon(
              Icons.emoji_events_rounded,
              size: 92,
              color: Colors.amberAccent,
            ),
            const SizedBox(height: 12),
            Text(
              result.level == 10 ? 'Boss Cleared!' : 'Level Complete!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            Text(
              '${result.seasonName} | Level ${result.level}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Icon(
                  Icons.star_rounded,
                  size: 42,
                  color: index < result.stars
                      ? Colors.amberAccent
                      : Colors.white24,
                ),
              ),
            ),
            const SizedBox(height: 22),
            _Line(label: 'Coins collected', value: '${result.coins}'),
            _Line(
              label: 'Accuracy',
              value: '${result.accuracyPercent.round()}%',
            ),
            _Line(
              label: 'Coins found',
              value:
                  '${(result.availableCoins * result.coinPercent / 100).round()} / ${result.availableCoins}',
            ),
            _Line(label: 'Perfect streak', value: '${result.perfectStreak}'),
            _Line(label: 'Mistakes', value: '${result.mistakes}'),
            _Line(
              label: 'Final score',
              value: '${result.performanceScore} / 100',
            ),
            _Line(label: 'Perfect flips', value: '${result.perfectFlips}'),
            _Line(
              label: 'Last second saves',
              value: '${result.lastSecondSaves}',
            ),
            _Line(label: 'Stars earned', value: '${result.stars}/3'),
            const SizedBox(height: 24),
            GameButton(
              label: hasNext ? 'Next Level' : 'All Roads Built',
              icon: Icons.arrow_forward_rounded,
              onPressed: hasNext
                  ? () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => GameplayScreen(
                          config: GameData.level(nextSeason, nextLevel),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            GameButton(
              label: 'Replay',
              icon: Icons.replay_rounded,
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => GameplayScreen(
                    config: GameData.level(result.seasonId, result.level),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GameButton(
              label: 'Back to Season',
              icon: Icons.map_rounded,
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      LevelSelectionScreen(seasonId: result.seasonId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
