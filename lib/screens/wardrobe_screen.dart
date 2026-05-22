import 'package:flutter/material.dart';

import '../data/wardrobe_catalog.dart';
import '../models/wardrobe_item.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/progress_service.dart';
import '../services/wardrobe_service.dart';
import '../theme.dart';
import '../widgets/pave_background.dart';
import '../widgets/runner_preview.dart';
import '../widgets/wardrobe_item_card.dart';

enum _WardrobeFilter { all, owned, locked, legendary }

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  WardrobeCategory _category = WardrobeCategory.character;
  _WardrobeFilter _filter = _WardrobeFilter.all;
  WardrobeItem? _previewItem;
  String? _flash;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    AdService.instance.loadRewardedAd();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = WardrobeService.instance;
    final loadout = _previewLoadout(wardrobe.loadout);
    final items = _filteredItems(
      WardrobeCatalog.byCategory(_category),
      wardrobe,
    );
    return Scaffold(
      body: PaveBackground(
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                loadout: loadout,
                animation: _controller,
                stylePower: _stylePower(wardrobe.loadout),
                flash: _flash,
                onWatchAdForCoins: _watchAdForCoins,
              ),
              _CategoryTabs(
                selected: _category,
                onChanged: (category) => setState(() => _category = category),
              ),
              _FilterChips(
                selected: _filter,
                onChanged: (filter) => setState(() => _filter = filter),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 720
                        ? 4
                        : (constraints.maxWidth >= 470 ? 3 : 2);
                    final aspect = constraints.maxWidth < 360 ? .66 : .72;
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: aspect,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final owned = wardrobe.isOwned(item);
                        final equipped = wardrobe.isEquipped(item);
                        final adProgress = wardrobe.adProgressFor(item);
                        return WardrobeItemCard(
                          item: item,
                          owned: owned,
                          equipped: equipped,
                          previewed: _previewItem?.id == item.id,
                          onTap: () {
                            AudioService.instance.playSelect();
                            setState(() => _previewItem = item);
                          },
                          onAction: () => _unlockOrEquip(item),
                          onWatchAd: item.rewardedAdsRequired > 0
                              ? () => _watchAdForItem(item)
                              : null,
                          adProgressText:
                              '${adProgress.clamp(0, item.rewardedAdsRequired)}/${item.rewardedAdsRequired}',
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<WardrobeItem> _filteredItems(
    List<WardrobeItem> items,
    WardrobeService wardrobe,
  ) {
    final gender = ProgressService.instance.selectedGender == 'girl'
        ? CharacterGender.girl
        : CharacterGender.boy;
    final compatible = items.where((item) => item.supportsGender(gender));
    switch (_filter) {
      case _WardrobeFilter.all:
        return compatible.toList();
      case _WardrobeFilter.owned:
        return compatible.where(wardrobe.isOwned).toList();
      case _WardrobeFilter.locked:
        return compatible.where((item) => !wardrobe.isOwned(item)).toList();
      case _WardrobeFilter.legendary:
        return compatible
            .where(
              (item) =>
                  item.rarity == WardrobeRarity.legendary ||
                  item.rarity == WardrobeRarity.mythic,
            )
            .toList();
    }
  }

  WardrobeLoadout _previewLoadout(WardrobeLoadout current) {
    final item = _previewItem;
    if (item == null || item.category == WardrobeCategory.bundle) {
      return current;
    }
    return WardrobeLoadout(
      character: item.category == WardrobeCategory.character
          ? item
          : current.character,
      hair: item.category == WardrobeCategory.hair ? item : current.hair,
      hat: item.category == WardrobeCategory.hat ? item : current.hat,
      glasses: item.category == WardrobeCategory.glasses
          ? item
          : current.glasses,
      top:
          item.category == WardrobeCategory.tShirt ||
              item.category == WardrobeCategory.top ||
              item.category == WardrobeCategory.dress
          ? item
          : current.top,
      jacket: item.category == WardrobeCategory.jacket ? item : current.jacket,
      pants: item.category == WardrobeCategory.pants ? item : current.pants,
      shoes: item.category == WardrobeCategory.shoes ? item : current.shoes,
      outfit: item.category == WardrobeCategory.outfit ? item : current.outfit,
      watch: item.category == WardrobeCategory.watch ? item : current.watch,
      bag: item.category == WardrobeCategory.bag ? item : current.bag,
      earrings: item.category == WardrobeCategory.earrings
          ? item
          : current.earrings,
      necklace: item.category == WardrobeCategory.necklace
          ? item
          : current.necklace,
      bracelet: item.category == WardrobeCategory.bracelet
          ? item
          : current.bracelet,
      trail: item.category == WardrobeCategory.trail ? item : current.trail,
      effect: item.category == WardrobeCategory.effect ? item : current.effect,
      roadTheme: item.category == WardrobeCategory.roadTheme
          ? item
          : current.roadTheme,
    );
  }

  int _stylePower(WardrobeLoadout loadout) {
    return [
      loadout.character,
      loadout.hair,
      loadout.hat,
      loadout.glasses,
      loadout.top,
      loadout.jacket,
      loadout.pants,
      loadout.shoes,
      loadout.outfit,
      loadout.watch,
      loadout.bag,
      loadout.earrings,
      loadout.necklace,
      loadout.bracelet,
      loadout.trail,
      loadout.effect,
      loadout.roadTheme,
    ].fold(0, (sum, item) => sum + 10 + item.rarity.index * 12);
  }

  Future<void> _unlockOrEquip(WardrobeItem item) async {
    final result = await WardrobeService.instance.unlockOrEquip(item);
    if (!mounted) return;
    if (result.success) {
      if (result.message == 'Unlocked') {
        await AudioService.instance.playUnlock();
      } else {
        await AudioService.instance.playSelect();
      }
    } else {
      await AudioService.instance.playError();
    }
    if (!mounted) return;
    setState(() {
      _previewItem = item.category == WardrobeCategory.bundle ? null : item;
      _flash = result.message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? result.message
              : '${result.message}. Complete levels to earn more coins.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _flash = null);
    });
  }

  Future<void> _watchAdForItem(WardrobeItem item) async {
    await AdService.instance.showRewardedAd(
      context: context,
      onUnavailable: () =>
          _showMessage('Ad is still loading, try again in a moment.'),
      onRewardEarned: () async {
        final result = await WardrobeService.instance.recordRewardedAdForItem(
          item,
        );
        if (!mounted) return;
        await (result.message.contains('Unlocked')
            ? AudioService.instance.playUnlock()
            : AudioService.instance.playSuccess());
        setState(() {
          _previewItem = item.category == WardrobeCategory.bundle ? null : item;
          _flash = result.message;
        });
        _showMessage(result.message);
      },
    );
  }

  Future<void> _watchAdForCoins() async {
    final wardrobe = WardrobeService.instance;
    if (!wardrobe.canWatchAdForCoins) {
      await AudioService.instance.playError();
      _showMessage('Daily rewarded coin limit reached.');
      return;
    }
    await AdService.instance.showRewardedAd(
      context: context,
      onUnavailable: () =>
          _showMessage('Ad is still loading, try again in a moment.'),
      onRewardEarned: () async {
        final rewarded = await wardrobe.rewardCoinsFromAd(coins: 50);
        if (!mounted) return;
        await (rewarded
            ? AudioService.instance.playCoin()
            : AudioService.instance.playError());
        setState(() => _flash = rewarded ? '+50 coins' : 'Daily limit reached');
        _showMessage(
          rewarded ? '+50 coins added' : 'Daily rewarded coin limit reached.',
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.loadout,
    required this.animation,
    required this.stylePower,
    required this.flash,
    required this.onWatchAdForCoins,
  });

  final WardrobeLoadout loadout;
  final Animation<double> animation;
  final int stylePower;
  final String? flash;
  final VoidCallback onWatchAdForCoins;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final previewSize = compact ? 92.0 : 118.0;
        return Container(
          margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          padding: EdgeInsets.all(compact ? 10 : 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .28),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: kGlowBlue.withValues(alpha: .16),
                blurRadius: 28,
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              AnimatedBuilder(
                animation: animation,
                builder: (context, _) => RunnerPreview(
                  loadout: loadout,
                  animationValue: animation.value,
                  size: previewSize,
                ),
              ),
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Wardrobe',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 22 : 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Icon(Icons.monetization_on_rounded, color: kGold),
                        Text(
                          '${ProgressService.instance.coins}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    Text(
                      loadout.character.name,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Style Power $stylePower',
                      style: const TextStyle(
                        color: kGlowBlue,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Complete levels to earn more coins',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .45),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onWatchAdForCoins,
                      icon: const Icon(Icons.play_circle_rounded),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Watch Ad +50 (${WardrobeService.instance.dailyAdCoinLimit - WardrobeService.instance.dailyAdCoinCount}/${WardrobeService.instance.dailyAdCoinLimit})',
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kGold,
                        side: const BorderSide(color: kGold),
                      ),
                    ),
                    if (flash != null)
                      Text(
                        flash!,
                        style: const TextStyle(
                          color: kGold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.selected, required this.onChanged});

  final WardrobeCategory selected;
  final ValueChanged<WardrobeCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    final categories = _categoriesForSelectedGender();
    return SizedBox(
      height: 46,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        children: categories.map((category) {
          final active = category == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: active,
              label: Text(category.label),
              onSelected: (_) => onChanged(category),
              selectedColor: kGlowBlue,
              labelStyle: TextStyle(
                color: active ? Colors.black : Colors.white,
                fontWeight: FontWeight.w900,
              ),
              backgroundColor: Colors.white.withValues(alpha: .08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
                side: BorderSide(color: active ? kGlowBlue : Colors.white12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<WardrobeCategory> _categoriesForSelectedGender() {
    if (ProgressService.instance.selectedGender == 'girl') {
      return const [
        WardrobeCategory.character,
        WardrobeCategory.hair,
        WardrobeCategory.hat,
        WardrobeCategory.glasses,
        WardrobeCategory.top,
        WardrobeCategory.dress,
        WardrobeCategory.jacket,
        WardrobeCategory.pants,
        WardrobeCategory.shoes,
        WardrobeCategory.bag,
        WardrobeCategory.earrings,
        WardrobeCategory.necklace,
        WardrobeCategory.bracelet,
        WardrobeCategory.trail,
        WardrobeCategory.roadTheme,
      ];
    }
    return const [
      WardrobeCategory.character,
      WardrobeCategory.hair,
      WardrobeCategory.hat,
      WardrobeCategory.glasses,
      WardrobeCategory.tShirt,
      WardrobeCategory.jacket,
      WardrobeCategory.pants,
      WardrobeCategory.shoes,
      WardrobeCategory.watch,
      WardrobeCategory.trail,
      WardrobeCategory.roadTheme,
    ];
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onChanged});

  final _WardrobeFilter selected;
  final ValueChanged<_WardrobeFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = {
      _WardrobeFilter.all: 'All',
      _WardrobeFilter.owned: 'Owned',
      _WardrobeFilter.locked: 'Locked',
      _WardrobeFilter.legendary: 'Legendary',
    };
    return SizedBox(
      height: 38,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        children: labels.entries.map((entry) {
          final active = selected == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: active,
              label: Text(entry.value),
              onSelected: (_) => onChanged(entry.key),
              selectedColor: kGold,
              labelStyle: TextStyle(
                color: active ? Colors.black : Colors.white70,
                fontWeight: FontWeight.w800,
              ),
              backgroundColor: Colors.white.withValues(alpha: .06),
            ),
          );
        }).toList(),
      ),
    );
  }
}
