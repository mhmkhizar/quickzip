// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/file_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/file_list_tile.dart';
import '../provider/file_provider.dart';
import 'dart:io';
import '../provider/extracted_screen_provider.dart';
import '../provider/search_provider.dart';
import '../provider/page_index_provider.dart';
import '../provider/page_controller_provider.dart';

class ExtractedScreen extends ConsumerStatefulWidget {
  const ExtractedScreen({super.key});

  @override
  ConsumerState<ExtractedScreen> createState() => _ExtractedScreenState();
}

class _ExtractedScreenState extends ConsumerState<ExtractedScreen> {
  Directory? currentFolder;
  List<String> pathSegments = ['Extracted'];

  // ignore: unused_element
  void _updatePathSegments(FileSystemEntity folder) {
    if (folder is! Directory) return;

    final path = folder.path;
    final segments = path
        .replaceAll('/storage/emulated/0/QuickZip Extracted Files/', '')
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    setState(() {
      currentFolder = folder;
      pathSegments = ['Extracted', ...segments];
    });
  }

  // ignore: unused_element
  void _navigateBack() {
    setState(() {
      currentFolder = null;
      pathSegments = ['Extracted'];
    });
  }

  Future<bool> _handleBackNavigation() async {
    final extractedScreen = ref.read(extractedScreenProvider);
    if (extractedScreen.currentFolder != null) {
      // Get the parent folder path
      final currentPath = extractedScreen.currentFolder!.path;
      final parentPath = Directory(currentPath).parent.path;

      // Check if we're going back to root
      if (parentPath == '/storage/emulated/0/QuickZip Extracted Files') {
        ref.read(extractedScreenProvider.notifier).navigateBack();
      } else {
        // Navigate to parent folder
        ref
            .read(extractedScreenProvider.notifier)
            .navigateToFolder(Directory(parentPath));
      }
      ref.read(pageIndexProvider.notifier).state = 1;
      return false;
    }

    // If we're in the extracted tab but not in a folder, go back to compressed tab
    final currentIndex = ref.read(pageIndexProvider);
    if (currentIndex != 0) {
      // Set the page index to 0 (Compressed)
      ref.read(pageIndexProvider.notifier).state = 0;
      // Use the PageController to animate to the compressed tab
      ref.read(pageControllerProvider).animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
      return false;
    }
    return false; // Never allow direct app exit from here
  }

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(extractedFilesProvider);
    final extractedScreen = ref.watch(extractedScreenProvider);
    final searchQuery = ref.watch(extractedSearchQueryProvider);
    ref.watch(pageIndexProvider);

    return WillPopScope(
      onWillPop: _handleBackNavigation,
      child: files.when(
        data: (fileList) {
          if (extractedScreen.currentFolder != null) {
            return FutureBuilder<List<FileSystemEntity>>(
              future: ref
                  .read(fileServiceProvider)
                  .getFilesInExtractedFolder(extractedScreen.currentFolder!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Apply search filter to folder contents
                final filteredFiles =
                    ref.watch(filteredExtractedFilesProvider(snapshot.data!));

                return filteredFiles.isEmpty
                    ? Center(
                        child: Text(
                          searchQuery.isEmpty
                              ? 'Folder is empty'
                              : 'No matching files',
                          style: const TextStyle(color: AppTheme.primaryGrey),
                        ),
                      )
                    : FileList(
                        files: filteredFiles,
                        isCompressed: false,
                        onFolderTap: (folder) {
                          if (folder is Directory) {
                            // Clear search when navigating to maintain folder view
                            ref
                                .read(extractedSearchQueryProvider.notifier)
                                .state = '';
                            ref
                                .read(extractedScreenProvider.notifier)
                                .navigateToFolder(folder);
                            ref.read(pageIndexProvider.notifier).state = 1;
                          }
                        },
                      );
              },
            );
          }

          // Apply search filter to root files
          final filteredFiles =
              ref.watch(filteredExtractedFilesProvider(fileList));
          return filteredFiles.isEmpty
              ? Center(
                  child: Text(
                    searchQuery.isEmpty
                        ? 'No files found'
                        : 'No matching files',
                    style: const TextStyle(color: AppTheme.primaryGrey),
                  ),
                )
              : FileList(
                  files: filteredFiles,
                  isCompressed: false,
                  onFolderTap: (folder) {
                    if (folder is Directory) {
                      // Clear search when navigating to maintain folder view
                      ref.read(extractedSearchQueryProvider.notifier).state =
                          '';
                      ref
                          .read(extractedScreenProvider.notifier)
                          .navigateToFolder(folder);
                      ref.read(pageIndexProvider.notifier).state = 1;
                    }
                  },
                );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
