import 'package:shared_preferences/shared_preferences.dart';

import '../data/game_data.dart';
import '../models/game_result.dart';
import '../models/skin_model.dart';
import 'audio_service.dart';
import 'daily_service.dart';
import 'wardrobe_service.dart';

class ProgressService {
  ProgressService._();

  static final ProgressService instance = ProgressService._();

  static const _coins = 'coins';
  static const _bestEndless = 'bestEndlessDistance';
  static const _selectedSkin = 'selectedSkin';
  static const _selectedGender = 'selectedCharacterGender';
  static const _runnerChosen = 'runnerChosen';
  static const _completed = 'completedLevels';
  static const _unlockedSkins = 'unlockedSkins';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    if (!unlockedSkins.contains('default')) {
      await _prefs!.setStringList(_unlockedSkins, ['default']);
    }
    if (selectedSkinId.isEmpty) {
      await _prefs!.setString(_selectedSkin, 'default');
    }
    await AudioService.instance.init(_prefs!);
    await DailyService.instance.init(_prefs!);
    await WardrobeService.instance.init(_prefs!);
  }

  SharedPreferences get prefs {
    final current = _prefs;
    if (current == null) {
      throw StateError('ProgressService.init must be called before use.');
    }
    return current;
  }

  int get coins => prefs.getInt(_coins) ?? 0;
  int get bestEndlessDistance => prefs.getInt(_bestEndless) ?? 0;
  String get selectedSkinId => prefs.getString(_selectedSkin) ?? 'default';
  String get selectedGender => prefs.getString(_selectedGender) ?? 'boy';
  bool get hasChosenRunner => prefs.getBool(_runnerChosen) ?? false;
  List<String> get completedLevels =>
      prefs.getStringList(_completed) ?? <String>[];
  List<String> get unlockedSkins =>
      prefs.getStringList(_unlockedSkins) ?? <String>['default'];

  int starsFor(int seasonId, int level) =>
      prefs.getInt('stars_$seasonId-$level') ?? 0;

  int scoreFor(int seasonId, int level) =>
      prefs.getInt('score_$seasonId-$level') ?? 0;

  Future<void> chooseRunnerGender(String gender) async {
    await prefs.setString(_selectedGender, gender);
    await prefs.setBool(_runnerChosen, true);
  }

  int get totalStars {
    var total = 0;
    for (final season in GameData.seasons) {
      for (var level = 1; level <= 10; level++) {
        total += starsFor(season.id, level);
      }
    }
    return total;
  }

  int seasonCompletedCount(int seasonId) =>
      completedLevels.where((id) => id.startsWith('$seasonId-')).length;

  int seasonStars(int seasonId) {
    var total = 0;
    for (var level = 1; level <= 10; level++) {
      total += starsFor(seasonId, level);
    }
    return total;
  }

  bool isSeasonUnlocked(int seasonId) {
    if (seasonId == 1) return true;
    return seasonCompletedCount(seasonId - 1) >= 10;
  }

  bool isLevelUnlocked(int seasonId, int level) {
    if (!isSeasonUnlocked(seasonId)) return false;
    if (level == 1) return true;
    return completedLevels.contains('$seasonId-${level - 1}');
  }

  bool isSeasonComplete(int seasonId) => seasonCompletedCount(seasonId) >= 10;

  Future<void> completeLevel(GameResult result) async {
    final id = '${result.seasonId}-${result.level}';
    final completed = completedLevels.toSet()..add(id);
    await prefs.setStringList(_completed, completed.toList());

    final previousStars = starsFor(result.seasonId, result.level);
    if (result.stars > previousStars) {
      await prefs.setInt('stars_$id', result.stars);
    }
    if (result.performanceScore > scoreFor(result.seasonId, result.level)) {
      await prefs.setInt('score_$id', result.performanceScore);
    }
    await addCoins(result.coins, recordDaily: false);
    await DailyService.instance.recordLevel(
      coins: result.coins,
      perfectSaves: result.perfectFlips + result.lastSecondSaves,
      score: result.distance,
    );
    await _unlockProgressSkins();
    await WardrobeService.instance.syncProgressUnlocks();
  }

  Future<void> addCoins(int value, {bool recordDaily = true}) async {
    await prefs.setInt(_coins, coins + value);
    if (recordDaily && value > 0) {
      await DailyService.instance.recordCoins(value);
    }
  }

  Future<void> spendCoins(int value) async {
    await prefs.setInt(_coins, (coins - value).clamp(0, 1 << 31));
  }

  Future<void> saveBestEndless(int distance) async {
    if (distance > bestEndlessDistance) {
      await prefs.setInt(_bestEndless, distance);
    }
    await DailyService.instance.recordScore(distance);
  }

  Future<bool> unlockOrSelectSkin(RunnerSkin skin) async {
    final unlocked = unlockedSkins.toSet();
    if (unlocked.contains(skin.id)) {
      await prefs.setString(_selectedSkin, skin.id);
      return true;
    }
    final seasonReady =
        skin.requiredSeason == null || isSeasonComplete(skin.requiredSeason!);
    if (seasonReady && coins >= skin.coinCost) {
      await prefs.setInt(_coins, coins - skin.coinCost);
      unlocked.add(skin.id);
      await prefs.setStringList(_unlockedSkins, unlocked.toList());
      await prefs.setString(_selectedSkin, skin.id);
      return true;
    }
    return false;
  }

  Future<void> _unlockProgressSkins() async {
    final unlocked = unlockedSkins.toSet();
    for (final skin in GameData.skins.where(
      (skin) => skin.requiredSeason != null,
    )) {
      if (isSeasonComplete(skin.requiredSeason!)) {
        unlocked.add(skin.id);
      }
    }
    await prefs.setStringList(_unlockedSkins, unlocked.toList());
  }
}
