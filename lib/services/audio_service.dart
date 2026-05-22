import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/game_data.dart';

class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  static const _legacyMutedKey = 'audio_muted';
  static const _musicMutedKey = 'music_muted';
  static const _sfxMutedKey = 'sfx_muted';
  static const _musicVolumeKey = 'music_volume';
  static const _sfxVolumeKey = 'sfx_volume';
  static const menuMusicAsset = 'audio/music/menu_loop.mp3';

  final AudioPlayer _musicPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.loop);
  final AudioPlayer _sfxPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  SharedPreferences? _prefs;
  String? _currentMusicAsset;
  double _musicDucking = 1;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    await _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _musicPlayer.setPlayerMode(PlayerMode.mediaPlayer);
  }

  bool get musicMuted => _prefs?.getBool(_musicMutedKey) ?? muted;
  bool get sfxMuted => _prefs?.getBool(_sfxMutedKey) ?? muted;
  bool get muted => _prefs?.getBool(_legacyMutedKey) ?? false;
  double get musicVolume => _prefs?.getDouble(_musicVolumeKey) ?? .38;
  double get sfxVolume => _prefs?.getDouble(_sfxVolumeKey) ?? .55;

  Future<void> setMuted(bool value) async {
    await setMusicMuted(value);
    await setSfxMuted(value);
    await _prefs?.setBool(_legacyMutedKey, value);
  }

  Future<void> toggleMuted() async => setMuted(!(musicMuted || sfxMuted));

  Future<void> setMusicMuted(bool value) async {
    await _prefs?.setBool(_musicMutedKey, value);
    await _prefs?.setBool(_legacyMutedKey, value && sfxMuted);
    if (value) {
      await pauseMusic();
    } else if (_currentMusicAsset != null) {
      await resumeMusic();
    }
  }

  Future<void> setSfxMuted(bool value) async {
    await _prefs?.setBool(_sfxMutedKey, value);
    await _prefs?.setBool(_legacyMutedKey, value && musicMuted);
  }

  Future<void> setMusicVolume(double value) async {
    final volume = value.clamp(0.0, 1.0).toDouble();
    await _prefs?.setDouble(_musicVolumeKey, volume);
    await _musicPlayer.setVolume(volume * _musicDucking);
  }

  Future<void> setSfxVolume(double value) async {
    await _prefs?.setDouble(_sfxVolumeKey, value.clamp(0.0, 1.0).toDouble());
  }

  Future<void> playMenuMusic() => _playMusic(menuMusicAsset, volumeScale: .65);

  Future<void> playClick() => playTap();

  Future<void> playSeasonMusic(int seasonId, {double volumeScale = 1}) async {
    final season = GameData.seasons.firstWhere(
      (item) => item.id == seasonId,
      orElse: () => GameData.seasons.first,
    );
    await _playMusic(season.musicAsset, volumeScale: volumeScale);
  }

  Future<void> stopMusic() async {
    _currentMusicAsset = null;
    await _musicPlayer.stop();
  }

  Future<void> pauseMusic() async {
    try {
      await _musicPlayer.pause();
    } on Exception {
      // Missing or unsupported music assets should never affect play.
    }
  }

  Future<void> resumeMusic() async {
    if (musicMuted) return;
    try {
      await _musicPlayer.resume();
    } on Exception {
      if (_currentMusicAsset != null) {
        await _playMusic(_currentMusicAsset!);
      }
    }
  }

  Future<void> playTap() async {
    await HapticFeedback.lightImpact();
    await _playSfx('tap.wav');
  }

  Future<void> playCoin() => _playSfx('coin.wav');

  Future<void> playSuccess() async {
    await HapticFeedback.mediumImpact();
    await _playSfx('success.wav');
  }

  Future<void> playFail() async {
    await HapticFeedback.heavyImpact();
    unawaited(_duckMusic());
    await _playSfx('fail.wav');
  }

  Future<void> playLevelComplete() async {
    await HapticFeedback.mediumImpact();
    await _playSfx('level_complete.wav');
  }

  Future<void> playUnlock() => _playSfx('unlock.wav');

  Future<void> playSelect() => _playSfx('select.wav');

  Future<void> playError() async {
    await HapticFeedback.heavyImpact();
    await _playSfx('error.wav');
  }

  Future<void> _playMusic(String asset, {double volumeScale = 1}) async {
    if (musicMuted) return;
    final effectiveVolume = musicVolume * volumeScale * _musicDucking;
    try {
      if (_currentMusicAsset == asset) {
        await _musicPlayer.setVolume(effectiveVolume);
        final state = _musicPlayer.state;
        if (state == PlayerState.paused || state == PlayerState.stopped) {
          await _musicPlayer.resume();
        }
        return;
      }
      _currentMusicAsset = asset;
      await _musicPlayer.stop();
      await _musicPlayer.play(AssetSource(asset), volume: effectiveVolume);
    } on Exception {
      // Add royalty-free loops at assets/music/*.mp3 when ready.
    }
  }

  Future<void> _duckMusic() async {
    if (musicMuted || _currentMusicAsset == null) return;
    _musicDucking = .35;
    await _musicPlayer.setVolume(musicVolume * _musicDucking);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _musicDucking = 1;
    if (!musicMuted) await _musicPlayer.setVolume(musicVolume);
  }

  Future<void> _playSfx(String file) async {
    if (sfxMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/sfx/$file'), volume: sfxVolume);
    } on Exception {
      // Audio should never block gameplay or navigation.
    }
  }
}
