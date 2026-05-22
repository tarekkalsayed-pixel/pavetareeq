# PaveTareeq

PaveTareeq - Build the Run is a Flutter arcade runner game where the player does not directly move the runner. Instead, the player protects the runner by fixing the road ahead before the runner reaches danger tiles.

## Game Idea

The runner automatically moves forward on a fast arcade road. The player's job is to tap broken, locked, falling, moving, or warning tiles at the right time so the road becomes safe before impact. Good timing earns better rewards, while wrong taps or missed danger tiles can end the run.

The game includes themed seasons, handcrafted difficulty progression, coins, skins, wardrobe items, music, sound effects, daily missions, rewarded ads, and an endless mode.

## Features

- Level-based road-building runner gameplay
- Endless mode
- Five themed seasons:
  - Toy City
  - Candy Sky
  - Desert Rush
  - Neon Night
  - Space Road
- Boss-style final levels
- Coins, unlockable skins, wardrobe items, and road themes
- Perfect saves, last-second saves, star ratings, and score breakdowns
- Daily rewards and daily mission tracking
- Background music and sound effects
- Google Mobile Ads integration
- Local progress saving with shared preferences

## Languages Used

- Dart: main Flutter application, game logic, UI, services, models, and painters
- Kotlin: Android host activity
- Java: generated Flutter plugin registrant for Android
- XML: Android manifests, launch backgrounds, and style resources
- Gradle / Kotlin DSL: Android build configuration
- YAML: Flutter package configuration, assets, and analyzer options

## Tech Stack

- Flutter
- Dart
- Android
- shared_preferences
- google_mobile_ads
- audioplayers
- flutter_lints

## Project Structure

```text
lib/
  data/       Game data, seasons, wardrobe catalog
  game/       Arcade game view, road painting, runner painting, particles
  models/     Game, scoring, season, skin, tile, and wardrobe models
  screens/    Splash, home, gameplay, selection, result, and wardrobe screens
  services/   Ads, audio, progress, scoring, daily, and wardrobe services
  widgets/    Shared UI widgets
```

## Run Locally

```bash
flutter pub get
flutter run
```

## Tests

```bash
flutter test
```
