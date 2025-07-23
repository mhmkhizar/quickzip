import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/file_list_tile.dart';
import '../provider/file_provider.dart';
import '../provider/search_provider.dart';

class CompressedScreen extends ConsumerWidget {
  const CompressedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compressedFiles = ref.watch(compressedFilesProvider);

    return compressedFiles.when(
      data: (files) {
        final filteredFiles = ref.watch(filteredCompressedFilesProvider(files));
        return filteredFiles.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No ZIP files found. If you have ZIP files in other locations, please move them to your Downloads folder to access them here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.primaryGrey),
                  ),
                ),
              )
            : RefreshIndicator(
                color: Colors.green,
                backgroundColor: const Color(0xff1d1d1d),
                onRefresh: () async {
                  // ignore: unused_result
                  await ref.refresh(compressedFilesProvider.future);
                },
                child: FileList(
                  files: filteredFiles,
                  isCompressed: true,
                ),
              );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        debugPrint('Error loading compressed files: $error');
        debugPrint('Stack trace: $stack');
        return Center(child: Text('Error: $error'));
      },
    );
  }
}
