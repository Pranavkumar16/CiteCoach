import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../library/providers/library_provider.dart';

/// PDF Reader screen with navigation and chat FAB.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.documentId,
    this.initialPage,
    this.highlightText,
  });

  /// Document ID to display.
  final int documentId;

  /// Initial page to navigate to.
  final int? initialPage;

  /// Text to highlight (from citation).
  final String? highlightText;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late PdfViewerController _pdfController;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _errorMessage;
  String? _documentTitle;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final libraryNotifier = ref.read(libraryProvider.notifier);
      final document = await libraryNotifier.getDocument(widget.documentId);

      if (document == null) {
        setState(() {
          _errorMessage = 'Document not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _documentTitle = document.title;
        _filePath = document.filePath;
        _totalPages = document.pageCount;
        _isLoading = false;
      });

      // Navigate to initial page if specified
      if (widget.initialPage != null && widget.initialPage! > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pdfController.jumpToPage(widget.initialPage!);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load document: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate200,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _documentTitle ?? 'Document',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'goto',
                child: Row(
                  children: [
                    Icon(Icons.bookmark_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Go to Page'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _buildChatFab(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryIndigo,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filePath == null) {
      return const Center(
        child: Text('No file path available'),
      );
    }

    return SfPdfViewer.file(
      File(_filePath!),
      controller: _pdfController,
      onPageChanged: (PdfPageChangedDetails details) {
        setState(() {
          _currentPage = details.newPageNumber;
        });
      },
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        setState(() {
          _totalPages = details.document.pages.count;
          if (widget.initialPage != null) {
            _currentPage = widget.initialPage!;
          }
        });
      },
      canShowScrollHead: true,
      canShowPaginationDialog: false,
      pageSpacing: 8,
    );
  }

  Widget _buildChatFab() {
    if (_isLoading || _errorMessage != null) return const SizedBox.shrink();

    return FloatingActionButton(
      onPressed: () {
        context.push('/document/${widget.documentId}/chat');
      },
      backgroundColor: AppColors.primaryIndigo,
      child: const Icon(
        Icons.chat_bubble_outline,
        color: Colors.white,
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_isLoading || _errorMessage != null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _currentPage > 1
                  ? () => _pdfController.previousPage()
                  : null,
              color: AppColors.primaryIndigo,
              disabledColor: AppColors.textTertiary,
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingMd,
                vertical: AppDimensions.spacingSm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              child: Text(
                'Page $_currentPage of $_totalPages',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _currentPage < _totalPages
                  ? () => _pdfController.nextPage()
                  : null,
              color: AppColors.primaryIndigo,
              disabledColor: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _SearchDialog(
        controller: _pdfController,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'goto':
        _showGoToPageDialog();
        break;
    }
  }

  void _showGoToPageDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1-$_totalPages',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                _pdfController.jumpToPage(page);
                Navigator.pop(context);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }
}

/// Search dialog for PDF text search.
class _SearchDialog extends StatefulWidget {
  const _SearchDialog({required this.controller});

  final PdfViewerController controller;

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final _searchController = TextEditingController();
  PdfTextSearchResult? _searchResult;

  @override
  void dispose() {
    _searchController.dispose();
    _searchResult?.clear();
    super.dispose();
  }

  void _search() {
    if (_searchController.text.isNotEmpty) {
      _searchResult = widget.controller.searchText(_searchController.text);
      _searchResult!.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _searchResult != null && _searchResult!.totalInstanceCount > 0;

    return AlertDialog(
      title: const Text('Search'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search text...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) => _search(),
            autofocus: true,
          ),
          if (hasResults) ...[
            const SizedBox(height: 16),
            Text(
              'Found ${_searchResult!.totalInstanceCount} results',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: () => _searchResult?.previousInstance(),
                ),
                Text('${_searchResult!.currentInstanceIndex} / ${_searchResult!.totalInstanceCount}'),
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  onPressed: () => _searchResult?.nextInstance(),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _searchResult?.clear();
            Navigator.pop(context);
          },
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: _search,
          child: const Text('Search'),
        ),
      ],
    );
  }
}
