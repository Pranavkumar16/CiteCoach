import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../core/widgets/loading_indicator.dart';
import '../../library/providers/library_provider.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.documentId,
    this.initialPage = 1,
  });

  final int documentId;
  final int initialPage;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final PdfViewerController _pdfViewerController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  Widget build(BuildContext context) {
    // We need to fetch the document path first
    final documentAsync = ref.watch(documentByIdProvider(widget.documentId));

    return Scaffold(
      appBar: AppBar(
        title: documentAsync.when(
          data: (doc) => Text(doc?.title ?? 'Reader'),
          loading: () => const Text('Reader'),
          error: (_, __) => const Text('Reader'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement menu
            },
          ),
        ],
      ),
      body: documentAsync.when(
        data: (document) {
          if (document == null) {
            return const Center(child: Text('Document not found'));
          }
          return SfPdfViewer.file(
            File(document.filePath),
            key: _pdfViewerKey,
            controller: _pdfViewerController,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              if (widget.initialPage > 1) {
                // Jump to the initial page if specified
                // Note: jumpToPage is 1-based index in the UI but API might expect 1-based too.
                // Syncfusion PdfViewerController.jumpToPage takes a 1-based page number.
                _pdfViewerController.jumpToPage(widget.initialPage);
              }
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Failed to load PDF: ${details.error}')),
               );
            },
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
