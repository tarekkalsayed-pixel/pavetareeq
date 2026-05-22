import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../game/arcade_game_view.dart';
import '../game/particle_system.dart';
import '../game/runner_painter.dart';
import '../models/tile_model.dart';
import '../services/progress_service.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/wardrobe_service.dart';
import '../theme.dart';
import '../widgets/game_button.dart';
import '../widgets/pave_background.dart';

class EndlessScreen extends StatefulWidget {
  const EndlessScreen({super.key});

  @override
  State<EndlessScreen> createState() => _EndlessScreenState();
}

class _EndlessScreenState extends State<EndlessScreen>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final ParticleSystem _particles = ParticleSystem();
  final List<RoadTile> _tiles = [];
  late final AnimationController _runnerController;
  Timer? _timer;
  double _position = 0;
  double _speed = 1.28;
  double _shake = 0;
  double _darken = 0;
  int _processedIndex = -1;
  int _coins = 0;
  int _distance = 0;
  bool _gameOver = false;
  RunnerPose _pose = RunnerPose.running;
  String _feedback = 'Endless road';

  @override
  void initState() {
    super.initState();
    _runnerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    )..repeat();
    _restart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _runnerController.dispose();
    super.dispose();
  }

  void _restart() {
    _timer?.cancel();
    _particles.particles.clear();
    _tiles
      ..clear()
      ..addAll(
        List.generate(
          20,
          (index) =>
              RoadTile(type: index < 4 ? TileType.safe : _nextType(index)),
        ),
      );
    setState(() {
      _position = 0;
      _speed = 1.28;
      _shake = 0;
      _darken = 0;
      _processedIndex = -1;
      _coins = 0;
      _distance = 0;
      _gameOver = false;
      _pose = RunnerPose.running;
      _feedback = 'Endless road';
    });
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  TileType _nextType(int index) {
    final difficulty = min(.55, index / 120);
    final roll = _random.nextDouble();
    if (roll < .12 + difficulty) {
      return [
        TileType.broken,
        TileType.fallingBridge,
        TileType.locked,
        TileType.laserWarning,
      ][_random.nextInt(4)];
    }
    if (roll < .34) return TileType.coin;
    if (roll < .5) {
      return [
        TileType.ramp,
        TileType.speed,
        TileType.slow,
        TileType.gravity,
        TileType.teleport,
      ][_random.nextInt(5)];
    }
    return TileType.safe;
  }

  void _tick() {
    if (_gameOver) return;
    final dangerGap = _nextDangerGap();
    setState(() {
      _position += _speed * .016;
      _speed += .0018;
      _distance = (_position * 10).floor();
      _particles.tick(.016);
      _shake = dangerGap != null && dangerGap < 1.1
          ? (1.1 - dangerGap) * 8
          : max(0, _shake - .35);
      while (_tiles.length < _position.floor() + 20) {
        _tiles.add(RoadTile(type: _nextType(_tiles.length)));
      }
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
      unawaited(_end());
      return;
    }
    switch (tile.type) {
      case TileType.coin:
        if (!tile.collected) {
          tile.collected = true;
          _coins += 2;
          final effect = WardrobeService.instance.loadout.effect;
          _particles.burst(
            _actionPoint(),
            effect.id == 'no_effect' ? kGold : effect.primary,
            text: '+coins',
            count: effect.id == 'no_effect' ? 10 : 18,
          );
          unawaited(AudioService.instance.playCoin());
          _feedback = 'Coin +2';
        }
      case TileType.speed:
        _speed += .12;
        _particles.burst(
          _actionPoint(),
          const Color(0xFFFF8F00),
          text: 'BOOST',
        );
        _feedback = 'Speed up';
      case TileType.slow:
        _speed = max(.95, _speed - .18);
        _particles.burst(_actionPoint(), const Color(0xFF72D6FF), text: 'SLOW');
        _feedback = 'Slow tile';
      case TileType.teleport:
        _position += 1.5;
        _particles.burst(_actionPoint(), const Color(0xFF9B5DE5), text: 'WARP');
        _feedback = 'Teleport';
      case TileType.ramp:
      case TileType.gravity:
        _coins += 1;
        _particles.burst(_actionPoint(), kSafeGreen, text: '+1');
        unawaited(AudioService.instance.playSuccess());
        _feedback = 'Bonus';
      case TileType.safe:
      case TileType.broken:
      case TileType.fallingBridge:
      case TileType.locked:
      case TileType.moving:
      case TileType.laserWarning:
      case TileType.finish:
        break;
    }
  }

  Future<void> _end() async {
    if (_gameOver) return;
    _gameOver = true;
    _timer?.cancel();
    setState(() {
      _pose = RunnerPose.falling;
      _darken = 1;
      _feedback = 'Game Over';
      _particles.burst(_actionPoint(), kDangerRed, text: 'FALL!', count: 28);
    });
    unawaited(AudioService.instance.playFail());
    await ProgressService.instance.addCoins(_coins);
    await ProgressService.instance.saveBestEndless(_distance);
    if (mounted) {
      await AdsService.instance.recordGameFinishedAndMaybeShowInterstitial(
        context: context,
      );
    }
    if (mounted) setState(() {});
  }

  void _tapTile(int index) {
    if (index < 0 || index >= _tiles.length || _gameOver) return;
    final tile = _tiles[index];
    if (!tile.canTap || tile.fixed) return;
    setState(() {
      tile.tapsLeft -= 1;
      if (tile.tapsLeft <= 0) {
        tile.fixed = true;
        final gap = index - _position;
        if (gap > 0 && gap < .75) {
          _coins += 3;
          _shake = 9;
          _feedback = 'LAST SECOND SAVE!';
          _particles.burst(_actionPoint(), kGold, text: 'SAVED!', count: 22);
          unawaited(AudioService.instance.playSuccess());
        } else if (gap > 0 && gap < 1.8) {
          _coins += 2;
          _feedback = 'PERFECT!';
          _particles.burst(
            _actionPoint(),
            kGlowBlue,
            text: 'PERFECT!',
            count: 18,
          );
          unawaited(AudioService.instance.playSuccess());
        } else {
          _feedback = 'Fixed';
          _particles.burst(
            _actionPoint(),
            kSafeGreen,
            text: 'FIXED',
            count: 12,
          );
          unawaited(AudioService.instance.playSuccess());
        }
      } else {
        _feedback = 'One more tap';
      }
    });
  }

  Offset _actionPoint() {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height * .58);
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    final skin = GameData.skins.firstWhere(
      (item) => item.id == progress.selectedSkinId,
    );
    final loadout = WardrobeService.instance.loadout;
    final season = GameData.seasons[4];
    final dangerGap = _nextDangerGap();
    return Scaffold(
      body: PaveBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _runnerController,
                builder: (context, _) => ArcadeGameView(
                  tiles: _tiles,
                  position: _position,
                  season: season,
                  skin: skin,
                  loadout: loadout,
                  runnerPhase: _runnerController.value,
                  particles: _particles.particles,
                  onTapTile: _tapTile,
                  pose: _pose,
                  shake: _shake,
                  darken: _darken,
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: dangerGap != null && dangerGap < 1.7
                        ? kDangerRed
                        : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_distance}m | Best ${max(progress.bestEndlessDistance, _distance)}m',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            dangerGap != null && dangerGap < 1.7
                                ? 'DANGER CLOSE!'
                                : _feedback,
                            style: TextStyle(
                              color: dangerGap != null && dangerGap < 1.7
                                  ? kDangerRed
                                  : kGlowBlue,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.monetization_on_rounded, color: kGold),
                    Text(
                      '$_coins',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            if (_gameOver)
              Positioned(
                left: 18,
                right: 18,
                bottom: 22,
                child: _GameOverPanel(
                  distance: _distance,
                  coins: _coins,
                  onRestart: _restart,
                ),
              )
            else
              const Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Text(
                  'Tap glowing danger tiles before the runner reaches them.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GameOverPanel extends StatelessWidget {
  const _GameOverPanel({
    required this.distance,
    required this.coins,
    required this.onRestart,
  });

  final int distance;
  final int coins;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .58),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(color: kGlowPink.withValues(alpha: .24), blurRadius: 30),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Game Over',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '$distance meters | $coins coins',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          GameButton(
            label: 'Restart',
            icon: Icons.refresh_rounded,
            onPressed: onRestart,
          ),
          const SizedBox(height: 10),
          GameButton(
            label: 'Back Home',
            icon: Icons.home_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
