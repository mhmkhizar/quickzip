import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Search query states for each section
final compressedSearchQueryProvider = StateProvider<String>((ref) => '');
final extractedSearchQueryProvider = StateProvider<String>((ref) => '');

// Filtered providers for each section
final filteredCompressedFilesProvider =
    Provider.family<List<FileSystemEntity>, List<FileSystemEntity>>(
        (ref, files) {
  final searchQuery = ref.watch(compressedSearchQueryProvider).toLowerCase();

  if (searchQuery.isEmpty) {
    return files;
  }

  return files.where((file) {
    final fileName = file.path.split('/').last.toLowerCase();
    return fileName.contains(searchQuery);
  }).toList();
});

final filteredExtractedFilesProvider =
    Provider.family<List<FileSystemEntity>, List<FileSystemEntity>>(
        (ref, files) {
  final searchQuery = ref.watch(extractedSearchQueryProvider).toLowerCase();

  if (searchQuery.isEmpty) {
    return files;
  }

  return files.where((entity) {
    final name = entity.path.split('/').last.toLowerCase();

    // If it's a directory, include it if its name matches or if any of its contents match
    if (entity is Directory) {
      try {
        final hasMatchingContents = entity.listSync(recursive: true).any(
            (file) =>
                file.path.split('/').last.toLowerCase().contains(searchQuery));
        return name.contains(searchQuery) || hasMatchingContents;
      } catch (e) {
        return name.contains(searchQuery);
      }
    }

    // For files, just check the name
    return name.contains(searchQuery);
  }).toList();
});
