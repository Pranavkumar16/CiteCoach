import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/constants.dart';
import '../../../core/widgets/widgets.dart';
import '../../../routing/app_router.dart';
import '../domain/document.dart';
import '../providers/library_provider.dart';
import 'widgets/document_card.dart';
import 'widgets/empty_library_view.dart';

/// Main library screen showing all documents.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh library when screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryProvider);

    // Show error snackbar if import failed
    ref.listen<LibraryState>(libraryProvider, (previous, next) {
      if (next.importError != null && previous?.importError != next.importError) {
        _showErrorSnackBar(next.importError!);
        ref.read(libraryProvider.notifier).clearImportError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, state),
            Expanded(
              child: _buildContent(context, state),
            ),
          ],
        ),
      ),
      floatingActionButton: state.documents.isNotEmpty
          ? _buildFAB(context, state)
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, LibraryState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingMd,
        AppDimensions.spacingLg,
        AppDimensions.spacingMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.libraryTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              if (state.documents.isNotEmpty)
                Text(
                  '${state.documentCount} document${state.documentCount == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
            ],
          ),
          if (state.documents.isNotEmpty) _buildSortButton(context, state),
        ],
      ),
    );
  }

  Widget _buildSortButton(BuildContext context, LibraryState state) {
    return PopupMenuButton<DocumentSortOption>(
      icon: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingSm),
        decoration: BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sort_rounded,
              size: AppDimensions.iconSizeSm,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppDimensions.spacingXs),
            Text(
              'Sort',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
      initialValue: state.sortOption,
      onSelected: (option) {
        ref.read(libraryProvider.notifier).setSortOption(option);
      },
      itemBuilder: (context) => DocumentSortOption.values.map((option) {
        return PopupMenuItem(
          value: option,
          child: Row(
            children: [
              if (option == state.sortOption)
                const Icon(
                  Icons.check_rounded,
                  size: AppDimensions.iconSizeSm,
                  color: AppColors.primaryIndigo,
                )
              else
                const SizedBox(width: AppDimensions.iconSizeSm),
              const SizedBox(width: AppDimensions.spacingSm),
              Text(option.label),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContent(BuildContext context, LibraryState state) {
    if (state.isLoading && state.documents.isEmpty) {
      return const Center(
        child: LoadingIndicator(),
      );
    }

    if (state.hasError && state.documents.isEmpty) {
      return _buildErrorView(context, state);
    }

    if (state.isEmpty) {
      return EmptyLibraryView(
        onImportPressed: _importPdf,
        isImporting: state.isImporting,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(libraryProvider.notifier).refresh(),
      color: AppColors.primaryIndigo,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: AppDimensions.spacingSm,
          bottom: AppDimensions.spacing4xl + AppDimensions.fabSize,
        ),
        itemCount: state.documents.length,
        itemBuilder: (context, index) {
          final document = state.documents[index];
          return DocumentCard(
            document: document,
            onTap: () => _onDocumentTap(document),
            onChatTap: document.isReady
                ? () => _onChatTap(document)
                : null,
            onReadTap: document.isReady
                ? () => _onReadTap(document)
                : null,
            onDeleteTap: () => _onDeleteTap(document),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, LibraryState state) {
    return Center(
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
              state.error ?? 'Something went wrong',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            GradientButton(
              text: AppStrings.retry,
              onPressed: () => ref.read(libraryProvider.notifier).refresh(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context, LibraryState state) {
    return FloatingActionButton.extended(
      onPressed: state.isImporting ? null : _importPdf,
      backgroundColor: AppColors.primaryIndigo,
      foregroundColor: AppColors.white,
      icon: state.isImporting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.white,
              ),
            )
          : const Icon(Icons.add_rounded),
      label: Text(
        state.isImporting ? 'Importing...' : 'Import PDF',
      ),
    );
  }

  Future<void> _importPdf() async {
    final document = await ref.read(libraryProvider.notifier).importPdf();
    if (document != null && mounted) {
      // Navigate to processing screen
      context.goToProcessing(document.id.toString());
    }
  }

  void _onDocumentTap(Document document) {
    if (document.isReady) {
      _onChatTap(document);
    } else if (document.isPending || document.hasError) {
      context.goToProcessing(document.id.toString());
    }
  }

  void _onChatTap(Document document) {
    ref.read(libraryProvider.notifier).markDocumentOpened(document.id);
    context.goToChat(document.id.toString());
  }

  void _onReadTap(Document document) {
    ref.read(libraryProvider.notifier).markDocumentOpened(document.id);
    context.goToReader(document.id.toString());
  }

  void _onDeleteTap(Document document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(libraryProvider.notifier).deleteDocument(document.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: AppColors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
