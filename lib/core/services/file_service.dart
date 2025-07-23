import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:archive/archive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/archive_utils.dart';
import 'extract_file.dart';

final fileServiceProvider = Provider<FileService>((ref) => FileService());

class FileService {
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      try {
        // First request MANAGE_EXTERNAL_STORAGE for Android 11+
        if (await Permission.manageExternalStorage.status.isDenied) {
          final result = await Permission.manageExternalStorage.request();
          if (result.isGranted) {
            debugPrint('MANAGE_EXTERNAL_STORAGE permission granted');
            return true;
          }
        } else if (await Permission.manageExternalStorage.status.isGranted) {
          return true;
        }

        // Fallback permissions for older Android versions
        Map<Permission, PermissionStatus> statuses = await [
          Permission.storage,
          Permission.accessMediaLocation,
        ].request();

        bool allGranted = true;
        statuses.forEach((permission, status) {
          if (!status.isGranted) {
            allGranted = false;
            debugPrint('${permission.toString()} is not granted');
          }
        });

        return allGranted;
      } catch (e) {
        debugPrint('Error requesting permissions: $e');
        return false;
      }
    } else if (Platform.isIOS) {
      return await Permission.photos.request().isGranted;
    }
    return false;
  }

  Future<List<FileSystemEntity>> getCompressedFiles() async {
    List<FileSystemEntity> compressedFiles = [];

    try {
      if (Platform.isAndroid) {
        final List<Directory> storageDirs = await _getAccessibleStoragePaths();

        for (final dir in storageDirs) {
          try {
            // Only add .zip files
            final files = await _scanDirectory(dir);
            compressedFiles.addAll(
              files.where((file) =>
                  file is File && file.path.toLowerCase().endsWith('.zip')),
            );
          } catch (e) {
            debugPrint('Error scanning ${dir.path}: $e');
            continue;
          }
        }
      } else if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        final files = await _scanDirectory(directory);
        compressedFiles.addAll(
          files.where((file) =>
              file is File && file.path.toLowerCase().endsWith('.zip')),
        );
      }

      compressedFiles = await _processFiles(compressedFiles);
    } catch (e) {
      debugPrint('Error getting compressed files: $e');
    }

    // Sort files by modification time (newest first)
    compressedFiles.sort((a, b) {
      try {
        if (!a.existsSync()) return 1;
        if (!b.existsSync()) return -1;
        return b.statSync().modified.compareTo(a.statSync().modified);
      } catch (e) {
        // Handle files that might be inaccessible
        debugPrint('Error comparing files: $e');
        return 0;
      }
    });

    await _saveCompressedFiles(compressedFiles);
    return compressedFiles;
  }

  Future<List<Directory>> _getAccessibleStoragePaths() async {
    List<Directory> accessibleDirs = [];

    try {
      // Wait for permissions to be granted
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        debugPrint('Permissions not granted, returning empty list');
        return accessibleDirs;
      }

      // Primary storage
      final primary = Directory('/storage/emulated/0');
      if (await _isDirectoryAccessible(primary)) {
        accessibleDirs.add(primary);
      }

      // Common directories with better error handling
      final commonPaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Movies',
      ];

      for (final path in commonPaths) {
        final dir = Directory(path);
        if (await _isDirectoryAccessible(dir)) {
          accessibleDirs.add(dir);
        }
      }

      // External storage handling with better error handling
      if (await Permission.manageExternalStorage.isGranted) {
        try {
          final storage = Directory('/storage');
          if (await storage.exists()) {
            final items = await storage.list().toList();
            for (var item in items) {
              if (item is Directory &&
                  !item.path.contains('emulated') &&
                  !item.path.contains('self')) {
                if (await _isDirectoryAccessible(item)) {
                  accessibleDirs.add(item);
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error accessing external storage: $e');
        }
      }
    } catch (e) {
      debugPrint('Error getting storage paths: $e');
    }

    return accessibleDirs;
  }

  Future<bool> _isDirectoryAccessible(Directory dir) async {
    try {
      if (!await dir.exists()) return false;

      // Try to list directory contents
      try {
        final stream = dir.list();
        await for (final _ in stream.take(1)) {
          return true; // If we can read at least one entry, directory is accessible
        }
        return true; // Directory exists but is empty
      } catch (e) {
        debugPrint('Error accessing directory ${dir.path}: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking directory ${dir.path}: $e');
      return false;
    }
  }

  Future<List<FileSystemEntity>> _scanDirectory(Directory directory) async {
    List<FileSystemEntity> files = [];
    try {
      debugPrint('Scanning directory: ${directory.path}');
      final stream = directory.list(recursive: true, followLinks: false);

      await for (final entity in stream) {
        if (entity is File && _isCompressedFile(entity.path)) {
          try {
            // Verify file is actually accessible
            if (await entity.exists()) {
              files.add(entity);
              debugPrint('Found compressed file: ${entity.path}');
            }
          } catch (e) {
            debugPrint('Error accessing file ${entity.path}: $e');
            continue;
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning directory ${directory.path}: $e');
    }
    return files;
  }

  Future<List<FileSystemEntity>> _processFiles(
      List<FileSystemEntity> files) async {
    // Remove duplicates and files that no longer exist
    final uniqueFiles = <String, FileSystemEntity>{};
    for (var file in files) {
      try {
        if (file.existsSync()) {
          uniqueFiles[file.path] = file;
        }
      } catch (e) {
        debugPrint('Error checking if file exists: $e');
      }
    }

    // Sort by modification date (newest first)
    final sortedFiles = uniqueFiles.values.toList()
      ..sort((a, b) {
        try {
          if (!a.existsSync()) return 1;
          if (!b.existsSync()) return -1;
          return b.statSync().modified.compareTo(a.statSync().modified);
        } catch (e) {
          // Handle files that might be inaccessible
          debugPrint('Error comparing files: $e');
          return 0;
        }
      });

    return sortedFiles;
  }

  bool _isCompressedFile(String path) {
    final compressedExtensions = [
      '.zip',
      '.rar',
      '.7z',
      '.tar',
      '.gz',
      '.bz2',
      '.xz',
      '.tgz',
      '.tbz2',
      '.tbz',
      '.txz',
      '.apk'
    ];
    return compressedExtensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  // ignore: unused_element
  Archive? _getArchiveFromFile(String path, List<int> bytes,
      {String? password}) {
    try {
      if (path.toLowerCase().endsWith('.zip')) {
        if (password?.isEmpty ?? true) {
          // Try without password first
          try {
            final archive = ZipDecoder().decodeBytes(bytes);
            if (archive.isNotEmpty) return archive;
          } catch (_) {
            // If fails, it might need a password
            throw const FormatException('This file is password protected');
          }
        }

        // Try with password
        final archive = ZipDecoder().decodeBytes(bytes, password: password);
        if (archive.isEmpty) {
          throw const FormatException('Invalid password or corrupted archive');
        }
        return archive;
      } else if (path.toLowerCase().endsWith('.tar')) {
        return TarDecoder().decodeBytes(bytes);
      } else {
        throw const FormatException('Unsupported archive format');
      }
    } catch (e) {
      debugPrint('Error decoding archive: $e');
      if (e.toString().toLowerCase().contains('password')) {
        throw const FormatException('This file is password protected');
      }
      rethrow;
    }
  }

  Future<void> extractFile(File file,
      {String? password, ValueNotifier<double>? progressNotifier}) async {
    final fileName = file.path.split('/').last;
    final fileNameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));
    final extractionDir = await getExtractionDirectory();
    final outputPath = '${extractionDir.path}/$fileNameWithoutExt';

    try {
      // Create output directory if it doesn't exist
      final outputDir = Directory(outputPath);
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      // Use native Kotlin code to extract the file with progress updates
      await ArchiveExtractor.extractZip(
        file.path,
        outputPath,
        password: password,
        onProgress: (progress, status) {
          if (progressNotifier != null) {
            progressNotifier.value = progress;
          }
        },
      );

      await _saveExtractedFile(outputPath);
    } catch (e) {
      debugPrint('Error extracting file: $e');
      rethrow;
    }
  }

  Future<Directory> getExtractionDirectory() async {
    if (Platform.isAndroid) {
      // For Android, create in root storage
      final directory =
          Directory('/storage/emulated/0/QuickZip Extracted Files');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } else {
      // For iOS, use app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final extractionDir =
          Directory('${appDir.path}/QuickZip Extracted Files');
      if (!await extractionDir.exists()) {
        await extractionDir.create(recursive: true);
      }
      return extractionDir;
    }
  }

  Future<List<FileSystemEntity>> getExtractedFiles() async {
    final extractionDir = await getExtractionDirectory();

    List<FileSystemEntity> extractedFiles = [];

    try {
      // Only get top-level files and folders, not recursive
      extractedFiles =
          extractionDir.listSync(recursive: false, followLinks: false);

      // Filter out files that might have been deleted
      extractedFiles = extractedFiles.where((entity) {
        try {
          return entity.existsSync();
        } catch (e) {
          debugPrint('Error checking if entity exists: $e');
          return false;
        }
      }).toList();

      // Sort by creation time, newest first
      extractedFiles.sort((a, b) {
        try {
          if (!a.existsSync()) return 1;
          if (!b.existsSync()) return -1;
          final aTime = a.statSync().changed;
          final bTime = b.statSync().changed;
          return bTime.compareTo(aTime);
        } catch (e) {
          debugPrint('Error comparing files: $e');
          return 0;
        }
      });
    } catch (e) {
      debugPrint('Error listing extracted files: $e');
    }

    await _saveExtractedFiles(extractedFiles);
    return extractedFiles;
  }

  Future<void> _saveCompressedFiles(List<FileSystemEntity> files) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'compressed_files', files.map((f) => f.path).toList());
  }

  Future<void> _saveExtractedFile(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final extractedFiles = prefs.getStringList('extracted_files') ?? [];
    extractedFiles.add(filePath);
    await prefs.setStringList('extracted_files', extractedFiles);
  }

  Future<void> _saveExtractedFiles(List<FileSystemEntity> files) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'extracted_files', files.map((f) => f.path).toList());
  }

  Future<List<String>> getStoredCompressedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('compressed_files') ?? [];
  }

  Future<List<String>> getStoredExtractedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('extracted_files') ?? [];
  }

  Future<bool> isPasswordProtected(File file) async {
    try {
      return await ArchiveUtils.isPasswordProtected(file.path);
    } catch (e) {
      debugPrint('Error checking password protection: $e');
      return false;
    }
  }

  Future<List<FileSystemEntity>> getFilesInExtractedFolder(
      Directory folder) async {
    try {
      if (!folder.existsSync()) return [];

      // Get all files and directories in the folder
      List<FileSystemEntity> entities = [];
      try {
        entities = folder
            .listSync(recursive: false, followLinks: false)
            .where((entity) {
          // Include all directories and files that exist
          try {
            return entity.existsSync();
          } catch (e) {
            debugPrint('Error accessing entity ${entity.path}: $e');
            return false;
          }
        }).toList();
      } catch (e) {
        debugPrint('Error listing folder contents: $e');
        return [];
      }

      // Sort entities: directories first, then files, both sorted by name
      try {
        entities.sort((a, b) {
          try {
            // Check if entities still exist
            if (!a.existsSync()) return 1;
            if (!b.existsSync()) return -1;

            // Put directories first
            if (a is Directory && b is File) return -1;
            if (a is File && b is Directory) return 1;

            // Sort by name within the same type
            return a.path.toLowerCase().compareTo(b.path.toLowerCase());
          } catch (e) {
            debugPrint('Error comparing entities: $e');
            return 0;
          }
        });
      } catch (e) {
        debugPrint('Error sorting folder contents: $e');
      }

      return entities;
    } catch (e) {
      debugPrint('Error getting files from folder: $e');
      return [];
    }
  }
}
