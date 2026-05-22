import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  // Google test ad unit IDs. Replace these with production IDs only for release.
  static const bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _isLoadingRewarded = false;
  bool _isLoadingInterstitial = false;
  int _finishedGamesThisSession = 0;
  DateTime? _lastInterstitialShownAt;

  bool get isRewardedReady => _rewardedAd != null;
  bool get isInterstitialReady => _interstitialAd != null;

  void initialize() {
    loadRewardedAd();
    loadInterstitialAd();
  }

  void loadRewardedAd() {
    if (_isLoadingRewarded || _rewardedAd != null) return;
    _isLoadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingRewarded = false;
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (_) {
          _isLoadingRewarded = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  void loadInterstitialAd() {
    if (_isLoadingInterstitial || _interstitialAd != null) return;
    _isLoadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingInterstitial = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (_) {
          _isLoadingInterstitial = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<void> recordGameFinishedAndMaybeShowInterstitial({
    required BuildContext context,
  }) async {
    _finishedGamesThisSession += 1;
    if (_finishedGamesThisSession <= 1) {
      loadInterstitialAd();
      return;
    }
    if (_finishedGamesThisSession % 3 != 0) {
      loadInterstitialAd();
      return;
    }
    final lastShown = _lastInterstitialShownAt;
    if (lastShown != null &&
        DateTime.now().difference(lastShown) < const Duration(minutes: 2)) {
      loadInterstitialAd();
      return;
    }
    await showInterstitialIfReady();
  }

  Future<void> showInterstitialIfReady() async {
    final ad = _interstitialAd;
    if (ad == null) {
      loadInterstitialAd();
      return;
    }

    _interstitialAd = null;
    _lastInterstitialShownAt = DateTime.now();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        loadInterstitialAd();
      },
    );
    await ad.show();
  }

  Future<void> showRewardedAd({
    required BuildContext context,
    required VoidCallback onRewardEarned,
    VoidCallback? onUnavailable,
    VoidCallback? onClosed,
  }) async {
    final ad = _rewardedAd;
    if (ad == null) {
      loadRewardedAd();
      onUnavailable?.call();
      return;
    }

    _rewardedAd = null;
    var earnedReward = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd();
        onClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        loadRewardedAd();
        if (!earnedReward) onUnavailable?.call();
      },
    );
    await ad.show(
      onUserEarnedReward: (ad, reward) {
        earnedReward = true;
        onRewardEarned();
      },
    );
  }

  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd = null;
    _interstitialAd = null;
  }
}

class AdService {
  static AdsService get instance => AdsService.instance;
}

class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  void loadRewardedAd() => AdsService.instance.loadRewardedAd();

  Future<void> showRewardedAd({
    required BuildContext context,
    required VoidCallback onReward,
    VoidCallback? onUnavailable,
  }) {
    return AdsService.instance.showRewardedAd(
      context: context,
      onRewardEarned: onReward,
      onUnavailable:
          onUnavailable ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ad not ready yet, try again later.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
    );
  }
}
