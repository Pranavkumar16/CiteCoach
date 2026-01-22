import 'package:equatable/equatable.dart';

/// Represents the current state of document processing.
class ProcessingState extends Equatable {
  const ProcessingState({
    required this.documentId,
    required this.currentPhase,
    this.overallProgress = 0.0,
    this.stepProgress = 0.0,
    this.pageCount = 0,
    this.pagesProcessed = 0,
    this.chunksCreated = 0,
    this.errorMessage,
    this.isComplete = false,
  });

  /// The document being processed.
  final int documentId;

  /// Current processing phase.
  final ProcessingPhase currentPhase;

  /// Overall progress (0.0 to 1.0).
  final double overallProgress;

  /// Progress within the current step (0.0 to 1.0).
  final double stepProgress;

  /// Total number of pages in the document.
  final int pageCount;

  /// Number of pages processed so far.
  final int pagesProcessed;

  /// Number of chunks created.
  final int chunksCreated;

  /// Error message if processing failed.
  final String? errorMessage;

  /// Whether processing is complete.
  final bool isComplete;

  /// Check if there's an error.
  bool get hasError => errorMessage != null;

  /// Check if currently processing.
  bool get isProcessing =>
      !isComplete && !hasError && currentPhase != ProcessingPhase.idle;

  /// Get overall progress as percentage string.
  String get progressPercent => '${(overallProgress * 100).toInt()}%';

  /// Get step description.
  String get stepDescription => currentPhase.description;

  /// Create initial state.
  factory ProcessingState.initial(int documentId) {
    return ProcessingState(
      documentId: documentId,
      currentPhase: ProcessingPhase.idle,
    );
  }

  /// Create error state.
  factory ProcessingState.error(int documentId, String message) {
    return ProcessingState(
      documentId: documentId,
      currentPhase: ProcessingPhase.idle,
      errorMessage: message,
    );
  }

  /// Create completed state.
  factory ProcessingState.completed(int documentId, int pageCount, int chunks) {
    return ProcessingState(
      documentId: documentId,
      currentPhase: ProcessingPhase.complete,
      overallProgress: 1.0,
      stepProgress: 1.0,
      pageCount: pageCount,
      pagesProcessed: pageCount,
      chunksCreated: chunks,
      isComplete: true,
    );
  }

  /// Copy with updated fields.
  ProcessingState copyWith({
    int? documentId,
    ProcessingPhase? currentPhase,
    double? overallProgress,
    double? stepProgress,
    int? pageCount,
    int? pagesProcessed,
    int? chunksCreated,
    String? errorMessage,
    bool clearError = false,
    bool? isComplete,
  }) {
    return ProcessingState(
      documentId: documentId ?? this.documentId,
      currentPhase: currentPhase ?? this.currentPhase,
      overallProgress: overallProgress ?? this.overallProgress,
      stepProgress: stepProgress ?? this.stepProgress,
      pageCount: pageCount ?? this.pageCount,
      pagesProcessed: pagesProcessed ?? this.pagesProcessed,
      chunksCreated: chunksCreated ?? this.chunksCreated,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  List<Object?> get props => [
        documentId,
        currentPhase,
        overallProgress,
        stepProgress,
        pageCount,
        pagesProcessed,
        chunksCreated,
        errorMessage,
        isComplete,
      ];
}

/// Steps in the document processing pipeline.
enum ProcessingPhase {
  /// Not yet started.
  idle,

  /// Loading the PDF file.
  loading,

  /// Extracting text from pages.
  extractingText,

  /// Splitting text into chunks.
  chunking,

  /// Generating embeddings for chunks.
  embedding,

  /// Finalizing and saving to database.
  finalizing,

  /// Processing complete.
  complete,
}

/// Extension methods for ProcessingPhase.
extension ProcessingPhaseExtension on ProcessingPhase {
  /// Get human-readable description.
  String get description {
    switch (this) {
      case ProcessingPhase.idle:
        return 'Preparing...';
      case ProcessingPhase.loading:
        return 'Loading PDF...';
      case ProcessingPhase.extractingText:
        return 'Extracting text...';
      case ProcessingPhase.chunking:
        return 'Creating chunks...';
      case ProcessingPhase.embedding:
        return 'Generating embeddings & page index...';
      case ProcessingPhase.finalizing:
        return 'Finalizing...';
      case ProcessingPhase.complete:
        return 'Complete!';
    }
  }

  /// Get short label for UI.
  String get label {
    switch (this) {
      case ProcessingPhase.idle:
        return 'Prepare';
      case ProcessingPhase.loading:
        return 'Load';
      case ProcessingPhase.extractingText:
        return 'Extract';
      case ProcessingPhase.chunking:
        return 'Chunk';
      case ProcessingPhase.embedding:
        return 'Embed';
      case ProcessingPhase.finalizing:
        return 'Finalize';
      case ProcessingPhase.complete:
        return 'Done';
    }
  }

  /// Get step number (1-based).
  int get stepNumber {
    switch (this) {
      case ProcessingPhase.idle:
        return 0;
      case ProcessingPhase.loading:
        return 1;
      case ProcessingPhase.extractingText:
        return 2;
      case ProcessingPhase.chunking:
        return 3;
      case ProcessingPhase.embedding:
        return 4;
      case ProcessingPhase.finalizing:
        return 5;
      case ProcessingPhase.complete:
        return 6;
    }
  }

  /// Total number of processing steps.
  static int get totalSteps => 5;

  /// Check if this step is before another.
  bool isBefore(ProcessingPhase other) => stepNumber < other.stepNumber;

  /// Check if this step is after another.
  bool isAfter(ProcessingPhase other) => stepNumber > other.stepNumber;

  /// Check if this step is active or completed relative to another.
  bool isActiveOrComplete(ProcessingPhase current) =>
      stepNumber <= current.stepNumber;
}
