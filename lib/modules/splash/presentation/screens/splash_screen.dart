import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../widgets/splash_widget.dart';
import 'no_internet_screen.dart';
import '../../../../core/utils/network_util.dart';
import '../../../../core/services/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Show splash screen for minimum duration while checking connectivity
      final results = await Future.wait([
        Future.delayed(const Duration(seconds: 2)),
        NetworkUtil.checkInternetConnection(),
      ]);

      if (!mounted) return;

      // Get the internet check result (second item in results list)
      final hasInternet = results[1] as bool;

      if (kDebugMode) {
        print('Internet connectivity check result: $hasInternet');
      }

      // Navigate based on connectivity result
      if (hasInternet) {
        AppRoutes.pushReplacement(const HomeScreen());
      } else {
        AppRoutes.pushReplacement(const NoInternetScreen());
      }
    } catch (e) {
      debugPrint('Error during initialization: $e');
      if (mounted) {
        AppRoutes.pushReplacement(const NoInternetScreen());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? const CupertinoPageScaffold(
            backgroundColor: AppTheme.darkBackground,
            child: SplashContainer(),
          )
        : const Scaffold(
            backgroundColor: AppTheme.darkBackground,
            body: SplashContainer(),
          );
  }
}
