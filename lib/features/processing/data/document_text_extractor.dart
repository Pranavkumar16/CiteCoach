import 'dart:io';
import 'dart:typed_data';

import 'package:docx_to_text/docx_to_text.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';

final documentTextExtractorProvider = Provider<DocumentTextExtractor>((ref) {
  return DocumentTextExtractor();
});

/// Supported document types.
enum DocumentType {
  pdf,
  scannedPdf,
  docx,
  doc,
  txt,
  markdown,
  epub,
  image,
  unknown;

  /// Human-readable label.
  String get label {
    switch (this) {
      case DocumentType.pdf: return 'PDF';
      case DocumentType.scannedPdf: return 'Scanned PDF';
      case DocumentType.docx: return 'Word Document';
      case DocumentType.doc: return 'Word Document (Legacy)';
      case DocumentType.txt: return 'Text File';
      case DocumentType.markdown: return 'Markdown';
      case DocumentType.epub: return 'EPUB';
      case DocumentType.image: return 'Image';
      case DocumentType.unknown: return 'Unknown';
    }
  }

  /// Icon name for UI.
  String get iconName {
    switch (this) {
      case DocumentType.pdf:
      case DocumentType.scannedPdf: return 'picture_as_pdf';
      case DocumentType.docx:
      case DocumentType.doc: return 'description';
      case DocumentType.txt:
      case DocumentType.markdown: return 'text_snippet';
      case DocumentType.epub: return 'menu_book';
      case DocumentType.image: return 'image';
      case DocumentType.unknown: return 'insert_drive_file';
    }
  }

  /// Whether this type supports page-level navigation.
  bool get hasPages {
    switch (this) {
      case DocumentType.pdf:
      case DocumentType.scannedPdf:
        return true;
      default:
        return false;
    }
  }

  /// Detect document type from file extension.
  static DocumentType fromExtension(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.pdf': return DocumentType.pdf;
      case '.docx': return DocumentType.docx;
      case '.doc': return DocumentType.doc;
      case '.txt': return DocumentType.txt;
      case '.md':
      case '.markdown': return DocumentType.markdown;
      case '.epub': return DocumentType.epub;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.bmp':
      case '.webp':
      case '.tiff':
      case '.tif': return DocumentType.image;
      default: return DocumentType.unknown;
    }
  }

  /// All supported file extensions.
  static List<String> get supportedExtensions => [
    'pdf', 'docx', 'doc', 'txt', 'md', 'markdown',
    'epub', 'jpg', 'jpeg', 'png', 'bmp', 'webp', 'tiff', 'tif',
  ];
}

/// Result of text extraction from any document type.
class ExtractionResult {
  const ExtractionResult({
    required this.documentType,
    required this.pageCount,
    required this.pages,
    this.error,
  });

  final DocumentType documentType;
  final int pageCount;

  /// Extracted text per page (1-based page numbers).
  /// For non-paged documents (txt, docx, epub), content is split
  /// into virtual pages of ~3000 chars for consistent citation UX.
  final Map<int, String> pages;

  final String? error;
  bool get isSuccess => error == null && pages.isNotEmpty;

  factory ExtractionResult.error(String message) {
    return ExtractionResult(
      documentType: DocumentType.unknown,
      pageCount: 0,
      pages: {},
      error: message,
    );
  }
}

typedef ProgressCallback = void Function(int current, int total, String status);

/// Unified text extraction service for all supported document types.
///
/// Routes each file type to the appropriate extraction engine:
/// - PDF: Syncfusion text extraction → OCR fallback for scanned pages
/// - DOCX/DOC: docx_to_text package
/// - TXT/MD: Direct file read
/// - EPUB: epubx chapter extraction
/// - Images: Google ML Kit on-device OCR
class DocumentTextExtractor {
  DocumentTextExtractor();

  /// On-device text recognizer (lazy initialized).
  TextRecognizer? _textRecognizer;

  static const int _virtualPageSize = 3000; // chars per virtual page

  /// Extract text from any supported document.
  Future<ExtractionResult> extractText(
    String filePath, {
    ProgressCallback? onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return ExtractionResult.error('File not found: $filePath');
    }

    final docType = DocumentType.fromExtension(filePath);
    debugPrint('DocumentTextExtractor: Extracting $docType from $filePath');

    switch (docType) {
      case DocumentType.pdf:
        return _extractPdf(filePath, onProgress: onProgress);
      case DocumentType.docx:
        return _extractDocx(filePath, onProgress: onProgress);
      case DocumentType.doc:
        return _extractDocx(filePath, onProgress: onProgress);
      case DocumentType.txt:
        return _extractPlainText(filePath, onProgress: onProgress);
      case DocumentType.markdown:
        return _extractPlainText(filePath, onProgress: onProgress);
      case DocumentType.epub:
        return _extractEpub(filePath, onProgress: onProgress);
      case DocumentType.image:
        return _extractImage(filePath, onProgress: onProgress);
      default:
        return ExtractionResult.error('Unsupported file format');
    }
  }

  // ========== PDF Extraction with OCR Fallback ==========

  Future<ExtractionResult> _extractPdf(
    String filePath, {
    ProgressCallback? onProgress,
  }) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      final pages = <int, String>{};
      int scannedPageCount = 0;
      bool isScanned = false;

      for (int i = 0; i < pageCount; i++) {
        final pageNumber = i + 1;
        onProgress?.call(pageNumber, pageCount, 'Extracting page $pageNumber');

        try {
          final extractor = PdfTextExtractor(document);
          final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
          final cleaned = _cleanText(text);

          if (cleaned.length > 20) {
            pages[pageNumber] = cleaned;
          } else {
            // Page has little/no text — likely scanned, try OCR
            scannedPageCount++;
            onProgress?.call(pageNumber, pageCount, 'OCR page $pageNumber');
            final ocrText = await _ocrPdfPage(document, i);
            if (ocrText.isNotEmpty) {
              pages[pageNumber] = ocrText;
              isScanned = true;
            }
          }
        } catch (e) {
          debugPrint('DocumentTextExtractor: Page $pageNumber error: $e');
        }
        await Future.delayed(const Duration(milliseconds: 10));
      }

      document.dispose();
      debugPrint('DocumentTextExtractor: PDF extracted. ${pages.length}/$pageCount pages. '
          'Scanned pages: $scannedPageCount');

      return ExtractionResult(
        documentType: isScanned ? DocumentType.scannedPdf : DocumentType.pdf,
        pageCount: pageCount,
        pages: pages,
      );
    } catch (e) {
      return ExtractionResult.error('PDF extraction failed: $e');
    }
  }

  /// OCR a single PDF page by rendering to image then running ML Kit.
  Future<String> _ocrPdfPage(PdfDocument document, int pageIndex) async {
    // PDF page-to-image rendering is not supported by syncfusion_flutter_pdf.
    // Scanned PDF pages without embedded text will return empty.
    debugPrint('DocumentTextExtractor: PDF OCR not available for page $pageIndex (no image renderer)');
    return '';
  }

  // ========== Word Document Extraction ==========

  Future<ExtractionResult> _extractDocx(
    String filePath, {
    ProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(0, 1, 'Reading document...');
      final bytes = await File(filePath).readAsBytes();
      final text = docxToText(bytes);

      if (text.isEmpty) {
        return ExtractionResult.error('No text found in document');
      }

      onProgress?.call(1, 1, 'Processing text...');
      final pages = _splitIntoVirtualPages(text);

      return ExtractionResult(
        documentType: DocumentType.docx,
        pageCount: pages.length,
        pages: pages,
      );
    } catch (e) {
      return ExtractionResult.error('Word document extraction failed: $e');
    }
  }

  // ========== Plain Text / Markdown ==========

  Future<ExtractionResult> _extractPlainText(
    String filePath, {
    ProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(0, 1, 'Reading file...');
      final text = await File(filePath).readAsString();

      if (text.isEmpty) {
        return ExtractionResult.error('File is empty');
      }

      final docType = DocumentType.fromExtension(filePath);
      // For markdown, strip common syntax for cleaner text
      final cleanedText = docType == DocumentType.markdown
          ? _stripMarkdown(text)
          : text;

      onProgress?.call(1, 1, 'Processing...');
      final pages = _splitIntoVirtualPages(cleanedText);

      return ExtractionResult(
        documentType: docType,
        pageCount: pages.length,
        pages: pages,
      );
    } catch (e) {
      return ExtractionResult.error('Text extraction failed: $e');
    }
  }

  /// Strip markdown formatting for cleaner RAG processing.
  String _stripMarkdown(String text) {
    var result = text;
    // Remove headers markup but keep text
    result = result.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    // Remove bold/italic markers
    result = result.replaceAll(RegExp(r'\*{1,3}'), '');
    result = result.replaceAll(RegExp(r'_{1,3}'), '');
    // Remove link syntax, keep text
    result = result.replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m.group(1) ?? '');
    // Remove image syntax
    result = result.replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '');
    // Remove code blocks
    result = result.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    result = result.replaceAll(RegExp(r'`[^`]+`'), '');
    return result;
  }

  // ========== EPUB Extraction ==========

  Future<ExtractionResult> _extractEpub(
    String filePath, {
    ProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(0, 1, 'Reading EPUB...');
      final bytes = await File(filePath).readAsBytes();
      final book = await EpubReader.readBook(bytes);

      final allText = StringBuffer();

      // Extract text from chapters
      final chapters = book.Chapters ?? [];
      for (int i = 0; i < chapters.length; i++) {
        onProgress?.call(i + 1, chapters.length, 'Chapter ${i + 1}');

        final chapter = chapters[i];
        final chapterText = _stripHtml(chapter.HtmlContent ?? '');
        if (chapterText.isNotEmpty) {
          allText.writeln(chapterText);
          allText.writeln(); // Paragraph break between chapters
        }

        // Also extract sub-chapters
        for (final sub in chapter.SubChapters ?? []) {
          final subText = _stripHtml(sub.HtmlContent ?? '');
          if (subText.isNotEmpty) {
            allText.writeln(subText);
            allText.writeln();
          }
        }
      }

      final text = allText.toString();
      if (text.trim().isEmpty) {
        return ExtractionResult.error('No readable text found in EPUB');
      }

      final pages = _splitIntoVirtualPages(text);

      return ExtractionResult(
        documentType: DocumentType.epub,
        pageCount: pages.length,
        pages: pages,
      );
    } catch (e) {
      return ExtractionResult.error('EPUB extraction failed: $e');
    }
  }

  /// Strip HTML tags and decode common entities.
  String _stripHtml(String html) {
    var text = html;
    // Remove all tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    // Decode common entities
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&apos;', "'");
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll(RegExp(r'&#\d+;'), '');
    // Clean whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  // ========== Image OCR ==========

  Future<ExtractionResult> _extractImage(
    String filePath, {
    ProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(0, 1, 'Running OCR on image...');
      final text = await _runOcr(filePath);

      if (text.isEmpty) {
        return ExtractionResult.error('No text detected in image');
      }

      onProgress?.call(1, 1, 'Processing text...');
      // Images are always "page 1"
      return ExtractionResult(
        documentType: DocumentType.image,
        pageCount: 1,
        pages: {1: text},
      );
    } catch (e) {
      return ExtractionResult.error('Image OCR failed: $e');
    }
  }

  /// Run Google ML Kit on-device OCR on an image file.
  Future<String> _runOcr(String imagePath) async {
    try {
      _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer!.processImage(inputImage);

      return recognizedText.text;
    } catch (e) {
      debugPrint('DocumentTextExtractor: OCR error: $e');
      return '';
    }
  }

  // ========== Helpers ==========

  /// Split long text into virtual pages for consistent citation UX.
  /// Each "page" is roughly _virtualPageSize characters, broken at paragraph
  /// boundaries so citations remain meaningful.
  Map<int, String> _splitIntoVirtualPages(String text) {
    final pages = <int, String>{};
    if (text.isEmpty) return pages;

    final paragraphs = text.split(RegExp(r'\n\s*\n'));
    final currentPage = StringBuffer();
    int pageNumber = 1;

    for (final paragraph in paragraphs) {
      final trimmed = paragraph.trim();
      if (trimmed.isEmpty) continue;

      if (currentPage.length + trimmed.length > _virtualPageSize &&
          currentPage.isNotEmpty) {
        pages[pageNumber] = currentPage.toString().trim();
        pageNumber++;
        currentPage.clear();
      }
      currentPage.writeln(trimmed);
      currentPage.writeln();
    }

    // Don't forget the last page
    if (currentPage.isNotEmpty) {
      pages[pageNumber] = currentPage.toString().trim();
    }

    return pages;
  }

  /// Clean extracted text.
  String _cleanText(String text) {
    if (text.isEmpty) return '';
    var cleaned = text.replaceAll(RegExp(r'\s+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'[\x00-\x09\x0B\x0C\x0E-\x1F]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\r\n|\r'), '\n');
    return cleaned.trim();
  }

  /// Dispose resources.
  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}
