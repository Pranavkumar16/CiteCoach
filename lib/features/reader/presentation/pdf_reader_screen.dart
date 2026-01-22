import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../core/constants/constants.dart';
import '../../../core/widgets/widgets.dart';
import '../../../routing/app_router.dart';
import '../../library/providers/library_provider.dart';
import '../../setup/providers/setup_provider.dart';

/// Offline PDF reader with page navigation and chat entry point.
class PdfReaderScreen extends ConsumerStatefulWidget {
  const PdfReaderScreen({
    super.key,
    required this.documentId,
    this.initialPage,
    this.highlightText,
    this.fromChat = false,
  });

  final int documentId;
  final int? initialPage;
  final String? highlightText;
  final bool fromChat;

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  final PdfViewerController _controller = PdfViewerController();
  PdfTextSearchResult? _searchResult;

  int _currentPage = 1;
  int _pageCount = 0;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage ?? 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _pageCount = details.document.pages.count;
      _loadError = null;
    });

    final initialPage = widget.initialPage ?? 1;
    if (initialPage > 1) {
      _controller.jumpToPage(initialPage);
    }

    _highlightCitation();
  }

  void _handleDocumentLoadFailed(PdfDocumentLoadFailedDetails details) {
    setState(() {
      _loadError = details.error;
    });
  }

  void _handlePageChanged(PdfPageChangedDetails details) {
    setState(() {
      _currentPage = details.newPageNumber;
    });
  }

  void _highlightCitation() {
    final text = widget.highlightText?.trim();
    if (text == null || text.isEmpty) return;

    final result = _controller.searchText(text);
    if (result.hasResult) {
      result.nextInstance();
      setState(() {
        _searchResult = result;
      });
    }
  }

  void _goToPage(int page) {
    if (page < 1 || (_pageCount > 0 && page > _pageCount)) return;
    _controller.jumpToPage(page);
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(setupProvider);
    final documentAsync = ref.watch(documentByIdProvider(widget.documentId));

    return documentAsync.when(
      data: (document) {
        if (document == null) {
          return _buildErrorScaffold(context, AppStrings.errorPdfLoad);
        }

        if (_loadError != null) {
          return _buildErrorScaffold(context, _loadError!);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              document.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (_searchResult != null && _searchResult!.hasResult)
                IconButton(
                  tooltip: 'Next match',
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchResult?.nextInstance(),
                ),
            ],
          ),
          body: Column(
            children: [
              if (widget.fromChat) _buildFromChatBanner(context),
              Expanded(
                child: SfPdfViewer.file(
                  File(document.filePath),
                  controller: _controller,
                  onDocumentLoaded: _handleDocumentLoaded,
                  onDocumentLoadFailed: _handleDocumentLoadFailed,
                  onPageChanged: _handlePageChanged,
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: Icon(
              setupState.canUseChat
                  ? Icons.chat_bubble_outline_rounded
                  : Icons.lock_outline_rounded,
            ),
            label: Text(
              setupState.canUseChat ? AppStrings.chat : AppStrings.downloadNow,
            ),
            onPressed: () {
              if (setupState.canUseChat) {
                context.goToChat(widget.documentId.toString());
              } else {
                context.go(AppRoutes.downloadRequired);
              }
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: _buildPageControls(context),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: LoadingIndicator(useGradient: true)),
      ),
      error: (_, __) => _buildErrorScaffold(context, AppStrings.errorPdfLoad),
    );
  }

  Widget _buildFromChatBanner(BuildContext context) {
    final pageLabel = widget.initialPage ?? _currentPage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm,
      ),
      color: AppColors.primaryIndigo.withOpacity(0.08),
      child: Row(
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 16,
            color: AppColors.primaryIndigo,
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Text(
              '${AppStrings.fromChatAnswer} p.$pageLabel',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryIndigo,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          TextButton(
            onPressed: () => context.goToChat(widget.documentId.toString()),
            child: const Text('Back to chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildPageControls(BuildContext context) {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSm,
          vertical: AppDimensions.spacingXs,
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            ),
            Expanded(
              child: Text(
                _pageLabel(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: _pageCount > 0 && _currentPage < _pageCount
                  ? () => _goToPage(_currentPage + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _pageLabel() {
    if (_pageCount == 0) {
      return 'Page $_currentPage';
    }

    return AppStrings.pageOf
        .replaceFirst('{current}', _currentPage.toString())
        .replaceFirst('{total}', _pageCount.toString());
  }

  Widget _buildErrorScaffold(BuildContext context, String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reader'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: AppDimensions.iconSizeXxl,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              SecondaryButton(
                text: AppStrings.backToLibrary,
                onPressed: () => context.go(AppRoutes.library),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
