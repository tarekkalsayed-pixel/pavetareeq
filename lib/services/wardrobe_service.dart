import 'package:shared_preferences/shared_preferences.dart';

import '../data/wardrobe_catalog.dart';
import '../models/wardrobe_item.dart';
import 'progress_service.dart';

class WardrobeLoadout {
  const WardrobeLoadout({
    required this.character,
    required this.hair,
    required this.hat,
    required this.glasses,
    required this.top,
    required this.jacket,
    required this.pants,
    required this.shoes,
    required this.outfit,
    required this.watch,
    required this.bag,
    required this.earrings,
    required this.necklace,
    required this.bracelet,
    required this.trail,
    required this.effect,
    required this.roadTheme,
  });

  final WardrobeItem character;
  final WardrobeItem hair;
  final WardrobeItem hat;
  final WardrobeItem glasses;
  final WardrobeItem top;
  final WardrobeItem jacket;
  final WardrobeItem pants;
  final WardrobeItem shoes;
  final WardrobeItem outfit;
  final WardrobeItem watch;
  final WardrobeItem bag;
  final WardrobeItem earrings;
  final WardrobeItem necklace;
  final WardrobeItem bracelet;
  final WardrobeItem trail;
  final WardrobeItem effect;
  final WardrobeItem roadTheme;
}

class WardrobeService {
  WardrobeService._();

  static final WardrobeService instance = WardrobeService._();

  static const _owned = 'wardrobe_ownedItemIds';
  static const _equippedCharacter = 'selectedSkin';
  static const _equippedHair = 'wardrobe_equippedHair';
  static const _equippedHat = 'wardrobe_equippedHat';
  static const _equippedGlasses = 'wardrobe_equippedGlasses';
  static const _equippedTop = 'wardrobe_equippedTop';
  static const _equippedJacket = 'wardrobe_equippedJacket';
  static const _equippedPants = 'wardrobe_equippedPants';
  static const _equippedShoes = 'wardrobe_equippedShoes';
  static const _equippedOutfit = 'wardrobe_equippedOutfit';
  static const _equippedWatch = 'wardrobe_equippedWatch';
  static const _equippedBag = 'wardrobe_equippedBag';
  static const _equippedEarrings = 'wardrobe_equippedEarrings';
  static const _equippedNecklace = 'wardrobe_equippedNecklace';
  static const _equippedBracelet = 'wardrobe_equippedBracelet';
  static const _equippedTrail = 'wardrobe_equippedTrail';
  static const _equippedEffect = 'wardrobe_equippedEffect';
  static const _equippedRoadTheme = 'wardrobe_equippedRoadTheme';
  static const _dailyAdCoinsDate = 'wardrobe_dailyAdCoinsDate';
  static const _dailyAdCoinsCount = 'wardrobe_dailyAdCoinsCount';

  SharedPreferences? _prefs;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    final owned = ownedItemIds.toSet()
      ..addAll([
        'default',
        'skater',
        'street_girl',
        'short_hair',
        'long_hair',
        'no_hat',
        'no_glasses',
        'basic_top',
        'basic_jacket',
        'runner_pants',
        'basic_shoes',
        'default_hoodie',
        'no_watch',
        'no_bag',
        'no_earrings',
        'no_necklace',
        'no_bracelet',
        'no_trail',
        'no_effect',
        'toy_city_road',
      ])
      ..add('classic_road')
      ..addAll(prefs.getStringList('unlockedSkins') ?? const <String>[]);
    await prefs.setStringList(_owned, owned.toList());
    await _ensureDefault(_equippedCharacter, 'default');
    await _ensureDefault(_equippedHair, 'short_hair');
    await _ensureDefault(_equippedHat, 'no_hat');
    await _ensureDefault(_equippedGlasses, 'no_glasses');
    await _ensureDefault(_equippedTop, 'basic_top');
    await _ensureDefault(_equippedJacket, 'basic_jacket');
    await _ensureDefault(_equippedPants, 'runner_pants');
    await _ensureDefault(_equippedShoes, 'basic_shoes');
    await _ensureDefault(_equippedOutfit, 'default_hoodie');
    await _ensureDefault(_equippedWatch, 'no_watch');
    await _ensureDefault(_equippedBag, 'no_bag');
    await _ensureDefault(_equippedEarrings, 'no_earrings');
    await _ensureDefault(_equippedNecklace, 'no_necklace');
    await _ensureDefault(_equippedBracelet, 'no_bracelet');
    await _ensureDefault(_equippedTrail, 'no_trail');
    await _ensureDefault(_equippedEffect, 'no_effect');
    await _ensureDefault(_equippedRoadTheme, 'toy_city_road');
    await syncProgressUnlocks();
  }

  SharedPreferences get prefs {
    final current = _prefs;
    if (current == null) {
      throw StateError('WardrobeService.init must be called before use.');
    }
    return current;
  }

  List<String> get ownedItemIds => prefs.getStringList(_owned) ?? <String>[];

  WardrobeLoadout get loadout => WardrobeLoadout(
    character: WardrobeCatalog.byId(
      prefs.getString(_equippedCharacter) ?? 'default',
    ),
    hair: WardrobeCatalog.byId(prefs.getString(_equippedHair) ?? 'short_hair'),
    hat: WardrobeCatalog.byId(prefs.getString(_equippedHat) ?? 'no_hat'),
    glasses: WardrobeCatalog.byId(
      prefs.getString(_equippedGlasses) ?? 'no_glasses',
    ),
    top: WardrobeCatalog.byId(prefs.getString(_equippedTop) ?? 'basic_top'),
    jacket: WardrobeCatalog.byId(
      prefs.getString(_equippedJacket) ?? 'basic_jacket',
    ),
    pants: WardrobeCatalog.byId(
      prefs.getString(_equippedPants) ?? 'runner_pants',
    ),
    shoes: WardrobeCatalog.byId(
      prefs.getString(_equippedShoes) ?? 'basic_shoes',
    ),
    outfit: WardrobeCatalog.byId(
      prefs.getString(_equippedOutfit) ?? 'default_hoodie',
    ),
    watch: WardrobeCatalog.byId(prefs.getString(_equippedWatch) ?? 'no_watch'),
    bag: WardrobeCatalog.byId(prefs.getString(_equippedBag) ?? 'no_bag'),
    earrings: WardrobeCatalog.byId(
      prefs.getString(_equippedEarrings) ?? 'no_earrings',
    ),
    necklace: WardrobeCatalog.byId(
      prefs.getString(_equippedNecklace) ?? 'no_necklace',
    ),
    bracelet: WardrobeCatalog.byId(
      prefs.getString(_equippedBracelet) ?? 'no_bracelet',
    ),
    trail: WardrobeCatalog.byId(prefs.getString(_equippedTrail) ?? 'no_trail'),
    effect: WardrobeCatalog.byId(
      prefs.getString(_equippedEffect) ?? 'no_effect',
    ),
    roadTheme: WardrobeCatalog.byId(
      prefs.getString(_equippedRoadTheme) ?? 'toy_city_road',
    ),
  );

  int adProgressFor(WardrobeItem item) =>
      prefs.getInt('wardrobe_ads_${item.id}') ?? 0;

  int get dailyAdCoinCount {
    _resetDailyAdCoinsIfNeeded();
    return prefs.getInt(_dailyAdCoinsCount) ?? 0;
  }

  int get dailyAdCoinLimit => 5;

  bool get canWatchAdForCoins => dailyAdCoinCount < dailyAdCoinLimit;

  bool isOwned(WardrobeItem item) =>
      ownedItemIds.contains(item.id) ||
      item.isFree ||
      (_hasProgressRequirement(item) && _progressUnlocked(item));

  bool isEquipped(WardrobeItem item) {
    final key = _equipKey(item.category);
    return key != null &&
        (prefs.getString(key) ?? _defaultFor(item.category)) == item.id;
  }

  Future<WardrobeActionResult> unlockOrEquip(WardrobeItem item) async {
    if (isOwned(item)) {
      await equip(item);
      return const WardrobeActionResult(success: true, message: 'Equipped');
    }
    if (!_coinUnlockAllowed(item)) {
      return WardrobeActionResult(success: false, message: item.unlockText);
    }
    if (ProgressService.instance.coins < item.price) {
      return const WardrobeActionResult(
        success: false,
        message: 'Not enough coins',
      );
    }
    await ProgressService.instance.spendCoins(item.price);
    final owned = ownedItemIds.toSet()..add(item.id);
    if (item.category == WardrobeCategory.bundle) {
      owned.addAll(item.bundleItemIds);
    }
    await prefs.setStringList(_owned, owned.toList());
    await equip(item);
    return const WardrobeActionResult(success: true, message: 'Unlocked');
  }

  Future<WardrobeActionResult> recordRewardedAdForItem(
    WardrobeItem item,
  ) async {
    if (isOwned(item)) {
      await equip(item);
      return const WardrobeActionResult(success: true, message: 'Equipped');
    }
    if (item.rewardedAdsRequired <= 0) {
      return const WardrobeActionResult(
        success: false,
        message: 'This item cannot be unlocked with ads',
      );
    }
    final watched = (adProgressFor(item) + 1).clamp(
      0,
      item.rewardedAdsRequired,
    );
    await prefs.setInt('wardrobe_ads_${item.id}', watched);
    if (watched >= item.rewardedAdsRequired) {
      final owned = ownedItemIds.toSet()..add(item.id);
      await prefs.setStringList(_owned, owned.toList());
      await equip(item);
      return const WardrobeActionResult(
        success: true,
        message: 'Unlocked with rewarded ads',
      );
    }
    return WardrobeActionResult(
      success: true,
      message: '$watched/${item.rewardedAdsRequired} ads watched',
    );
  }

  Future<bool> rewardCoinsFromAd({int coins = 50}) async {
    _resetDailyAdCoinsIfNeeded();
    if (!canWatchAdForCoins) return false;
    await ProgressService.instance.addCoins(coins);
    await prefs.setInt(_dailyAdCoinsCount, dailyAdCoinCount + 1);
    return true;
  }

  Future<void> equip(WardrobeItem item) async {
    if (item.category == WardrobeCategory.bundle) {
      for (final id in item.bundleItemIds) {
        final bundleItem = WardrobeCatalog.byId(id);
        if (isOwned(bundleItem)) {
          await equip(bundleItem);
        }
      }
      return;
    }
    final key = _equipKey(item.category);
    if (key != null) await prefs.setString(key, item.id);
  }

  Future<void> syncProgressUnlocks() async {
    final owned = ownedItemIds.toSet();
    for (final item in WardrobeCatalog.items) {
      if (_progressUnlocked(item) && item.price == 0) {
        owned
          ..add(item.id)
          ..addAll(item.bundleItemIds);
      }
    }
    await prefs.setStringList(_owned, owned.toList());
  }

  bool _hasProgressRequirement(WardrobeItem item) =>
      item.requiredSeason != null || item.requiredCompletedLevels != null;

  bool _progressUnlocked(WardrobeItem item) {
    final progress = ProgressService.instance;
    final seasonReady =
        item.requiredSeason == null ||
        progress.isSeasonComplete(item.requiredSeason!);
    final levelsReady =
        item.requiredCompletedLevels == null ||
        progress.completedLevels.length >= item.requiredCompletedLevels!;
    return seasonReady && levelsReady;
  }

  Future<void> _ensureDefault(String key, String value) async {
    if ((prefs.getString(key) ?? '').isEmpty) await prefs.setString(key, value);
  }

  String? _equipKey(WardrobeCategory category) {
    switch (category) {
      case WardrobeCategory.character:
        return _equippedCharacter;
      case WardrobeCategory.hair:
        return _equippedHair;
      case WardrobeCategory.hat:
        return _equippedHat;
      case WardrobeCategory.glasses:
        return _equippedGlasses;
      case WardrobeCategory.tShirt:
      case WardrobeCategory.top:
      case WardrobeCategory.dress:
        return _equippedTop;
      case WardrobeCategory.jacket:
        return _equippedJacket;
      case WardrobeCategory.pants:
        return _equippedPants;
      case WardrobeCategory.shoes:
        return _equippedShoes;
      case WardrobeCategory.outfit:
        return _equippedOutfit;
      case WardrobeCategory.watch:
        return _equippedWatch;
      case WardrobeCategory.bag:
        return _equippedBag;
      case WardrobeCategory.earrings:
        return _equippedEarrings;
      case WardrobeCategory.necklace:
        return _equippedNecklace;
      case WardrobeCategory.bracelet:
        return _equippedBracelet;
      case WardrobeCategory.trail:
        return _equippedTrail;
      case WardrobeCategory.effect:
        return _equippedEffect;
      case WardrobeCategory.roadTheme:
        return _equippedRoadTheme;
      case WardrobeCategory.bundle:
        return null;
    }
  }

  String _defaultFor(WardrobeCategory category) {
    switch (category) {
      case WardrobeCategory.character:
        return 'default';
      case WardrobeCategory.hair:
        return 'short_hair';
      case WardrobeCategory.hat:
        return 'no_hat';
      case WardrobeCategory.glasses:
        return 'no_glasses';
      case WardrobeCategory.tShirt:
      case WardrobeCategory.top:
      case WardrobeCategory.dress:
        return 'basic_top';
      case WardrobeCategory.jacket:
        return 'basic_jacket';
      case WardrobeCategory.pants:
        return 'runner_pants';
      case WardrobeCategory.shoes:
        return 'basic_shoes';
      case WardrobeCategory.outfit:
        return 'default_hoodie';
      case WardrobeCategory.watch:
        return 'no_watch';
      case WardrobeCategory.bag:
        return 'no_bag';
      case WardrobeCategory.earrings:
        return 'no_earrings';
      case WardrobeCategory.necklace:
        return 'no_necklace';
      case WardrobeCategory.bracelet:
        return 'no_bracelet';
      case WardrobeCategory.trail:
        return 'no_trail';
      case WardrobeCategory.effect:
        return 'no_effect';
      case WardrobeCategory.roadTheme:
        return 'toy_city_road';
      case WardrobeCategory.bundle:
        return '';
    }
  }

  bool _coinUnlockAllowed(WardrobeItem item) =>
      item.price > 0 || _progressUnlocked(item);

  void _resetDailyAdCoinsIfNeeded() {
    final today = _todayKey(DateTime.now());
    if (prefs.getString(_dailyAdCoinsDate) != today) {
      prefs.setString(_dailyAdCoinsDate, today);
      prefs.setInt(_dailyAdCoinsCount, 0);
    }
  }

  String _todayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class WardrobeActionResult {
  const WardrobeActionResult({required this.success, required this.message});

  final bool success;
  final String message;
}
