import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import '../../../../core/services/ads_manager.dart';
import '../../../../core/services/file_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../provider/file_provider.dart';
import 'extracting_dialog.dart';
import 'archive_extractor_dialog.dart';
import '../provider/selection_provider.dart';
import '../provider/page_index_provider.dart';
import '../../../../core/utils/show_custom_snackbar.dart';

class FileList extends ConsumerWidget {
  final List<FileSystemEntity> files;
  final bool isCompressed;
  final Function(FileSystemEntity)? onFolderTap;

  const FileList({
    super.key,
    required this.files,
    required this.isCompressed,
    this.onFolderTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(selectionStateProvider);

    return files.isEmpty
        ? ListView(
            physics: const ClampingScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: const Center(
                  child: Text(
                    'No files found',
                    style: TextStyle(
                        color: AppTheme.primaryGrey,
                        fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ],
          )
        : ListView.builder(
            physics: const ClampingScrollPhysics(),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final fileName = file.path.split('/').last;
              final fileSize = file is File
                  ? (file.existsSync()
                      ? (file.lengthSync() / 1024 / 1024).toStringAsFixed(2)
                      : "0.00")
                  : '';

              // Check if file exists before trying to get last modified date
              DateTime lastModified;
              try {
                lastModified = file.existsSync()
                    ? file.statSync().modified
                    : DateTime.now();
              } catch (e) {
                // Use current time if file doesn't exist or can't be accessed
                lastModified = DateTime.now();
              }

              final formattedDate =
                  '${lastModified.day} ${_getMonth(lastModified.month)} ${lastModified.year}';
              debugPrint('fileSize: $fileSize');
              return ListTile(
                dense: true,
                selected: selectionState.selectedFiles.contains(file.path),
                selectedTileColor: Colors.green.withOpacity(0.2),
                minLeadingWidth: 40,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: Icon(
                  _getFileIcon(file),
                  color: AppTheme.primaryGreen,
                  size: 37,
                ),
                title: Text(
                  fileName.length > 30
                      ? '${fileName.substring(0, 30)}...'
                      : fileName,
                  style: const TextStyle(
                      color: AppTheme.primaryWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  file is File
                      ? '$formattedDate - ${fileSize}MB'
                      : formattedDate,
                  style: const TextStyle(
                      color: AppTheme.hintText, fontWeight: FontWeight.w300),
                ),
                trailing: SizedBox(
                  width: 40, // Adjust button width
                  height: 40, // Adjust button height
                  child: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppTheme.primaryWhite,
                      size: 22,
                    ),
                    color: const Color(0xff1d1d1d),
                    offset: const Offset(-10, 35), // Adjust dropdown position
                    padding: EdgeInsets.zero,
                    iconSize: 24,
                    splashRadius: 20,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8), // Add rounded corners
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'open':
                          if (file is Directory && onFolderTap != null) {
                            onFolderTap!(file);
                          } else {
                            _openFile(context, file.path);
                          }
                          break;
                        case 'extract':
                          if (file is File) {
                            _extractFile(context, ref, file);
                          }
                          break;
                        case 'delete':
                          _handleDelete(context, file, ref);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (!isCompressed) // Show only for extracted screen
                        PopupMenuItem(
                          height: 35, // Reduce height
                          value: 'open',
                          child: Text(
                            file is Directory ? 'Open' : 'Open',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                      if (isCompressed && file is File)
                        const PopupMenuItem(
                          height: 35, // Reduce height
                          value: 'extract',
                          child: Text(
                            'Extract',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      const PopupMenuItem(
                        height: 35, // Reduce height
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: selectionState.isSelectionMode
                    ? () => ref
                        .read(selectionStateProvider.notifier)
                        .toggleSelection(file.path)
                    : () {
                        if (file is Directory && onFolderTap != null) {
                          onFolderTap!(file);
                          ref.read(pageIndexProvider.notifier).state = 0;
                        } else if (isCompressed && file is File) {
                          _extractFile(context, ref, file);
                        } else {
                          _openFile(context, file.path);
                        }
                      },
                onLongPress: () {
                  if (!selectionState.isSelectionMode) {
                    ref
                        .read(selectionStateProvider.notifier)
                        .startSelection(file.path);
                  } else {
                    ref
                        .read(selectionStateProvider.notifier)
                        .toggleSelection(file.path);
                  }
                },
              );
            },
          );
  }

  IconData _getFileIcon(FileSystemEntity file) {
    if (file is Directory) {
      // Use different icons for compressed and extracted screens
      return isCompressed ? Icons.folder : Icons.folder_outlined;
    }

    final extension = file.path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_outlined;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Icons.movie_outlined;
      case 'mp3':
      case 'wav':
        return Icons.audiotrack;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'txt':
      case 'docx':
        return Icons.text_snippet_outlined;
      case 'zip':
      case 'rar':
      case 'tar':
        return Icons.folder_zip_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  void _extractFile(BuildContext context, WidgetRef ref, File file) async {
    final fileService = ref.read(fileServiceProvider);
    final isPasswordProtected = await fileService.isPasswordProtected(file);
    final fileName = file.path.split('/').last;
    final isTomitoFile = fileName.toLowerCase().contains('tomito+');
    final fileSize =
        (await file.length() / 1024).ceil(); // Calculate file size here

    if (!context.mounted) return;

    // Show password dialog if needed
    final shouldExtract = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ArchiveExtractorDialog(
        filePath: file.path,
        fileName: fileName,
        requiresAd: isTomitoFile,
        isPasswordProtected: isPasswordProtected,
        onExtract: (String? password) async {
          try {
            if (isTomitoFile) {
              final adsManager = ref.read(adsManagerProvider);

              // Dispose any existing interstitial ad to ensure clean state
              // (We'll load a new one during extraction screen initialization)
              adsManager.disposeInterstitialAd();

              // Load the rewarded ad to show at the beginning
              await adsManager.loadRewardedAd();

              if (!context.mounted) return false;

              // Show extraction dialog first
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => ExtractionDialog(
                  requiresAd: false,
                  onExtract: (String? extractPassword,
                      ValueNotifier<double> progress) async {
                    try {
                      await fileService.extractFile(
                        file,
                        password: extractPassword ?? password,
                        progressNotifier: progress,
                      );
                      if (context.mounted) {
                        showCustomSnackBar(
                            context, 'File extracted successfully');
                        // ignore: unused_result
                        ref.refresh(extractedFilesProvider);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error extracting file: $e'),
                          ),
                        );
                      }
                      rethrow;
                    }
                  },
                  fileSize: fileSize,
                  fileName: fileName,
                  isPasswordProtected: false,
                ),
              );

              // Then show rewarded ad
              final bool adShown = await adsManager.showRewardedAd(
                onRewardEarned: () {
                  // Close the password dialog when reward is earned
                  Navigator.pop(context);
                  // Extraction is already running in background
                },
              );

              if (!adShown) {
                if (context.mounted) {
                  // Close extraction dialog if ad fails to show
                  Navigator.pop(context);
                  showCustomSnackBar(
                      context, "Ad failed to load please try again");
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   const SnackBar(
                  //     content:
                  //         Text('Please watch the ad to extract Tomito+ files'),
                  //   ),
                  // );
                }
                return false;
              }
            } else {
              _showExtractionDialog(context, ref, file, password);
            }
            return true;
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error extracting file: $e')),
              );
            }
            return false;
          }
        },
      ),
    );

    if (shouldExtract != true) return;
  }

  void _showExtractionDialog(
      BuildContext context, WidgetRef ref, File file, String? password) async {
    final fileService = ref.read(fileServiceProvider);
    final fileSize = await file.length();
    final formattedFileSize = (fileSize / 1024).ceil();
    final fileName = file.path.split('/').last;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExtractionDialog(
        requiresAd: true,
        onExtract:
            (String? extractPassword, ValueNotifier<double> progress) async {
          try {
            await fileService.extractFile(
              file,
              password: extractPassword ?? password,
              progressNotifier: progress,
            );
            if (context.mounted) {
              showCustomSnackBar(context, 'File extracted successfully');
            }
            // ignore: unused_result
            ref.refresh(extractedFilesProvider);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error extracting file: $e')),
              );
            }
            rethrow;
          }
        },
        fileSize: formattedFileSize,
        fileName: fileName,
        isPasswordProtected:
            false, // We handle password in a separate dialog now
      ),
    );
  }

  Future<void> _openFile(BuildContext context, String filePath) async {
    try {
      // Handle MKV files specifically
      if (filePath.toLowerCase().endsWith('.mkv')) {
        // Use specific type for MKV files to limit options to video players
        final result = await OpenFile.open(
          filePath,
          type: "video/x-matroska", // Specific MIME type for MKV files
        );
        if (result.type != ResultType.done) {
          if (context.mounted) {
            showCustomSnackBar(
                context, 'Could not open MKV file: ${result.message}');
          }
        }
      } else {
        // Handle all other file types as before
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done) {
          if (context.mounted) {
            showCustomSnackBar(
                context, 'Could not open file: ${result.message}');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        showCustomSnackBar(context, 'Error opening file: $e');
      }
    }
  }

  Future<void> _handleDelete(
      BuildContext context, FileSystemEntity entity, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: AppTheme.primaryBlack,
        title: Text(
          'Delete ${entity is Directory ? 'Folder' : 'File'}',
          style: const TextStyle(
              color: AppTheme.primaryWhite, fontWeight: FontWeight.w500),
        ),
        content: Text(
          'Are you sure you want to delete "${entity.path.split('/').last}"?',
          style: const TextStyle(
              color: AppTheme.primaryWhite, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                  color: AppTheme.lightWhite, fontWeight: FontWeight.w400),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                  color: AppTheme.primaryGreen, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true && context.mounted) {
      try {
        if (entity.existsSync()) {
          if (entity is Directory) {
            await entity.delete(recursive: true);
          } else if (entity is File) {
            await entity.delete();
          }

          if (context.mounted) {
            showCustomSnackBar(context, 'Items deleted successfully');

            // Refresh the appropriate file list based on tab
            if (isCompressed) {
              // ignore: unused_result
              ref.refresh(compressedFilesProvider);
            } else {
              // ignore: unused_result
              ref.refresh(extractedFilesProvider);
            }
          }
        } else {
          if (context.mounted) {
            showCustomSnackBar(context, 'Item no longer exists');
          }
          // Refresh list anyway to update UI
          if (isCompressed) {
            // ignore: unused_result
            ref.refresh(compressedFilesProvider);
          } else {
            // ignore: unused_result
            ref.refresh(extractedFilesProvider);
          }
        }
      } catch (e) {
        if (context.mounted) {
          showCustomSnackBar(context, 'Error deleting items: $e');
        }
      }
    }
  }
}
