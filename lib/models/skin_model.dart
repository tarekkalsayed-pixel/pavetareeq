import 'package:flutter/material.dart';

class RunnerSkin {
  const RunnerSkin({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.unlockText,
    required this.coinCost,
    this.requiredSeason,
  });

  final String id;
  final String name;
  final Color primary;
  final Color secondary;
  final String unlockText;
  final int coinCost;
  final int? requiredSeason;
}
