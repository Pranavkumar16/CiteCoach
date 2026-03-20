import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../core/constants/constants.dart';
import '../../../routing/app_router.dart';
import '../../library/domain/document.dart';
import '../../library/providers/library_provider.dart';

/// Full PDF reader with citation navigation support.
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
  late PdfViewerController _pdfController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoaded = false;
  bool _showControls = true;
  PdfTextSearchResult? _searchResult;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    _searchController.dispose();
    _searchResult?.dispose();
    super.dispose();
  }

  void _jumpToPage(int page) {
    _pdfController.jumpToPage(page);
    setState(() => _currentPage = page);
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchResult?.clear();
        _searchController.clear();
      }
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      _searchResult?.clear();
      return;
    }
    _searchResult = _pdfController.searchText(query);
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
      backgroundColor: AppColors.zinc900,
      body: SafeArea(
        child: Stack(
          children: [
            // PDF Viewer
            GestureDetector(
              onTap: () => setState(() => _showControls = !_showControls),
              child: SfPdfViewer.file(
                file,
                key: _pdfViewerKey,
                controller: _pdfController,
                canShowScrollHead: true,
                canShowScrollStatus: true,
                enableDoubleTapZooming: true,
                enableTextSelection: true,
                pageSpacing: 4,
                onDocumentLoaded: (details) {
                  setState(() {
                    _totalPages = details.document.pages.count;
                    _isLoaded = true;
                  });
                  // Jump to initial page if specified (e.g. from citation tap)
                  if (widget.initialPage != null && widget.initialPage! > 0) {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _jumpToPage(widget.initialPage!);
                    });
                  }
                },
                onPageChanged: (details) {
                  setState(() {
                    _currentPage = details.newPageNumber;
                  });
                },
                onDocumentLoadFailed: (details) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to load PDF: ${details.description}'),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                },
              ),
            ),

            // Top toolbar
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(context, document),
              ),

            // Search bar
            if (_isSearching)
              Positioned(
                top: 56,
                left: 0,
                right: 0,
                child: _buildSearchBar(),
              ),

            // Bottom toolbar
            if (_showControls && _isLoaded)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(context, document),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Document document) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.zinc900.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    document.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_isLoaded)
                    Text(
                      'Page $_currentPage of $_totalPages',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: 'Chat about this document',
              onPressed: () {
                context.push(
                    '/document/${widget.documentId}/chat');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.zinc800,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search in document...',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          const SizedBox(width: 8),
          if (_searchResult != null && _searchResult!.hasResult) ...[
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up, size: 20),
              onPressed: () => _searchResult?.previousInstance(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              onPressed: () => _searchResult?.nextInstance(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: _toggleSearch,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Document document) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.zinc900.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page navigation
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: _currentPage > 1 ? () => _jumpToPage(1) : null,
                iconSize: 20,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1
                    ? () => _jumpToPage(_currentPage - 1)
                    : null,
                iconSize: 20,
              ),
              // Page input
              GestureDetector(
                onTap: () => _showPageJumpDialog(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$_currentPage / $_totalPages',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages
                    ? () => _jumpToPage(_currentPage + 1)
                    : null,
                iconSize: 20,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPage < _totalPages
                    ? () => _jumpToPage(_totalPages)
                    : null,
                iconSize: 20,
              ),
            ],
          ),
          // Zoom controls
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_out, size: 20),
                onPressed: () {
                  final zoom = _pdfController.zoomLevel;
                  if (zoom > 1.0) _pdfController.zoomLevel = zoom - 0.25;
                },
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in, size: 20),
                onPressed: () {
                  final zoom = _pdfController.zoomLevel;
                  if (zoom < 3.0) _pdfController.zoomLevel = zoom + 0.25;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPageJumpDialog(BuildContext context) {
    final controller = TextEditingController(text: '$_currentPage');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '1 - $_totalPages',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                _jumpToPage(page);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }
}
