import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const primaryGreen = Color(0xFF1CE783);
  static const primaryBlack = Color(0xFF1d1d1d);
  static const primaryGrey = Color(0xFF838383);
  static const primaryWhite = Color(0xffe2e2e2);
  static const hintText = Color(0xffcacaca);
  static const lightWhite = Color(0xffb3b3b3);
  static const transparent = Colors.transparent;
  static const darkBackground = Color(0xFF111111);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkError = Color(0xFFCF6679);
  static const primaryWhite2 = Color(0xFFAFAFAF);

  // Material Dark Theme for Android
  static ThemeData get materialDarkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        surface: darkSurface,
        error: darkError,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
      ),
    );
  }

  // Cupertino Dark Theme for iOS
  static CupertinoThemeData get cupertinoDarkTheme {
    return const CupertinoThemeData(
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: darkBackground,
      textTheme: CupertinoTextThemeData(
        textStyle: TextStyle(
          color: CupertinoColors.white,
        ),
      ),
      barBackgroundColor: primaryGreen,
    );
  }
}
