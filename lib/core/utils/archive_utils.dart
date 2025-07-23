import 'dart:io';
import 'package:flutter/foundation.dart';

class ArchiveUtils {
  // ignore: constant_identifier_names
  static const int HEADER_SIZE = 8192; // 8KB for header check

  static Future<bool> isPasswordProtected(String filePath) async {
    try {
      final file = File(filePath);
      final RandomAccessFile raf = await file.open(mode: FileMode.read);

      try {
        // Only read the header portion
        final headerBytes = await raf.read(HEADER_SIZE);
        final extension = filePath.toLowerCase();

        if (extension.endsWith('.zip')) {
          return _isZipPasswordProtected(headerBytes);
        } else if (extension.endsWith('.rar')) {
          return _isRarPasswordProtected(headerBytes);
        } else if (extension.endsWith('.7z')) {
          return _is7zPasswordProtected(headerBytes);
        }
        return false;
      } finally {
        await raf.close();
      }
    } catch (e) {
      debugPrint('Error checking password protection: $e');
      return false; // Default to not password protected on error
    }
  }

  static bool _isZipPasswordProtected(List<int> bytes) {
    try {
      // Check for encryption flag in ZIP header
      for (int i = 0; i < bytes.length - 30; i++) {
        if (bytes[i] == 0x50 &&
            bytes[i + 1] == 0x4B &&
            bytes[i + 2] == 0x03 &&
            bytes[i + 3] == 0x04) {
          // General purpose bit flag is at offset 6
          int flag = bytes[i + 6] | (bytes[i + 7] << 8);
          // Bit 0 indicates encryption
          return (flag & 0x1) == 0x1;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking ZIP password protection: $e');
      return false;
    }
  }

  static bool _isRarPasswordProtected(List<int> bytes) {
    try {
      if (bytes.length > 7 &&
          bytes[0] == 0x52 &&
          bytes[1] == 0x61 &&
          bytes[2] == 0x72 &&
          bytes[3] == 0x21) {
        // Check header type and flags
        for (int i = 7; i < bytes.length - 7; i++) {
          if (bytes[i] == 0x74) {
            int flags = bytes[i + 3] | (bytes[i + 4] << 8);
            return (flags & 0x04) == 0x04;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking RAR password protection: $e');
      return false;
    }
  }

  static bool _is7zPasswordProtected(List<int> bytes) {
    try {
      if (bytes.length > 32 &&
          bytes[0] == 0x37 &&
          bytes[1] == 0x7A &&
          bytes[2] == 0xBC &&
          bytes[3] == 0xAF) {
        // Check property info
        for (int i = 32; i < bytes.length - 2; i++) {
          if (bytes[i] == 0x06 && bytes[i + 1] == 0x0) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking 7z password protection: $e');
      return false;
    }
  }
}
