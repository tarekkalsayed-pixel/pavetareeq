import 'dart:async';

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../game/runner_painter.dart';
import '../services/daily_service.dart';
import '../services/progress_service.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/wardrobe_service.dart';
import '../theme.dart';
import '../widgets/game_button.dart';
import '../widgets/pave_background.dart';
import '../widgets/stat_chip.dart';
import 'endless_screen.dart';
import 'gameplay_screen.dart';
import 'level_selection_screen.dart';
import 'season_selection_screen.dart';
import 'skins_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ProgressService get progress => ProgressService.instance;

  @override
  void initState() {
    super.initState();
    unawaited(AudioService.instance.playMenuMusic());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = GameData.skins.firstWhere(
      (item) => item.id == progress.selectedSkinId,
    );
    final loadout = WardrobeService.instance.loadout;
    final daily = DailyService.instance.stats;
    final hasProgress = progress.completedLevels.isNotEmpty;
    final next = _nextUnlockedLevel();
    return Scaffold(
      body: PaveBackground(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        colors: [Colors.white, kGlowBlue, kGlowPink],
                      ).createShader(rect),
                      child: Text(
                        'PaveTareeq',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(fontSize: 40, color: Colors.white),
                      ),
                    ),
                  ),
                  StatChip(
                    icon: Icons.monetization_on_rounded,
                    label: 'Coins',
                    value: '${progress.coins}',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Flip fast. Choose right. Master the road.',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _ProgressCards(
                currentSeason: next.$1,
                currentLevel: next.$2,
                coins: progress.coins,
                streak: daily.streak,
              ),
              const SizedBox(height: 18),
              _ArcadeHero(
                controller: _controller,
                skin: skin,
                loadout: loadout,
                onPlay: _playFirstUnlocked,
                showContinue: hasProgress,
              ),
              const SizedBox(height: 16),
              if (hasProgress) ...[
                GameButton(
                  label: 'Continue',
                  icon: Icons.bolt_rounded,
                  onPressed: _playFirstUnlocked,
                ),
                const SizedBox(height: 10),
              ],
              GameButton(
                label: 'Play',
                icon: Icons.play_arrow_rounded,
                onPressed: _playFirstUnlocked,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GameButton(
                      label: 'Seasons',
                      icon: Icons.map_rounded,
                      onPressed: () => _open(const SeasonSelectionScreen()),
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GameButton(
                      label: 'Skins',
                      icon: Icons.face_rounded,
                      onPressed: () => _open(const SkinsScreen()),
                      compact: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GameButton(
                      label: 'Daily Reward',
                      icon: Icons.card_giftcard_rounded,
                      onPressed: _watchDailyReward,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GameButton(
                      label: 'Settings',
                      icon: Icons.settings_rounded,
                      onPressed: _showSettings,
                      compact: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GameButton(
                label: 'Endless Mode',
                icon: Icons.all_inclusive_rounded,
                onPressed: () => _open(const EndlessScreen()),
              ),
              const SizedBox(height: 16),
              _DailyCard(stats: daily),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  void _playFirstUnlocked() {
    for (final season in GameData.seasons) {
      for (var level = 1; level <= 10; level++) {
        if (progress.isLevelUnlocked(season.id, level) &&
            progress.starsFor(season.id, level) == 0) {
          _open(GameplayScreen(config: GameData.level(season.id, level)));
          return;
        }
      }
    }
    _open(const LevelSelectionScreen(seasonId: 1));
  }

  (int, int) _nextUnlockedLevel() {
    for (final season in GameData.seasons) {
      for (var level = 1; level <= 10; level++) {
        if (progress.isLevelUnlocked(season.id, level) &&
            progress.starsFor(season.id, level) == 0) {
          return (season.id, level);
        }
      }
    }
    return (5, 10);
  }

  Future<void> _watchDailyReward() async {
    final wardrobe = WardrobeService.instance;
    if (!wardrobe.canWatchAdForCoins) {
      await AudioService.instance.playError();
      _showSnack('Daily rewarded coin limit reached.');
      return;
    }
    await AdsService.instance.showRewardedAd(
      context: context,
      onUnavailable: () =>
          _showSnack('Ad is still loading, try again in a moment.'),
      onRewardEarned: () async {
        final rewarded = await wardrobe.rewardCoinsFromAd(coins: 50);
        if (!mounted) return;
        await (rewarded
            ? AudioService.instance.playCoin()
            : AudioService.instance.playError());
        setState(() {});
        _showSnack(
          rewarded ? '+50 coins added' : 'Daily rewarded coin limit reached.',
        );
      },
    );
  }

  void _showSettings() {
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: kPanel,
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: !AudioService.instance.musicMuted,
                onChanged: (value) async {
                  await AudioService.instance.setMusicMuted(!value);
                  if (value) await AudioService.instance.playMenuMusic();
                  setDialogState(() {});
                },
                title: const Text('Music'),
                subtitle: const Text('Season loops and menu music.'),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: !AudioService.instance.sfxMuted,
                onChanged: (value) async {
                  await AudioService.instance.setSfxMuted(!value);
                  if (value) await AudioService.instance.playSelect();
                  setDialogState(() {});
                },
                title: const Text('Sound effects'),
                subtitle: const Text(
                  'Ads never appear during active gameplay.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                AudioService.instance.playTap();
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _ProgressCards extends StatelessWidget {
  const _ProgressCards({
    required this.currentSeason,
    required this.currentLevel,
    required this.coins,
    required this.streak,
  });

  final int currentSeason;
  final int currentLevel;
  final int coins;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.35,
      children: [
        _MiniCard(
          icon: Icons.terrain_rounded,
          label: 'Current season',
          value: '$currentSeason',
        ),
        _MiniCard(
          icon: Icons.flag_rounded,
          label: 'Current level',
          value: '$currentLevel',
        ),
        _MiniCard(
          icon: Icons.monetization_on_rounded,
          label: 'Coins',
          value: '$coins',
        ),
        _MiniCard(
          icon: Icons.local_fire_department_rounded,
          label: 'Best streak',
          value: '$streak',
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(color: kGlowBlue.withValues(alpha: .08), blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: kGold),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcadeHero extends StatelessWidget {
  const _ArcadeHero({
    required this.controller,
    required this.skin,
    required this.loadout,
    required this.onPlay,
    required this.showContinue,
  });

  final AnimationController controller;
  final dynamic skin;
  final dynamic loadout;
  final VoidCallback onPlay;
  final bool showContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 270,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
        boxShadow: [
          BoxShadow(color: kGlowBlue.withValues(alpha: .18), blurRadius: 34),
        ],
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _HomeHeroPainter(controller.value),
            child: Stack(
              children: [
                Positioned(
                  left: 22,
                  top: 22,
                  right: 130,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Build the run.',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        showContinue
                            ? 'Your road is waiting.'
                            : "Don't run. Build the run.",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 52,
                  child: AnimatedRunner(
                    skin: skin,
                    animationValue: controller.value,
                    pose: RunnerPose.running,
                    loadout: loadout,
                    size: 112,
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: GameButton(
                    label: 'Build the Run',
                    icon: Icons.auto_fix_high_rounded,
                    onPressed: onPlay,
                    compact: true,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeHeroPainter extends CustomPainter {
  const _HomeHeroPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF101B45), Color(0xFF321A5F), Color(0xFF080B1D)],
        ).createShader(Offset.zero & size),
    );
    final center = Offset(size.width * .5, size.height * .1);
    final left = Offset(size.width * .08, size.height);
    final right = Offset(size.width * .92, size.height);
    final road = Path()
      ..moveTo(center.dx - 28, center.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(center.dx + 28, center.dy)
      ..close();
    canvas.drawPath(
      road,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            kGlowBlue.withValues(alpha: .2),
            kGlowPink.withValues(alpha: .45),
          ],
        ).createShader(Offset.zero & size),
    );
    for (var i = 0; i < 10; i++) {
      final p = ((i / 10) + t) % 1;
      final y = center.dy + p * p * size.height * .95;
      final w = 40 + p * size.width * .55;
      canvas.drawLine(
        Offset(size.width / 2 - w / 2, y),
        Offset(size.width / 2 + w / 2, y),
        Paint()
          ..color = Colors.white.withValues(alpha: .08 + p * .18)
          ..strokeWidth = 2 + p * 5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HomeHeroPainter oldDelegate) => true;
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.stats});

  final DailyStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: kGold),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Today's Road",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${stats.streak} day streak',
                style: const TextStyle(
                  color: kGold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Mission(
            label: 'Complete 3 levels',
            value: stats.levelMission,
            detail: '${stats.completedLevels}/3',
          ),
          _Mission(
            label: 'Collect 30 coins',
            value: stats.coinMission,
            detail: '${stats.coinsEarned}/30',
          ),
          _Mission(
            label: 'Get 5 perfect saves',
            value: stats.perfectMission,
            detail: '${stats.perfectSaves}/5',
          ),
          const SizedBox(height: 6),
          Text(
            'Total play days: ${stats.totalPlayDays} | Best today: ${stats.bestScore}m',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Mission extends StatelessWidget {
  const _Mission({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final double value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(detail, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: Colors.white12,
              color: kGlowBlue,
            ),
          ),
        ],
      ),
    );
  }
}
