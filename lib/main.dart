import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quickzip/modules/home/presentation/screens/home_screen.dart';
import 'core/services/ads_manager.dart';
import 'core/services/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/network_util.dart';
import 'core/utils/show_custom_snackbar.dart';
import 'modules/splash/presentation/screens/no_internet_screen.dart';
import 'modules/home/presentation/provider/extracted_screen_provider.dart';
import 'modules/home/presentation/provider/page_index_provider.dart';
import 'modules/home/presentation/provider/page_controller_provider.dart';

void main() async { 
  WidgetsFlutterBinding.ensureInitialized();

  // Lock screen orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Future.delayed(const Duration(milliseconds: 500));
  // Add a small delay before checking internet connectivity
  // await Future.delayed(const Duration(milliseconds: 500));

  // Check internet connectivity before launching the app
  final hasInternet = await NetworkUtil.checkInternetConnection();

  // Initialize Mobile Ads SDK
  await MobileAds.instance.initialize();

  runApp(
    ProviderScope(
      child: MyApp(hasInternet: hasInternet),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  final bool hasInternet;

  const MyApp({super.key, required this.hasInternet});
  // final bool hasInternet;

  // const MyApp({super.key, required this.hasInternet});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  DateTime? _lastBackPressTime;
  bool _isInitialized = false;
  bool? _hasInternet;

  _checkInternetConnection() async {
    _hasInternet = await NetworkUtil.checkInternetConnection();
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      // ✅ Check real internet before proceeding
      _hasInternet = await NetworkUtil.checkInternetConnection();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // ✅ Load banner ad only if internet is present
        if (_hasInternet == true) {
          ref.read(adsManagerProvider).loadBannerAd(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final adsManager = ref.watch(adsManagerProvider);

    return Platform.isIOS
        ? CupertinoApp(
            title: 'QuickZip',
            theme: AppTheme.cupertinoDarkTheme,
            home: WillPopScope(
              onWillPop: _onWillPop,
              child: Scaffold(
                body: Column(
                  children: [
                    Expanded(
                      child: Navigator(
                        key: AppRoutes.navKey,
                        onGenerateRoute: (settings) {
                          return CupertinoPageRoute(
                            builder: (context) => widget.hasInternet
                                ? const HomeScreen()
                                : const NoInternetScreen(),
                          );
                        },
                      ),
                    ),
                    adsManager.getBannerAdWidget(),
                  ],
                ),
              ),
            ),
            debugShowCheckedModeBanner: false,
          )
        : MaterialApp(
            title: 'QuickZip',
            theme: AppTheme.materialDarkTheme,
            home: WillPopScope(
              onWillPop: _onWillPop,
              child: Scaffold(
                body: Column(
                  children: [
                    Expanded(
                      child: Navigator(
                        key: AppRoutes.navKey,
                        onGenerateRoute: (settings) {
                          return MaterialPageRoute(
                            builder: (context) => widget.hasInternet
                                ? const HomeScreen()
                                : const NoInternetScreen(),
                          );
                        },
                      ),
                    ),
                    adsManager.getBannerAdWidget(),
                    // _hasInternet == true
                    //     ? adsManager.getBannerAdWidget()
                    //     : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
            debugShowCheckedModeBanner: false,
          );
  }

  // _decideRoute() {
  //   if (_hasInternet == null) {
  //     return const SplashContainer();
  //   }
  //   if (_hasInternet == true) {
  //     return const HomeScreen();
  //   } else {
  //     return const NoInternetScreen();
  //   }
  // }

  Future<bool> _onWillPop() async {
    // First check if we can pop the current route
    if (AppRoutes.navKey.currentState != null &&
        AppRoutes.navKey.currentState!.canPop()) {
      AppRoutes.navKey.currentState!.pop();
      return false;
    }

    // If we're in an extracted folder, handle the back navigation
    final extractedScreen = ref.read(extractedScreenProvider);
    if (extractedScreen.currentFolder != null) {
      // Get the parent folder path
      final currentPath = extractedScreen.currentFolder!.path;
      final parentPath = Directory(currentPath).parent.path;

      // Check if we're going back to root
      if (parentPath == '/storage/emulated/0/QuickZip Extracted Files') {
        ref.read(extractedScreenProvider.notifier).navigateBack();
      } else {
        // Navigate to parent folder
        ref
            .read(extractedScreenProvider.notifier)
            .navigateToFolder(Directory(parentPath));
      }
      ref.read(pageIndexProvider.notifier).state = 1;
      return false;
    }

    // If we're not in a folder, handle normal tab navigation
    final currentIndex = ref.read(pageIndexProvider);
    if (currentIndex != 0) {
      ref.read(pageIndexProvider.notifier).state = 0;

      // Animate to the compressed tab
      try {
        final pageController = ref.read(pageControllerProvider);
        pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } catch (e) {
        debugPrint('Error accessing page controller: $e');
      }

      return false;
    }

    // If we're at the root route, implement double-tap to exit
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      showCustomSnackBar(AppRoutes.context, 'Press back again to exit');
      return false;
    }
    return true;
  }
}


// class SplashScreenWrapper extends ConsumerStatefulWidget {
//   const SplashScreenWrapper({super.key});

//   @override
//   SplashScreenWrapperState createState() => SplashScreenWrapperState();
// }

// class SplashScreenWrapperState extends ConsumerState<SplashScreenWrapper> {
//   late final AdsManager _adManager;
//   bool _hasNavigated = false;

//   @override
//   void initState() {
//     super.initState();
//     _adManager = ref.read(adsManagerProvider);

//     debugPrint("Ad Loading Status: ${_adManager.isAppOpenAdLoaded}");

//     if (_adManager.isAppOpenAdLoaded) {
//       debugPrint("Ad already loaded, proceeding...");
//       _proceedWithNavigation();
//     } else {
//       _adManager.addListener(_onAdStateChanged);
//       _adManager.loadAppOpenAd();
//       _startTimeout(); // Ensure it doesn't get stuck indefinitely
//     }
//   }

//   void _onAdStateChanged() {
//     debugPrint("Ad State Changed: Loaded - ${_adManager.isAppOpenAdLoaded}");
//     if (_adManager.isAppOpenAdLoaded && !_hasNavigated) {
//       _proceedWithNavigation();
//     }
//   }

//   void _startTimeout() {
//     Future.delayed(const Duration(seconds: 5), () {
//       if (!_hasNavigated) {
//         debugPrint("Ad not loaded in time, navigating to splash screen...");
//         _proceedWithNavigation();
//       }
//     });
//   }

//   Future<void> _proceedWithNavigation() async {
//     if (_hasNavigated || !mounted) return;

//     _hasNavigated = true;
//     _adManager.removeListener(_onAdStateChanged);

//     if (_adManager.isAppOpenAdLoaded) {
//       try {
//         debugPrint("Showing App Open Ad...");
//         await _adManager.showAppOpenAd();
//         await Future.delayed(const Duration(milliseconds: 300));
//       } catch (e) {
//         debugPrint("Error showing App Open Ad: $e");
//       }
//     }

//     if (mounted) {
//       debugPrint("Navigating to Splash Screen...");
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const SplashScreen()),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _adManager.removeListener(_onAdStateChanged);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: Center(
//         child: Platform.isIOS
//             ? const CupertinoActivityIndicator()
//             : const CircularProgressIndicator(),
//       ),
//     );
//   }
// }