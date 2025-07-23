import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ArchiveExtractor {
  static const _channel = MethodChannel('com.example.quick_zip_app/archive');
  static const _progressChannel =
      EventChannel('com.example.quick_zip_app/progress');

  static Stream<Map<String, dynamic>> getProgressStream() {
    return _progressChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event as Map);
    });
  }

  static Future<bool> validatePassword(
      String zipFilePath, String password) async {
    try {
      final result = await _channel.invokeMethod('validatePassword', {
        'zipFilePath': zipFilePath,
        'password': password,
      });
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Failed to validate password: ${e.message}');
      if (e.code == 'WRONG_PASSWORD') {
        return false;
      }
      if (e.code == 'NOT_ENCRYPTED') {
        return true; // Non-encrypted files don't need password validation
      }
      throw Exception('Failed to validate password: ${e.message}');
    }
  }

  static Future<void> extractZip(String zipFilePath, String outputDirPath,
      {String? password,
      Function(double progress, String status)? onProgress}) async {
    try {
      // Validate password before attempting extraction
      if (password != null) {
        final isValid = await validatePassword(zipFilePath, password);
        if (!isValid) {
          throw Exception('Incorrect password');
        }
      }

      // Start listening to progress updates
      final progressSubscription = getProgressStream().listen(
        (progressData) {
          if (onProgress != null) {
            final progress = progressData['progress'] as double;
            final status = progressData['status'] as String? ?? 'Extracting...';
            onProgress(progress / 100.0, status);
          }
        },
        onError: (error) {
          debugPrint('Progress stream error: $error');
        },
      );

      // Start extraction
      await _channel.invokeMethod('extractZip', {
        'zipFilePath': zipFilePath,
        'outputDirPath': outputDirPath,
        'password': password,
      });

      // Cancel the progress subscription after extraction is complete
      await progressSubscription.cancel();
    } on PlatformException catch (e) {
      debugPrint('Failed to extract zip: ${e.message}');
      switch (e.code) {
        case 'WRONG_PASSWORD':
          throw Exception('Incorrect password');
        case 'PASSWORD_REQUIRED':
          throw Exception('Password is required for this file');
        case 'NOT_ENCRYPTED':
          // Try extraction without password
          return await extractZip(zipFilePath, outputDirPath,
              onProgress: onProgress);
        default:
          throw Exception('Failed to extract file: ${e.message}');
      }
    }
  }
}
