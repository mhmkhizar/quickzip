import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdsManager extends ChangeNotifier {
  // App Open Ad
  // AppOpenAd? _appOpenAd;
  // final bool _isAppOpenAdLoaded = false;
  // final bool _isShowingAd = false;

  // Banner Ad
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  //Inline adaptive banner ad
  static const double _insets = 16.0;
  BannerAd? _inlineAdaptiveAd;
  bool _isLoaded = false;
  AdSize? _adSize;
  Orientation? _currentOrientation;
  // Native Ad
  // NativeAd? _nativeAd;
  // bool _isNativeAdLoaded = false;

  // Rewarded Ad
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  // Interstitial Ad
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;

  // Test ad unit IDs - Replace with your actual ad unit IDs in production
  // final String appOpenAdUnitId = Platform.isAndroid
  //     ? 'ca-app-pub-3940256099942544/9257395921'
  //     : 'ca-app-pub-3940256099942544/5575463023';

  final String bannerAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // Test ID for Android
      : 'ca-app-pub-3940256099942544/2934735716'; // Test ID for iOS

  // final String nativeAdUnitId = Platform.isAndroid
  //     ? 'ca-app-pub-3940256099942544/2247696110'
  //     : 'ca-app-pub-3940256099942544/3986624511';

  // Ad unit IDs
  final String rewardedAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';

  // Interstitial Ad unit ID
  final String interstitialAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  //Inline adaptive ad ID
  final String inlineAdaptiveUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/9214589741' // Android test ad unit ID
      : 'ca-app-pub-3940256099942544/4411468910'; // iOS test ad unit ID

  // Getters
  // bool get isAppOpenAdLoaded => _isAppOpenAdLoaded;
  // bool get isShowingAd => _isShowingAd;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  // bool get isNativeAdLoaded => _isNativeAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  BannerAd? get bannerAd => _bannerAd;
  // NativeAd? get nativeAd => _nativeAd;
  RewardedAd? get rewardedAd => _rewardedAd;
  // InterstitialAd? get interstitialAd => _interstitialAd;
  BannerAd? get inlineAdaptiveAd => _inlineAdaptiveAd;
  bool get isLoaded => _isLoaded;
  AdSize? get adSize => _adSize;

  // Load App Open Ad
  // Future<void> loadAppOpenAd() async {
  //   if (_isAppOpenAdLoaded || _isShowingAd) {
  //     debugPrint('An ad is already loaded or showing.');
  //     return;
  //   }

  //   try {
  //     await AppOpenAd.load(
  //       adUnitId: appOpenAdUnitId,
  //       request: const AdRequest(),
  //       adLoadCallback: AppOpenAdLoadCallback(
  //         onAdLoaded: _onAdLoaded,
  //         onAdFailedToLoad: _onAdFailedToLoad,
  //       ),
  //       orientation: AppOpenAd.orientationPortrait,
  //     );
  //   } catch (e) {
  //     debugPrint('Error loading AppOpenAd: $e');
  //     _handleAdFailure();
  //   }
  // }

  // void _onAdLoaded(AppOpenAd ad) {
  //   debugPrint('AppOpenAd loaded successfully');
  //   _appOpenAd = ad;
  //   _isAppOpenAdLoaded = true;
  //   _setupFullScreenContentCallback();
  //   notifyListeners();
  // }

  // void _onAdFailedToLoad(LoadAdError error) {
  //   debugPrint('AppOpenAd failed to load: ${error.message}');
  //   _handleAdFailure();
  // }

  // void _setupFullScreenContentCallback() {
  //   if (_appOpenAd == null) return;

  //   _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
  //     onAdShowedFullScreenContent: (ad) {
  //       _isShowingAd = true;
  //       debugPrint('AppOpenAd showed full screen content');
  //       notifyListeners();
  //     },
  //     onAdFailedToShowFullScreenContent: (ad, error) {
  //       debugPrint('AppOpenAd failed to show: ${error.message}');
  //       _isShowingAd = false;
  //       _disposeAd();
  //       loadAppOpenAd(); // Retry loading on failure
  //     },
  //     onAdDismissedFullScreenContent: (ad) {
  //       debugPrint('AppOpenAd was dismissed');
  //       _isShowingAd = false;
  //       _disposeAd();
  //       loadAppOpenAd(); // Reload ad after dismissal
  //     },
  //     onAdClicked: (ad) {
  //       debugPrint('AppOpenAd was clicked');
  //     },
  //     onAdImpression: (ad) {
  //       debugPrint('AppOpenAd impression recorded');
  //     },
  //   );
  // }

  // // Show App Open Ad
  // Future<bool> showAppOpenAd() async {
  //   if (!_isAppOpenAdLoaded || _appOpenAd == null) {
  //     debugPrint('Attempted to show ad before loading');
  //     return false;
  //   }

  //   if (_isShowingAd) {
  //     debugPrint('Ad is already showing');
  //     return false;
  //   }

  //   try {
  //     await _appOpenAd!.show();
  //     return true;
  //   } catch (e) {
  //     debugPrint('Error showing AppOpenAd: $e');
  //     _handleAdFailure();
  //     return false;
  //   }
  // }

  // Load Banner Ad
  Future<void> loadBannerAd(BuildContext context) async {
    if (_isBannerAdLoaded) {
      debugPrint('Banner Ad is already loaded.');
      return;
    }

    try {
      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
              MediaQuery.of(context).size.width.truncate());

      _bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        request: const AdRequest(),
        size: size!,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('BannerAd loaded successfully');
            _isBannerAdLoaded = true;
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('BannerAd failed to load: ${error.message}');
            _isBannerAdLoaded = false;
            ad.dispose();
            notifyListeners();
          },
          onAdOpened: (ad) {
            debugPrint('BannerAd opened');
          },
          onAdClosed: (ad) {
            debugPrint('BannerAd closed');
          },
          onAdImpression: (ad) {
            debugPrint('BannerAd impression recorded');
          },
        ),
      )..load();
    } catch (e) {
      debugPrint('Error loading BannerAd: $e');
      _isBannerAdLoaded = false;
      notifyListeners();
    }
  }

  // Get Banner Ad Widget
  Widget getBannerAdWidget() {
    if (_bannerAd == null || !_isBannerAdLoaded) {
      return const SizedBox
          .shrink(); // Return an empty widget if no ad is loaded
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }

  //Inline adaptive banner ad
  double getAdWidth(BuildContext context) {
    return MediaQuery.of(context).size.width - (2 * _insets);
  }

  Future<void> loadAd(BuildContext context) async {
    final newOrientation = MediaQuery.of(context).orientation;

    // Return if orientation hasn't changed and ad is already loaded
    if (_currentOrientation == newOrientation && _isLoaded) return;

    _currentOrientation = newOrientation;

    await _inlineAdaptiveAd?.dispose();
    _inlineAdaptiveAd = null;
    _isLoaded = false;
    notifyListeners();

    // ignore: use_build_context_synchronously
    final adWidth = getAdWidth(context);
    final size = AdSize.getCurrentOrientationInlineAdaptiveBannerAdSize(
      adWidth.truncate(),
    );

    _inlineAdaptiveAd = BannerAd(
      adUnitId: inlineAdaptiveUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) async {
          debugPrint('Inline adaptive banner loaded: ${ad.responseInfo}');

          final bannerAd = ad as BannerAd;
          final AdSize? platformAdSize = await bannerAd.getPlatformAdSize();
          if (platformAdSize == null) {
            debugPrint(
                'Error: getPlatformAdSize() returned null for $bannerAd');
            return;
          }

          _inlineAdaptiveAd = bannerAd;
          _isLoaded = true;
          _adSize = platformAdSize;
          notifyListeners();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('Inline adaptive banner failed to load: $error');
          ad.dispose();
          _isLoaded = false;
          notifyListeners();
        },
      ),
    );

    await _inlineAdaptiveAd!.load();
  }

  Widget getAdWidget(BuildContext context) {
    if (_isLoaded && _inlineAdaptiveAd != null && _adSize != null) {
      return Container(
        width: getAdWidth(context),
        height: _adSize!.height.toDouble(),
        alignment: Alignment.center,
        child: AdWidget(ad: _inlineAdaptiveAd!),
      );
    }
    return const SizedBox.shrink();
  }

  // Load Native Ad
  // Future<void> loadNativeAd() async {
  //   if (_isNativeAdLoaded) {
  //     debugPrint('Native Ad is already loaded.');
  //     return;
  //   }

  //   try {
  //     _nativeAd = NativeAd(
  //       adUnitId: nativeAdUnitId,
  //       listener: NativeAdListener(
  //         onAdLoaded: (ad) {
  //           debugPrint('Native Ad loaded successfully');
  //           _isNativeAdLoaded = true;
  //           notifyListeners();
  //         },
  //         onAdFailedToLoad: (ad, error) {
  //           debugPrint('Native Ad failed to load: ${error.message}');
  //           ad.dispose();
  //           _isNativeAdLoaded = false;
  //           notifyListeners();
  //         },
  //       ),
  //       request: const AdRequest(),
  //       nativeTemplateStyle: NativeTemplateStyle(
  //         templateType: TemplateType.medium,
  //         mainBackgroundColor: Colors.black,
  //         cornerRadius: 10.0,
  //         callToActionTextStyle: NativeTemplateTextStyle(
  //           textColor: Colors.white,
  //           backgroundColor: Colors.green,
  //           style: NativeTemplateFontStyle.monospace,
  //           size: 16.0,
  //         ),
  //         primaryTextStyle: NativeTemplateTextStyle(
  //           textColor: Colors.white,
  //           backgroundColor: Colors.transparent,
  //           style: NativeTemplateFontStyle.bold,
  //           size: 18.0,
  //         ),
  //         secondaryTextStyle: NativeTemplateTextStyle(
  //           textColor: Colors.grey,
  //           backgroundColor: Colors.transparent,
  //           style: NativeTemplateFontStyle.normal,
  //           size: 14.0,
  //         ),
  //       ),
  //     )..load();
  //   } catch (e) {
  //     debugPrint('Error loading Native Ad: $e');
  //     _isNativeAdLoaded = false;
  //     notifyListeners();
  //   }
  // }

  // Get Native Ad Widget
  // Widget getNativeAdWidget() {
  //   if (_isNativeAdLoaded && _nativeAd != null) {
  //     return Container(
  //       constraints: const BoxConstraints(
  //         minWidth: 320,
  //         minHeight: 320,
  //         maxWidth: 400,
  //         maxHeight: 400,
  //       ),
  //       decoration: BoxDecoration(
  //         color: const Color(0xff1d1d1d),
  //         borderRadius: BorderRadius.circular(10),
  //       ),
  //       child: AdWidget(ad: _nativeAd!),
  //     );
  //   }
  //   return const SizedBox.shrink();
  // }

  // Load Rewarded Ad
  Future<void> loadRewardedAd() async {
    if (_isRewardedAdLoaded) {
      debugPrint('Rewarded Ad is already loaded.');
      return;
    }

    try {
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Rewarded Ad loaded successfully');
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
            _setupRewardedAdCallback(ad);
            notifyListeners();
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded Ad failed to load: ${error.message}');
            _isRewardedAdLoaded = false;
            notifyListeners();
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading Rewarded Ad: $e');
      _isRewardedAdLoaded = false;
      notifyListeners();
    }
  }

  void _setupRewardedAdCallback(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Rewarded Ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Rewarded Ad was dismissed');
        ad.dispose();
        _isRewardedAdLoaded = false;
        loadRewardedAd(); // Reload for next use
        notifyListeners();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded Ad failed to show: ${error.message}');
        ad.dispose();
        _isRewardedAdLoaded = false;
        loadRewardedAd(); // Try to reload
        notifyListeners();
      },
      onAdImpression: (ad) {
        debugPrint('Rewarded Ad impression recorded');
      },
    );
  }

  // Show Rewarded Ad
  Future<bool> showRewardedAd({required Function onRewardEarned}) async {
    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      debugPrint('Rewarded Ad not ready to show');
      return false;
    }

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          onRewardEarned();
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error showing Rewarded Ad: $e');
      return false;
    }
  }

  // Load Interstitial Ad
  Future<void> loadInterstitialAd() async {
    if (_isInterstitialAdLoaded) {
      debugPrint('Interstitial ad already loaded.');
      return;
    }

    debugPrint('Starting to load interstitial ad...');
    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('👍 Interstitial Ad loaded successfully');
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
            _setupInterstitialAdCallback(ad);
            notifyListeners();
          },
          onAdFailedToLoad: (error) {
            debugPrint('❌ Interstitial Ad failed to load: ${error.message}');
            _isInterstitialAdLoaded = false;
            _interstitialAd = null;
            notifyListeners();
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ Error loading Interstitial Ad: $e');
      _isInterstitialAdLoaded = false;
      _interstitialAd = null;
      notifyListeners();
    }
  }

  // Setup Interstitial Ad callbacks
  void _setupInterstitialAdCallback(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Interstitial Ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Interstitial Ad was dismissed');
        ad.dispose();
        _isInterstitialAdLoaded = false;
        loadInterstitialAd(); // Reload for next use
        notifyListeners();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial Ad failed to show: ${error.message}');
        ad.dispose();
        _isInterstitialAdLoaded = false;
        loadInterstitialAd(); // Try to reload
        notifyListeners();
      },
      onAdImpression: (ad) {
        debugPrint('Interstitial Ad impression recorded');
      },
      onAdClicked: (ad) {
        debugPrint('Interstitial Ad clicked');
      },
    );
  }

  // Show Interstitial Ad
  Future<bool> showInterstitialAd() async {
    if (!_isInterstitialAdLoaded || _interstitialAd == null) {
      debugPrint('❌ Interstitial Ad not ready to show');
      return false;
    }

    debugPrint('Attempting to show interstitial ad...');
    try {
      await _interstitialAd!.show();
      debugPrint('👍 Interstitial Ad shown successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error showing Interstitial Ad: $e');
      return false;
    }
  }

  // Handle Ad Failure
  // void _handleAdFailure() {
  //   _isAppOpenAdLoaded = false;
  //   _isShowingAd = false;
  //   _disposeAd();
  //   notifyListeners();
  // }

  // Dispose Banner Ad
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
    notifyListeners();
  }

  // Dispose Interstitial Ad
  void disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdLoaded = false;
    notifyListeners();
  }

  // Dispose Ad
  // void _disposeAd() {
  //   try {
  //     _appOpenAd?.dispose();
  //   } catch (e) {
  //     debugPrint('Error disposing AppOpenAd: $e');
  //   } finally {
  //     _appOpenAd = null;
  //     _isAppOpenAdLoaded = false;
  //     _isShowingAd = false;
  //     notifyListeners();
  //   }
  // }

  // Clean up resources
  @override
  void dispose() {
    // _disposeAd();
    _bannerAd?.dispose();
    // _nativeAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _inlineAdaptiveAd?.dispose();
    super.dispose();
  }
}

// Provider definition with auto-dispose
final adsManagerProvider = ChangeNotifierProvider.autoDispose<AdsManager>(
  (ref) {
    return AdsManager();
  },
);
