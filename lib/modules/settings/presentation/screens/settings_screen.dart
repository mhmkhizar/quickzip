import 'dart:io';
import 'package:flutter/material.dart';
import 'package:quickzip/core/services/app_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/rating_dialog.dart';
import 'privacy_policy_screen.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // Load Banner Ad when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ref.read(adsManagerProvider).loadBannerAd(context);
      // ref.read(adsManagerProvider).loadBannerAd2(context);
    });
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        onRatingSubmitted: (rating) {
          if (rating >= 3) {
            _openStorePage();
          }
        },
      ),
    );
  }

  Future<void> _openStorePage() async {
    final uri = Uri.parse(
      Platform.isAndroid
          ? 'market://details?id=com.yourcompany.quickzip'
          : 'https://apps.apple.com/app/idYOUR_APP_ID',
    );

    try {
      await launchUrl(uri);
    } catch (e) {
      debugPrint('Error opening store page: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // final adsManager = ref.watch(adsManagerProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: const Text(
          'Settings',
          style: TextStyle(
              fontWeight: FontWeight.w500, color: AppTheme.primaryWhite),
        ),
        leading: IconButton(
          onPressed: () {
            AppRoutes.back();
          },
          icon: const Icon(Icons.arrow_back),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppTheme.primaryWhite),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: const Text(
                    'Rate Us',
                    style: TextStyle(
                        color: AppTheme.primaryWhite,
                        fontWeight: FontWeight.w600),
                  ),
                  leading: const Icon(Icons.thumb_up_outlined),
                  iconColor: AppTheme.primaryGreen,
                  onTap: _showRatingDialog,
                ),
                ListTile(
                  title: const Text(
                    'Share with friends',
                    style: TextStyle(
                        color: AppTheme.primaryWhite,
                        fontWeight: FontWeight.w600),
                  ),
                  leading: const Icon(Icons.share_outlined),
                  iconColor: AppTheme.primaryGreen,
                  onTap: () {
                    Share.share(
                      'Check out QuickZip!',
                    );
                  },
                ),
                ListTile(
                  title: const Text(
                    'Privacy Policy',
                    style: TextStyle(
                        color: AppTheme.primaryWhite,
                        fontWeight: FontWeight.w600),
                  ),
                  leading: const Icon(Icons.privacy_tip_outlined),
                  iconColor: AppTheme.primaryGreen,
                  onTap: () {
                    AppRoutes.push(
                      const PrivacyPolicyPage(),
                    );
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => const PrivacyPolicyPage(),
                    //   ),
                    // );
                    // showDialog(
                    //   context: context,
                    //   builder: (context) => const AlertDialog(
                    //     title: Text('Privacy Policy'),
                    //   ),
                    // );
                  },
                ),
                const ListTile(
                  title: Text(
                    'App Version',
                    style: TextStyle(
                        color: AppTheme.primaryWhite,
                        fontWeight: FontWeight.w600),
                  ),
                  leading: Icon(Icons.verified_outlined),
                  iconColor: AppTheme.primaryGreen,
                  subtitle: Text('1.0.0'),
                ),
              ],
            ),
          ),
          // adsManager.getBannerAdWidget2(),
        ],
      ),
    );
  }
}
