import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickzip/core/services/app_router.dart';
import 'package:quickzip/modules/home/presentation/screens/home_screen.dart';
import 'package:quickzip/modules/settings/presentation/screens/settings_screen.dart';

import '../../../../core/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
              fontWeight: FontWeight.w500, color: AppTheme.primaryWhite),
        ),
        leading: IconButton(
          onPressed: () {
            AppRoutes.back(
              const SettingsPage(),
            );
          },
          icon: const Icon(Icons.arrow_back),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppTheme.primaryWhite),
        ),
        backgroundColor: AppTheme.darkBackground,
      ),
      body: Column(
        children: [
          Expanded(
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              backgroundColor: AppTheme.primaryBlack,
              content: const SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Last Updated Date (Underlined)
                      Text(
                        'Last updated: 2025-02-01',
                        style: TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                          color: AppTheme.primaryWhite,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Introduction
                      Text(
                        'Introduction',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Welcome to QuickZip! This Privacy Policy explains how we handle your information when you use our app. '
                        'By using QuickZip, you agree to the practices described below.',
                        style: TextStyle(color: AppTheme.primaryWhite),
                      ),
                      SizedBox(height: 20),

                      // Permissions Required
                      Text(
                        'Permissions Required',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'To provide core functionality, QuickZip requires the following permissions:',
                        style: TextStyle(color: AppTheme.primaryWhite),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Storage Access:',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryWhite),
                      ),
                      SizedBox(height: 20),
                      Text(
                        '• Required to access, extract, and manage ZIP files on your device.\n'
                        '• Android 11+ Only: The [MANAGE_EXTERNAL_STORAGE] permission is needed for seamless file operations.\n'
                        '• iOS: No additional permissions beyond standard storage access.',
                        style: TextStyle(
                            color: AppTheme.primaryWhite, fontSize: 12),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Internet Access:',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryWhite),
                      ),
                      SizedBox(height: 20),

                      Text(
                        '• Required for displaying ads (via Google AdMob) and validating app functionality.\n'
                        '• The app will not work without an active internet connection.',
                        style: TextStyle(
                            color: AppTheme.primaryWhite, fontSize: 12),
                      ),
                      SizedBox(height: 20),

                      // Data Collection & Usage
                      Text(
                        'Data Collection & Usage',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'For Advertising:',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryWhite),
                      ),
                      SizedBox(height: 20),

                      Text(
                        '• Our advertising partners (e.g., Google AdMob) may collect anonymized data to deliver personalized ads.\n'
                        '• Ads keep QuickZip free. By using the app, you consent to ad-related data collection.',
                        style: TextStyle(
                          color: AppTheme.primaryWhite,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'For Analytics:',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryWhite),
                      ),
                      SizedBox(height: 20),
                      Text(
                        '• Third-party tools may analyze app performance and user behavior to improve functionality.\n'
                        '• No personally identifiable information is shared.',
                        style: TextStyle(
                            color: AppTheme.primaryWhite, fontSize: 12),
                      ),
                      SizedBox(height: 20),

                      // Third-Party Services
                      Text(
                        'Third-Party Services',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "AdMob: Google's AdMob service displays ads. Review Google's Privacy Policy here.",
                        style: TextStyle(
                            color: AppTheme.primaryWhite, fontSize: 12),
                      ),
                      Text(
                        'App Stores: QuickZip is distributed via Google Play Store and Apple App Store. Their terms apply to app downloads and updates.',
                        style: TextStyle(
                            color: AppTheme.primaryWhite, fontSize: 12),
                      ),
                      SizedBox(height: 20),

                      // User Control
                      Text(
                        'User Control',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '• You can reset or withdraw permissions via your device settings.\n'
                        '• Ads cannot be disabled but are non-intrusive (banner and rewarded video formats only).',
                        style: TextStyle(
                          color: AppTheme.primaryWhite,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Security
                      Text(
                        'Security',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '• QuickZip does not store, share, or transmit your files or passwords outside your device.\n'
                        '• Password-protected ZIP files are decrypted locally, and passwords are not logged.',
                        style: TextStyle(
                            color: AppTheme.primaryWhite, fontSize: 12),
                      ),
                      SizedBox(height: 20),

                      // Policy Updates
                      Text(
                        'Policy Updates',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '• This policy may change. Continued app use implies acceptance of revisions.',
                        style: TextStyle(
                            color: AppTheme.primaryWhite, fontSize: 12),
                      ),
                      SizedBox(height: 20),

                      // Contact
                      Text(
                        'Contact',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen),
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        children: [
                          Text(
                            'For questions, contact us at: ',
                            style: TextStyle(
                                color: AppTheme.primaryWhite, fontSize: 12),
                          ),
                          Text(
                            'eagolainc@protonmail.com',
                            style: TextStyle(
                                color: AppTheme.primaryWhite,
                                decoration: TextDecoration.underline,
                                fontSize: 12),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 38),
            child: ElevatedButton(
              onPressed: () {
                // Navigate back to home screen
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: const BorderSide(
                    color: AppTheme.primaryGreen,
                    width: 1,
                  ),
                ),
                elevation: 0,
              ),
              child: const Text(
                'ACCEPT',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: AppTheme.primaryBlack,
                    title: const Text(
                      'Exit the app',
                      style: TextStyle(
                        color: AppTheme.primaryWhite,
                        fontSize: 20,
                      ),
                    ),
                    content: const Text(
                      'Are you sure you want to exit from this app?',
                      style: TextStyle(
                        color: AppTheme.primaryWhite,
                        fontSize: 16,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          SystemNavigator.pop();
                        },
                        child: const Text(
                          'Exit',
                          style: TextStyle(
                            color: AppTheme.primaryWhite,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppTheme.primaryGrey,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: const Text(
              'DECLINE',
              style: TextStyle(
                color: AppTheme.primaryGrey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          )

          // const SizedBox(
          //   height: 40,
          // )
        ],
      ),
    );
  }
}
