import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../core/widgets/loading_indicator.dart';
import '../../library/providers/library_provider.dart';

class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({
    super.key,
    required this.documentId,
    this.initialPage = 1,
  });

  final int documentId;
  final int initialPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We need to fetch the document path first
    final documentAsync = ref.watch(documentByIdProvider(documentId));

    return Scaffold(
      appBar: AppBar(
        title: documentAsync.when(
          data: (doc) => Text(doc?.title ?? 'Reader'),
          loading: () => const Text('Reader'),
          error: (_, __) => const Text('Reader'),
        ),
      ),
      body: documentAsync.when(
        data: (document) {
          if (document == null) {
            return const Center(child: Text('Document not found'));
          }
          return SfPdfViewer.file(
            File(document.filePath),
            controller: PdfViewerController(),
            // note: syncfusion_flutter_pdfviewer might not support initialPage in this version
            // or it might be done via controller.jumpToPage in onDocumentLoaded
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
               if (initialPage > 1) {
                  // TODO: Implement jump to page if needed
               }
            },
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
