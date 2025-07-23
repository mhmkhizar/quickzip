import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectionState {
  final Set<String> selectedFiles;
  final bool isSelectionMode;

  const SelectionState({
    this.selectedFiles = const {},
    this.isSelectionMode = false,
  });

  SelectionState copyWith({
    Set<String>? selectedFiles,
    bool? isSelectionMode,
  }) {
    return SelectionState(
      selectedFiles: selectedFiles ?? this.selectedFiles,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }
}

final selectionStateProvider =
    StateNotifierProvider<SelectionNotifier, SelectionState>((ref) {
  return SelectionNotifier();
});

class SelectionNotifier extends StateNotifier<SelectionState> {
  SelectionNotifier() : super(const SelectionState());

  void toggleSelection(String path) {
    if (state.selectedFiles.contains(path)) {
      final newSelected = Set<String>.from(state.selectedFiles)..remove(path);
      state = state.copyWith(
        selectedFiles: newSelected,
        isSelectionMode: newSelected.isNotEmpty,
      );
    } else {
      state = state.copyWith(
        selectedFiles: {...state.selectedFiles, path},
        isSelectionMode: true,
      );
    }
  }

  void startSelection(String path) {
    state = state.copyWith(
      selectedFiles: {path},
      isSelectionMode: true,
    );
  }

  void clearSelection() {
    state = const SelectionState();
  }
}
