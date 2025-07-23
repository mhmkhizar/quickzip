import 'dart:convert';

import 'package:flutter/material.dart';

class PasswordGenerator {
  static bool isTomitoFile(String fileName) {
    try {
      // Normalize the filename
      String normalizedName = _normalizeFileName(fileName);

      // Get base name without extension
      String baseName = _getBaseNameWithoutExtension(normalizedName);

      // Check for any case variation of "tomito"
      return _checkTomito(baseName);
    } catch (e) {
      debugPrint('Error checking Tomito file: $e');
      return false;
    }
  }

  static String _normalizeFileName(String fileName) {
    try {
      // Decode UTF-8 if needed
      String decoded = utf8.decode(fileName.codeUnits, allowMalformed: true);

      // Remove any extra whitespace
      decoded = decoded.trim();

      // Remove any invisible characters
      decoded = decoded.replaceAll(RegExp(r'\s+'), ' ');

      return decoded;
    } catch (e) {
      return fileName;
    }
  }

  static String _getBaseNameWithoutExtension(String fileName) {
    // List of supported extensions
    final extensions = ['.zip', '.rar', '.7z', '.tar', '.gz', '.bz2'];

    String baseName = fileName;
    for (final ext in extensions) {
      if (fileName.toLowerCase().endsWith(ext)) {
        baseName = fileName.substring(0, fileName.length - ext.length);
        break;
      }
    }
    return baseName;
  }

  static bool _checkTomito(String baseName) {
    // Convert to lowercase for case-insensitive comparison
    String lowerName = baseName.toLowerCase();

    // Check if "tomito" exists in the filename in any form
    return lowerName.contains('tomito');
  }

  static String generatePassword(String fileName) {
    // Remove the extension from the file name
    String nameWithoutExt = _getBaseNameWithoutExtension(fileName);

    // Step 1: Remove special characters and convert to lowercase
    String step1 =
        nameWithoutExt.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();

    // Step 2: Convert letters to their positions (a=1, b=2, etc.)
    String step2 = step1.split('').map((char) {
      if (RegExp(r'[a-z]').hasMatch(char)) {
        return (char.codeUnitAt(0) - 'a'.codeUnitAt(0) + 1).toString();
      }
      return char;
    }).join('');

    // Step 3: Take first 20 numbers (pad with zeros if needed)
    String step3 = (step2 + '0' * 20).substring(0, 20);

    // Step 4: Increment each number
    String step4 = step3.split('').map((char) {
      int digit = int.parse(char);
      return ((digit + 1) % 10).toString();
    }).join('');

    // Step 5: Pair and mix
    String step5 = _pairAndMix(step4);

    // Step 6: Reverse
    String step6 = step5.split('').reversed.join('');

    // Step 7: Increment again
    String step7 = step6.split('').map((char) {
      int digit = int.parse(char);
      return ((digit + 1) % 10).toString();
    }).join('');

    // Step 8: Pair and mix again
    String step8 = _pairAndMix(step7);

    // Step 9: Final reverse
    return step8.split('').reversed.join('');
  }

  static String _pairAndMix(String input) {
    int length = input.length;
    List<String> mixed = [];
    for (int i = 0; i < length ~/ 2; i++) {
      mixed.add(input[i]);
      mixed.add(input[length - 1 - i]);
    }
    return mixed.join('');
  }
}
