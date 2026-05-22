import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../data/wardrobe_catalog.dart';
import '../game/runner_painter.dart';
import '../services/progress_service.dart';
import '../services/wardrobe_service.dart';
import '../widgets/game_button.dart';
import '../widgets/pave_background.dart';
import 'home_screen.dart';

class CharacterSelectionScreen extends StatelessWidget {
  const CharacterSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaveBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const SizedBox(height: 18),
              Text(
                'Choose Your Runner',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'You can change this later from Wardrobe.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 26),
              _RunnerChoice(
                title: 'Boy Runner',
                characterId: 'default',
                gender: 'boy',
                colors: const [Color(0xFF3DDCFF), Color(0xFFFFD05A)],
              ),
              const SizedBox(height: 16),
              _RunnerChoice(
                title: 'Girl Runner',
                characterId: 'street_girl',
                gender: 'girl',
                colors: const [Color(0xFFFF7AC8), Color(0xFF7AF7FF)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunnerChoice extends StatelessWidget {
  const _RunnerChoice({
    required this.title,
    required this.characterId,
    required this.gender,
    required this.colors,
  });

  final String title;
  final String characterId;
  final String gender;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final current = WardrobeService.instance.loadout;
    final character = WardrobeCatalog.byId(characterId);
    final preview = WardrobeLoadout(
      character: character,
      hair: gender == 'girl'
          ? WardrobeCatalog.byId('long_hair')
          : WardrobeCatalog.byId('short_hair'),
      hat: current.hat,
      glasses: current.glasses,
      top: current.top,
      jacket: current.jacket,
      pants: current.pants,
      shoes: current.shoes,
      outfit: current.outfit,
      watch: current.watch,
      bag: current.bag,
      earrings: current.earrings,
      necklace: current.necklace,
      bracelet: current.bracelet,
      trail: current.trail,
      effect: current.effect,
      roadTheme: current.roadTheme,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.first.withValues(alpha: .38),
            colors.last.withValues(alpha: .18),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.last.withValues(alpha: .55)),
      ),
      child: Row(
        children: [
          AnimatedRunner(
            skin: GameData.skins.first,
            animationValue: .18,
            pose: RunnerPose.running,
            loadout: preview,
            size: 112,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                GameButton(
                  label: 'Select',
                  icon: Icons.check_rounded,
                  compact: true,
                  onPressed: () async {
                    await ProgressService.instance.chooseRunnerGender(gender);
                    await WardrobeService.instance.equip(character);
                    if (gender == 'girl') {
                      await WardrobeService.instance.equip(
                        WardrobeCatalog.byId('long_hair'),
                      );
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const HomeScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
