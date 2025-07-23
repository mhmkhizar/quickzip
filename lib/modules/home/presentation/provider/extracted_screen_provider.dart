import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExtractedScreenState {
  final Directory? currentFolder;
  final List<String> pathSegments;

  ExtractedScreenState({
    this.currentFolder,
    this.pathSegments = const ['Extracted'],
  });
}

class ExtractedScreenNotifier extends StateNotifier<ExtractedScreenState> {
  ExtractedScreenNotifier() : super(ExtractedScreenState());

  void navigateToFolder(Directory folder) {
    final path = folder.path;
    final segments = path
        .replaceAll('/storage/emulated/0/QuickZip Extracted Files/', '')
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    state = ExtractedScreenState(
      currentFolder: folder,
      pathSegments: ['Extracted', ...segments],
    );
  }

  void navigateBack() {
    state = ExtractedScreenState();
  }
}

final extractedScreenProvider =
    StateNotifierProvider<ExtractedScreenNotifier, ExtractedScreenState>(
        (ref) => ExtractedScreenNotifier());
