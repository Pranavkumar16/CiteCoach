import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Provider for the PDF processor.
final pdfProcessorProvider = Provider<PdfProcessor>((ref) {
  return PdfProcessor();
});

/// Result of PDF text extraction.
class ExtractionResult {
  const ExtractionResult({
    required this.pageCount,
    required this.pages,
    this.error,
  });

  /// Total number of pages.
  final int pageCount;

  /// Extracted text for each page (indexed by page number, 1-based).
  final Map<int, String> pages;

  /// Error message if extraction failed.
  final String? error;

  /// Check if extraction was successful.
  bool get isSuccess => error == null && pages.isNotEmpty;
}

/// Result of text chunking.
class ChunkingResult {
  const ChunkingResult({
    required this.chunks,
    this.error,
  });

  /// List of text chunks with metadata.
  final List<TextChunk> chunks;

  /// Error message if chunking failed.
  final String? error;

  /// Check if chunking was successful.
  bool get isSuccess => error == null;
}

/// A text chunk with metadata for RAG retrieval.
class TextChunk {
  const TextChunk({
    required this.pageNumber,
    required this.chunkIndex,
    required this.text,
    required this.startOffset,
    required this.endOffset,
  });

  /// The page this chunk belongs to.
  final int pageNumber;

  /// Index of this chunk within the page.
  final int chunkIndex;

  /// The actual text content.
  final String text;

  /// Start character offset within the page.
  final int startOffset;

  /// End character offset within the page.
  final int endOffset;

  /// Estimated token count (rough approximation: ~4 chars per token).
  int get estimatedTokens => (text.length / 4).ceil();
}

/// Progress callback for extraction/chunking operations.
typedef ProgressCallback = void Function(int current, int total, String status);

/// Service for processing PDF documents.
/// 
/// Handles:
/// - Text extraction from PDF pages
/// - Text chunking with overlap for RAG retrieval
class PdfProcessor {
  PdfProcessor();

  /// Configuration for chunking.
  static const int chunkSize = 512; // Target tokens per chunk (~2048 chars)
  static const int chunkOverlap = 64; // Overlap tokens (~256 chars)
  static const int minChunkSize = 100; // Minimum characters for a chunk

  /// Extract text from all pages of a PDF.
  Future<ExtractionResult> extractText(
    String filePath, {
    ProgressCallback? onProgress,
  }) async {
    try {
      debugPrint('PdfProcessor: Starting extraction for $filePath');

      // Read the PDF file
      final file = File(filePath);
      if (!await file.exists()) {
        return const ExtractionResult(
          pageCount: 0,
          pages: {},
          error: 'PDF file not found',
        );
      }

      final bytes = await file.readAsBytes();
      
      // Load PDF document
      final document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      
      debugPrint('PdfProcessor: PDF has $pageCount pages');

      final pages = <int, String>{};
      
      // Extract text from each page
      for (int i = 0; i < pageCount; i++) {
        final pageNumber = i + 1; // 1-based page numbers
        
        onProgress?.call(pageNumber, pageCount, 'Extracting page $pageNumber');
        
        try {
          // Access page to verify it exists (document.pages[i])
          final textExtractor = PdfTextExtractor(document);
          final text = textExtractor.extractText(startPageIndex: i, endPageIndex: i);
          
          // Clean and normalize the text
          final cleanedText = _cleanText(text);
          
          if (cleanedText.isNotEmpty) {
            pages[pageNumber] = cleanedText;
          }
          
          debugPrint('PdfProcessor: Page $pageNumber extracted (${cleanedText.length} chars)');
        } catch (e) {
          debugPrint('PdfProcessor: Error extracting page $pageNumber: $e');
          // Continue with other pages even if one fails
        }
        
        // Small delay to prevent UI blocking
        await Future.delayed(const Duration(milliseconds: 10));
      }

      document.dispose();

      debugPrint('PdfProcessor: Extraction complete. ${pages.length}/$pageCount pages extracted');

      return ExtractionResult(
        pageCount: pageCount,
        pages: pages,
      );
    } catch (e) {
      debugPrint('PdfProcessor: Extraction error: $e');
      return ExtractionResult(
        pageCount: 0,
        pages: {},
        error: 'Failed to extract text: ${e.toString()}',
      );
    }
  }

  /// Clean and normalize extracted text.
  String _cleanText(String text) {
    if (text.isEmpty) return '';

    // Replace multiple whitespace with single space
    var cleaned = text.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove control characters except newlines
    cleaned = cleaned.replaceAll(RegExp(r'[\x00-\x09\x0B\x0C\x0E-\x1F]'), '');
    
    // Normalize line breaks
    cleaned = cleaned.replaceAll(RegExp(r'\r\n|\r'), '\n');
    
    // Trim leading/trailing whitespace
    cleaned = cleaned.trim();
    
    return cleaned;
  }

  /// Chunk text from extracted pages for RAG retrieval.
  /// 
  /// Uses a sliding window approach with overlap to ensure
  /// context is preserved across chunk boundaries.
  Future<ChunkingResult> chunkText(
    Map<int, String> pages, {
    ProgressCallback? onProgress,
  }) async {
    try {
      debugPrint('PdfProcessor: Starting chunking for ${pages.length} pages');

      final chunks = <TextChunk>[];
      final pageNumbers = pages.keys.toList()..sort();
      
      for (int i = 0; i < pageNumbers.length; i++) {
        final pageNumber = pageNumbers[i];
        final pageText = pages[pageNumber]!;
        
        onProgress?.call(i + 1, pageNumbers.length, 'Chunking page $pageNumber');
        
        // Chunk this page's text
        final pageChunks = _chunkPageText(pageNumber, pageText);
        chunks.addAll(pageChunks);
        
        // Small delay to prevent UI blocking
        await Future.delayed(const Duration(milliseconds: 5));
      }

      debugPrint('PdfProcessor: Chunking complete. ${chunks.length} chunks created');

      return ChunkingResult(chunks: chunks);
    } catch (e) {
      debugPrint('PdfProcessor: Chunking error: $e');
      return ChunkingResult(
        chunks: [],
        error: 'Failed to chunk text: ${e.toString()}',
      );
    }
  }

  /// Chunk a single page's text.
  List<TextChunk> _chunkPageText(int pageNumber, String text) {
    if (text.length < minChunkSize) {
      // Text too short, return as single chunk
      return [
        TextChunk(
          pageNumber: pageNumber,
          chunkIndex: 0,
          text: text,
          startOffset: 0,
          endOffset: text.length,
        ),
      ];
    }

    final chunks = <TextChunk>[];
    final targetChunkChars = chunkSize * 4; // ~4 chars per token
    final overlapChars = chunkOverlap * 4;
    
    int startOffset = 0;
    int chunkIndex = 0;

    while (startOffset < text.length) {
      // Calculate end offset
      int endOffset = startOffset + targetChunkChars;
      
      if (endOffset >= text.length) {
        // Last chunk
        endOffset = text.length;
      } else {
        // Try to break at sentence boundary
        endOffset = _findSentenceBoundary(text, endOffset, targetChunkChars);
      }

      final chunkText = text.substring(startOffset, endOffset).trim();
      
      if (chunkText.length >= minChunkSize) {
        chunks.add(TextChunk(
          pageNumber: pageNumber,
          chunkIndex: chunkIndex,
          text: chunkText,
          startOffset: startOffset,
          endOffset: endOffset,
        ));
        chunkIndex++;
      }

      // Move start position with overlap
      startOffset = endOffset - overlapChars;
      if (startOffset < 0) startOffset = 0;
      
      // Prevent infinite loop
      if (startOffset >= text.length - minChunkSize) break;
    }

    return chunks;
  }

  /// Find the best sentence boundary near the target position.
  int _findSentenceBoundary(String text, int targetPos, int maxChars) {
    // Define sentence-ending punctuation
    final sentenceEnders = ['. ', '! ', '? ', '.\n', '!\n', '?\n'];
    
    // Search window: 20% of chunk size before and after target
    final searchWindow = (maxChars * 0.2).toInt();
    final searchStart = (targetPos - searchWindow).clamp(0, text.length);
    final searchEnd = (targetPos + searchWindow).clamp(0, text.length);
    
    int bestPos = targetPos;
    int bestDistance = searchWindow + 1;
    
    for (final ender in sentenceEnders) {
      int pos = searchStart;
      while (pos < searchEnd) {
        final idx = text.indexOf(ender, pos);
        if (idx == -1 || idx >= searchEnd) break;
        
        final endPos = idx + ender.length;
        final distance = (endPos - targetPos).abs();
        
        if (distance < bestDistance) {
          bestDistance = distance;
          bestPos = endPos;
        }
        
        pos = idx + 1;
      }
    }
    
    return bestPos.clamp(0, text.length);
  }

  /// Get estimated processing time based on page count.
  Duration estimateProcessingTime(int pageCount) {
    // Rough estimate: ~500ms per page for extraction + chunking + embedding
    return Duration(milliseconds: pageCount * 500);
  }
}
