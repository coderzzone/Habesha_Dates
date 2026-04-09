import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;
    debugPrint('AdMob Initialized');
  }

  static String get bannerAdUnitId {
    if (kDebugMode) {
      // Official AdMob test unit IDs to avoid load failures in development.
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-7163477416722901/5440075308'; 
    } else if (Platform.isIOS) {
      return 'ca-app-pub-7163477416722901/5440075308'; 
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get rewardedAdUnitId {
    if (kDebugMode) {
      // Official AdMob test unit IDs to avoid load failures in development.
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-7163477416722901/8281861062'; 
    } else if (Platform.isIOS) {
      return 'ca-app-pub-7163477416722901/8281861062'; 
    }
    throw UnsupportedError('Unsupported platform');
  }

  void showRewardedAd({
    required Function(AdWithoutView ad, RewardItem reward) onUserEarnedReward,
    Function()? onAdFailedToLoad,
  }) {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
            },
          );
          ad.show(onUserEarnedReward: onUserEarnedReward);
        },
        onAdFailedToLoad: (error) {
          debugPrint(
            'RewardedAd failed to load: code=${error.code}, message=${error.message}, domain=${error.domain}',
          );
          if (onAdFailedToLoad != null) onAdFailedToLoad();
        },
      ),
    );
  }
}
