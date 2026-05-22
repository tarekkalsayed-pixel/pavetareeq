import 'package:shared_preferences/shared_preferences.dart';

class DailyStats {
  const DailyStats({
    required this.streak,
    required this.totalPlayDays,
    required this.completedLevels,
    required this.coinsEarned,
    required this.perfectSaves,
    required this.bestScore,
  });

  final int streak;
  final int totalPlayDays;
  final int completedLevels;
  final int coinsEarned;
  final int perfectSaves;
  final int bestScore;

  double get levelMission => (completedLevels / 3).clamp(0, 1);
  double get coinMission => (coinsEarned / 30).clamp(0, 1);
  double get perfectMission => (perfectSaves / 5).clamp(0, 1);
}

class DailyService {
  DailyService._();

  static final DailyService instance = DailyService._();

  static const _lastPlayedDate = 'daily_lastPlayedDate';
  static const _streak = 'daily_streak';
  static const _totalPlayDays = 'daily_totalPlayDays';
  static const _completedLevels = 'daily_completedLevels';
  static const _coinsEarned = 'daily_coinsEarned';
  static const _perfectSaves = 'daily_perfectSaves';
  static const _bestScore = 'daily_bestScore';

  SharedPreferences? _prefs;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    await markPlayed();
  }

  SharedPreferences get prefs {
    final current = _prefs;
    if (current == null) {
      throw StateError('DailyService.init must be called before use.');
    }
    return current;
  }

  DailyStats get stats => DailyStats(
    streak: prefs.getInt(_streak) ?? 0,
    totalPlayDays: prefs.getInt(_totalPlayDays) ?? 0,
    completedLevels: prefs.getInt(_completedLevels) ?? 0,
    coinsEarned: prefs.getInt(_coinsEarned) ?? 0,
    perfectSaves: prefs.getInt(_perfectSaves) ?? 0,
    bestScore: prefs.getInt(_bestScore) ?? 0,
  );

  Future<void> markPlayed() async {
    final today = _todayKey(DateTime.now());
    final last = prefs.getString(_lastPlayedDate);
    if (last == today) return;

    final yesterday = _todayKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final newStreak = last == yesterday ? (prefs.getInt(_streak) ?? 0) + 1 : 1;
    await prefs.setString(_lastPlayedDate, today);
    await prefs.setInt(_streak, newStreak);
    await prefs.setInt(_totalPlayDays, (prefs.getInt(_totalPlayDays) ?? 0) + 1);
    await prefs.setInt(_completedLevels, 0);
    await prefs.setInt(_coinsEarned, 0);
    await prefs.setInt(_perfectSaves, 0);
    await prefs.setInt(_bestScore, 0);
  }

  Future<void> recordLevel({
    required int coins,
    required int perfectSaves,
    required int score,
  }) async {
    await markPlayed();
    await prefs.setInt(
      _completedLevels,
      (prefs.getInt(_completedLevels) ?? 0) + 1,
    );
    await recordCoins(coins);
    await prefs.setInt(
      _perfectSaves,
      (prefs.getInt(_perfectSaves) ?? 0) + perfectSaves,
    );
    await recordScore(score);
  }

  Future<void> recordCoins(int coins) async {
    await markPlayed();
    await prefs.setInt(_coinsEarned, (prefs.getInt(_coinsEarned) ?? 0) + coins);
  }

  Future<void> recordScore(int score) async {
    await markPlayed();
    if (score > (prefs.getInt(_bestScore) ?? 0)) {
      await prefs.setInt(_bestScore, score);
    }
  }

  String _todayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
