import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';

import '../../../core/constants/constants.dart';
import '../../../routing/app_router.dart';
import '../../library/domain/document.dart';
import '../../library/providers/library_provider.dart';

/// PDF Reader screen with page navigation and citation support.
///
/// Features:
/// - Full PDF viewing with pinch-to-zoom
/// - Page indicator and navigation
/// - Jump to specific page (for citation click-through)
/// - Open chat from reader
/// - Bookmark last read page
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.documentId,
    this.initialPage,
  });

  final int documentId;
  final int? initialPage;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final PdfViewerController _pdfController;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _currentPage = widget.initialPage ?? 1;
  }

  @override
  void dispose() {
    _pdfController.dispose();
    // Save last read page
    _saveReadProgress();
    super.dispose();
  }

  void _saveReadProgress() {
    ref.read(libraryProvider.notifier).updateLastReadPage(
          widget.documentId,
          _currentPage,
        );
  }

  void _jumpToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _pdfController.jumpToPage(page);
    }
  }

  void _showPagePicker() {
    final controller = TextEditingController(text: _currentPage.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '1 - $_totalPages',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final page = int.tryParse(value);
            if (page != null) {
              _jumpToPage(page);
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null) {
                _jumpToPage(page);
              }
              Navigator.pop(context);
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final document = libraryState.documents
        .where((d) => d.id == widget.documentId)
        .firstOrNull;

    if (document == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reader')),
        body: const Center(child: Text('Document not found')),
      );
    }

    final file = File(document.filePath);

    return Scaffold(
      appBar: _buildAppBar(document),
      body: Column(
        children: [
          // PDF Viewer
          Expanded(
            child: file.existsSync()
                ? SfPdfViewer.file(
                    file,
                    controller: _pdfController,
                    initialZoomLevel: 1.0,
                    pageSpacing: 4,
                    canShowScrollHead: true,
                    canShowPaginationDialog: false,
                    onDocumentLoaded: (details) {
                      setState(() {
                        _totalPages = details.document.pages.count;
                        _isLoading = false;
                      });
                      // Jump to initial page after loading
                      if (widget.initialPage != null &&
                          widget.initialPage! > 1) {
                        Future.delayed(
                          const Duration(milliseconds: 300),
                          () => _jumpToPage(widget.initialPage!),
                        );
                      }
                    },
                    onPageChanged: (details) {
                      setState(() {
                        _currentPage = details.newPageNumber;
                      });
                    },
                    onDocumentLoadFailed: (details) {
                      setState(() => _isLoading = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Failed to load PDF: ${details.error}'),
                            backgroundColor: AppColors.errorRed,
                          ),
                        );
                      }
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.errorRed),
                        const SizedBox(height: 16),
                        const Text('PDF file not found'),
                        const SizedBox(height: 8),
                        Text(
                          document.filePath,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),

          // Bottom page indicator bar
          if (!_isLoading && _totalPages > 0) _buildPageIndicator(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _saveReadProgress();
          context.push(AppRoutes.documentChat(widget.documentId.toString()));
        },
        backgroundColor: AppColors.primaryIndigo,
        child: const Icon(Icons.chat_rounded, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Document document) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _saveReadProgress();
          context.pop();
        },
      ),
      title: Text(
        document.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        // Page picker
        IconButton(
          icon: const Icon(Icons.find_in_page_rounded),
          tooltip: 'Go to page',
          onPressed: _totalPages > 0 ? _showPagePicker : null,
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      height: AppDimensions.pageIndicatorHeight,
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous page
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                _currentPage > 1 ? () => _jumpToPage(_currentPage - 1) : null,
          ),

          // Page indicator (tappable)
          GestureDetector(
            onTap: _showPagePicker,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingMd,
                vertical: AppDimensions.spacingXxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Text(
                'Page $_currentPage of $_totalPages',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // Next page
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages
                ? () => _jumpToPage(_currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
