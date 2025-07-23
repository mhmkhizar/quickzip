import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/show_custom_snackbar.dart';
import 'extractionscreen.dart';

class ExtractionDialog extends ConsumerStatefulWidget {
  final bool requiresAd;
  final Function(String? password, ValueNotifier<double> progressNotifier)
      onExtract;
  final int fileSize;
  final String fileName;
  final bool isPasswordProtected;

  const ExtractionDialog({
    super.key,
    required this.requiresAd,
    required this.onExtract,
    required this.fileSize,
    required this.fileName,
    required this.isPasswordProtected,
  });

  @override
  ConsumerState<ExtractionDialog> createState() => _ExtractionDialogState();
}

class _ExtractionDialogState extends ConsumerState<ExtractionDialog> {
  final progressNotifier = ValueNotifier(0.0);
  final passwordController = TextEditingController();
  final extractionCompleter = Completer<void>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleExtraction();
    });
  }

  Future<void> handleExtraction() async {
    if (widget.isPasswordProtected && passwordController.text.isEmpty) {
      showCustomSnackBar(context, 'Please enter the password');
      return;
    }

    // Pop the current dialog
    if (mounted) {
      Navigator.of(context).pop();
    }

    // Show extraction screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExtractionScreen(
          fileName: widget.fileName,
          progressNotifier: progressNotifier,
          extractionCompleter: extractionCompleter,
        ),
      ),
    );

    // Add 5-second delay before starting extraction
    await Future.delayed(const Duration(seconds: 5));

    // Reset progress to 0 before starting extraction
    progressNotifier.value = 0.0;

    // Start the actual extraction process
    try {
      await widget.onExtract(
        widget.isPasswordProtected ? passwordController.text : null,
        progressNotifier,
      );

      // Wait for extraction to fully complete
      await extractionCompleter.future;
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(context, 'Error during extraction: $e');
      }
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // No UI, just handles logic
  }
}
