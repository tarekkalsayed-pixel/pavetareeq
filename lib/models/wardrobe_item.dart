import 'package:flutter/material.dart';

enum WardrobeCategory {
  character,
  hair,
  hat,
  glasses,
  tShirt,
  top,
  dress,
  jacket,
  pants,
  shoes,
  outfit,
  watch,
  bag,
  earrings,
  necklace,
  bracelet,
  trail,
  effect,
  bundle,
  roadTheme,
}

enum WardrobeRarity { common, rare, epic, legendary, mythic }

enum CharacterGender { boy, girl }

enum WardrobeGenderCompatibility { boy, girl, both }

class WardrobeItem {
  const WardrobeItem({
    required this.id,
    required this.name,
    required this.category,
    required this.rarity,
    required this.price,
    required this.rewardedAdsRequired,
    required this.unlockText,
    required this.primary,
    required this.secondary,
    this.genderCompatibility = WardrobeGenderCompatibility.both,
    this.requiredSeason,
    this.requiredCompletedLevels,
    this.bundleItemIds = const <String>[],
  });

  final String id;
  final String name;
  final WardrobeCategory category;
  final WardrobeRarity rarity;
  final int price;
  final int rewardedAdsRequired;
  final String unlockText;
  final Color primary;
  final Color secondary;
  final WardrobeGenderCompatibility genderCompatibility;
  final int? requiredSeason;
  final int? requiredCompletedLevels;
  final List<String> bundleItemIds;

  bool get isFree =>
      price == 0 &&
      rewardedAdsRequired == 0 &&
      requiredSeason == null &&
      requiredCompletedLevels == null;

  bool supportsGender(CharacterGender gender) =>
      genderCompatibility == WardrobeGenderCompatibility.both ||
      (genderCompatibility == WardrobeGenderCompatibility.boy &&
          gender == CharacterGender.boy) ||
      (genderCompatibility == WardrobeGenderCompatibility.girl &&
          gender == CharacterGender.girl);
}

extension WardrobeCategoryLabel on WardrobeCategory {
  String get label {
    switch (this) {
      case WardrobeCategory.character:
        return 'Characters';
      case WardrobeCategory.hair:
        return 'Hair';
      case WardrobeCategory.hat:
        return 'Hats / Caps';
      case WardrobeCategory.glasses:
        return 'Glasses';
      case WardrobeCategory.tShirt:
        return 'T-Shirts';
      case WardrobeCategory.top:
        return 'Tops';
      case WardrobeCategory.dress:
        return 'Dresses';
      case WardrobeCategory.jacket:
        return 'Jackets';
      case WardrobeCategory.pants:
        return 'Pants';
      case WardrobeCategory.shoes:
        return 'Shoes';
      case WardrobeCategory.outfit:
        return 'Outfits';
      case WardrobeCategory.watch:
        return 'Watches';
      case WardrobeCategory.bag:
        return 'Bags';
      case WardrobeCategory.earrings:
        return 'Earrings';
      case WardrobeCategory.necklace:
        return 'Necklaces';
      case WardrobeCategory.bracelet:
        return 'Bracelets';
      case WardrobeCategory.trail:
        return 'Trails';
      case WardrobeCategory.effect:
        return 'Effects';
      case WardrobeCategory.bundle:
        return 'Bundles';
      case WardrobeCategory.roadTheme:
        return 'Road Themes';
    }
  }
}

extension WardrobeRarityVisuals on WardrobeRarity {
  String get label {
    switch (this) {
      case WardrobeRarity.common:
        return 'Common';
      case WardrobeRarity.rare:
        return 'Rare';
      case WardrobeRarity.epic:
        return 'Epic';
      case WardrobeRarity.legendary:
        return 'Legendary';
      case WardrobeRarity.mythic:
        return 'Mythic';
    }
  }

  Color get color {
    switch (this) {
      case WardrobeRarity.common:
        return const Color(0xFFB8C7D9);
      case WardrobeRarity.rare:
        return const Color(0xFF3DDCFF);
      case WardrobeRarity.epic:
        return const Color(0xFFB35CFF);
      case WardrobeRarity.legendary:
        return const Color(0xFFFFD05A);
      case WardrobeRarity.mythic:
        return const Color(0xFFFF4FD8);
    }
  }
}
