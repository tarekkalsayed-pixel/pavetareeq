import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../game/arcade_game_view.dart';
import '../game/particle_system.dart';
import '../game/runner_painter.dart';
import '../models/game_result.dart';
import '../models/season_model.dart';
import '../models/tile_model.dart';
import '../services/progress_service.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/scoring_service.dart';
import '../services/wardrobe_service.dart';
import '../theme.dart';
import '../widgets/pave_background.dart';
import 'result_screens.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({required this.config, super.key});

  final LevelConfig config;

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _runnerController;
  late final List<RoadTile> _tiles;
  final ParticleSystem _particles = ParticleSystem();
  Timer? _timer;
  double _position = 0;
  double _speed = 1;
  double _shake = 0;
  double _darken = 0;
  int _processedIndex = -1;
  int _coins = 0;
  int _collectedCoinTiles = 0;
  int _successfulFlips = 0;
  int _requiredFlips = 0;
  int _mistakes = 0;
  int _perfectFlips = 0;
  int _lastSecondSaves = 0;
  int _currentPerfectStreak = 0;
  int _bestPerfectStreak = 0;
  bool _ended = false;
  bool _showBossIntro = false;
  RunnerPose _pose = RunnerPose.running;
  String _feedback = 'Build the road';
  DateTime? _levelStartedAt;

  @override
  void initState() {
    super.initState();
    _tiles = widget.config.tiles.map((type) => RoadTile(type: type)).toList();
    _requiredFlips = _tiles.where((tile) => tile.canTap).length;
    _speed = widget.config.speed;
    _feedback = widget.config.isBoss
        ? 'Boss Road!'
        : 'Fix danger tiles before impact';
    unawaited(AudioService.instance.playSeasonMusic(widget.config.season.id));
    final runMs = (780 - widget.config.difficulty.speedMultiplier * 95)
        .clamp(560, 720)
        .round();
    _runnerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: runMs),
    )..repeat();
    if (widget.config.isBoss) {
      _showBossIntro = true;
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted || _ended) return;
        setState(() => _showBossIntro = false);
        _levelStartedAt = DateTime.now();
        _timer = Timer.periodic(
          const Duration(milliseconds: 16),
          (_) => _tick(),
        );
      });
    } else {
      _levelStartedAt = DateTime.now();
      _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _runnerController.dispose();
    super.dispose();
  }

  void _tick() {
    if (_ended) return;
    final dangerGap = _nextDangerGap();
    setState(() {
      _position += (_speed / widget.config.difficulty.tileGap) * .016;
      _particles.tick(.016);
      final warningGap = widget.config.difficulty.warningDuration;
      final ambientShake =
          max(0, widget.config.difficulty.speedMultiplier - 2.0) * .55;
      _shake = dangerGap != null && dangerGap < warningGap
          ? (warningGap - dangerGap) *
                widget.config.difficulty.cameraShakeStrength
          : max(ambientShake, _shake - .3);
    });
    final index = _position.floor();
    if (index != _processedIndex && index >= 0 && index < _tiles.length) {
      _processedIndex = index;
      _enterTile(index);
    }
  }

  double? _nextDangerGap() {
    for (
      var i = _position.floor();
      i < min(_tiles.length, _position.floor() + 4);
      i++
    ) {
      final tile = _tiles[i];
      if (tile.isDanger && !tile.fixed) return i - _position;
    }
    return null;
  }

  void _enterTile(int index) {
    final tile = _tiles[index];
    if (!tile.isPassable) {
      _fail();
      return;
    }
    switch (tile.type) {
      case TileType.coin:
        if (!tile.collected) {
          tile.collected = true;
          _collectedCoinTiles += 1;
          _coins += widget.config.difficulty.coinValue(
            seasonId: widget.config.season.id,
            level: widget.config.level,
          );
          final effect = WardrobeService.instance.loadout.effect;
          _particles.burst(
            _screenActionPoint(),
            effect.id == 'no_effect' ? kGold : effect.primary,
            text: '+coins',
            count: effect.id == 'no_effect' ? 10 : 18,
          );
          unawaited(AudioService.instance.playCoin());
          _show('Coin collected');
        }
      case TileType.ramp:
        _coins += 1;
        _particles.burst(_screenActionPoint(), kSafeGreen, text: 'JUMP!');
        unawaited(AudioService.instance.playSuccess());
        _show('Ramp bonus');
      case TileType.speed:
        _speed = min(
          widget.config.difficulty.speedMultiplier + .22,
          _speed + .12 + widget.config.difficulty.speedMultiplier * .025,
        );
        _particles.burst(
          _screenActionPoint(),
          const Color(0xFFFF8F00),
          text: 'BOOST',
        );
        _show('Speed up');
      case TileType.slow:
        _speed = max(
          widget.config.difficulty.speedMultiplier * .82,
          _speed - .2,
        );
        _particles.burst(
          _screenActionPoint(),
          const Color(0xFF72D6FF),
          text: 'SLOW',
        );
        _show('Slow tile');
      case TileType.teleport:
        _position = min(_position + 2, _tiles.length - 2);
        _particles.burst(
          _screenActionPoint(),
          const Color(0xFF9B5DE5),
          text: 'WARP',
        );
        _show('Teleport');
      case TileType.gravity:
        _coins += 2;
        _particles.burst(
          _screenActionPoint(),
          const Color(0xFF00C2A8),
          text: 'GRAVITY',
        );
        _show('Gravity pulse');
      case TileType.finish:
        unawaited(_complete());
      case TileType.safe:
      case TileType.broken:
      case TileType.fallingBridge:
      case TileType.locked:
      case TileType.moving:
      case TileType.laserWarning:
        break;
    }
  }

  void _tapTile(int index) {
    if (index < 0 || index >= _tiles.length || _ended) return;
    final tile = _tiles[index];
    if (!tile.canTap || tile.fixed) {
      setState(() {
        _shake = max(_shake, 5);
        _feedback = 'Wrong tile!';
        _mistakes += 1;
        _currentPerfectStreak = 0;
        _particles.burst(
          _screenActionPoint(),
          kDangerRed,
          text: 'NO!',
          count: 10,
        );
      });
      unawaited(AudioService.instance.playError());
      return;
    }
    setState(() {
      tile.tapsLeft -= 1;
      if (tile.tapsLeft <= 0) {
        tile.fixed = true;
        _successfulFlips += 1;
        final gap = index - _position;
        final lastSecondWindow = max(
          .42,
          widget.config.difficulty.reactionTime * .5,
        );
        final perfectWindow = max(
          .9,
          widget.config.difficulty.reactionTime * 1.25,
        );
        if (gap > 0 && gap < lastSecondWindow) {
          _lastSecondSaves += 1;
          _currentPerfectStreak += 1;
          _bestPerfectStreak = max(_bestPerfectStreak, _currentPerfectStreak);
          _coins += widget.config.difficulty.perfectBonus(lastSecond: true);
          _shake = 9;
          _feedback = 'LAST SECOND SAVE!';
          _particles.burst(
            _screenActionPoint(),
            kGold,
            text: 'SAVED!',
            count: 22,
          );
          unawaited(AudioService.instance.playSuccess());
        } else if (gap > 0 && gap < perfectWindow) {
          _perfectFlips += 1;
          _currentPerfectStreak += 1;
          _bestPerfectStreak = max(_bestPerfectStreak, _currentPerfectStreak);
          _coins += widget.config.difficulty.perfectBonus(lastSecond: false);
          _feedback = 'PERFECT!';
          _particles.burst(
            _screenActionPoint(),
            kGlowBlue,
            text: 'PERFECT!',
            count: 18,
          );
          unawaited(AudioService.instance.playSuccess());
        } else {
          _feedback = 'Road restored';
          _currentPerfectStreak = 0;
          _particles.burst(
            _screenActionPoint(),
            kSafeGreen,
            text: 'FIXED',
            count: 12,
          );
          unawaited(AudioService.instance.playSuccess());
        }
      } else {
        _feedback = 'One more tap';
        _particles.burst(
          _screenActionPoint(),
          kDangerRed,
          text: '${tile.tapsLeft}',
          count: 8,
        );
      }
    });
  }

  Offset _screenActionPoint() {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height * .58);
  }

  void _show(String text) {
    setState(() => _feedback = text);
  }

  void _fail() {
    _ended = true;
    _timer?.cancel();
    setState(() {
      _pose = RunnerPose.falling;
      _darken = 1;
      _feedback = 'Runner fell';
      _particles.burst(
        _screenActionPoint(),
        kDangerRed,
        text: 'FALL!',
        count: 26,
      );
    });
    unawaited(AudioService.instance.playFail());
    Future<void>.delayed(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      final result = GameResult(
        completed: false,
        seasonId: widget.config.season.id,
        level: widget.config.level,
        seasonName: widget.config.season.name,
        distance: (_position * 10).floor(),
        coins: _coins,
        availableCoins: widget.config.availableCoins,
        perfectFlips: _perfectFlips,
        lastSecondSaves: _lastSecondSaves,
        stars: 0,
        accuracyPercent: 0,
        coinPercent: 0,
        perfectStreak: _bestPerfectStreak,
        mistakes: _mistakes,
        performanceScore: 0,
        perfectRun: false,
      );
      await AdsService.instance.recordGameFinishedAndMaybeShowInterstitial(
        context: context,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              LevelFailedScreen(result: result, retryConfig: widget.config),
        ),
      );
    });
  }

  Future<void> _complete() async {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
    setState(() {
      _pose = RunnerPose.celebrating;
      _feedback = widget.config.isBoss ? 'Boss Defeated!' : 'Level Complete!';
      final effect = WardrobeService.instance.loadout.effect;
      _particles.burst(
        _screenActionPoint(),
        effect.id == 'no_effect' ? kGold : effect.primary,
        text: widget.config.isBoss ? 'BOSS CLEAR!' : 'COMPLETE!',
        count: widget.config.isBoss ? 72 : (effect.id == 'no_effect' ? 42 : 58),
      );
    });
    unawaited(AudioService.instance.playLevelComplete());
    final elapsed = DateTime.now().difference(
      _levelStartedAt ?? DateTime.now(),
    );
    final targetTime = Duration(
      milliseconds:
          ((_tiles.length / widget.config.difficulty.speedMultiplier) * 760)
              .round(),
    );
    final score = ScoringService.calculate(
      completed: true,
      successfulFlips: _successfulFlips,
      requiredFlips: _requiredFlips,
      collectedCoins: _collectedCoinTiles,
      availableCoins: widget.config.availableCoins,
      perfectStreak: _bestPerfectStreak,
      mistakes: _mistakes,
      elapsed: elapsed,
      targetTime: targetTime,
    );
    final result = GameResult(
      completed: true,
      seasonId: widget.config.season.id,
      level: widget.config.level,
      seasonName: widget.config.season.name,
      distance: _tiles.length * 10,
      coins: _coins + score.coinReward - _collectedCoinTiles,
      availableCoins: widget.config.availableCoins,
      perfectFlips: _perfectFlips,
      lastSecondSaves: _lastSecondSaves,
      stars: score.stars,
      accuracyPercent: score.accuracyPercent,
      coinPercent: score.coinPercent,
      perfectStreak: _bestPerfectStreak,
      mistakes: _mistakes,
      performanceScore: score.performanceScore,
      perfectRun: score.perfectRun,
    );
    await ProgressService.instance.completeLevel(result);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    await AdsService.instance.recordGameFinishedAndMaybeShowInterstitial(
      context: context,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LevelCompleteScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = GameData.skins.firstWhere(
      (item) => item.id == ProgressService.instance.selectedSkinId,
    );
    final loadout = WardrobeService.instance.loadout;
    final dangerGap = _nextDangerGap();
    return Scaffold(
      body: PaveBackground(
        gradientColors: widget.config.season.backgroundGradient,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _runnerController,
                builder: (context, _) => ArcadeGameView(
                  tiles: _tiles,
                  position: _position,
                  season: widget.config.season,
                  skin: skin,
                  loadout: loadout,
                  runnerPhase: _runnerController.value,
                  particles: _particles.particles,
                  onTapTile: _tapTile,
                  pose: _pose,
                  shake: _shake,
                  darken: _darken,
                  speedIntensity: widget.config.difficulty.speedMultiplier,
                ),
              ),
            ),
            _GameHud(
              season: widget.config.season,
              level: widget.config.level,
              feedback: _feedback,
              coins: _coins,
              speedText:
                  'Speed x${widget.config.difficulty.speedMultiplier.toStringAsFixed(1)}',
              difficultyText:
                  '${widget.config.difficulty.difficultyLabel} ${widget.config.difficulty.difficultyLevel}/10',
              rewardText:
                  'Reward x${widget.config.difficulty.rewardMultiplier}',
              danger:
                  dangerGap != null &&
                  dangerGap < widget.config.difficulty.warningDuration,
              onClose: () => Navigator.of(context).pop(),
            ),
            if (widget.config.isBoss) _BossGlow(season: widget.config.season),
            if (_showBossIntro)
              _BossIntroCard(
                season: widget.config.season,
                label: widget.config.difficulty.difficultyLabel,
              ),
          ],
        ),
      ),
    );
  }
}

class _BossGlow extends StatelessWidget {
  const _BossGlow({required this.season});

  final SeasonConfig season;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: season.secondaryColor.withValues(alpha: .45),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: season.primaryColor.withValues(alpha: .28),
                blurRadius: 36,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BossIntroCard extends StatelessWidget {
  const _BossIntroCard({required this.season, required this.label});

  final SeasonConfig season;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: .36)),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: season.colors),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white70, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: season.secondaryColor.withValues(alpha: .35),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${season.name} Boss',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
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

class _GameHud extends StatelessWidget {
  const _GameHud({
    required this.season,
    required this.level,
    required this.feedback,
    required this.coins,
    required this.speedText,
    required this.difficultyText,
    required this.rewardText,
    required this.danger,
    required this.onClose,
  });

  final SeasonConfig season;
  final int level;
  final String feedback;
  final int coins;
  final String speedText;
  final String difficultyText;
  final String rewardText;
  final bool danger;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 14,
      right: 14,
      top: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .28),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: danger ? kDangerRed : Colors.white12,
            width: danger ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (danger ? kDangerRed : season.colors.first).withValues(
                alpha: danger ? .32 : .14,
              ),
              blurRadius: 24,
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${season.name} | Level $level',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    danger ? 'DANGER CLOSE!' : feedback,
                    style: TextStyle(
                      color: danger ? kDangerRed : kGlowBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _HudPill(text: speedText),
                      _HudPill(text: difficultyText),
                      _HudPill(text: rewardText),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.monetization_on_rounded, color: kGold),
            const SizedBox(width: 4),
            Text('$coins', style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}
