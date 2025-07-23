import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/file_service.dart';

final compressedFilesProvider =
    FutureProvider<List<FileSystemEntity>>((ref) async {
  final fileService = ref.watch(fileServiceProvider);
  return await fileService.getCompressedFiles();
});

final extractedFilesProvider =
    FutureProvider<List<FileSystemEntity>>((ref) async {
  final fileService = ref.watch(fileServiceProvider);
  return await fileService.getExtractedFiles();
});
