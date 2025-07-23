// ignore_for_file: unused_result, deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../../core/services/ads_manager.dart';
import '../../../../core/services/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/password_generator.dart';
import '../../../../core/utils/show_custom_snackbar.dart';
import '../provider/file_provider.dart';
import '../provider/extracted_folder_navigation_provider.dart';

class ExtractionScreen extends ConsumerStatefulWidget {
  final String fileName;
  final ValueNotifier<double> progressNotifier;
  final Completer<void> extractionCompleter;

  const ExtractionScreen({
    super.key,
    required this.fileName,
    required this.progressNotifier,
    required this.extractionCompleter,
  });

  @override
  ConsumerState<ExtractionScreen> createState() => _ExtractionScreenState();
}

class _ExtractionScreenState extends ConsumerState<ExtractionScreen> {
  bool _hasCompleted = false;
  bool _isVerifyingFiles = false;
  int _totalFiles = 0;
  int _processedFiles = 0;

  // Dedicated banner ad for this screen only
  BannerAd? _extractionBannerAd;
  bool _isExtractionBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    // Initialize progress to 0
    widget.progressNotifier.value = 0.0;

    // Load other ads
    Future.microtask(() {
      if (mounted) {
        final adsManager = ref.read(adsManagerProvider);

        // Dispose any existing interstitial ad first to start clean
        adsManager.disposeInterstitialAd();

        // Load inline adaptive ad for the main content area
        adsManager.loadAd(context);

        // Load the interstitial ad early so it's ready at the end
        // But we'll only show it after extraction completes
        if (PasswordGenerator.isTomitoFile(widget.fileName)) {
          adsManager.loadInterstitialAd();
        }

        // Load our own dedicated banner ad for this screen
        _loadExtractionBannerAd();
      }
    });

    widget.progressNotifier.addListener(_onProgressChanged);
  }

  // Load a dedicated banner ad for this screen only
  void _loadExtractionBannerAd() async {
    if (!mounted) return;

    try {
      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
              MediaQuery.of(context).size.width.truncate());

      // Use the same ad unit ID as in AdsManager but create a new instance
      final adUnitId = Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // Test ID for Android
          : 'ca-app-pub-3940256099942544/2934735716'; // Test ID for iOS

      _extractionBannerAd = BannerAd(
        adUnitId: adUnitId,
        request: const AdRequest(),
        size: size!,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('Extraction BannerAd loaded successfully');
            if (mounted) {
              setState(() {
                _isExtractionBannerAdLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Extraction BannerAd failed to load: ${error.message}');
            ad.dispose();
            _extractionBannerAd = null;
            if (mounted) {
              setState(() {
                _isExtractionBannerAdLoaded = false;
              });
            }
          },
        ),
      );

      await _extractionBannerAd?.load();
    } catch (e) {
      debugPrint('Error loading Extraction BannerAd: $e');
    }
  }

  // Get banner ad widget for extraction screen
  Widget _getExtractionBannerAdWidget() {
    if (_extractionBannerAd == null || !_isExtractionBannerAdLoaded) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _extractionBannerAd!.size.width.toDouble(),
      height: _extractionBannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _extractionBannerAd!),
    );
  }

  // Dispose extraction banner ad
  void _disposeExtractionBannerAd() {
    _extractionBannerAd?.dispose();
    _extractionBannerAd = null;
    if (mounted) {
      setState(() {
        _isExtractionBannerAdLoaded = false;
      });
    }
  }

  void updateExtractionProgress(Map<String, dynamic> progressData) {
    if (!mounted) return;

    setState(() {
      _totalFiles = progressData['totalFiles'] ?? 0;
      _processedFiles = progressData['processedFiles'] ?? 0;
    });
  }

  void _onProgressChanged() async {
    final currentProgress = widget.progressNotifier.value;

    // Only proceed when extraction is actually complete (100%)
    if (currentProgress >= 1.0 && !_hasCompleted && !_isVerifyingFiles) {
      _isVerifyingFiles = true;

      // Add a small delay to ensure extraction is fully complete
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Complete the extraction
        if (!widget.extractionCompleter.isCompleted) {
          widget.extractionCompleter.complete();
        }

        // Get the extracted folder path
        final extractedPath =
            '/storage/emulated/0/QuickZip Extracted Files/${widget.fileName.replaceAll('.zip', '')}';

        // Only proceed with success if progress is still 100%
        if (widget.progressNotifier.value >= 1.0) {
          _hasCompleted = true;

          // Dispose our dedicated extraction banner ad
          _disposeExtractionBannerAd();

          // Show success message
          showCustomSnackBar(context, 'File extracted successfully');

          // Navigate to extracted folder and open it
          ref.read(extractedFolderNavigationProvider.notifier).state =
              extractedPath;
          ref.refresh(extractedFilesProvider);

          // Now handle interstitial ad for Tomito+ files (at the very end)
          if (PasswordGenerator.isTomitoFile(widget.fileName)) {
            final adsManager = ref.read(adsManagerProvider);

            debugPrint(
                'Preparing to show interstitial ad at end of extraction');

            // In case the ad wasn't loaded or failed to load, try again
            if (!adsManager.isInterstitialAdLoaded) {
              debugPrint('Interstitial ad not loaded, loading now...');
              await adsManager.loadInterstitialAd();
              // Give it time to load
              await Future.delayed(const Duration(milliseconds: 1500));
            } else {
              debugPrint('Interstitial ad already loaded and ready to show');
            }

            if (adsManager.isInterstitialAdLoaded && mounted) {
              debugPrint('Showing interstitial ad at end of extraction');
              // Make sure to show it before popping the screen
              await adsManager.showInterstitialAd();
              // Add a small delay after showing the ad
              await Future.delayed(const Duration(milliseconds: 500));
              debugPrint('Interstitial ad shown successfully');
            } else {
              debugPrint(
                  'Interstitial ad not ready to show at end of extraction');
            }
          }

          // Reload the standard banner ad for the home screen
          Future.delayed(const Duration(milliseconds: 300), () {
            if (AppRoutes.context.mounted) {
              ref.read(adsManagerProvider).loadBannerAd(AppRoutes.context);
            }
          });

          // Pop the extraction screen AFTER showing the ad
          debugPrint(
              'Extraction complete, navigating away from extraction screen');
          Navigator.of(context).pop();
        }
      }
      _isVerifyingFiles = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final adsManager = ref.watch(adsManagerProvider);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Processing',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryWhite,
            ),
          ),
          backgroundColor: AppTheme.darkBackground,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(color: AppTheme.primaryWhite),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder<double>(
                      valueListenable: widget.progressNotifier,
                      builder: (context, progress, _) {
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Extracting: ${widget.fileName.length > 29 ? '${widget.fileName.substring(0, 29)}...' : widget.fileName}',
                                  style: const TextStyle(
                                      color: AppTheme.primaryWhite,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryWhite),
                                ),
                              ],
                            ),
                            if (_totalFiles > 0) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Files: $_processedFiles/$_totalFiles',
                                style: const TextStyle(
                                  color: AppTheme.primaryGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(4),
                              ),
                              value: progress,
                              backgroundColor: AppTheme.primaryGrey,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryGreen),
                              minHeight: 5,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 25),
                    Center(
                      child: Container(
                        width: 50,
                        height: 2,
                        color: AppTheme.primaryGrey,
                      ),
                    ),
                    const SizedBox(height: 25),
                    // Inline adaptive ad in the main content area
                    adsManager.getAdWidget(context),
                  ],
                ),
              ),
            ),
            // Show our dedicated extraction banner ad
            _getExtractionBannerAdWidget(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose our dedicated banner ad
    _disposeExtractionBannerAd();

    // Also dispose the interstitial ad to prevent it from showing in subsequent extractions
    final adsManager = ref.read(adsManagerProvider);
    adsManager.disposeInterstitialAd();

    widget.progressNotifier.removeListener(_onProgressChanged);
    super.dispose();
  }
}
