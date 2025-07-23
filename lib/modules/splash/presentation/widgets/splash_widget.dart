import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../../core/services/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/network_util.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../screens/no_internet_screen.dart';

class SplashContainer extends ConsumerStatefulWidget {
  const SplashContainer({super.key});

  @override
  ConsumerState<SplashContainer> createState() => SplashContainerState();
}

class SplashContainerState extends ConsumerState<SplashContainer> {
  bool _isChecking = false;
  String _connectionType = 'Unknown';
  StreamSubscription? _connectivitySubscription;
  bool _isAnimationComplete = false;

  @override
  void initState() {
    super.initState();
    // Add a delay to show splash screen for at least 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isAnimationComplete = true;
        });
        _monitorConnectivity();
      }
    });
    _updateConnectionType();
  }

  Future<void> _updateConnectionType() async {
    final type = await NetworkUtil.getConnectionType();
    if (mounted) {
      setState(() => _connectionType = type);
    }
  }

  void _monitorConnectivity() {
    if (!_isAnimationComplete) return;

    // Initial check with delay to ensure animation is complete
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _checkConnection();
      }
    });

    // Monitor for changes
    _connectivitySubscription =
        NetworkUtil.onConnectivityChanged().listen((hasInternet) async {
      if (!_isAnimationComplete || !mounted) return;

      await _updateConnectionType();

      if (hasInternet && mounted) {
        // Add a small delay before navigation to ensure smooth transition
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          AppRoutes.pushReplacement(const HomeScreen());
        }
      }
    });
  }

  Future<void> _checkConnection() async {
    if (_isChecking || !_isAnimationComplete) return;

    setState(() => _isChecking = true);

    try {
      await _updateConnectionType();
      final hasInternet = await NetworkUtil.checkInternetConnection();

      if (!mounted) return;

      if (hasInternet) {
        // Add a small delay before navigation to ensure smooth transition
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          AppRoutes.pushReplacement(const HomeScreen());
        }
      } else {
        if (mounted) {
          AppRoutes.pushReplacement(const NoInternetScreen());
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/logo/QuickZip.png',
            height: 120,
            width: 120,
          ),
          // const SizedBox(height: 24),
          // if (_isChecking)
          //   const CircularProgressIndicator(
          //     valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          //   ),
        ],
      ),
    );
  }
}
