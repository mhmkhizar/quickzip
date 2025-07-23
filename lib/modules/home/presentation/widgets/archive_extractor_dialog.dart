// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickzip/core/services/app_router.dart';
import 'package:quickzip/core/theme/app_theme.dart';
import '../../../../core/utils/network_util.dart';
import '../../../../core/utils/password_generator.dart';
import '../../../../modules/splash/presentation/screens/no_internet_screen.dart';
import '../../../../core/utils/show_custom_snackbar.dart';
import '../../../../core/services/ads_manager.dart';
import '../../../../core/services/extract_file.dart';

class ArchiveExtractorDialog extends ConsumerStatefulWidget {
  final String fileName;
  final String filePath;
  final bool requiresAd;
  final Function(String?) onExtract;
  final bool isPasswordProtected;

  const ArchiveExtractorDialog({
    super.key,
    required this.fileName,
    required this.filePath,
    required this.requiresAd,
    required this.onExtract,
    required this.isPasswordProtected,
  });

  @override
  ConsumerState<ArchiveExtractorDialog> createState() =>
      _ArchiveExtractorDialogState();
}

class _ArchiveExtractorDialogState extends ConsumerState<ArchiveExtractorDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isTomitoFile = false;
  bool _isLoadingAd = false;
  bool _isChecking = false;
  int _failedAdAttempts = 0;

  @override
  void initState() {
    super.initState();
    _isTomitoFile = PasswordGenerator.isTomitoFile(widget.fileName);
    if (widget.isPasswordProtected && _isTomitoFile) {
      _passwordController.text =
          PasswordGenerator.generatePassword(widget.fileName);
    }
  }

  Future<void> _updateConnectionType() async {
    if (mounted) {}
  }

  Future<void> _preloadRewardedAd() async {
    final adsManager = ref.read(adsManagerProvider);

    // If ad is already loaded, don't reload
    if (adsManager.isRewardedAdLoaded) {
      debugPrint('Rewarded ad is already loaded in dialog');
      return;
    }

    setState(() => _isLoadingAd = true);

    // Try to load the ad with retries
    int attempts = 0;
    const maxAttempts = 2; // Changed to 2 attempts

    while (attempts < maxAttempts && !adsManager.isRewardedAdLoaded) {
      try {
        debugPrint(
            'Attempting to load rewarded ad (Attempt ${attempts + 1}/$maxAttempts)');
        await adsManager.loadRewardedAd();

        if (adsManager.isRewardedAdLoaded) {
          debugPrint('Rewarded ad loaded successfully in dialog');
          _failedAdAttempts = 0; // Reset failed attempts on success
          break; // Exit the loop if ad loaded successfully
        }

        if (attempts < maxAttempts - 1) {
          // Wait before next attempt (2, 4 seconds)
          await Future.delayed(Duration(seconds: (attempts + 1) * 2));
        }

        attempts++;
        _failedAdAttempts = attempts; // Track failed attempts
      } catch (e) {
        debugPrint('Error loading rewarded ad in dialog: $e');
        if (attempts < maxAttempts - 1) {
          await Future.delayed(Duration(seconds: (attempts + 1) * 2));
        }
        attempts++;
        _failedAdAttempts = attempts; // Track failed attempts
      }
    }

    if (mounted) {
      setState(() => _isLoadingAd = false);
    }
  }

  void _handleExtract() async {
    if (widget.isPasswordProtected && _passwordController.text.isEmpty) {
      showCustomSnackBar(context, 'Please enter the password');
      return;
    }

    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      await _updateConnectionType();
      final hasInternet = await NetworkUtil.checkInternetConnection();

      if (!mounted) return;

      if (!hasInternet) {
        Navigator.pop(context);
        AppRoutes.pushReplacement(const NoInternetScreen());
        return;
      }

      // For non-Tomito password-protected files, validate password first
      if (widget.isPasswordProtected && !_isTomitoFile) {
        debugPrint('Validating password for file: ${widget.filePath}');
        bool isPasswordValid = false;

        try {
          isPasswordValid = await ArchiveExtractor.validatePassword(
            widget.filePath,
            _passwordController.text,
          );
          debugPrint('Password validation result: $isPasswordValid');

          if (!mounted) return;

          if (!isPasswordValid) {
            Navigator.pop(context); // Close the dialog first
            showCustomSnackBar(
                context, 'Incorrect password, Please try again.');
            setState(() => _isChecking = false);
            return;
          }
        } catch (e) {
          debugPrint('Error during password validation: $e');
          if (mounted) {
            Navigator.pop(context); // Close the dialog first
            showCustomSnackBar(context, e.toString());
            setState(() => _isChecking = false);
          }
          return;
        }
      }

      // Password validation successful or not required, proceed with extraction
      debugPrint('Starting extraction process');

      // Only show rewarded ad for Tomito files
      if (_isTomitoFile) {
        final adsManager = ref.read(adsManagerProvider);

        // If we've had 2 failed attempts, proceed with extraction
        if (_failedAdAttempts >= 2) {
          debugPrint('Proceeding with extraction after 2 failed ad attempts');
          Navigator.pop(context);
          widget.onExtract(
            widget.isPasswordProtected ? _passwordController.text : null,
          );
          return;
        }

        // Try to load the ad
        await _preloadRewardedAd();

        // If ad is still not loaded after 2 attempts, increment failed attempts and proceed
        if (!adsManager.isRewardedAdLoaded) {
          _failedAdAttempts++;
          if (_failedAdAttempts >= 2) {
            debugPrint(
                'Proceeding with extraction after 2 failed ad attempts (post ad load)');
            Navigator.pop(context);
            widget.onExtract(
              widget.isPasswordProtected ? _passwordController.text : null,
            );
            return;
          } else {
            Navigator.pop(context); // Close the dialog first
            showCustomSnackBar(context, 'Failed to load ad. Please try again.');
            return;
          }
        }

        final bool adShown = await adsManager.showRewardedAd(
          onRewardEarned: () async {
            try {
              Navigator.pop(context);
              widget.onExtract(
                widget.isPasswordProtected ? _passwordController.text : null,
              );
            } catch (e) {
              debugPrint('Error during extraction after ad: $e');
              if (mounted) {
                showCustomSnackBar(context, e.toString());
              }
            }
          },
        );

        if (!adShown) {
          _failedAdAttempts++;
          if (_failedAdAttempts >= 2) {
            debugPrint(
                'Proceeding with extraction after 2 failed ad attempts (post ad show)');
            Navigator.pop(context);
            widget.onExtract(
              widget.isPasswordProtected ? _passwordController.text : null,
            );
            return;
          } else {
            Navigator.pop(context); // Close the dialog first
            showCustomSnackBar(context, 'Failed to show ad. Please try again.');
            return;
          }
        }
      } else {
        try {
          Navigator.pop(context);
          widget.onExtract(
            widget.isPasswordProtected ? _passwordController.text : null,
          );
        } catch (e) {
          debugPrint('Error during extraction: $e');
          if (mounted) {
            showCustomSnackBar(context, e.toString());
          }
        }
      }
    } catch (e) {
      debugPrint('Error in extraction process: $e');
      if (mounted) {
        Navigator.pop(context); // Close the dialog first
        showCustomSnackBar(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      backgroundColor: AppTheme.primaryBlack,
      title: Text(_isTomitoFile ? 'Extract Archive' : 'Extract Archive'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Do you want to extract ${widget.fileName}?'),
          const SizedBox(height: 16),
          if (_isTomitoFile)
            const Text(
              'This is a password-protected special\nZip file provided by our partner,\nTomito+. To extract this file, you\nmust watch a rewarded ad.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryGrey,
              ),
            )
          else if (widget.isPasswordProtected)
            const Text(
              'This file is a password-protected zip file. Please enter the password below to extract it.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryGrey,
              ),
            ),
          if (widget.isPasswordProtected) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              enabled: !_isTomitoFile,
              readOnly: _isTomitoFile,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _isTomitoFile
                        ? AppTheme.primaryGrey
                        : AppTheme.primaryGreen,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
                labelText: 'Password',
                labelStyle: const TextStyle(color: AppTheme.primaryGreen),
                border: const OutlineInputBorder(),
                hintText: 'Password',
                hintStyle: const TextStyle(color: AppTheme.primaryGrey),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryGrey),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryGreen),
                ),
                disabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryGrey),
                ),
              ),
              obscureText: _obscureText,
              style: TextStyle(
                color: _isTomitoFile
                    ? AppTheme.primaryGrey
                    : AppTheme.primaryWhite,
              ),
              onSubmitted: (_) => _handleExtract(),
            ),
            const SizedBox(height: 10),
            if (_isTomitoFile)
              const Text(
                '*Auto-generated password for Tomito+ file',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryGrey,
                ),
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppTheme.primaryGrey),
          ),
        ),
        if (_isChecking || _isLoadingAd)
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
          )
        else
          TextButton(
            onPressed: _handleExtract,
            child: Text(
              _isTomitoFile ? 'Watch Ad to Extract' : 'Extract',
              style: const TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
