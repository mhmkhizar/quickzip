import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickzip/core/utils/show_custom_snackbar.dart';
import '../../../../core/services/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/network_util.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'dart:async';

class NoInternetScreen extends ConsumerStatefulWidget {
  const NoInternetScreen({super.key});

  @override
  ConsumerState<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends ConsumerState<NoInternetScreen>
    with SingleTickerProviderStateMixin {
  bool _isChecking = false;
  String _connectionType = 'Unknown';
  StreamSubscription? _connectivitySubscription;
  bool _isAnimationComplete = false;

  // Animation controller for slide animation
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Configure right-to-left slide animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Start from right
      end: Offset.zero, // End at center
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Add fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start the animation and set up completion listener
    _animationController.forward().then((_) {
      if (mounted) {
        setState(() {
          _isAnimationComplete = true;
        });
        // Only start monitoring connectivity after animation completes
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
        String message = 'No internet connection. ';
        if (_connectionType == 'WiFi' || _connectionType == 'Mobile Data') {
          message += '$_connectionType is ON but no internet access.';
        } else {
          message += 'Please check your network settings.';
        }

        showCustomSnackBar(context, message);
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/no_internet_icn.png',
                        // width: 80,
                        height: 80,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Uh-Oh!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No Internet Connection',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please check your internet connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.primaryWhite,
                        ),
                      ),
                      const SizedBox(height: 32),
                      OutlinedButton(
                        onPressed: _isChecking ? null : _checkConnection,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryGreen),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: _isChecking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryGreen,
                                  ),
                                ),
                              )
                            : const Text(
                                'Try Again',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primaryGreen,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
