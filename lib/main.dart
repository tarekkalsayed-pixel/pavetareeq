import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  AdsService.instance.initialize();
  runApp(const PaveTareeqApp());
}

class PaveTareeqApp extends StatelessWidget {
  const PaveTareeqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PaveTareeq',
      debugShowCheckedModeBanner: false,
      theme: buildPaveTheme(),
      home: const SplashScreen(),
    );
  }
}
